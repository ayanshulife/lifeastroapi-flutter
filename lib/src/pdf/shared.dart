/// Shared building blocks of the report templates: branding, escaping, text
/// clean-up, the CSS skeleton and the document layout. Port of the Node SDK's
/// src/pdf/shared.ts; output must stay byte-identical (golden tests).
library;

import 'js.dart';
import 'locales.dart';

/// Branding for a report: your logo, colours, company name, footer and an
/// optional watermark. Every field is optional; a field you set wins over the
/// branding stored on your API account (the report JSON's `Branding`).
class Branding {
  /// Creates branding overrides.
  const Branding({
    this.companyName,
    this.logoUrl,
    this.primaryColor,
    this.secondaryColor,
    this.footerText,
    this.watermarkText,
  });

  /// Shown on the cover.
  final String? companyName;

  /// Cover logo: `http(s)`, `data:image/...` or a relative URL.
  final String? logoUrl;

  /// Headings, table headers, accents (a CSS colour).
  final String? primaryColor;

  /// Meta text and footer (a CSS colour).
  final String? secondaryColor;

  /// Line printed at the bottom of every page.
  final String? footerText;

  /// Diagonal watermark, for example `SAMPLE`.
  final String? watermarkText;

  /// Branding from the report JSON's `Branding` object (PascalCase keys) or
  /// from a camelCase map.
  factory Branding.fromJson(Map<String, Object?> json) {
    String? s(String a, String b) => asStr(json[a]) ?? asStr(json[b]);
    return Branding(
      companyName: s('companyName', 'CompanyName'),
      logoUrl: s('logoUrl', 'LogoURL'),
      primaryColor: s('primaryColor', 'PrimaryColor'),
      secondaryColor: s('secondaryColor', 'SecondaryColor'),
      footerText: s('footerText', 'FooterText'),
      watermarkText: s('watermarkText', 'WatermarkText'),
    );
  }
}

/// Branding with defaults applied.
class ResolvedBranding {
  /// Creates resolved branding.
  const ResolvedBranding({
    required this.companyName,
    required this.logoUrl,
    required this.primaryColor,
    required this.secondaryColor,
    required this.footerText,
    required this.watermarkText,
  });

  /// Company name (may be empty).
  final String companyName;

  /// Safe logo URL (may be empty).
  final String logoUrl;

  /// Safe primary colour.
  final String primaryColor;

  /// Safe secondary colour.
  final String secondaryColor;

  /// Footer text.
  final String footerText;

  /// Watermark text (may be empty).
  final String watermarkText;
}

const _defaultPrimary = '#1a1a1a';
const _defaultSecondary = '#666666';
const _defaultFooter = 'Generated using LifeAstroAPI';

String _firstNonEmpty(List<Object?> vals) {
  for (final v in vals) {
    if (v is String && v.trim() != '') return v;
  }
  return '';
}

/// Merges [override] over the branding embedded in the report JSON ([raw],
/// PascalCase keys), then applies defaults. Overrides win per field.
ResolvedBranding resolveBranding(Object? raw, [Branding? override]) {
  final r = asMap(raw);
  return ResolvedBranding(
    companyName: _firstNonEmpty([override?.companyName, r['CompanyName']]),
    logoUrl: _safeUrl(_firstNonEmpty([override?.logoUrl, r['LogoURL']])),
    primaryColor: _safeColor(
        _firstNonEmpty([override?.primaryColor, r['PrimaryColor']]),
        _defaultPrimary),
    secondaryColor: _safeColor(
        _firstNonEmpty([override?.secondaryColor, r['SecondaryColor']]),
        _defaultSecondary),
    footerText:
        _firstNonEmpty([override?.footerText, r['FooterText'], _defaultFooter]),
    watermarkText:
        _firstNonEmpty([override?.watermarkText, r['WatermarkText']]),
  );
}

// A CSS colour goes unescaped into a `:root { --brand-primary: X }` rule, so
// it is validated against the safe colour grammar instead of escaped.
final _safeColorRe = RegExp(
    r'^(#([0-9a-fA-F]{3,4}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})|[a-zA-Z]+|(?:rgb|rgba|hsl|hsla)\([0-9.,%/\s]+\))$');

String _safeColor(String value, String fallback) {
  final v = value.trim();
  return _safeColorRe.hasMatch(v) ? v : fallback;
}

// `logoUrl` is rendered into `<img src>`. Only http(s), `data:image/...` and
// relative URLs are kept. This does not prevent SSRF to an internal host;
// render untrusted branding with restricted network egress.
String _safeUrl(String value) {
  final v = value.trim();
  if (v == '') return '';
  final scheme =
      RegExp(r'^([a-z][a-z0-9+.-]*):', caseSensitive: false).firstMatch(v);
  if (scheme == null) return v;
  final s = scheme.group(1)!.toLowerCase();
  if (s == 'http' || s == 'https') return v;
  if (RegExp(r'^data:image/', caseSensitive: false).hasMatch(v)) return v;
  return '';
}

/// Escapes a value for a CSS string literal (`content: "..."`).
String cssString(Object? value) {
  if (value == null) return '';
  return jsStr(value)
      .replaceAllMapped(RegExp(r'[\\"<>]'),
          (m) => '\\${m[0]!.codeUnitAt(0).toRadixString(16)} ')
      .replaceAll(RegExp('[\u0000-\u001F  ]'), ' ');
}

const _esc = {
  '&': '&amp;',
  '<': '&lt;',
  '>': '&gt;',
  '"': '&quot;',
  "'": '&#39;',
};

/// Replaces em/en dashes and arrows used in prose with a comma, and tidies
/// the punctuation that leaves behind. Works for every script.
String humanize(String text) {
  final t = text.trim();
  if (t == '—' || t == '–') return text;
  var s = text
      .replaceAll(RegExp(r'\s*(?:⟶|⇒|→|->|=>)\s*'), ', ')
      .replaceAllMapped(
          RegExp(r'(\S)\s*[—–]\s*(\S)'), (m) => '${m[1]}, ${m[2]}')
      .replaceAllMapped(RegExp(r'(\S)\s*[—–]\s*$'), (m) => m[1]!)
      .replaceAllMapped(RegExp(r'^\s*[—–]\s*(\S)'), (m) => m[1]!);
  s = s
      .replaceAll(RegExp(r'\s+,'), ',')
      .replaceAll(RegExp(r',\s*,+'), ', ')
      .replaceAllMapped(RegExp(r',\s*([।.!?])'), (m) => m[1]!)
      .replaceAllMapped(RegExp(r'([(\[])\s*,\s*'), (m) => m[1]!)
      .replaceAllMapped(RegExp(r'\s*,\s*([)\]])'), (m) => m[1]!)
      .replaceFirst(RegExp(r'^\s*,\s*'), '')
      .replaceFirst(RegExp(r',\s*$'), '');
  return s;
}

/// Makes an authored narrative body read as a second-person reading: drops
/// the repeated "three levels" filler paragraph and, for en/hi/mr, turns the
/// third-person "native" / "जातक" into "you" / "आप" / "तुम्ही".
String cleanNarrative(String text, [String locale = 'en']) {
  var s = text;
  s = s.replaceAll(
      RegExp(
          r'(?:वैदिक\s*ज्योतिष|यह\s*कुंडली|यह\s*स्थिति|शास्त्र)[^।]*?तीन\s*स्तर(?:ों|ां)[\s\S]*?(?:शास्त्र\s*है।|शास्त्र\s*आहे\.?|दिशा\s*देने[^।]*।)'),
      '');
  s = s.replaceAll(
      RegExp(r'[^।]*इन\s*तीन\s*स्तर(?:ों|ां)[\s\S]*?देख[^।]*।'), '');
  s = s.replaceAll(
      RegExp(
          r'(In Vedic astrology[^.]*three levels[\s\S]*?(?:guidance\.|direction to life\.))'),
      '');

  if (locale == 'hi') {
    s = s
        .replaceAll(RegExp(r'जातक\s*की'), 'आपकी')
        .replaceAll(RegExp(r'जातक\s*को'), 'आपको')
        .replaceAll(RegExp(r'जातक\s*के'), 'आपके')
        .replaceAll(RegExp(r'जातक\s*का'), 'आपका')
        .replaceAll(RegExp(r'जातक\s*में'), 'आपमें')
        .replaceAll(RegExp(r'जातक\s*पर'), 'आप पर')
        .replaceAll(RegExp(r'जातक\s*स्वयं'), 'आप स्वयं')
        .replaceAll('जातक', 'आप');
  } else if (locale == 'mr') {
    s = s
        .replaceAll('जातकाच्या', 'तुमच्या')
        .replaceAll('जातकाला', 'तुम्हाला')
        .replaceAll('जातकाचे', 'तुमचे')
        .replaceAll('जातकाचा', 'तुमचा')
        .replaceAll('जातक', 'तुम्ही');
  } else if (const ['te', 'ta', 'kn', 'ml', 'gu', 'bn'].contains(locale)) {
    // No rewrite: these corpora are written in the second person at the
    // source, and the English rules must not run on this prose.
  } else {
    s = s
        .replaceAll(RegExp(r"\bthe native's\b"), 'your')
        .replaceAll(RegExp(r"\bThe native's\b"), 'Your')
        .replaceAll(RegExp(r'\bthe native\b'), 'you')
        .replaceAll(RegExp(r'\bThe native\b'), 'You')
        .replaceAll(RegExp(r"\bnative's\b"), 'your')
        .replaceAll(RegExp(r'\bnative\b'), 'you');
  }

  s = s
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .replaceAll(RegExp(r'[ \t]+\n'), '\n')
      .trim();
  return s;
}

/// HTML-escapes a value after [humanize]. `null` gives `''`.
String esc(Object? value) {
  if (value == null) return '';
  return humanize(jsStr(value))
      .replaceAllMapped(RegExp('[&<>"\']'), (m) => _esc[m[0]]!);
}

/// HTML-escapes a narrative body: [cleanNarrative] first, then [esc].
String escBody(Object? value, [String locale = 'en']) {
  if (value == null) return '';
  return esc(cleanNarrative(jsStr(value), locale));
}

/// Escapes each item of a list and joins them with [sep].
String escList(Object? items, [String sep = '; ']) {
  if (items is! List) return '';
  return items.map(esc).join(sep);
}

/// A value, or a dash when empty.
String orDash(Object? value) {
  final s = esc(value);
  return s == '' ? '—' : s;
}

String _watermarkCss(ResolvedBranding b) {
  if (b.watermarkText.isEmpty) return '';
  return '''

body::before {
  content: "${cssString(b.watermarkText)}";
  position: fixed; top: 50%; left: 50%;
  transform: translate(-50%, -50%) rotate(-30deg);
  font-size: 80pt; color: rgba(0,0,0,0.06); font-weight: 700;
  pointer-events: none; z-index: 0;
}''';
}

String _footerCss(ResolvedBranding b) {
  if (b.footerText.isEmpty) return '';
  return '''

@page {
  @bottom-center {
    content: "${cssString(b.footerText)}";
    font-family: $indicFontStack;
    font-size: 8pt;
    color: ${_cssColor(b.secondaryColor)};
  }
}''';
}

String _cssColor(String value) {
  return RegExp(
              r'^(#[0-9a-fA-F]{3,8}|[a-zA-Z]+|rgba?\([0-9.,%\s]+\)|hsla?\([0-9.,%\sdeg]+\))$')
          .hasMatch(value.trim())
      ? value.trim()
      : '#666666';
}

/// The logo and company-name block of a cover page.
String coverBrandingHtml(ResolvedBranding b) {
  var html = '';
  if (b.logoUrl.isNotEmpty) {
    html += '<img src="${esc(b.logoUrl)}" alt="" class="logo">';
  }
  if (b.companyName.isNotEmpty) {
    html += '<div class="company">${esc(b.companyName)}</div>';
  }
  return html;
}

/// The footer line shown after the content on screen.
String footerHtml(ResolvedBranding b) =>
    b.footerText.isNotEmpty ? '<footer>${esc(b.footerText)}</footer>' : '';

/// Wraps a report body in a complete, self-contained HTML document.
String layoutDocument({
  String? lang,
  required String title,
  required ResolvedBranding branding,
  required String bodyHtml,
  String extraCss = '',
  bool pageFooter = true,
}) {
  final l = esc(lang ?? 'en');
  return '''<!doctype html>
<html lang="${l.isNotEmpty ? l : 'en'}">
<head>
<meta charset="utf-8">
<title>${esc(title)}</title>
<style>
:root { --brand-primary: ${esc(branding.primaryColor)}; --brand-secondary: ${esc(branding.secondaryColor)}; }
$baseCss
${_watermarkCss(branding)}
${pageFooter ? _footerCss(branding) : ''}
$extraCss
</style>
</head>
<body>
$bodyHtml
${footerHtml(branding)}
</body>
</html>''';
}

/// Renders authored narrative sections (heading, body, bullets, citations).
String narrativeSectionsHtml(Object? sections,
    [String sourcesLabel = 'Sources']) {
  if (sections is! List || sections.isEmpty) return '';
  return sections.map((raw) {
    final s = asMap(raw);
    final bulletsRaw = s['Bullets'];
    final bullets = bulletsRaw is List && bulletsRaw.isNotEmpty
        ? '<ul>${bulletsRaw.map((b) => '<li>${esc(b)}</li>').join()}</ul>'
        : '';
    final citesRaw = s['Citations'];
    final cites = citesRaw is List && citesRaw.isNotEmpty
        ? '<div class="citations">${esc(sourcesLabel)}: ${escList(citesRaw)}</div>'
        : '';
    return '<div class="narrative-section"><h3>${esc(s['Heading'])}</h3><div class="body">${esc(s['Body'])}</div>$bullets$cites</div>';
  }).join('\n');
}

/// A label lookup for [locale], falling back to English, then `''`.
String Function(String key) makeLabeler(
    Map<String, Map<String, String>> labels, String? locale) {
  final loc = locale != null && locale.isNotEmpty && labels[locale] != null
      ? locale
      : 'en';
  final table = labels[loc] ?? labels['en'] ?? const {};
  final fallback = labels['en'] ?? const {};
  return (key) => table[key] ?? fallback[key] ?? '';
}

/// The CSS skeleton shared by every report.
const baseCss =
    '\n* { box-sizing: border-box; }\n/* Form controls and headings do not always inherit font-family in print, so\n   the Indic stack is set on them explicitly too. */\nh1, h2, h3, h4, th, td, li, dt, dd, input, button { font-family: inherit; }\nhtml, body {\n  font-family: \'Noto Sans\', \'Noto Sans Devanagari\', \'Noto Sans Telugu\', \'Noto Sans Tamil\', \'Noto Sans Kannada\', \'Noto Sans Bengali\', \'Noto Sans Gujarati\', \'Noto Sans Gurmukhi\', \'Noto Sans Malayalam\', sans-serif;\n  color: #1a1a1a;\n  font-size: 11pt;\n  line-height: 1.45;\n  margin: 0;\n}\n@page { size: A4; margin: 18mm 15mm 22mm 15mm; }\nh2 {\n  color: var(--brand-primary);\n  border-bottom: 2px solid var(--brand-primary);\n  padding-bottom: 2mm;\n  font-size: 16pt;\n  margin-top: 8mm;\n}\nh3 { font-size: 12pt; margin: 6mm 0 2mm; }\np { margin: 2mm 0; }\ntable { width: 100%; border-collapse: collapse; margin: 4mm 0; }\nth, td { text-align: left; padding: 2mm 3mm; border-bottom: 1px solid #e5e5e5; vertical-align: top; }\nth { background: var(--brand-primary); color: #fff; font-weight: 600; font-size: 10pt; }\n.cover { page-break-after: always; text-align: center; padding: 40mm 0 0; }\n.cover img.logo { max-height: 24mm; max-width: 60mm; margin-bottom: 8mm; }\n.cover h1 { color: var(--brand-primary); font-size: 28pt; margin: 0 0 4mm; }\n.cover .company { color: var(--brand-secondary); font-size: 14pt; margin-bottom: 16mm; }\n.cover .subject { font-size: 16pt; margin-bottom: 4mm; }\n.cover .meta { color: var(--brand-secondary); font-size: 11pt; }\n.cover .generated { margin-top: 32mm; color: var(--brand-secondary); font-size: 9pt; }\n.narrative-section { margin-top: 6mm; page-break-inside: avoid; }\n.narrative-section .body { margin: 2mm 0; white-space: pre-wrap; }\n.narrative-section ul { margin: 1mm 0 2mm 6mm; padding: 0; }\n.narrative-section .citations { color: var(--brand-secondary); font-size: 9pt; font-style: italic; }\n.cards { display: flex; gap: 4mm; margin: 4mm 0; flex-wrap: wrap; }\n.card { flex: 1 1 0; min-width: 40mm; border: 1px solid #e5e5e5; border-radius: 2mm; padding: 3mm; }\n.card .label { color: var(--brand-secondary); font-size: 9pt; text-transform: uppercase; letter-spacing: .04em; }\n.card .value { font-size: 14pt; color: var(--brand-primary); font-weight: 600; margin-top: 1mm; }\n/* On screen the footer is an ordinary block after the content. In print it\n   is hidden and the same text is drawn in the page\'s bottom margin instead\n   (see footerCss): a position:fixed footer is laid out against the page\n   CONTENT box, so it prints on top of the last lines of body text. */\nfooter {\n  text-align: center; color: var(--brand-secondary); font-size: 8pt;\n  margin-top: 10mm;\n}\n@media print { footer { display: none; } }\n/* Telugu and Kannada stack vowel signs and conjuncts above and below the\n   line and Tamil has tall marks too, so their lines get a little more height\n   (Devanagari keeps the 1.45 it was tuned for). Letter-spacing and uppercase are Latin\n   typography; spacing splits Indic clusters apart, so drop it.\n   :where() keeps the specificity of a plain "body" rule, so a report\'s own\n   body line-height (Brihad sets 1.8) still wins. */\n:where(html:lang(te), html:lang(ta), html:lang(kn), html:lang(ml)) body { line-height: 1.6; }\n:where(html:lang(hi), html:lang(mr), html:lang(te), html:lang(ta), html:lang(kn), html:lang(ml)) * { letter-spacing: normal !important; }\n';
