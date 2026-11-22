// The HTML layer is pure: it needs no browser, process, file or network, so
// it also runs inside apps. Runs on the VM and in browsers.
import 'package:lifeastroapi/lifeastroapi.dart';
import 'package:lifeastroapi/pdf.dart';
import 'package:test/test.dart';

const _renderers = {
  'kundliLite': renderKundliLiteHtml,
  'kundliDetailed': renderKundliDetailedHtml,
  'kundliBrihad': renderKundliBrihadHtml,
  'matchMaking': renderMatchMakingHtml,
  'dashaAnalysis': renderDashaAnalysisHtml,
  'numerology': renderNumerologyHtml,
  'sadeSati': renderSadeSatiHtml,
  'varshaphal': renderVarshaphalHtml,
  'horoscope': renderHoroscopeHtml,
  'mangalDosha': renderMangalDoshaHtml,
};

void main() {
  // What the SDK's own client returns: decoded JSON, Map<String, dynamic>.
  final Map<String, dynamic> report = {
    'Locale': 'pa',
    'language': 'pa',
    'Name': 'Arjun Mehta',
    'GeneratedAt': '2026-01-01T00:00:00Z',
  };
  final gurmukhi = RegExp('[\\u0A00-\\u0A7F]');

  _renderers.forEach((name, render) {
    test('$name renders Punjabi labels, branded', () {
      final html = render(
          report, const Branding(companyName: 'Acme Astro', footerText: 'F'));
      expect(html, startsWith('<!doctype html>'));
      expect(html, contains('<html lang="pa">'));
      expect(gurmukhi.hasMatch(html), isTrue);
      expect(html, contains('Acme Astro'));
    });
  });

  test('a4PrintOptions matches the templates and Node', () {
    expect(a4PrintOptions.width, 595);
    expect(a4PrintOptions.height, 842);
    expect(a4PrintOptions.margins,
        (top: 51.0, right: 43.0, bottom: 62.0, left: 43.0));
    expect(renderKundliLiteHtml(report),
        contains('@page { size: A4; margin: 18mm 15mm 22mm 15mm; }'));
  });

  test('Lang.pa is the code the templates read', () {
    expect(Lang.pa.name, report['Locale']);
  });
}
