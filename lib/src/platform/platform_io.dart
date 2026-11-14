import 'dart:io' show Platform;

/// `LIFEASTRO_API_KEY` from the process environment.
String? platformApiKey() => Platform.environment['LIFEASTRO_API_KEY'];

/// Native platforms may set `User-Agent`.
const bool canSetUserAgent = true;
