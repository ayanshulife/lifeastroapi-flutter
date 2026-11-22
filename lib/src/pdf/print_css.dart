/// The print options that a page's own CSS would otherwise win over, as CSS
/// that wins over it. Port of the Node SDK's `printOptionsCss` and
/// `mergeMargin` (src/pdf/render.ts).
library;

import 'engine.dart';
import 'js.dart';

// Paper sizes of the `format` option as the CSS names them: width, height.
(String, String) _paper(PaperFormat format) => switch (format) {
      PaperFormat.a3 => ('297mm', '420mm'),
      PaperFormat.a4 => ('210mm', '297mm'),
      PaperFormat.a5 => ('148mm', '210mm'),
      PaperFormat.letter => ('8.5in', '11in'),
      PaperFormat.legal => ('8.5in', '14in'),
      PaperFormat.tabloid => ('11in', '17in'),
    };

final _cssLengthRe = RegExp(r'^([0-9]+(?:\.[0-9]+)?|\.[0-9]+)(px|in|cm|mm)?$',
    caseSensitive: false);

/// A margin as Puppeteer reads it (no unit means px), or `null` when it is
/// not set or not a length.
String? _cssLength(String? value) {
  final m = _cssLengthRe.firstMatch(jsTrim(value ?? ''));
  return m == null ? null : '${m[1]}${(m[2] ?? 'px').toLowerCase()}';
}

/// The margins and paper the caller names, no backgrounds, and the caller's
/// footer in place of the report's. `''` when none is set.
String printOptionsCss(HtmlToPdfOptions options) {
  final page = <String>[];
  final margin = options.margin;
  for (final (side, given) in [
    ('top', margin?.top),
    ('right', margin?.right),
    ('bottom', margin?.bottom),
    ('left', margin?.left),
  ]) {
    final value = _cssLength(given);
    if (value != null) page.add('margin-$side: $value !important;');
  }
  // An explicit preferCssPageSize keeps its meaning: true = the CSS size,
  // false = scale to the paper. Portrait A4 is the default, so it never
  // overrides a CSS size.
  if (options.preferCssPageSize == null &&
      (options.format != PaperFormat.a4 || options.landscape)) {
    final (w, h) = _paper(options.format);
    page.add('size: ${options.landscape ? '$h $w' : '$w $h'} !important;');
  }
  if (options.displayHeaderFooter && options.footerTemplate != null) {
    page.add('@bottom-center { content: none !important; }');
  }
  var css = page.isEmpty ? '' : '@page { ${page.join(' ')} }\n';
  if (!options.printBackground) {
    // The reports ask for exact colours, which prints backgrounds anyway;
    // without them white text needs ink.
    //
    // Economy printing paints a see-through fill solid white, which cut the
    // watermark into strips: no fill at all.
    css += 'body *, body *::before, body *::after '
        '{ background: transparent !important; box-shadow: none !important; }\n'
        'html { -webkit-print-color-adjust: economy !important; '
        'print-color-adjust: economy !important; }\n'
        'th, .part-banner .part-h2, .toc-banner, .summary-card, .num-chip, '
        '.number-block .number, .moon-sign-badge, .year-badge, '
        '.remedy-block .category, .dosha-block .severity, '
        '.yoga-block .name::before '
        '{ color: #1a1a1a !important; }\n';
  }
  return css;
}

/// [html] with [printOptionsCss] after it, or untouched when that is empty.
///
/// The report helpers and both built-in engines call this, so a custom engine
/// and a direct `engine.htmlToPdf` get it too. It is never added twice.
String withPrintOptionsCss(String html, HtmlToPdfOptions options) {
  final css = printOptionsCss(options);
  if (css.isEmpty) return html;
  final style = '\n<style>$css</style>';
  return html.endsWith(style) ? html : '$html$style';
}

/// [defaults], side by side replaced by what the caller set. A blank side
/// keeps the default.
PdfMargin mergeMargin(PdfMargin defaults, PdfMargin? given) {
  String? pick(String? value, String? fallback) =>
      value != null && jsTrim(value).isNotEmpty ? value : fallback;
  return PdfMargin(
    top: pick(given?.top, defaults.top),
    bottom: pick(given?.bottom, defaults.bottom),
    left: pick(given?.left, defaults.left),
    right: pick(given?.right, defaults.right),
  );
}
