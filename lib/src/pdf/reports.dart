/// One-call report → PDF helpers (the Node SDK's `*Pdf` functions).
library;

import 'dart:typed_data';

import 'chrome.dart';
import 'engine.dart';
import 'js.dart';
import 'locales.dart';
import 'outline.dart';
import 'print_css.dart';
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
/// Flutter app, pass a [GotenbergPdfEngine]. Nothing is sent to LifeAstroAPI.
Future<Uint8List> htmlToPdf(String html,
    {HtmlToPdfOptions options = const HtmlToPdfOptions(), PdfEngine? engine}) {
  final page = withPrintOptionsCss(html, options);
  return _withEngine(engine, options, (e) => e.htmlToPdf(page, options));
}

Future<T> _withEngine<T>(PdfEngine? engine, HtmlToPdfOptions options,
    Future<T> Function(PdfEngine e) body) async {
  if (engine != null) return body(engine);
  final own = await launchDefaultEngine(abortTrigger: options.abortTrigger);
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
        PdfEngine? engine) async =>
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
    PdfEngine? engine}) async {
  // Header and footer resolve branding like the pages do: the caller's
  // fields, unless blank, over the report's.
  final report = data['Branding'];
  final pdfOptions = options.copyWith(
    displayHeaderFooter: headerFooterChoice(options) ?? true,
    headerTemplate:
        jsOr(options.headerTemplate, brihadHeaderTemplate(report, branding)),
    footerTemplate:
        jsOr(options.footerTemplate, brihadFooterTemplate(report, branding)),
    margin: mergeMargin(
      PdfMargin(
        top: brihadPdfMargin.top,
        bottom: brihadPdfMargin.bottom,
        left: brihadPdfMargin.left,
        right: brihadPdfMargin.right,
      ),
      options.margin,
    ),
  );
  final baseHtml = renderKundliBrihadHtml(data, branding);
  final tagged = tagBrihadSectionsForToc(baseHtml);

  return _withEngine(engine, pdfOptions, (e) async {
    Future<Uint8List> print(String html) =>
        e.htmlToPdf(withPrintOptionsCss(html, pdfOptions), pdfOptions);
    if (tagged.titles.isEmpty) return print(baseHtml);
    final heading = tocHeading[asStr(safeLocale(data['Locale'])) ?? 'en'] ??
        tocHeading['en']!;

    // Pass 1: a placeholder TOC with the right number of rows, and each
    // section marker made a link so the PDF tells which page it landed on.
    final placeholder = buildBrihadToc([
      for (var i = 0; i < tagged.titles.length; i++)
        (title: tagged.titles[i], page: i + 1),
    ], heading);
    final pass1 = await print(
        _insertTocAfterCover(_linkMarkers(tagged.html), placeholder));

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
    if (entries.isEmpty) return print(baseHtml);

    // Pass 2: the TOC with the real page numbers, then PDF bookmarks. The
    // markers did their job in pass 1; a no-break space keeps the same line
    // box without leaving the token in the PDF's text.
    final unmarked = tagged.html.replaceAll(tocMarkerRe, '&nbsp;');
    final pdf = await print(
        _insertTocAfterCover(unmarked, buildBrihadToc(entries, heading)));
    try {
      return addPdfOutline(pdf, [
        for (final x in entries)
          (
            title: x.title,
            page: x.page,
            level: partPrefixRe.hasMatch(jsTrim(x.title)) ? 1 : 2,
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
