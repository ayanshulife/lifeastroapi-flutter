/// Stand-in for platforms without `dart:io` (the web).
library;

import 'dart:typed_data';

import 'engine.dart';

/// Chrome over the DevTools protocol needs `dart:io`; on the web, use
/// [GotenbergPdfEngine] or print the HTML from the browser.
class ChromePdfEngine implements PdfEngine {
  ChromePdfEngine._();

  /// Not available on this platform.
  static Future<ChromePdfEngine> launch({
    String? executablePath,
    bool noSandbox = false,
    List<String> args = const [],
    Duration timeout = const Duration(seconds: 30),
  }) =>
      throw UnsupportedError(_message);

  /// Not available on this platform.
  static Future<ChromePdfEngine> connect(String webSocketDebuggerUrl) =>
      throw UnsupportedError(_message);

  /// Always `null` on this platform.
  static String? findChromeExecutable() => null;

  /// Not available on this platform.
  Future<Object?> evaluate(String html, String expression,
          {Duration timeout = const Duration(seconds: 30)}) =>
      throw UnsupportedError(_message);

  @override
  Future<Uint8List> htmlToPdf(String html,
          [HtmlToPdfOptions options = const HtmlToPdfOptions()]) =>
      throw UnsupportedError(_message);

  @override
  Future<void> close() async {}
}

const _message = 'ChromePdfEngine needs dart:io. On the web, pass a '
    'GotenbergPdfEngine (engine:) or open the HTML and use the browser\'s '
    'print dialog.';

/// No default engine on the web.
Future<PdfEngine> launchDefaultEngine() => throw UnsupportedError(
    'No default PDF engine on the web: pass engine: GotenbergPdfEngine(...), '
    'or render the HTML (render*Html) and print it from the browser.');
