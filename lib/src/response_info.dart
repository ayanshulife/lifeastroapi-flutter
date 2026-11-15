/// What the API reports about a call besides its body: request id, credits,
/// rate limit, cache and language. Passed to the `onResponse` hook.
library;

/// Your plan's per-minute rate limit, from the `X-RateLimit-*` headers.
class RateLimit {
  /// Creates a rate limit.
  const RateLimit({
    required this.limit,
    required this.remaining,
    required this.resetAt,
  });

  /// `X-RateLimit-Limit`: requests per minute for your plan.
  final int limit;

  /// `X-RateLimit-Remaining`: requests left in the current window.
  final int remaining;

  /// `X-RateLimit-Reset`: when the window resets, in UTC.
  final DateTime resetAt;

  @override
  bool operator ==(Object other) =>
      other is RateLimit &&
      other.limit == limit &&
      other.remaining == remaining &&
      other.resetAt == resetAt;

  @override
  int get hashCode => Object.hash(limit, remaining, resetAt);

  @override
  String toString() => 'RateLimit(limit: $limit, remaining: $remaining, '
      'resetAt: ${resetAt.toIso8601String()})';
}

/// What the API reported about one call besides its body: the request id,
/// your credit balance after the call, your plan's per-minute rate limit and
/// whether the answer came from the API's cache.
///
/// Passed to `onResponse` (client parameter or [RequestOptions]) for every
/// final HTTP response, success or error; not for network failures or for
/// attempts that were retried. A field is `null` when the API did not send
/// its header.
class ResponseInfo {
  /// Creates a response info.
  const ResponseInfo({
    required this.status,
    required this.path,
    this.requestId,
    this.creditsRemaining,
    this.rateLimit,
    this.cache,
    this.language,
  });

  /// HTTP status of the response.
  final int status;

  /// Request path, e.g. `/v1/panchang/basic`.
  final String path;

  /// `X-Request-ID`. Quote it to support.
  final String? requestId;

  /// `X-Credits-Remaining`: the balance after this call (unchanged after a
  /// failed call). `null` on free-tier accounts, whose allowance is not a
  /// balance, and on calls that cost nothing.
  final int? creditsRemaining;

  /// `X-RateLimit-*`: set only when all three headers are present and numeric.
  final RateLimit? rateLimit;

  /// `X-Cache`, e.g. `HIT` when the API answered from its cache (billed the
  /// same).
  final String? cache;

  /// `Content-Language`: the language the answer is in.
  final String? language;

  @override
  bool operator ==(Object other) =>
      other is ResponseInfo &&
      other.status == status &&
      other.path == path &&
      other.requestId == requestId &&
      other.creditsRemaining == creditsRemaining &&
      other.rateLimit == rateLimit &&
      other.cache == cache &&
      other.language == language;

  @override
  int get hashCode => Object.hash(
      status, path, requestId, creditsRemaining, rateLimit, cache, language);

  @override
  String toString() => 'ResponseInfo(status: $status, path: $path, '
      'requestId: $requestId, creditsRemaining: $creditsRemaining, '
      'rateLimit: $rateLimit, cache: $cache, language: $language)';
}

/// Receives the [ResponseInfo] of each call. Errors thrown inside it (or by
/// the future of an `async` hook) are ignored.
typedef ResponseHook = void Function(ResponseInfo info);

/// Reads the [ResponseInfo] of a response. Header names are case-insensitive;
/// a header that is missing or not a number leaves its field `null`.
ResponseInfo responseInfoFrom(
    int status, String path, Map<String, String> headers) {
  final h = <String, String>{
    for (final e in headers.entries) e.key.toLowerCase(): e.value,
  };
  int? number(String name) {
    final v = h[name];
    return v == null ? null : int.tryParse(v.trim());
  }

  String? text(String name) {
    final v = h[name];
    return v == null || v.isEmpty ? null : v;
  }

  final limit = number('x-ratelimit-limit');
  final remaining = number('x-ratelimit-remaining');
  final reset = number('x-ratelimit-reset');
  RateLimit? rateLimit;
  // DateTime covers +/- 8.64e12 seconds around the epoch.
  if (limit != null &&
      remaining != null &&
      reset != null &&
      reset.abs() <= 8640000000000) {
    rateLimit = RateLimit(
      limit: limit,
      remaining: remaining,
      resetAt: DateTime.fromMillisecondsSinceEpoch(reset * 1000, isUtc: true),
    );
  }
  return ResponseInfo(
    status: status,
    path: path,
    requestId: text('x-request-id'),
    creditsRemaining: number('x-credits-remaining'),
    rateLimit: rateLimit,
    cache: text('x-cache'),
    language: text('content-language'),
  );
}

/// Calls each hook with [info]. A hook that throws, or whose future fails,
/// never breaks the call.
void emitResponseInfo(List<ResponseHook?> hooks, ResponseInfo info) {
  for (final hook in hooks) {
    if (hook == null) continue;
    try {
      // An `async` hook is a valid `void Function`; catch its future's error
      // too, so it does not surface as an uncaught error.
      final Object? result = hook(info) as Object?;
      if (result is Future<Object?>) {
        result.ignore();
      }
    } catch (_) {
      // A logging hook must never break the call.
    }
  }
}
