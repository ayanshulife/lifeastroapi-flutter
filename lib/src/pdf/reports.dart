/// One-call report → PDF helpers (the Node SDK's `*Pdf` functions).
library;

import 'dart:typed_data';

import 'chrome.dart';
import 'engine.dart';
import 'js.dart';
import 'locales.dart';
import 'outline.dart';
import 'shared.dart';
import 'templates/dasha_analysis.dart';
import 'templates/horoscope.dart';
import 'templates/kundli_brihad.dart';
import 'templates/kundli_brihad_sections.dart';
import 'templates/kundli_detailed.dart';
import 'templates/kundli_lite.dart';
import 'templates/mangal_dosha.dart';
import 'templates/match_making.dart';
import 'templates/numerology.dart';
import 'templates/sade_sati.dart';
import 'templates/varshaphal.dart';

/// Prints a complete HTML document (from any `render*Html` function) to PDF.
///
/// With no [engine], a headless Chrome/Chromium/Edge is launched for this
/// one call and closed afterwards (`dart:io` platforms). On a server, launch
/// one [ChromePdfEngine] and pass it to every call; on the web or in a
/// Flutter app, pass a [GotenbergPdfEngine].
Future<Uint8List> htmlToPdf(String html,
    {HtmlToPdfOptions options = const HtmlToPdfOptions(), PdfEngine? engine}) {
  return _withEngine(engine, (e) => e.htmlToPdf(html, options));
}

Future<T> _withEngine<T>(
    PdfEngine? engine, Future<T> Function(PdfEngine e) body) async {
  if (engine != null) return body(engine);
  final own = await launchDefaultEngine();
  try {
    return await body(own);
  } finally {
    await own.close();
  }
}

Future<Uint8List> _toPdf(
        String Function(Map<String, Object?>, [Branding?]) render,
        Map<String, Object?> data,
        Branding? branding,
        HtmlToPdfOptions options,
        PdfEngine? engine) =>
    htmlToPdf(render(data, branding), options: options, engine: engine);

/// Kundli (lite) report JSON (`client.reports.kundliLite`) → PDF.
Future<Uint8List> kundliLitePdf(Map<String, Object?> data,
        {Branding? branding,
        HtmlToPdfOptions options = const HtmlToPdfOptions(),
        PdfEngine? engine}) =>
    _toPdf(renderKundliLiteHtml, data, branding, options, engine);

/// Kundli (detailed) report JSON (`client.reports.kundliDetailed`) → PDF.
Future<Uint8List> kundliDetailedPdf(Map<String, Object?> data,
        {Branding? branding,
        HtmlToPdfOptions options = const HtmlToPdfOptions(),
        PdfEngine? engine}) =>
    _toPdf(renderKundliDetailedHtml, data, branding, options, engine);

/// Match-making report JSON (`client.reports.matchMaking`) → PDF.
Future<Uint8List> matchMakingPdf(Map<String, Object?> data,
        {Branding? branding,
        HtmlToPdfOptions options = const HtmlToPdfOptions(),
        PdfEngine? engine}) =>
    _toPdf(renderMatchMakingHtml, data, branding, options, engine);

/// Dasha analysis report JSON (`client.reports.dashaAnalysis`) → PDF.
Future<Uint8List> dashaAnalysisPdf(Map<String, Object?> data,
        {Branding? branding,
        HtmlToPdfOptions options = const HtmlToPdfOptions(),
        PdfEngine? engine}) =>
    _toPdf(renderDashaAnalysisHtml, data, branding, options, engine);

/// Numerology report JSON (`client.reports.numerology`) → PDF.
Future<Uint8List> numerologyPdf(Map<String, Object?> data,
        {Branding? branding,
        HtmlToPdfOptions options = const HtmlToPdfOptions(),
        PdfEngine? engine}) =>
    _toPdf(renderNumerologyHtml, data, branding, options, engine);

/// Sade Sati report JSON (`client.reports.sadeSati`) → PDF.
Future<Uint8List> sadeSatiPdf(Map<String, Object?> data,
        {Branding? branding,
        HtmlToPdfOptions options = const HtmlToPdfOptions(),
        PdfEngine? engine}) =>
    _toPdf(renderSadeSatiHtml, data, branding, options, engine);

/// Varshaphal report JSON (`client.reports.varshaphal`) → PDF.
Future<Uint8List> varshaphalPdf(Map<String, Object?> data,
        {Branding? branding,
        HtmlToPdfOptions options = const HtmlToPdfOptions(),
        PdfEngine? engine}) =>
    _toPdf(renderVarshaphalHtml, data, branding, options, engine);

/// Horoscope report JSON (`client.reports.horoscopeDaily` / `Weekly` /
/// `Monthly`) → PDF.
Future<Uint8List> horoscopePdf(Map<String, Object?> data,
        {Branding? branding,
        HtmlToPdfOptions options = const HtmlToPdfOptions(),
        PdfEngine? engine}) =>
    _toPdf(renderHoroscopeHtml, data, branding, options, engine);

/// Mangal Dosha report JSON (`client.reports.mangalDosha`) → PDF.
Future<Uint8List> mangalDoshaPdf(Map<String, Object?> data,
        {Branding? branding,
        HtmlToPdfOptions options = const HtmlToPdfOptions(),
        PdfEngine? engine}) =>
    _toPdf(renderMangalDoshaHtml, data, branding, options, engine);

/// Brihad Kundli report JSON (`client.reports.kundliBrihad`) → PDF.
///
/// Adds a running header and footer in the page margin, a table of contents
/// with the exact page of every section (read from a first render), and PDF
/// bookmarks. It renders twice and is large (well over 100 pages): give it
/// time and run it in a background job.
Future<Uint8List> kundliBrihadPdf(Map<String, Object?> data,
    {Branding? branding,
    HtmlToPdfOptions options = const HtmlToPdfOptions(),
    PdfEngine? engine}) {
  final raw = _rawBranding(data['Branding'], branding);
  final pdfOptions = options.copyWith(
    displayHeaderFooter: true,
    headerTemplate: brihadHeaderTemplate(raw),
    footerTemplate: brihadFooterTemplate(raw),
    margin: options.margin ??
        PdfMargin(
          top: brihadPdfMargin.top,
          bottom: brihadPdfMargin.bottom,
          left: brihadPdfMargin.left,
          right: brihadPdfMargin.right,
        ),
  );
  final baseHtml = renderKundliBrihadHtml(data, branding);
  final tagged = tagBrihadSectionsForToc(baseHtml);

  return _withEngine(engine, (e) async {
    if (tagged.titles.isEmpty) return e.htmlToPdf(baseHtml, pdfOptions);
    final heading =
        tocHeading[jsStr(data['Locale'], nullAs: 'en')] ?? tocHeading['en']!;

    // Pass 1: a placeholder TOC with the right number of rows, and each
    // section marker made a link so the PDF tells which page it landed on.
    final placeholder = buildBrihadToc([
      for (var i = 0; i < tagged.titles.length; i++)
        (title: tagged.titles[i], page: i + 1),
    ], heading);
    final pass1 = await e.htmlToPdf(
        _linkMarkers(_insertTocAfterCover(tagged.html, placeholder)),
        pdfOptions);

    final entries = <({String title, int page})>[];
    try {
      final pages = linkTargetPages(pass1);
      for (var i = 0; i < tagged.titles.length; i++) {
        final page = pages['$_markerUrl$i'];
        if (page != null) entries.add((title: tagged.titles[i], page: page));
      }
    } on FormatException {
      entries.clear();
    }
    // No page numbers found: print without a TOC rather than with wrong ones.
    if (entries.isEmpty) return e.htmlToPdf(baseHtml, pdfOptions);

    // Pass 2: the TOC with the real page numbers, then PDF bookmarks.
    final pdf = await e.htmlToPdf(
        _insertTocAfterCover(tagged.html, buildBrihadToc(entries, heading)),
        pdfOptions);
    try {
      return addPdfOutline(pdf, [
        for (final x in entries)
          (
            title: x.title,
            page: x.page,
            level: partPrefixRe.hasMatch(x.title.trim()) ? 1 : 2,
          ),
      ]);
    } on Object {
      return pdf;
    }
  });
}

const _markerUrl = 'https://toc.lifeastroapi.invalid/T';

String _linkMarkers(String html) => html.replaceAllMapped(
    RegExp(r'<span style="color:#fff;font-size:1px;">⟦T(\d+)⟧</span>'),
    (m) => '<span style="color:#fff;font-size:1px;">'
        '<a href="$_markerUrl${m[1]}" style="color:#fff;text-decoration:none;">'
        '⟦T${m[1]}⟧</a></span>');

String _insertTocAfterCover(String html, String toc) {
  final coverEnd = html.indexOf('</section>');
  if (coverEnd == -1) return toc + html;
  final at = coverEnd + '</section>'.length;
  return '${html.substring(0, at)}\n$toc\n${html.substring(at)}';
}

/// The report's PascalCase branding with the caller's overrides applied, for
/// the Brihad running header/footer.
Map<String, Object?> _rawBranding(Object? raw, Branding? override) {
  final out = Map<String, Object?>.of(asMap(raw));
  void set(String key, String? v) {
    if (v != null && v.trim().isNotEmpty) out[key] = v;
  }

  set('CompanyName', override?.companyName);
  set('LogoURL', override?.logoUrl);
  set('PrimaryColor', override?.primaryColor);
  set('SecondaryColor', override?.secondaryColor);
  set('FooterText', override?.footerText);
  set('WatermarkText', override?.watermarkText);
  return out;
}
