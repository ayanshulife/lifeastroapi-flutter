/// Branded, print-ready PDF reports from LifeAstroAPI report JSON, in all 10
/// languages, made on your side: nothing is sent to LifeAstroAPI to render.
///
/// Two layers:
///
/// 1. `render*Html(data, branding)` turns the JSON from `client.reports.*`
///    into a complete, self-contained HTML document. Pure Dart with no
///    browser, process, file or network access: works in Flutter (mobile,
///    desktop, web) and on servers. [a4PrintOptions] is the page geometry for
///    print APIs.
/// 2. `*Pdf(data, ...)` and [htmlToPdf] print that HTML to PDF bytes with a
///    Chromium-based [PdfEngine]: [ChromePdfEngine] (servers and desktop) or
///    [GotenbergPdfEngine] (any platform). In a Flutter app you can also
///    print the HTML with the platform's web view (see the README).
///
/// ```dart
/// import 'package:lifeastroapi/lifeastroapi.dart';
/// import 'package:lifeastroapi/pdf.dart';
///
/// final report = await client.reports.kundliDetailed(birth: arjun, lang: Lang.hi);
/// final html = renderKundliDetailedHtml(report,
///     const Branding(companyName: 'Acme Astro', primaryColor: '#6b21a8'));
/// final pdf = await kundliDetailedPdf(report); // launches Chrome once
/// ```
library;

export 'src/pdf/chrome.dart' show ChromePdfEngine;
export 'src/pdf/engine.dart' hide headerFooterChoice;
export 'src/pdf/outline.dart' show OutlineItem, addPdfOutline;
export 'src/pdf/reports.dart';
export 'src/pdf/shared.dart'
    show
        Branding,
        ResolvedBranding,
        resolveBranding,
        esc,
        escBody,
        humanize,
        cleanNarrative;
export 'src/pdf/templates/dasha_analysis.dart' show renderDashaAnalysisHtml;
export 'src/pdf/templates/horoscope.dart' show renderHoroscopeHtml;
export 'src/pdf/templates/kundli_brihad.dart' show renderKundliBrihadHtml;
export 'src/pdf/templates/kundli_detailed.dart' show renderKundliDetailedHtml;
export 'src/pdf/templates/kundli_lite.dart' show renderKundliLiteHtml;
export 'src/pdf/templates/mangal_dosha.dart' show renderMangalDoshaHtml;
export 'src/pdf/templates/match_making.dart' show renderMatchMakingHtml;
export 'src/pdf/templates/numerology.dart' show renderNumerologyHtml;
export 'src/pdf/templates/sade_sati.dart' show renderSadeSatiHtml;
export 'src/pdf/templates/varshaphal.dart' show renderVarshaphalHtml;
