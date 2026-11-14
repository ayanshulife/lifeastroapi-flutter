/// Exceptions thrown by the SDK.
///
/// Every non-2xx response becomes a [LifeAstroException] (or a more specific
/// subclass) with the API's `code`, the HTTP `status` and the `request_id`.
/// Network failures and timeouts throw [LifeAstroConnectionException].
library;

/// Base class of every exception the SDK throws.
class LifeAstroException implements Exception {
  /// Creates an exception for an API error.
  LifeAstroException(
    this.message, {
    required this.code,
    required this.status,
    this.requestId,
    this.body,
    this.cause,
  });

  /// Human-readable message from the API (or from the SDK for network errors).
  final String message;

  /// Machine-readable API error code, for example `insufficient_credits`.
  final String code;

  /// HTTP status code; `0` for network failures and timeouts.
  final int status;

  /// API request id, when the response had one. Quote it to support.
  final String? requestId;

  /// The parsed response body, when there was one.
  final Object? body;

  /// The underlying error, for network failures.
  final Object? cause;

  /// Name of the exception class (stable on every platform, unlike `runtimeType`).
  String get name => 'LifeAstroException';

  @override
  String toString() {
    final id = requestId == null ? '' : ' (request_id: $requestId)';
    return '$name: $status $code: $message$id';
  }
}

/// 400: a query parameter was missing, malformed or out of range.
class BadRequestException extends LifeAstroException {
  /// Creates a 400 exception.
  BadRequestException(super.message,
      {required super.code,
      required super.status,
      super.requestId,
      super.body});

  @override
  String get name => 'BadRequestException';
}

/// 401: missing or invalid API key.
class AuthenticationException extends LifeAstroException {
  /// Creates a 401 exception.
  AuthenticationException(super.message,
      {required super.code,
      required super.status,
      super.requestId,
      super.body});

  @override
  String get name => 'AuthenticationException';
}

/// 402: out of credits, trial used up, or payment required.
class PaymentRequiredException extends LifeAstroException {
  /// Creates a 402 exception.
  PaymentRequiredException(super.message,
      {required super.code,
      required super.status,
      super.requestId,
      super.body});

  @override
  String get name => 'PaymentRequiredException';
}

/// 403: the key is valid but not allowed (plan, IP allow-list, suspended).
class PermissionException extends LifeAstroException {
  /// Creates a 403 exception.
  PermissionException(super.message,
      {required super.code,
      required super.status,
      super.requestId,
      super.body});

  @override
  String get name => 'PermissionException';
}

/// 404: unknown path or id.
class NotFoundException extends LifeAstroException {
  /// Creates a 404 exception.
  NotFoundException(super.message,
      {required super.code,
      required super.status,
      super.requestId,
      super.body});

  @override
  String get name => 'NotFoundException';
}

/// 429: rate limit or daily quota reached.
class RateLimitException extends LifeAstroException {
  /// Creates a 429 exception.
  RateLimitException(super.message,
      {required super.code,
      required super.status,
      super.requestId,
      super.body,
      this.retryAfter});

  /// How long the API asked to wait (from the `Retry-After` header), if given.
  final Duration? retryAfter;

  @override
  String get name => 'RateLimitException';
}

/// 5xx: a server-side failure.
class ServerException extends LifeAstroException {
  /// Creates a 5xx exception.
  ServerException(super.message,
      {required super.code,
      required super.status,
      super.requestId,
      super.body});

  @override
  String get name => 'ServerException';
}

/// Network failure, DNS error, timeout or abort (no HTTP status).
///
/// [code] is `connection_error`, `timeout` or `aborted`.
class LifeAstroConnectionException extends LifeAstroException {
  /// Creates a network exception.
  LifeAstroConnectionException(super.message,
      {super.code = 'connection_error', super.cause})
      : super(status: 0);

  @override
  String get name => 'LifeAstroConnectionException';
}

/// Builds the right exception from an HTTP status and the parsed body.
LifeAstroException errorFromResponse(int status, Object? body,
    [Duration? retryAfter]) {
  final err = body is Map ? body['error'] : null;
  final parsed = err is Map ? err : const <String, Object?>{};
  final code = parsed['code'] is String
      ? parsed['code'] as String
      : _httpStatusCode(status);
  final message = parsed['message'] is String
      ? parsed['message'] as String
      : 'HTTP $status';
  final requestId =
      parsed['request_id'] is String ? parsed['request_id'] as String : null;

  switch (status) {
    case 400:
      return BadRequestException(message,
          code: code, status: status, requestId: requestId, body: body);
    case 401:
      return AuthenticationException(message,
          code: code, status: status, requestId: requestId, body: body);
    case 402:
      return PaymentRequiredException(message,
          code: code, status: status, requestId: requestId, body: body);
    case 403:
      return PermissionException(message,
          code: code, status: status, requestId: requestId, body: body);
    case 404:
      return NotFoundException(message,
          code: code, status: status, requestId: requestId, body: body);
    case 429:
      return RateLimitException(message,
          code: code,
          status: status,
          requestId: requestId,
          body: body,
          retryAfter: retryAfter);
  }
  if (status >= 500) {
    return ServerException(message,
        code: code, status: status, requestId: requestId, body: body);
  }
  return LifeAstroException(message,
      code: code, status: status, requestId: requestId, body: body);
}

String _httpStatusCode(int status) {
  if (status == 0) return 'connection_error';
  if (status >= 500) return 'internal_error';
  if (status >= 400) return 'bad_request';
  return 'error';
}
