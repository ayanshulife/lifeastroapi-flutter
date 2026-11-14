/// The web has no process environment.
String? platformApiKey() => null;

/// Browsers forbid setting `User-Agent`.
const bool canSetUserAgent = false;
