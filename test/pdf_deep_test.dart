// The deep parity test: the 432 shared reference renders (3 people x 12 report
// endpoints x 10 languages, untrimmed, plus branded ones) must come out as the
// very bytes the Node SDK writes.
//
// The reference is large, so it is not in this repo. The test runs when
// LIFEASTRO_PDF_WORK (default ../LifeAstroAPI/pdf_work) exists and is skipped
// otherwise.
//
//   dart test test/pdf_deep_test.dart -N kundli-brihad.pa
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:lifeastroapi/src/pdf/renderers.dart';
import 'package:lifeastroapi/src/pdf/shared.dart';
import 'package:lifeastroapi/src/pdf/templates/kundli_brihad.dart';
import 'package:test/test.dart';

import 'support/html_diff.dart';
import 'support/sha256.dart';

const _expectedCases = 432;
const _languages = ['hi', 'mr', 'te', 'ta', 'kn', 'ml', 'gu', 'bn', 'pa'];

void main() {
  final work =
      Platform.environment['LIFEASTRO_PDF_WORK'] ?? '../LifeAstroAPI/pdf_work';
  final manifest = File('$work/manifest.json');
  if (!manifest.existsSync()) {
    test('all $_expectedCases shared cases render like Node', () {},
        skip: 'no reference at $work (set LIFEASTRO_PDF_WORK to run this)');
    return;
  }

  final cases =
      ((jsonDecode(manifest.readAsStringSync()) as Map)['cases'] as List)
          .cast<Map<String, Object?>>();

  test('SHA-256 test helper', () {
    expect(sha256Hex(utf8.encode('abc')),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
  });

  test('the reference covers every renderer', () {
    expect(cases, hasLength(_expectedCases));
    expect({for (final c in cases) 'render${c['renderer']}Html'},
        reportRenderers.keys.toSet());
  });

  // Every language must draw what English draws (Marathi once drew 73 of the
  // 153 planets of its charts).
  for (final who in {
    for (final c in cases) (c['input'] as String).split('.').first,
  }) {
    test('$who: every language draws the same planets as English', () {
      List<String> drawn(String lang) => drawnPlanets(renderKundliBrihadHtml(
          jsonDecode(File('$work/inputs/$who.kundli-brihad.$lang.json')
              .readAsStringSync()) as Map<String, Object?>));
      final english = drawn('en');
      expect(english.where((r) => r.startsWith('chart')), isNotEmpty);
      expect(english.where((r) => r.startsWith('card <svg')), hasLength(9));
      for (final lang in _languages) {
        expect(drawn(lang), english, reason: lang);
      }
    });
  }

  for (final c in cases) {
    final id = c['id'] as String;
    test(id, () {
      final data =
          jsonDecode(File('$work/inputs/${c['input']}').readAsStringSync())
              as Map<String, Object?>;
      final branding = c['branding'] is Map
          ? Branding.fromJson((c['branding'] as Map).cast<String, Object?>())
          : null;
      final html =
          reportRenderers['render${c['renderer']}Html']!(data, branding);
      if (sha256Hex(utf8.encode(html)) == c['sha256']) return;
      final expected = File('$work/expected/$id.html');
      fail(expected.existsSync()
          ? firstDiff(expected.readAsStringSync(), html)
          : 'SHA-256 differs from the reference');
    });
  }
}
