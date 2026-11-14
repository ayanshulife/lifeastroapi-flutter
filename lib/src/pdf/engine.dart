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

import 'dart:typed_data';

import 'package:http/http.dart' as http;

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
  /// Creates margins; unset sides are 0.
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
    this.displayHeaderFooter = false,
    this.headerTemplate,
    this.footerTemplate,
    this.scale,
    this.timeout = const Duration(seconds: 30),
  });

  /// Paper size. The report templates also set A4 in their own CSS.
  final PaperFormat format;

  /// Landscape orientation.
  final bool landscape;

  /// Print background colours and images (the templates are branded).
  final bool printBackground;

  /// Use the template's own `@page` size. Default true, false when a
  /// running header/footer is on.
  final bool? preferCssPageSize;

  /// Page margins. Default: the template's own.
  final PdfMargin? margin;

  /// Print [headerTemplate] / [footerTemplate] in the page margin.
  final bool displayHeaderFooter;

  /// Running header HTML (inline styles only). Chromium fills
  /// `<span class="pageNumber|totalPages|title|date|url">`.
  final String? headerTemplate;

  /// Running footer HTML (inline styles only).
  final String? footerTemplate;

  /// Render scale, 0.1 to 2.
  final double? scale;

  /// Time allowed for the page to load and print.
  final Duration timeout;

  /// A copy with the given fields replaced.
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
      displayHeaderFooter: displayHeaderFooter ?? this.displayHeaderFooter,
      headerTemplate: headerTemplate ?? this.headerTemplate,
      footerTemplate: footerTemplate ?? this.footerTemplate,
      scale: scale ?? this.scale,
      timeout: timeout ?? this.timeout,
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

/// Converts a CSS length (`'26mm'`, `'1cm'`, `'0.5in'`, `'20px'`, `'20'`) to
/// inches, as Puppeteer does. `null` or empty gives 0.
double cssLengthToInches(String? value) {
  if (value == null || value.trim().isEmpty) return 0;
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
/// Install the Noto fonts in the Gotenberg image if your reports use Indic
/// scripts the image does not cover.
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
    final req = http.MultipartRequest('POST', baseUrl.replace(path: path))
      ..headers.addAll(headers);
    final (w, h) = options.paperInches;
    final m = options.margin;
    req.fields.addAll({
      'paperWidth': '$w',
      'paperHeight': '$h',
      'marginTop': '${cssLengthToInches(m?.top)}',
      'marginBottom': '${cssLengthToInches(m?.bottom)}',
      'marginLeft': '${cssLengthToInches(m?.left)}',
      'marginRight': '${cssLengthToInches(m?.right)}',
      'preferCssPageSize': '${options.effectivePreferCssPageSize}',
      'printBackground': '${options.printBackground}',
      'landscape': 'false', // orientation is already in paperWidth/Height
      'scale': '${options.scale ?? 1}',
    });
    req.files.add(
        http.MultipartFile.fromString('files', html, filename: 'index.html'));
    if (options.displayHeaderFooter) {
      req.files.add(http.MultipartFile.fromString(
          'files', _document(options.headerTemplate ?? '<span></span>'),
          filename: 'header.html'));
      req.files.add(http.MultipartFile.fromString(
          'files', _document(options.footerTemplate ?? '<span></span>'),
          filename: 'footer.html'));
    }
    final res = await http.Response.fromStream(
        await _client.send(req).timeout(options.timeout));
    if (res.statusCode != 200) {
      throw StateError(
          'Gotenberg returned ${res.statusCode}: ${res.body.length > 500 ? res.body.substring(0, 500) : res.body}');
    }
    return res.bodyBytes;
  }

  @override
  Future<void> close() async {
    if (_ownsClient) _client.close();
  }
}
