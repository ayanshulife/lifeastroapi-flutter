/// HTML → PDF engines. A report's HTML (from a `render*Html` function) is
/// printed by a Chromium-based engine, which shapes every Indic script
/// correctly:
///
/// - [ChromePdfEngine] (servers and desktop, `dart:io`): a local Chrome,
///   Chromium or Edge driven over the DevTools protocol, or a remote one.
/// - [GotenbergPdfEngine] (every platform, including Flutter mobile and web):
///   a Gotenberg service you run (`docker run gotenberg/gotenberg:8`).
///
/// You can also implement [PdfEngine] yourself.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'guard.dart';
import 'js.dart';
import 'print_css.dart';

/// Paper sizes, as Puppeteer defines them.
enum PaperFormat {
  /// 297 × 420 mm.
  a3(11.6929, 16.5354),

  /// 210 × 297 mm (default).
  a4(8.2677, 11.6929),

  /// 148 × 210 mm.
  a5(5.8268, 8.2677),

  /// 8.5 × 11 in.
  letter(8.5, 11),

  /// 8.5 × 14 in.
  legal(8.5, 14),

  /// 11 × 17 in.
  tabloid(11, 17);

  const PaperFormat(this.widthInches, this.heightInches);

  /// Width in inches.
  final double widthInches;

  /// Height in inches.
  final double heightInches;
}

/// Page margins as CSS lengths: `'10mm'`, `'1cm'`, `'0.5in'`, `'20px'`.
class PdfMargin {
  /// Creates margins. A side you set wins over the page's own CSS; an unset
  /// side keeps it (`0` without CSS). `kundliBrihadPdf` keeps its own default
  /// for an unset side.
  const PdfMargin({this.top, this.bottom, this.left, this.right});

  /// Top margin.
  final String? top;

  /// Bottom margin.
  final String? bottom;

  /// Left margin.
  final String? left;

  /// Right margin.
  final String? right;
}

/// Thrown when [HtmlToPdfOptions.abortTrigger] completed before the PDF was
/// ready. (A PDF that takes too long throws a `TimeoutException`.)
class PdfAbortedException implements Exception {
  /// Creates the exception.
  const PdfAbortedException();

  @override
  String toString() => 'PdfAbortedException: PDF rendering aborted by caller';
}

/// The page geometry of the reports in PDF points (1/72 inch): A4 and the
/// margins of the templates' `@page` rule, as the Node SDK's
/// `A4_PRINT_OPTIONS`. Chromium follows the CSS; pass this to print APIs of
/// web views that ignore `@page` (iOS does).
///
/// ```dart
/// final m = a4PrintOptions.margins;
/// final format = PdfPageFormat(a4PrintOptions.width, a4PrintOptions.height,
///     marginTop: m.top, marginRight: m.right,
///     marginBottom: m.bottom, marginLeft: m.left);
/// ```
const a4PrintOptions = (
  width: 595.0,
  height: 842.0,
  margins: (top: 51.0, right: 43.0, bottom: 62.0, left: 43.0),
);

/// Options for [PdfEngine.htmlToPdf] (the same as the Node SDK's
/// `htmlToPdf` options).
class HtmlToPdfOptions {
  /// Creates PDF options.
  const HtmlToPdfOptions({
    this.format = PaperFormat.a4,
    this.landscape = false,
    this.printBackground = true,
    this.preferCssPageSize,
    this.margin,
    bool? displayHeaderFooter,
    this.headerTemplate,
    this.footerTemplate,
    this.scale,
    this.timeout = const Duration(seconds: 30),
    this.abortTrigger,
  }) : _displayHeaderFooter = displayHeaderFooter;

  /// Paper size. A size other than A4, or [landscape], wins over the page's
  /// own `@page` size unless [preferCssPageSize] is true.
  final PaperFormat format;

  /// Landscape orientation.
  final bool landscape;

  /// Print background colours and images (the templates are branded).
  final bool printBackground;

  /// Use the page's own `@page` size. Default true, unless [landscape] or a
  /// [format] other than A4 is given (those then set the paper), and false
  /// when a running header/footer is on. An explicit true keeps the CSS size.
  final bool? preferCssPageSize;

  /// Page margins. A side you set wins over the page's own CSS; the others
  /// keep it. `kundliBrihadPdf` merges them side by side over its own.
  final PdfMargin? margin;

  // Null when the caller did not say: `kundliBrihadPdf` is then on.
  final bool? _displayHeaderFooter;

  /// Print [headerTemplate] / [footerTemplate] in the page margin. Default
  /// false, but `kundliBrihadPdf` prints its own unless this is set to false.
  bool get displayHeaderFooter => _displayHeaderFooter ?? false;

  /// Running header HTML (inline styles only). Chromium fills
  /// `<span class="pageNumber|totalPages|title|date|url">`.
  final String? headerTemplate;

  /// Running footer HTML (inline styles only). With [displayHeaderFooter] it
  /// replaces a report's own footer line.
  final String? footerTemplate;

  /// Render scale, 0.1 to 2.
  final double? scale;

  /// Time allowed for the page to load. Printing may take four times as
  /// long, so a Gotenberg request is given five times this. After that the
  /// call throws a `TimeoutException`. Raise it for a long Brihad on a busy
  /// machine.
  final Duration timeout;

  /// Cancels the PDF when this future completes. The call then throws
  /// [PdfAbortedException]; the engine stays usable.
  final Future<void>? abortTrigger;

  /// A copy with the given fields replaced. [abortTrigger] is kept; set it
  /// with the constructor.
  HtmlToPdfOptions copyWith({
    PaperFormat? format,
    bool? landscape,
    bool? printBackground,
    bool? preferCssPageSize,
    PdfMargin? margin,
    bool? displayHeaderFooter,
    String? headerTemplate,
    String? footerTemplate,
    double? scale,
    Duration? timeout,
  }) {
    return HtmlToPdfOptions(
      format: format ?? this.format,
      landscape: landscape ?? this.landscape,
      printBackground: printBackground ?? this.printBackground,
      preferCssPageSize: preferCssPageSize ?? this.preferCssPageSize,
      margin: margin ?? this.margin,
      displayHeaderFooter: displayHeaderFooter ?? _displayHeaderFooter,
      headerTemplate: headerTemplate ?? this.headerTemplate,
      footerTemplate: footerTemplate ?? this.footerTemplate,
      scale: scale ?? this.scale,
      timeout: timeout ?? this.timeout,
      abortTrigger: abortTrigger,
    );
  }

  /// Paper width and height in inches, after orientation.
  (double, double) get paperInches => landscape
      ? (format.heightInches, format.widthInches)
      : (format.widthInches, format.heightInches);

  /// Whether the template's `@page` size wins.
  bool get effectivePreferCssPageSize =>
      displayHeaderFooter ? false : (preferCssPageSize ?? true);
}

/// What the caller said about [HtmlToPdfOptions.displayHeaderFooter]: true,
/// false, or null for not said. Not exported by `package:lifeastroapi/pdf.dart`.
bool? headerFooterChoice(HtmlToPdfOptions options) =>
    options._displayHeaderFooter;

/// Converts a CSS length (`'26mm'`, `'1cm'`, `'0.5in'`, `'20px'`, `'20'`) to
/// inches, as Puppeteer does. `null` or empty gives 0.
double cssLengthToInches(String? value) {
  if (value == null || jsTrim(value).isEmpty) return 0;
  final m =
      RegExp(r'^\s*(-?\d*\.?\d+)\s*(px|in|cm|mm)?\s*$', caseSensitive: false)
          .firstMatch(value);
  if (m == null) {
    throw ArgumentError.value(value, 'margin', 'not a CSS length');
  }
  final n = double.parse(m[1]!);
  switch ((m[2] ?? 'px').toLowerCase()) {
    case 'in':
      return n;
    case 'cm':
      return n / 2.54;
    case 'mm':
      return n / 25.4;
    default:
      return n / 96;
  }
}

/// Something that prints a complete HTML document to PDF bytes.
///
/// When you write your own: the `*Pdf` helpers and the top-level `htmlToPdf`
/// have already added the CSS for the margins, paper, backgrounds and footer
/// of the options to the HTML it receives.
abstract interface class PdfEngine {
  /// Prints [html] to a PDF.
  Future<Uint8List> htmlToPdf(String html,
      [HtmlToPdfOptions options = const HtmlToPdfOptions()]);

  /// Releases the engine (closes a browser the engine launched).
  Future<void> close();
}

/// Prints through a Gotenberg service (https://gotenberg.dev), which runs
/// Chromium for you. Works from every platform, including Flutter mobile and
/// web (allow your origin with Gotenberg's CORS settings for web).
///
/// ```dart
/// final engine = GotenbergPdfEngine(Uri.parse('http://localhost:3000'));
/// final pdf = await kundliLitePdf(report, engine: engine);
/// ```
///
/// The HTML is sent to that service and nowhere else. If a script prints as
/// boxes, add its Noto font to your Gotenberg image.
class GotenbergPdfEngine implements PdfEngine {
  /// Creates an engine for the Gotenberg service at [baseUrl].
  GotenbergPdfEngine(this.baseUrl,
      {http.Client? httpClient, this.headers = const {}})
      : _client = httpClient ?? http.Client(),
        _ownsClient = httpClient == null;

  /// The Gotenberg base URL, for example `http://localhost:3000`.
  final Uri baseUrl;

  /// Extra request headers (for example basic auth).
  final Map<String, String> headers;

  final http.Client _client;
  final bool _ownsClient;

  static String _document(String fragment) =>
      '<!doctype html><html><head><meta charset="utf-8"></head>'
      '<body style="margin:0">$fragment</body></html>';

  @override
  Future<Uint8List> htmlToPdf(String html,
      [HtmlToPdfOptions options = const HtmlToPdfOptions()]) async {
    final path = baseUrl.path.endsWith('/')
        ? '${baseUrl.path}forms/chromium/convert/html'
        : '${baseUrl.path}/forms/chromium/convert/html';
    final cancel = Completer<void>();
    final req = http.AbortableMultipartRequest(
        'POST', baseUrl.replace(path: path),
        abortTrigger: cancel.future)
      ..headers.addAll(headers);
    final (w, h) = options.paperInches;
    final m = options.margin;
    // jsNum: the same text on every platform ('1', never '1.0').
    req.fields.addAll({
      'paperWidth': jsNum(w),
      'paperHeight': jsNum(h),
      'marginTop': jsNum(cssLengthToInches(m?.top)),
      'marginBottom': jsNum(cssLengthToInches(m?.bottom)),
      'marginLeft': jsNum(cssLengthToInches(m?.left)),
      'marginRight': jsNum(cssLengthToInches(m?.right)),
      'preferCssPageSize': '${options.effectivePreferCssPageSize}',
      'printBackground': '${options.printBackground}',
      'landscape': 'false', // orientation is already in paperWidth/Height
      'scale': jsNum(options.scale ?? 1),
    });
    req.files.add(http.MultipartFile.fromString(
        'files', withPrintOptionsCss(html, options),
        filename: 'index.html'));
    if (options.displayHeaderFooter) {
      req.files.add(http.MultipartFile.fromString(
          'files', _document(options.headerTemplate ?? '<span></span>'),
          filename: 'header.html'));
      req.files.add(http.MultipartFile.fromString(
          'files', _document(options.footerTemplate ?? '<span></span>'),
          filename: 'footer.html'));
    }
    // The deadline covers the download of the PDF as well.
    final res = await guard(
      Future(() async {
        if (cancel.isCompleted) throw const PdfAbortedException();
        return http.Response.fromStream(await _client.send(req));
      }),
      timeout: options.timeout * 5,
      what: 'the Gotenberg request',
      abortTrigger: options.abortTrigger,
      onCancel: cancel.complete,
    );
    if (res.statusCode != 200) {
      final body = utf8.decode(res.bodyBytes, allowMalformed: true);
      throw StateError('Gotenberg returned ${res.statusCode}: '
          '${body.length > 500 ? body.substring(0, 500) : body}');
    }
    final pdf = res.bodyBytes;
    if (pdf.length < 5 || latin1.decode(pdf.sublist(0, 5)) != '%PDF-') {
      throw StateError('Gotenberg did not return a PDF. Check that $baseUrl '
          'is a Gotenberg service.');
    }
    return pdf;
  }

  @override
  Future<void> close() async {
    if (_ownsClient) _client.close();
  }
}
