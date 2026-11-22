// Template defects fixed in 0.3.0, the same checks as the Node SDK's
// test/pdf-fixes.test.ts. Runs on the VM and in browsers.
import 'package:lifeastroapi/pdf.dart';
import 'package:lifeastroapi/src/pdf/renderers.dart';
import 'package:lifeastroapi/src/pdf/shared.dart';
import 'package:lifeastroapi/src/pdf/templates/north_indian_chart.dart';
import 'package:test/test.dart';

import 'support/html_diff.dart';

String _doc([Branding? branding]) => layoutDocument(
    title: 't', branding: resolveBranding(null, branding), bodyHtml: '');

void main() {
  const tag = '<img src=x>';

  group('escaping', () {
    test('Rajyoga planets', () {
      final html = renderKundliBrihadHtml({
        'rajyoga_power': {
          'percent': 5,
          'planets': [tag],
        },
      });
      expect(html, isNot(contains(tag)));
      expect(html, contains('&lt;img src=x&gt;'));
    });

    test('KP significator values', () {
      final html = renderKundliBrihadHtml({
        'kp': {
          'cusps': [
            {'house': 1},
          ],
          'planet_significators': [
            {
              'key': 'Sun',
              'values': [tag, 4],
            },
          ],
        },
      });
      expect(html, isNot(contains(tag)));
      expect(html, contains('&lt;img src=x&gt;, 4'));
    });

    test('a logo URL stays as written, only HTML-escaped', () {
      final html = coverBrandingHtml(resolveBranding(null,
          const Branding(logoUrl: 'https://cdn.example/a,,b->c.png?x=1&y=2')));
      expect(html,
          contains('src="https://cdn.example/a,,b-&gt;c.png?x=1&amp;y=2"'));
    });
  });

  group('customer HTML', () {
    test('carries no CSS comments', () {
      for (final html in [
        _doc(),
        renderKundliBrihadHtml({}),
        renderKundliLiteHtml({}),
        renderNumerologyHtml({'driver': 6}),
      ]) {
        expect(html, isNot(contains('/*')));
      }
    });

    test('keeps a watermark that holds comment markers', () {
      expect(_doc(const Branding(watermarkText: 'A/*B*/C')),
          contains('content: "A/*B*/C"'));
    });

    test('a line separator cannot end the CSS string', () {
      final separator = String.fromCharCode(0x2028);
      expect(_doc(Branding(watermarkText: 'A${separator}B')),
          contains('content: "A B"'));
    });

    test('drops Latin letter-spacing in every Indic language', () {
      final rule = _doc()
          .split('\n')
          .firstWhere((l) => l.contains('letter-spacing: normal'));
      for (final l in ['gu', 'bn', 'pa']) {
        expect(rule, contains('html:lang($l)'));
      }
    });

    test('the footer takes every colour the headings take', () {
      expect(_doc(const Branding(secondaryColor: 'rgb(1 2 3 / 50%)')),
          contains('color: rgb(1 2 3 / 50%);'));
      expect(_doc(const Branding(secondaryColor: 'red}body{')),
          contains('color: #666666;'));
    });
  });

  group('numerology', () {
    test('prints the name the API sends at the top level', () {
      expect(renderNumerologyHtml({'name': 'Arjun Mehta', 'driver': 6}),
          contains('<div class="subject">Arjun Mehta</div>'));
    });

    test('lays each label above its own value', () {
      expect(renderNumerologyHtml({'driver': 6}),
          contains('grid-auto-flow: column'));
    });
  });

  group('varshaphal solar return', () {
    const iso = '2027-01-15T16:39:17Z';

    test('prefers the local time of the birth', () {
      final html = renderVarshaphalHtml(
          {'SolarReturnISO': iso, 'SolarReturnLocal': '2027-01-15 22:09 IST'});
      expect(html, contains('2027-01-15 22:09 IST'));
      expect(html, isNot(contains('16:39:17Z')));
    });

    test('else prints readable UTC', () {
      expect(renderVarshaphalHtml({'SolarReturnISO': iso}),
          contains('2027-01-15 16:39 UTC'));
    });
  });

  group('match making', () {
    const wrong = {
      'hi': '8 गुण',
      'mr': '8 गुण',
      'gu': '8 ગુણ',
      'bn': '8 গুণ',
      'pa': '8 ਗੁਣ',
    };
    wrong.forEach((lang, eight) {
      test('$lang says 36 guna, with aligned score headings', () {
        final html = renderMatchMakingHtml({
          'Locale': lang,
          'Ashtakoota': {
            'Kootas': [
              {'name': 'Varna', 'score': 1, 'max': 1},
            ],
            'Total': 1,
            'Max': 36,
          },
        });
        expect(html, isNot(contains(eight)));
        expect(html, contains(eight.replaceFirst('8', '36')));
        expect('<th class="score">'.allMatches(html), hasLength(2));
      });
    });
  });

  group('North Indian chart cells', () {
    List<(String, String, String, int)> rowsOf(int house, int count) {
      final svg = northIndianChartSvg(lagnaSignIndex: 0, planets: [
        for (var i = 0; i < count; i++) ChartPlanet(label: 'P$i', house: house),
      ]);
      return [
        for (final m in RegExp(r'<text x="([^"]+)" y="([^"]+)" '
                r'font-size="([^"]+)" font-weight="bold"[^>]*>(.*?)</text>')
            .allMatches(svg))
          (m[1]!, m[2]!, m[3]!, '<tspan fill'.allMatches(m[4]!).length),
      ];
    }

    test('six planets in a top triangle go around the sign number', () {
      expect(
          rowsOf(12, 6), [('74.5', '16', '3.5', 2), ('74.5', '5', '3.5', 4)]);
    });

    test('a side triangle moves toward the middle of the chart', () {
      expect(rowsOf(3, 2), [('12', '26.5', '4', 2)]);
      expect(rowsOf(9, 2), [('88', '76.5', '4', 2)]);
    });

    test('every body is drawn once, with one decimal at most', () {
      for (var house = 1; house <= 12; house++) {
        for (var count = 1; count <= 12; count++) {
          final rows = rowsOf(house, count);
          expect(rows.fold<int>(0, (sum, r) => sum + r.$4), count,
              reason: 'house $house, $count bodies');
          for (final (x, y, _, _) in rows) {
            for (final v in [x, y]) {
              expect(v, matches(RegExp(r'^\d+(\.\d)?$')));
            }
          }
        }
      }
    });
  });

  group('Brihad layout', () {
    test('Part 1 starts on a page of its own after the contents', () {
      expect(renderKundliBrihadHtml({}),
          matches(RegExp(r'\.toc-section \{[^}]*page-break-after: always')));
    });

    test('its pages do not get the shared heading padding', () {
      expect(
          renderKundliBrihadHtml({}), contains('h2, h3 { padding-top: 0; }'));
    });

    test('the chart keeps the document font stack', () {
      final svg = northIndianChartSvg(lagnaSignIndex: 0, planets: const []);
      expect(svg, isNot(contains('Helvetica')));
    });
  });

  group('a locale that names an Object property is English', () {
    reportRenderers.forEach((name, render) {
      test(name, () {
        final key = name == 'renderHoroscopeHtml' ? 'language' : 'Locale';
        for (final bad in ['toString', 'constructor', '__proto__', 'valueOf']) {
          final data = <String, Object?>{key: bad};
          final html = render(data);
          expect(html, contains('<html lang="en">'), reason: bad);
          expect(html, render({key: 'en'}), reason: bad);
          expect(data[key], bad, reason: 'the input is not changed');
        }
      });
    });
  });

  test('Marathi Brihad: the same planets in the same cells as English', () {
    const names = {
      'Sun': 'सूर्य',
      'Moon': 'चंद्र',
      'Mars': 'मंगळ',
      'Mercury': 'बुध',
      'Jupiter': 'बृहस्पती',
      'Venus': 'शुक्र',
      'Saturn': 'शनी',
      'Rahu': 'राहू',
      'Ketu': 'केतू',
    };
    Map<String, Object?> report(String lang) {
      final planets =
          (lang == 'mr' ? names.values : names.keys).toList(growable: false);
      final sign = lang == 'mr' ? 'मेष' : 'Aries';
      return {
        'Locale': lang,
        'Ascendant': {'sign': sign},
        'Planets': [
          for (var i = 0; i < planets.length; i++)
            {
              'name': planets[i],
              'house_num': i + 1,
              'placement': {'sign': sign},
            },
        ],
        'DivisionalCharts': [
          for (final varga in ['D2', 'D9'])
            {
              'varga': varga,
              'lagna_sign': sign,
              'planets': [
                for (var i = 0; i < planets.length; i++)
                  {'name': planets[i], 'house': varga == 'D2' ? i % 2 + 1 : 9},
              ],
            },
        ],
      };
    }

    final english = drawnPlanets(renderKundliBrihadHtml(report('en')));
    expect(english.where((r) => r.startsWith('card <svg')), hasLength(9));
    expect(drawnPlanets(renderKundliBrihadHtml(report('mr'))), english);
  });

  test('a timestamp without a zone is UTC', () {
    for (final iso in [
      '2027-01-15T16:39:17',
      '2027-01-15t16:39:17',
      '2027-01-15 16:39',
    ]) {
      expect(renderVarshaphalHtml({'SolarReturnISO': iso}),
          contains('2027-01-15 16:39 UTC'),
          reason: iso);
    }
  });

  group('a field that should be a list and is not', () {
    test('listText keeps a lone string or number, and nothing else', () {
      expect(listText(['Sun', null, 2.0]), 'Sun, , 2');
      expect(listText('1, 5'), '1, 5');
      expect(listText(7), '7');
      expect(listText(1.0), '1');
      for (final other in [
        null,
        true,
        <String, int>{'a': 1}
      ]) {
        expect(listText(other), '', reason: '$other');
      }
    });

    test('Rajyoga planets', () {
      String planets(Object? value) => RegExp(r'<p>[^<:]*: ([^<]*)</p>')
          .allMatches(renderKundliBrihadHtml({
            'rajyoga_power': {'percent': 5, 'planets': value},
          }))
          .last[1]!;
      expect(planets('Sun, Moon'), 'Sun, Moon');
      expect(planets(7), '7');
      expect(planets(<String, int>{'a': 1}), '');
    });

    test('KP significator values', () {
      final html = renderKundliBrihadHtml({
        'kp': {
          'cusps': [
            {'house': 1},
          ],
          'planet_significators': [
            {'key': 'Sun', 'values': '1, 5'},
            {'key': 'Moon', 'values': <String, int>{}},
            {'key': 'Mars', 'values': '<b>'},
          ],
        },
      });
      expect(html, contains('<td>1, 5</td>'));
      expect(html, contains('<td>Moon</td><td></td>'));
      expect(html, contains('<td>&lt;b&gt;</td>'));
    });

    test('Sade Sati signs', () {
      String report(Object? signs) => renderSadeSatiHtml({
            'Current': {'SignsTraversed': signs},
            'Future': [
              {'StartDate': '2030', 'SignsTraversed': signs},
            ],
          });
      expect(report('Pisces'), contains('<td>Pisces</td>'));
      for (final other in [
        true,
        <String, int>{'a': 1}
      ]) {
        final html = report(other);
        expect(html, isNot(contains('[object')));
        expect(html, isNot(contains('<td>true</td>')));
      }
    });

    test('every list site renders', () {
      for (final value in [
        '1, 5',
        7,
        <String, int>{'a': 1}
      ]) {
        final html = renderKundliBrihadHtml({
          'narrative_chapters': value,
          'Ascendant': {'sign': 'Aries'},
          'Planets': [
            {'name': 'Sun', 'house_num': 1},
          ],
          'DivisionalCharts': [
            {'varga': 'D9', 'lagna_sign': 'Leo', 'planets': value},
          ],
          'gems': {'stones': value},
          'chalit': {
            'houses': [
              {'house': 1},
            ],
            'planets': value,
          },
          'kp': {
            'cusps': [
              {'house': 1},
            ],
            'planet_significators': value,
          },
          'jaimini': {'charakarakas': value, 'arudha_padas': value},
          'lalkitab': {'planets': value, 'rins': value},
          'ashtakavarga': {
            'sav': [28],
            'prastar': value,
          },
          'varshaphal': [
            {'year': 2026, 'sahams': value, 'panchavargeeya': value},
          ],
          'mudda_timeline': {
            'periods': [
              {'areas': value},
            ],
          },
          'rajyoga_power': {'swarnim_kaal': value, 'planets': value},
        });
        expect(html, endsWith('</html>'));
        expect(html, contains('class="section short-section"'),
            reason: 'no list of periods is a short section');
        expect(
            renderMatchMakingHtml({
              'MangalDoshaBoy': {
                'Computed': true,
                'HasDosha': true,
                'HousesOccupied': value,
              },
            }),
            endsWith('</html>'));
      }
    });
  });

  group('a null inside a list', () {
    final cases = <(String, Map<String, Object?>)>[
      (
        'KundliBrihad',
        {
          'Planets': <Object?>[null]
        }
      ),
      (
        'KundliBrihad',
        {
          'Planets': ['x', null]
        }
      ),
      (
        'KundliBrihad',
        {
          'Planets': [7, null]
        }
      ),
      (
        'KundliBrihad',
        {
          'narrative_chapters': [
            {'key': 'outlook'},
            null,
          ],
        },
      ),
      (
        'KundliDetailed',
        {
          'Planets': [<String, Object?>{}, null]
        },
      ),
      (
        'DashaAnalysis',
        {
          'AllMahadashas': <Object?>[null]
        }
      ),
      (
        'Horoscope',
        {
          'slow_movers': <Object?>[null]
        }
      ),
    ];
    for (final (name, data) in cases) {
      test('is skipped in $name: $data', () {
        final html = reportRenderers['render${name}Html']!(data, null);
        expect(html, endsWith('</html>'));
      });
    }

    test('plain values hold their places, other null items are dropped', () {
      final out = withoutNullItems({
        'text': ['x', null, 'y'],
        'number': <num?>[null, 7.5, 0],
        'flag': [false, null],
        'nulls': <Object?>[null, null],
        'objects': [
          null,
          {'a': 1},
          null,
          {
            'deep': [1, null],
          },
        ],
        'lists': [
          <Object?>[null],
          null,
        ],
        'mixed': [
          'x',
          null,
          <String, int>{'a': 1},
        ],
        'kept': null,
      });
      expect(out, {
        'text': ['x', '', 'y'],
        'number': ['', 7.5, 0],
        'flag': [false, ''],
        'nulls': <Object?>[],
        'objects': [
          {'a': 1},
          {
            'deep': [1, ''],
          },
        ],
        'lists': [<Object?>[]],
        'mixed': [
          'x',
          {'a': 1},
        ],
        'kept': null,
      });
    });

    test('a list typed without nulls takes a changed item', () {
      final out = withoutNullItems({
        'rows': <List<int?>>[
          [1, null],
        ],
        'maps': <Map<String, List<int?>>>[
          {
            'v': [2, null],
          },
        ],
      });
      expect(out['rows'], [
        [1, ''],
      ]);
      expect(out['maps'], [
        {
          'v': [2, ''],
        },
      ]);
    });

    test('a report without such a null comes back as it is', () {
      final data = <String, Object?>{
        'a': [1, 'x', double.nan, 2.5, true],
        'b': {
          'c': <String, Object?>{'d': null},
          'e': <Object?>[],
        },
      };
      expect(withoutNullItems(data), same(data));
    });

    test('recursion stops after 32 levels', () {
      Map<String, Object?> nested(int levels) {
        var data = <String, Object?>{
          'list': ['x', null],
        };
        for (var i = 0; i < levels; i++) {
          data = {'child': data};
        }
        return data;
      }

      expect('${withoutNullItems(nested(31))}', contains('[x, ]'));
      expect('${withoutNullItems(nested(32))}', contains('[x, null]'));
    });

    test("does not edit the caller's report", () {
      final planets = <Object?>[
        null,
        {'name': 'Sun'},
      ];
      final data = <String, Object?>{'Planets': planets};
      renderKundliBrihadHtml(data);
      expect(data['Planets'], same(planets));
      expect(planets, [
        null,
        {'name': 'Sun'},
      ]);
    });
  });

  test('cleanNarrative is linear on long text without a danda', () {
    final text = 'planet in the house of gains ' * 8000;
    final watch = Stopwatch()..start();
    cleanNarrative(text, 'en');
    expect(watch.elapsed, lessThan(const Duration(milliseconds: 1500)));
  });
}
