// Brihad Kundli PDF helpers (running header/footer, table of contents,
// section tagging) against the Node SDK (test/fixtures/pdf/brihad.json).
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:lifeastroapi/src/pdf/shared.dart';
import 'package:lifeastroapi/src/pdf/templates/kundli_brihad_sections.dart';
import 'package:lifeastroapi/src/pdf/templates/north_indian_chart.dart';
import 'package:test/test.dart';

void main() {
  final g = jsonDecode(File('test/fixtures/pdf/brihad.json').readAsStringSync())
      as Map<String, Object?>;

  test('palette, running header and footer, for every branding pair', () {
    List<int>? rgb((int, int, int)? c) => c == null ? null : [c.$1, c.$2, c.$3];
    final bands = (g['bands'] as List).cast<Map<String, Object?>>();
    expect(bands, hasLength(10));
    for (final band in bands) {
      final report = band['report'];
      final branding = band['branding'] is Map
          ? Branding.fromJson((band['branding'] as Map).cast<String, Object?>())
          : null;
      final why = jsonEncode([report, band['branding']]);
      final palette = brihadPalette(report, branding);
      final want = band['palette'] as Map?;
      expect(palette == null, want == null, reason: why);
      if (palette != null) {
        expect(rgb(palette.primary), want!['primary'], reason: why);
        expect(rgb(palette.accent), want['accent'], reason: why);
        expect(rgb(palette.muted), want['muted'], reason: why);
      }
      expect(brihadHeaderTemplate(report, branding), band['header'],
          reason: why);
      expect(brihadFooterTemplate(report, branding), band['footer'],
          reason: why);
    }
  });

  test('table of contents', () {
    final all = (g['toc'] as List).cast<Map<String, Object?>>();
    expect(all, hasLength(10), reason: 'every language has a heading');
    for (final t in all) {
      final entries = [
        for (final e in (t['entries'] as List).cast<Map<String, Object?>>())
          (title: e['title'] as String, page: e['page'] as int),
      ];
      expect(buildBrihadToc(entries, t['heading'] as String), t['html']);
    }
  });

  test('chart: every cell, 0 to 12 bodies', () {
    final charts =
        jsonDecode(File('test/fixtures/pdf/charts.json').readAsStringSync())
            as List;
    expect(charts, hasLength(13));
    for (final c in charts.cast<Map<String, Object?>>()) {
      final svg = northIndianChartSvg(
        lagnaSignIndex: c['lagnaSignIndex'] as int,
        planets: [
          for (final p in (c['planets'] as List).cast<Map<String, Object?>>())
            ChartPlanet(
                label: p['label'] as String,
                house: p['house'],
                color: p['color'] as String?),
        ],
      );
      expect(svg, c['svg']);
    }
  });

  test('section tagging', () {
    for (final t in (g['tagged'] as List).cast<Map<String, Object?>>()) {
      final golden =
          File('test/fixtures/pdf/golden/${t['id']}.html').readAsStringSync();
      final r = tagBrihadSectionsForToc(golden);
      expect(r.titles, t['titles'], reason: '${t['id']}');
      expect(r.html == t['html'], isTrue, reason: '${t['id']} tagged html');
    }
  });
}
