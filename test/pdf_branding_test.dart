// Branding, Brihad layout and print options: the checks of the Node SDK's
// test/pdf-branding-options.test.ts, plus the traps of a port. Runs on the VM
// and in browsers.
import 'package:lifeastroapi/pdf.dart';
import 'package:lifeastroapi/src/pdf/colors.dart';
import 'package:lifeastroapi/src/pdf/locales.dart';
import 'package:lifeastroapi/src/pdf/print_css.dart';
import 'package:lifeastroapi/src/pdf/renderers.dart';
import 'package:lifeastroapi/src/pdf/templates/kundli_brihad_sections.dart';
import 'package:lifeastroapi/src/pdf/templates/planet_glyphs.dart';
import 'package:test/test.dart';

const _apiDefaults = {
  'CompanyName': '',
  'LogoURL': '',
  'PrimaryColor': '#1a1a1a',
  'SecondaryColor': '#666666',
  'FooterText': 'Generated using LifeAstroAPI',
  'WatermarkText': '',
};
const _langs = ['en', 'hi', 'mr', 'te', 'ta', 'kn', 'ml', 'gu', 'bn', 'pa'];

String _brihad(Map<String, Object?> data, [Branding? branding]) =>
    renderKundliBrihadHtml(data, branding);

String _chr(int code) => String.fromCharCode(code);

double _contrast(Rgb a, Rgb b) {
  final (x, y) = (contrastOnWhite(a), contrastOnWhite(b));
  return x > y ? x / y : y / x;
}

void main() {
  group('watermark', () {
    test('prints behind the content in Brihad', () {
      final html = _brihad({}, const Branding(watermarkText: 'SAMPLE'));
      expect(html, contains('content: "SAMPLE"'));
      expect(html,
          isNot(matches(RegExp(r'body::before\s*\{[^}]*display:\s*none'))));
      expect(html, contains('body::before { z-index: -1; }'));
    });

    test('shows through Brihad rows and cards, and only then', () {
      const rule =
          'tr:nth-child(even) td, .graha-card { background: transparent;';
      expect(
          _brihad({}, const Branding(watermarkText: 'SAMPLE')), contains(rule));
      expect(_brihad({}), isNot(contains(rule)));
    });

    test('a see-through fill keeps its colour on white paper', () {
      for (final hex in [
        '#fcf3e3', '#fffaf0', '#fafafa', '#f0fdf4', //
        '#fef2f2', '#fefce8', '#f5f3ff', '#fff7e8',
      ]) {
        final want = parseColor(hex)!;
        final shown = parseColor(seeThrough(want))!;
        expect(shown.$1, closeTo(want.$1, 1));
        expect(shown.$2, closeTo(want.$2, 1));
        expect(shown.$3, closeTo(want.$3, 1));
      }
      expect(seeThrough((255, 255, 255)), 'transparent');
    });

    test('shrinks for a long word or line, counted in code points', () {
      int size(String text) => int.parse(
          RegExp(r'body::before \{[^}]*font-size: (\d+)pt').firstMatch(
              renderKundliLiteHtml({}, Branding(watermarkText: text)))![1]!);
      expect(size('SAMPLE'), 80);
      expect(size('CONFIDENTIAL'), 51);
      expect(size('DRAFT FOR REVIEW ONLY'), 61);
      expect(size('x' * 500), 10);
      // Code points: not UTF-16 units (emoji) and not graphemes (Devanagari).
      expect(size(String.fromCharCodes(List.filled(12, 0x1f600))), 51);
      expect(size('गोपनीय' * 2), 51);
      // JS trim and \s: U+00A0 and U+FEFF are space, U+0085 is not.
      expect(size('${_chr(0xa0)}CONFIDENTIAL${_chr(0xfeff)}'), 51);
      expect(size('CONFIDE${_chr(0xa0)}NTIAL'), 78); // two words, 13 long
      expect(size('CONFIDE${_chr(0x85)}NTIAL'), 47);
    });

    test('is in every renderer and language', () {
      reportRenderers.forEach((name, render) {
        for (final lang in _langs) {
          expect(
              render({'Locale': lang, 'language': lang},
                  const Branding(watermarkText: 'SAMPLE')),
              contains('content: "SAMPLE"'),
              reason: '$name $lang');
        }
      });
    });
  });

  group('Brihad brand palette', () {
    test("stays saffron for the API's default colours", () {
      for (final report in <Map<String, String>?>[
        null,
        _apiDefaults,
        {
          ..._apiDefaults,
          'PrimaryColor': '#1A1A1A',
          'SecondaryColor': ' #666666 '
        },
      ]) {
        expect(brihadPalette(report), isNull);
      }
      // The report's pair passed on by the caller is no brand either.
      for (final pair in const [
        Branding(primaryColor: '#1a1a1a', secondaryColor: '#666666'),
        Branding(primaryColor: ' #1A1A1A', secondaryColor: 'rgb(102,102,102)'),
      ]) {
        expect(brihadPalette(_apiDefaults, pair), isNull);
      }
      expect(
          brihadPalette(_apiDefaults, Branding.fromJson(_apiDefaults)), isNull);
      expect(_brihad({'Branding': _apiDefaults}), _brihad({}));
      expect(brihadHeaderTemplate(_apiDefaults), contains('#9e2b25'));
      expect(brihadFooterTemplate(_apiDefaults), contains('#c25e10'));
    });

    test("follows the caller's colours in pages, contents, header, footer", () {
      const branding =
          Branding(primaryColor: '#0b5cad', secondaryColor: '#0b6b36');
      final html = _brihad({'Branding': _apiDefaults}, branding);
      expect(html, contains('--as-teal:#0b5cad'));
      expect(html, contains('--as-amber:#0b6b36'));
      expect(
          html, contains('.toc-row .toc-page { color: #0b5cad !important; }'));
      for (final template in [brihadHeaderTemplate, brihadFooterTemplate]) {
        final out = template(_apiDefaults, branding);
        expect(out, contains('color:#0b5cad'));
        expect(out, contains('color:#0b6b36'));
        expect(out, isNot(matches(RegExp('#9e2b25|#c25e10'))));
      }
    });

    test("follows the report's colours", () {
      expect(
          _brihad({
            'Branding': {..._apiDefaults, 'PrimaryColor': '#0b5cad'},
          }),
          contains('--as-teal:#0b5cad'));
    });

    test('takes black when the caller asks for it', () {
      expect(
          brihadPalette(_apiDefaults, const Branding(primaryColor: '#1a1a1a'))
              ?.primary,
          (26, 26, 26));
    });

    test('the charts take the brand colour', () {
      final html = _brihad({
        'Ascendant': {'sign': 'Aries'},
        'Planets': [
          {'name': 'Sun', 'house_num': 1},
        ],
      }, const Branding(primaryColor: '#0b5cad'));
      expect(html, contains('stroke="#0b5cad"'));
    });

    test('gold details follow the primary; a lone secondary keeps saffron', () {
      expect(
          brihadPalette(null, const Branding(primaryColor: '#0b5cad'))!.accent,
          (11, 92, 173));
      final only = _brihad({}, const Branding(secondaryColor: '#0b6b36'));
      expect(only, contains('--as-amber:#0b6b36'));
      expect(only, isNot(contains('--as-teal:#0b6b36')));
    });

    test('stays readable for any brand colour', () {
      const white = (255, 255, 255);
      final fills = [
        for (final h in ['#fafafa', '#f0fdf4', '#fef2f2', '#fefce8'])
          parseColor(h)!,
      ];
      var text = 21.0;
      var banner = 21.0;
      for (var r = 0; r < 256; r += 15) {
        for (var g = 0; g < 256; g += 15) {
          for (var b = 0; b < 256; b += 15) {
            final hex = toHex((r, g, b));
            final palette = brihadPalette(
                null, Branding(primaryColor: hex, secondaryColor: hex))!;
            final primary = palette.primary!;
            final tints = [tintOnWhite(primary, 5), tintOnWhite(primary, 3)];
            for (final ink in [primary, palette.accent, palette.muted]) {
              final onWhite = _contrast(ink, white);
              if (onWhite < banner) banner = onWhite;
              for (final bg in [...fills, ...tints]) {
                final c = _contrast(ink, bg);
                if (c < text) text = c;
              }
            }
          }
        }
      }
      expect(banner, greaterThanOrEqualTo(5.2));
      expect(text, greaterThanOrEqualTo(4.5));
    });
  });

  group('colours', () {
    test('every accepted CSS form', () {
      const same = {
        '#0B5CAD': (11, 92, 173),
        '#05a': (0, 85, 170),
        '#05af': (0, 85, 170),
        '#0b5cadff': (11, 92, 173),
        'RebeccaPurple': (102, 51, 153),
        'rgb(11, 92, 173)': (11, 92, 173),
        'rgb(11 92 173)': (11, 92, 173),
        'rgba(0,0,0,0.5)': (128, 128, 128),
        'hsl(210, 100%, 50%)': (0, 128, 255),
        'rgb(100%, 0%, 0%)': (255, 0, 0),
      };
      same.forEach((value, rgb) => expect(parseColor(value), rgb));
    });

    test('refuses what cannot be printed', () {
      for (final value in [
        '', '  ', 'constructor', 'toString', 'inherit', 'transparent', //
        '#0000', 'rgb(1,2)', '#12345', 'rgb(1.2.3, 4, 5)', 'hsl(1,2,3)',
        'rgb(${_chr(0x661)}, 2, 3)', // an Arabic digit
        '${_chr(0x130)}NDIGO', // a Turkish capital dotted I
        '${_chr(0x212a)}haki', // the Kelvin sign
      ]) {
        expect(parseColor(value), isNull, reason: value);
      }
    });

    test('halves round up, never to even', () {
      expect(parseColor('rgba(0,0,0,0.5)'), (128, 128, 128)); // 127.5
      expect(parseColor('rgb(0.5, 1.5, 2.5)'), (1, 2, 3));
    });

    test('64 UTF-16 units at most', () {
      String padded(int width) => 'rgb(1,2,3${' ' * (width - 10)})';
      expect(padded(64), hasLength(64));
      expect(parseColor(padded(64)), (1, 2, 3));
      expect(parseColor(padded(65)), isNull);
    });

    test('readable colours print as given, only pale ones darker', () {
      expect(printableColor('rebeccapurple', '#1a1a1a'), 'rebeccapurple');
      expect(printableColor(' rgb(11 92 173) ', '#1a1a1a'), 'rgb(11 92 173)');
      expect(printableColor('notacolour', '#1a1a1a'), '#1a1a1a');
      expect(contrastOnWhite(parseColor(printableColor('#ffe14d', '#1a1a1a'))!),
          greaterThanOrEqualTo(4.5));
      expect(renderKundliLiteHtml({}, const Branding(primaryColor: '#ffe14d')),
          isNot(contains('--brand-primary: #ffe14d')));
      expect(
          renderKundliLiteHtml({}, const Branding(secondaryColor: '#ffe14d')),
          isNot(contains('color: #ffe14d')));
      expect(darkenToContrast((255, 255, 255), 22), (0, 0, 0));
    });
  });

  group('values named like Object properties', () {
    const names = [
      'constructor', 'toString', '__proto__', //
      'valueOf', 'hasOwnProperty', 'isPrototypeOf',
    ];

    test('are unknown words in every lookup', () {
      for (final v in names) {
        expect(planetGlyph(v), '');
        expect(southPlanetToEn(v), '');
        expect(localizeLord('te', v), v);
        expect(localizeLord(v, 'Sun'), 'Sun');
        expect(localizeWeekday(v, 'Sunday'), 'Sunday');
        expect(renderNorthChart(v, [], '', 'en', '#000'), '');
        expect(
            renderNorthChart(
                'Aries',
                [
                  {'name': v, 'house': 1},
                  {'name': 'Sun', 'house': v},
                ],
                '',
                'en',
                '#000'),
            isNot(matches(RegExp('native code|<tspan fill'))));
      }
    });

    test('neither throw nor print code in any renderer', () {
      final cases = <(ReportRenderer, Map<String, Object?> Function(String))>[
        (
          renderMangalDoshaHtml,
          (v) => {
                'Status': v,
                'HasDosha': true,
                'HousesOccupied': [7],
              }
        ),
        (
          renderMatchMakingHtml,
          (v) => {
                'Ashtakoota': {'Verdict': v}
              }
        ),
        (
          renderSadeSatiHtml,
          (v) => {
                'CurrentStatus': {'status': v}
              }
        ),
        (
          renderNumerologyHtml,
          (v) => {
                'driver': v,
                'driver_factors': {'planet': v, 'day': v},
              }
        ),
        (
          renderKundliDetailedHtml,
          (v) => {
                'Houses': [
                  {'HouseNum': v},
                ],
              }
        ),
        (
          renderKundliBrihadHtml,
          (v) => {
                'Planets': [
                  {'name_en': v, 'house_num': 1},
                ],
                'Houses': [
                  {'HouseNum': v},
                ],
                'Remedies': [
                  {'Category': v},
                ],
                'maitri': {
                  'order': [v],
                  'naisargik': [
                    {'planet': 'Sun', 'relations': <String, Object?>{}},
                  ],
                },
              }
        ),
      ];
      for (final (render, data) in cases) {
        for (final lang in _langs) {
          for (final v in names) {
            expect(render({'Locale': lang, ...data(v)}),
                isNot(matches(RegExp(r'native code|\[object'))),
                reason: '$lang $v');
          }
        }
      }
    });
  });

  test('Mangal without a dosha has no dash-only house row', () {
    for (final lang in _langs) {
      for (final houses in <List<int>?>[null, []]) {
        final html = renderMangalDoshaHtml({
          'Locale': lang,
          'HasDosha': false,
          'Status': 'none',
          'HousesOccupied': houses,
        });
        expect(html, isNot(contains('<dd>—</dd>')), reason: lang);
        expect('<dt>'.allMatches(html), hasLength(3), reason: lang);
      }
      final with4 = renderMangalDoshaHtml({
        'Locale': lang,
        'HasDosha': true,
        'HousesOccupied': [-4],
      });
      expect('<dt>'.allMatches(with4), hasLength(4));
    }
  });

  group('blank caller branding', () {
    final blank = Branding(
      companyName: ' ',
      logoUrl: '\t',
      primaryColor: _chr(0xa0),
      secondaryColor: _chr(0xfeff),
      footerText: '\n',
      watermarkText: '  ',
    );
    const report = {
      'CompanyName': 'Json Co',
      'LogoURL': 'https://j/l.png',
      'PrimaryColor': '#0b5cad',
      'SecondaryColor': '#0b6b36',
      'FooterText': 'Json footer',
      'WatermarkText': 'JSON',
    };

    test('is unset in every renderer', () {
      reportRenderers.forEach((name, render) {
        expect(
            render({'Branding': report}, blank), render({'Branding': report}),
            reason: name);
        expect(render({}, blank), render({}), reason: name);
      });
    });

    test('is unset in the Brihad running header and footer', () {
      for (final template in [brihadHeaderTemplate, brihadFooterTemplate]) {
        expect(template(report, blank), template(report, null));
        expect(template(null, blank), template(null, null));
      }
      expect(brihadHeaderTemplate(report, blank), contains('Json Co'));
      expect(brihadFooterTemplate(report, blank), contains('Json footer'));
    });
  });

  group('branding text', () {
    test('prints as the caller wrote it', () {
      const branding = Branding(
          companyName: 'Acme — Astro', footerText: '© Acme — <private>');
      final lite = renderKundliLiteHtml({}, branding);
      expect(lite, contains('<div class="company">Acme — Astro</div>'));
      expect(lite, contains('<footer>© Acme — &lt;private&gt;</footer>'));
      expect(brihadHeaderTemplate(null, branding), contains('Acme — Astro'));
      expect(brihadFooterTemplate(null, branding),
          contains('© Acme — &lt;private&gt;'));
    });

    test('a protocol-relative logo gets https, which about:blank lacks', () {
      expect(
          resolveBranding(null, const Branding(logoUrl: '//cdn.example/l.png'))
              .logoUrl,
          'https://cdn.example/l.png');
    });
  });

  group('print options', () {
    test('add nothing by default', () {
      expect(printOptionsCss(const HtmlToPdfOptions()), '');
      expect(withPrintOptionsCss('<p>x</p>', const HtmlToPdfOptions()),
          '<p>x</p>');
    });

    test('each margin wins over @page', () {
      final css = printOptionsCss(
          const HtmlToPdfOptions(margin: PdfMargin(top: '40mm', left: '0')));
      expect(css, contains('margin-top: 40mm !important;'));
      expect(css, contains('margin-left: 0px !important;'));
      expect(css, isNot(matches(RegExp('margin-(bottom|right)'))));
      expect(
          printOptionsCss(const HtmlToPdfOptions(margin: PdfMargin(top: '12'))),
          contains('margin-top: 12px'));
      expect(
          printOptionsCss(const HtmlToPdfOptions(
              margin: PdfMargin(top: '1mm}body{display:none', bottom: ' '))),
          '');
    });

    test('format and landscape set the paper', () {
      expect(
          printOptionsCss(const HtmlToPdfOptions(format: PaperFormat.letter)),
          contains('size: 8.5in 11in !important;'));
      expect(printOptionsCss(const HtmlToPdfOptions(landscape: true)),
          contains('size: 297mm 210mm !important;'));
      expect(
          printOptionsCss(
              const HtmlToPdfOptions(format: PaperFormat.a5, landscape: true)),
          contains('size: 210mm 148mm !important;'));
      for (final prefer in [true, false]) {
        expect(
            printOptionsCss(HtmlToPdfOptions(
                format: PaperFormat.a5, preferCssPageSize: prefer)),
            '',
            reason: 'an explicit preferCssPageSize keeps its meaning');
      }
    });

    test('printBackground false, and a caller footer', () {
      expect(printOptionsCss(const HtmlToPdfOptions(printBackground: false)),
          contains('print-color-adjust: economy !important'));
      expect(
          printOptionsCss(const HtmlToPdfOptions(
              displayHeaderFooter: true, footerTemplate: '<b>x</b>')),
          contains('content: none !important'));
      expect(
          printOptionsCss(const HtmlToPdfOptions(footerTemplate: '<b>x</b>')),
          '');
    });

    test('backgrounds off: no fill at all, the first rule of the block', () {
      const fills = 'body *, body *::before, body *::after '
          '{ background: transparent !important; box-shadow: none !important; }';
      final off = printOptionsCss(const HtmlToPdfOptions(
          printBackground: false, margin: PdfMargin(top: '40mm')));
      expect(
          off,
          startsWith('@page { margin-top: 40mm !important; }\n$fills\n'
              'html { -webkit-print-color-adjust: economy !important;'));
      expect(printOptionsCss(const HtmlToPdfOptions(printBackground: false)),
          startsWith('$fills\n'));
      expect(printOptionsCss(const HtmlToPdfOptions(landscape: true)),
          isNot(contains('transparent')));
    });

    test('the CSS is added once', () {
      const options = HtmlToPdfOptions(landscape: true);
      final once = withPrintOptionsCss('<p>x</p>', options);
      expect(once, startsWith('<p>x</p>\n<style>@page { size: 297mm 210mm'));
      expect(once, endsWith('</style>'));
      expect(withPrintOptionsCss(once, options), once);
    });

    test('Brihad margins merge side by side', () {
      const defaults =
          PdfMargin(top: '26mm', bottom: '16mm', left: '0mm', right: '0mm');
      final m = mergeMargin(defaults,
          PdfMargin(top: '40mm', bottom: ' ', left: '0', right: _chr(0xfeff)));
      expect([m.top, m.bottom, m.left, m.right], ['40mm', '16mm', '0', '0mm']);
      final kept = mergeMargin(defaults, null);
      expect([kept.top, kept.bottom, kept.left, kept.right],
          ['26mm', '16mm', '0mm', '0mm']);
    });

    test('displayHeaderFooter is still a bool, false by default', () {
      final bool unset = const HtmlToPdfOptions().displayHeaderFooter;
      expect(unset, isFalse);
      expect(
          const HtmlToPdfOptions(displayHeaderFooter: true).displayHeaderFooter,
          isTrue);
    });
  });

  group('Brihad pages', () {
    test('a section of a few lines joins the next, and only such a one', () {
      String html(int rows) => _brihad({
            'rajyoga_power': {
              'percent': 50,
              'swarnim_kaal': [
                for (var i = 0; i < rows; i++) {'lord': 'Moon'},
              ],
            },
          });
      const short = '<section class="section short-section">';
      expect(html(1), contains(short));
      expect(html(2), contains(short));
      expect(html(3), isNot(contains(short)));
      expect(_brihad({}),
          contains('.short-section + .section { page-break-before: auto;'));
    });

    test('the four section classes', () {
      final html = _brihad({
        'avakahada': {'varna': 'x', 'nakshatra': 'x', 'gana': 'x'},
        'ishta_devata': {'deity': 'Vishnu'},
        'lalkitab': <String, Object?>{},
        'maitri': {
          'order': ['Sun'],
        },
      });
      expect(html, contains('class="section short-section"'));
      expect(html, contains('class="section maitri-section"'));
      final withBody = _brihad({
        'ishta_devata': {'deity': 'Vishnu', 'body': 'A long reading'},
      });
      expect(withBody, isNot(contains('class="section short-section"')));
      for (final name in ['compact-section', 'lalkitab-section']) {
        expect(html, contains('.$name'), reason: 'the rule for .$name');
      }
    });

    test('keeps the body text size', () {
      expect(
          _brihad({}),
          contains(
              'body { color: var(--as-ink); font-size: 11.5pt; line-height: 1.8; }'));
    });

    test('markers: the first child of a section, a second right after it', () {
      final html = _brihad({
        'Ascendant': {'sign': 'Aries'},
        'Planets': [
          {'name': 'Sun', 'house_num': 1},
        ],
        'Remedies': [
          {'Title': 'A', 'Category': 'charity'},
        ],
      });
      final tagged = tagBrihadSectionsForToc(html);
      const marker = '<span style="color:#fff;font-size:1px;">⟦T';
      final opened =
          RegExp(r'<section class="section[^"]*" data-toc-title="[^"]*">')
              .allMatches(tagged.html)
              .toList();
      expect(opened, isNotEmpty);
      for (final m in opened) {
        var rest = tagged.html.substring(m.end);
        var count = 0;
        while (rest.startsWith(marker)) {
          rest = rest.substring(rest.indexOf('</span>') + '</span>'.length);
          count++;
        }
        expect(count, inInclusiveRange(1, 2));
      }
      expect(marker.allMatches(tagged.html), hasLength(tagged.titles.length));
      expect(
          html,
          contains(
              '.section > span:first-child + span { text-indent: 20px; }'));
      expect(
          html, contains('height: 2px; line-height: 2px; margin-bottom: -2px'));
    });
  });

  test('the gem note sends nobody to an astrologer, in every language', () {
    for (final lang in _langs) {
      final note =
          RegExp(r'<p class="gems-note">(.*?)</p>').firstMatch(_brihad({
        'Locale': lang,
        'gems': {
          'stones': [
            {'stone': 'x'},
          ],
        },
      }))![1]!;
      expect(note, isNotEmpty, reason: lang);
      expect(
          note,
          isNot(matches(
              RegExp('astrologer|consult|ज्योतिष', caseSensitive: false))),
          reason: lang);
    }
  });

  test('the friendship tables fit the paper, so Chrome keeps the scale', () {
    final html = _brihad({
      'maitri': {
        'order': ['Sun', 'Moon'],
        'tatkalik': [
          {
            'planet': 'Sun',
            'relations': {'Moon': 'Neutral'},
          },
        ],
      },
    });
    // A part banner may come first when the section opens its part.
    expect(
        html,
        matches(RegExp(r'<section class="section maitri-section">\n'
            r'(?:<div class="part-banner">.*</div>\n)?<h2>[^<]*Maitri')));
    expect(
        html,
        contains('.section.maitri-section table tbody td '
            '{ padding-left: 1.2mm; padding-right: 1.2mm; }'));
  });

  test('English prints words for the API codes', () {
    String html(String category) => _brihad({
          'maitri': {
            'order': ['Sun', 'Moon'],
            'tatkalik': [
              {
                'planet': 'Sun',
                'relations': {'Sun': 'TempFriend', 'Moon': 'TempEnemy'},
              },
            ],
          },
          'Remedies': [
            {'Title': 'A', 'Category': category, 'Description': 'D'},
          ],
        });
    final out = html('graha_shanti');
    for (final words in [
      'Temporary friend',
      'Temporary enemy',
      'Graha shanti'
    ]) {
      expect(out, contains('>$words<'));
    }
    expect(out, isNot(matches(RegExp('TempFriend|TempEnemy|graha_shanti'))));
    expect(html('charity'), contains('>Charity<'));
    expect(html('ishta'), contains('>Ishta<'), reason: 'i is I, not dotted');
    // Anything that is not a lower-case ASCII code stays as it came.
    for (final kept in ['Graha_Shanti', 'graha shanti', 'दान', 'grah2']) {
      expect(html(kept), contains('>$kept<'));
    }
  });
}
