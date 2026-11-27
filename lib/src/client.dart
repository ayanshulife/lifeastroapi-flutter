/// The LifeAstro client: configuration, the resource groups, and a generic
/// escape hatch (`request` / `get`) for endpoints without a typed method.
library;

import 'package:http/http.dart' as http;

import 'platform/platform.dart';
import 'resources/resources.dart';
import 'response_info.dart';
import 'transport.dart';
import 'version.dart';

const _defaultBaseUrl = 'https://api.lifeastroapi.com';

/// Reads `LIFEASTRO_API_KEY` from the environment (native platforms only).
/// Tests replace it.
String? Function() environmentApiKey = platformApiKey;

/// The LifeAstroAPI client.
///
/// ```dart
/// import 'package:lifeastroapi/lifeastroapi.dart';
///
/// final client = LifeAstro(apiKey: 'dv_live_...');
///
/// final day = await client.panchang.basic(
///   lat: 19.076, lon: 72.8777, tz: 'Asia/Kolkata', lang: Lang.gu,
/// );
///
/// final planets = await client.chart.planets(
///   birth: const BirthInput(
///     date: '1990-01-15', time: '10:30', tz: 'Asia/Kolkata',
///     lat: 19.076, lon: 72.8777,
///   ),
/// );
///
/// client.close();
/// ```
class LifeAstro extends LifeAstroResources {
  /// Creates a client.
  ///
  /// - [apiKey]: your `dv_live_...` key. When omitted, `LIFEASTRO_API_KEY` is
  ///   read from the environment (native platforms). Get one at
  ///   https://lifeastroapi.com/dashboard/keys
  /// - [baseUrl]: the API (default `https://api.lifeastroapi.com`), a local
  ///   server, or your own backend that forwards to the API.
  /// - [timeout]: per-request timeout (default 30 seconds).
  /// - [maxRetries]: automatic retries on 429, 5xx and network errors
  ///   (default 2).
  /// - [httpClient]: your own `http.Client` (proxies, tests). The SDK does not
  ///   close a client you pass in.
  /// - [defaultHeaders]: extra headers sent on every request.
  /// - [onResponse]: called with the [ResponseInfo] of every call: request
  ///   id, credits left, rate limit, cache and language. Use it to log usage
  ///   or warn when credits run low. Errors thrown inside it are ignored.
  ///
  /// Throws [ArgumentError] when no API key is found.
  factory LifeAstro({
    String? apiKey,
    String? baseUrl,
    Duration timeout = const Duration(seconds: 30),
    int maxRetries = 2,
    http.Client? httpClient,
    Map<String, String> defaultHeaders = const {},
    ResponseHook? onResponse,
  }) {
    // Trimmed: a key read from a file or a quoted .env value often carries a
    // space or newline.
    final key = (apiKey ?? environmentApiKey())?.trim();
    if (key == null || key.isEmpty) {
      throw ArgumentError(
          'LifeAstro: an API key is required. Pass apiKey: or set '
          'LIFEASTRO_API_KEY. Get one at https://lifeastroapi.com/dashboard/keys');
    }
    final config = TransportConfig(
      apiKey: key,
      baseUrl: (baseUrl ?? _defaultBaseUrl).replaceFirst(RegExp(r'/+$'), ''),
      timeout: timeout,
      maxRetries: maxRetries < 0 ? 0 : maxRetries,
      client: httpClient ?? http.Client(),
      ownsClient: httpClient == null,
      userAgent: canSetUserAgent ? 'lifeastroapi-dart/$packageVersion' : null,
      defaultHeaders: Map.unmodifiable(defaultHeaders),
      onResponse: onResponse,
    );
    return LifeAstro._(Transport(config));
  }

  LifeAstro._(Transport super.core) : _transport = core;

  final Transport _transport;

  /// Calls any `/v1/*` endpoint directly and returns the parsed JSON.
  ///
  /// Useful for an endpoint that is newer than this SDK.
  ///
  /// ```dart
  /// final data = await client.request('/v1/panchang/tithi', query: {
  ///   'lat': 28.61, 'lon': 77.2, 'tz': 'Asia/Kolkata', 'date': '2027-01-15',
  /// });
  /// ```
  Future<T> request<T>(String path,
          {Map<String, Object?> query = const {}, RequestOptions? options}) =>
      _transport.request<T>(path, query, options);

  /// Alias for [request].
  Future<T> get<T>(String path,
          {Map<String, Object?> query = const {}, RequestOptions? options}) =>
      request<T>(path, query: query, options: options);

  /// Closes the HTTP client, if the SDK created it. Call it when you are done
  /// with the client.
  void close() => _transport.close();
}
