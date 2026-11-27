/// HTTP transport: URL and query building, bearer auth, timeout, JSON
/// parsing, typed errors, bounded retries with backoff and `Retry-After`, and
/// the `onResponse` hook.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'errors.dart';
import 'params.dart';
import 'response_info.dart';

/// Per-call options, accepted by every method as `options:`.
class RequestOptions {
  /// Creates per-call options.
  const RequestOptions(
      {this.timeout, this.raw = false, this.abortTrigger, this.onResponse});

  /// Overrides the client timeout for this call.
  final Duration? timeout;

  /// Returns the body exactly as received, without unwrapping a
  /// `{ data, meta }` envelope if one is present.
  final bool raw;

  /// Cancels the call when this future completes. The call then throws
  /// [LifeAstroConnectionException] with code `aborted`.
  final Future<void>? abortTrigger;

  /// Called with this call's [ResponseInfo] (after the client-level
  /// `onResponse`). Errors thrown inside it are ignored.
  final ResponseHook? onResponse;
}

/// What a resource group needs from the client: one GET request.
abstract interface class ClientCore {
  /// Sends `GET path?query` and returns the parsed JSON body.
  Future<T> request<T>(String path, Map<String, Object?> query,
      [RequestOptions? options]);
}

/// Resolved client settings.
class TransportConfig {
  /// Creates the settings.
  TransportConfig({
    required this.apiKey,
    required this.baseUrl,
    required this.timeout,
    required this.maxRetries,
    required this.client,
    required this.ownsClient,
    required this.userAgent,
    required this.defaultHeaders,
    this.onResponse,
  });

  /// Bearer token.
  final String apiKey;

  /// API base URL without a trailing slash.
  final String baseUrl;

  /// Per-request timeout.
  final Duration timeout;

  /// Retries on 408/425/429/5xx and network errors.
  final int maxRetries;

  /// The HTTP client.
  final http.Client client;

  /// Whether [client] was created by the SDK (and is closed by it).
  final bool ownsClient;

  /// `User-Agent` value, or `null` where a platform forbids setting it.
  final String? userAgent;

  /// Extra headers sent on every request (applied last).
  final Map<String, String> defaultHeaders;

  /// Called with the [ResponseInfo] of every final response, before a
  /// per-call hook.
  final ResponseHook? onResponse;
}

const _retryableStatus = {408, 425, 429, 500, 502, 503, 504};

/// The [ClientCore] that talks HTTP.
class Transport implements ClientCore {
  /// Creates a transport for [config].
  Transport(this.config);

  /// The resolved settings.
  final TransportConfig config;
  final Random _random = Random();

  /// Closes the HTTP client if the SDK created it.
  void close() {
    if (config.ownsClient) config.client.close();
  }

  Map<String, String> _headers() {
    final headers = <String, String>{
      'Authorization': 'Bearer ${config.apiKey}',
      'Accept': 'application/json',
    };
    final ua = config.userAgent;
    if (ua != null) headers['User-Agent'] = ua;
    headers.addAll(config.defaultHeaders);
    return headers;
  }

  Duration _backoff(int attempt, Duration? retryAfter) {
    if (retryAfter != null) {
      const cap = Duration(seconds: 30);
      return retryAfter > cap ? cap : retryAfter;
    }
    final base = min(500 * pow(2, attempt).toInt(), 8000);
    return Duration(milliseconds: base + _random.nextInt(250));
  }

  @override
  Future<T> request<T>(String path, Map<String, Object?> query,
      [RequestOptions? options]) async {
    final body = await send(path, query, options);
    return body as T;
  }

  /// Performs the GET and returns the parsed body (unwrapping a `data`
  /// envelope unless [RequestOptions.raw]).
  Future<Object?> send(String path, Map<String, Object?> query,
      [RequestOptions? options]) async {
    final fullPath = path.startsWith('/') ? path : '/$path';
    final url = Uri.parse(config.baseUrl + fullPath + encodeQuery(query));
    void report(_RawResponse res) {
      final hooks = [config.onResponse, options?.onResponse];
      if (hooks.every((h) => h == null)) return;
      emitResponseInfo(
          hooks, responseInfoFrom(res.status, fullPath, res.headers));
    }

    final timeout = options?.timeout ?? config.timeout;

    var callerAborted = false;
    final callerAbort = Completer<void>();
    final trigger = options?.abortTrigger;
    if (trigger != null) {
      void onAbort() {
        callerAborted = true;
        if (!callerAbort.isCompleted) callerAbort.complete();
      }

      unawaited(trigger.then((_) => onAbort(), onError: (_) => onAbort()));
    }

    LifeAstroException? lastError;
    for (var attempt = 0; attempt <= config.maxRetries; attempt++) {
      if (callerAborted) {
        throw LifeAstroConnectionException('Request aborted by caller',
            code: 'aborted');
      }

      final attemptAbort = Completer<void>();
      final result = Completer<_RawResponse>();
      var timedOut = false;
      void stop(Object reason) {
        if (!result.isCompleted) result.completeError(reason);
        if (!attemptAbort.isCompleted) attemptAbort.complete();
      }

      final timer = Timer(timeout, () {
        timedOut = true;
        stop(const _TimedOut());
      });
      unawaited(callerAbort.future.then((_) => stop(const _CallerAborted())));

      // The body is read inside the timeout window too, so a slow download is
      // bounded by `timeout`, not only the connection and headers.
      unawaited(_fetch(url, attemptAbort.future).then((r) {
        if (!result.isCompleted) result.complete(r);
      }, onError: (Object e, StackTrace st) {
        if (!result.isCompleted) result.completeError(e, st);
      }));

      _RawResponse res;
      try {
        res = await result.future;
      } on _CallerAborted {
        throw LifeAstroConnectionException('Request aborted by caller',
            code: 'aborted');
      } catch (e) {
        lastError = timedOut
            ? LifeAstroConnectionException(
                'Request timed out after ${timeout.inMilliseconds}ms',
                code: 'timeout',
                cause: e)
            : LifeAstroConnectionException('Network request failed',
                code: 'connection_error', cause: e);
        if (attempt < config.maxRetries) {
          await _sleep(
              _backoff(attempt, null), callerAbort.future, () => callerAborted);
          continue;
        }
        throw lastError;
      } finally {
        timer.cancel();
      }

      Object? body;
      var nonJson = false;
      if (res.text.isNotEmpty) {
        try {
          body = jsonDecode(res.text);
        } on FormatException {
          body = res.text;
          nonJson = true;
        }
      }

      if (res.status >= 200 && res.status < 300) {
        report(res);
        // A 2xx that is not JSON is not an API answer (a proxy or captive page).
        if (nonJson) throw nonJsonError(res.status, res.text);
        if (options?.raw ?? false) return body;
        // The API returns bare JSON today. A `{ data, meta }` envelope is
        // unwrapped if a response ever carries one, as the Node SDK does.
        if (body is Map && body.containsKey('data')) return body['data'];
        return body;
      }

      final retryAfter = parseRetryAfter(res.headers['retry-after']);
      lastError = nonJson
          ? nonJsonError(res.status, res.text, retryAfter)
          : errorFromResponse(res.status, body, retryAfter);
      if (_retryableStatus.contains(res.status) &&
          attempt < config.maxRetries) {
        await _sleep(_backoff(attempt, retryAfter), callerAbort.future,
            () => callerAborted);
        continue;
      }
      report(res);
      throw lastError;
    }
    throw lastError ??
        LifeAstroConnectionException('Request failed after retries');
  }

  Future<_RawResponse> _fetch(Uri url, Future<void> abort) async {
    final req = http.AbortableRequest('GET', url, abortTrigger: abort)
      ..headers.addAll(_headers());
    final res = await config.client.send(req);
    final bytes = await res.stream.toBytes();
    return _RawResponse(
        res.statusCode, res.headers, utf8.decode(bytes, allowMalformed: true));
  }
}

Future<void> _sleep(
    Duration d, Future<void> abort, bool Function() aborted) async {
  if (aborted()) {
    throw LifeAstroConnectionException('Request aborted', code: 'aborted');
  }
  final done = Completer<void>();
  final timer = Timer(d, () {
    if (!done.isCompleted) done.complete();
  });
  unawaited(abort.then((_) {
    timer.cancel();
    if (!done.isCompleted) done.complete();
  }));
  await done.future;
  if (aborted()) {
    throw LifeAstroConnectionException('Request aborted', code: 'aborted');
  }
}

/// Parses a `Retry-After` header: seconds, or an HTTP date.
Duration? parseRetryAfter(String? header, [DateTime? now]) {
  if (header == null) return null;
  final h = header.trim();
  if (h.isEmpty) return null;
  final secs = num.tryParse(h);
  if (secs != null) {
    return Duration(milliseconds: max(0, (secs * 1000).round()));
  }
  final at = _parseHttpDate(h);
  if (at == null) return null;
  final diff = at.difference((now ?? DateTime.now()).toUtc());
  return diff.isNegative ? Duration.zero : diff;
}

const _months = {
  'jan': 1,
  'feb': 2,
  'mar': 3,
  'apr': 4,
  'may': 5,
  'jun': 6,
  'jul': 7,
  'aug': 8,
  'sep': 9,
  'oct': 10,
  'nov': 11,
  'dec': 12,
};
final _httpDateRe = RegExp(
    r'^(?:\w{3},\s*)?(\d{1,2})[\s-](\w{3})[\s-](\d{2,4})\s+(\d{2}):(\d{2}):(\d{2})\s*GMT$',
    caseSensitive: false);

/// Parses an IMF-fixdate (`Wed, 21 Oct 2025 07:28:00 GMT`) or RFC 850 date.
DateTime? _parseHttpDate(String s) {
  final m = _httpDateRe.firstMatch(s);
  if (m == null) return null;
  final month = _months[m.group(2)!.toLowerCase()];
  if (month == null) return null;
  var year = int.parse(m.group(3)!);
  if (year < 100) year += year < 70 ? 2000 : 1900;
  return DateTime.utc(year, month, int.parse(m.group(1)!),
      int.parse(m.group(4)!), int.parse(m.group(5)!), int.parse(m.group(6)!));
}

class _RawResponse {
  _RawResponse(this.status, this.headers, this.text);
  final int status;
  final Map<String, String> headers;
  final String text;
}

class _TimedOut {
  const _TimedOut();
}

class _CallerAborted {
  const _CallerAborted();
}
