/// Every report renderer by its Node name (used by the golden tests and the
/// `*Pdf` helpers).
library;

import 'shared.dart';
import 'templates/dasha_analysis.dart';
import 'templates/horoscope.dart';
import 'templates/kundli_brihad.dart';
import 'templates/kundli_detailed.dart';
import 'templates/kundli_lite.dart';
import 'templates/mangal_dosha.dart';
import 'templates/match_making.dart';
import 'templates/numerology.dart';
import 'templates/sade_sati.dart';
import 'templates/varshaphal.dart';

/// A report renderer: report JSON (+ optional branding) to an HTML document.
typedef ReportRenderer = String Function(Map<String, Object?> data,
    [Branding? branding]);

/// Every renderer, keyed by its Node SDK name.
const Map<String, ReportRenderer> reportRenderers = {
  'renderKundliLiteHtml': renderKundliLiteHtml,
  'renderKundliDetailedHtml': renderKundliDetailedHtml,
  'renderKundliBrihadHtml': renderKundliBrihadHtml,
  'renderMatchMakingHtml': renderMatchMakingHtml,
  'renderDashaAnalysisHtml': renderDashaAnalysisHtml,
  'renderNumerologyHtml': renderNumerologyHtml,
  'renderSadeSatiHtml': renderSadeSatiHtml,
  'renderVarshaphalHtml': renderVarshaphalHtml,
  'renderHoroscopeHtml': renderHoroscopeHtml,
  'renderMangalDoshaHtml': renderMangalDoshaHtml,
};
