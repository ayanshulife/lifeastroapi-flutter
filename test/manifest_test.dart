// Every generated method, checked against the manifest and against the
// website's verified examples (test/fixtures/examples.json): each method is
// called once through a mock HTTP client and must send every parameter the
// API marks as required for that endpoint.
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lifeastroapi/lifeastroapi.dart';
import 'package:test/test.dart';

import '../tool/src/dispatch.g.dart';
import '../tool/src/samples.dart';

/// Params the examples list as required that the SDK leaves out on purpose.
const notReallyRequired = {
  // The handler reads `tz` only together with `date` (the transit moment);
  // without both it answers for now. Like the Node SDK, transit.sadeSati
  // sends the natal chart only.
  '/v1/transit/sade-sati': {'tz'},
  // Same rule: the transit moment defaults to now, and `tz` only goes with `date`.
  '/v1/vedic/narrative/transit-ashtakavarga': {'tz'},
};

/// Turns a path template into a pattern (`{varga}` matches one segment).
RegExp templatePattern(String path) => RegExp(
    '^${path.split(RegExp(r'\{[^}]+\}')).map(RegExp.escape).join('[^/]+')}\$');

void main() {
  final manifest = loadManifest();
  final examples =
      jsonDecode(File('test/fixtures/examples.json').readAsStringSync())
          as Map<String, Object?>;

  /// The example for a manifest path (placeholder names may differ).
  Map<String, Object?>? exampleFor(String path) {
    if (examples[path] != null) return examples[path] as Map<String, Object?>;
    final normal = path.replaceAll(RegExp(r'\{[^}]+\}'), '{}');
    for (final entry in examples.entries) {
      if (entry.key.replaceAll(RegExp(r'\{[^}]+\}'), '{}') == normal) {
        return entry.value as Map<String, Object?>;
      }
    }
    return null;
  }

  test('one method per manifest entry, same count as the Node SDK (334)', () {
    expect(manifest.length, 334);
    expect(invokers.length, manifest.length);
    expect(manifest.map((e) => e.key).toSet().length, manifest.length);
    for (final e in manifest) {
      expect(invokers.containsKey(e.key), isTrue, reason: e.key);
    }
  });

  test('English-only products and data endpoints take no lang', () {
    const englishOnly = ['/v1/western/', '/v1/tarot/', '/v1/geo/', '/v1/meta/'];
    for (final e in manifest) {
      if (englishOnly.any(e.path.startsWith) &&
          !e.path.startsWith('/v1/western/narrative/')) {
        expect(e.hasParam('lang'), isFalse, reason: e.key);
      }
    }
    for (final key in [
      'panchang.rahuKaal',
      'panchang.sunriseSunset',
      'chart.yogas',
      'chart.doshas',
      'transit.windows',
      'milan.overlay',
    ]) {
      final e = manifest.firstWhere((m) => m.key == key);
      expect(e.hasParam('lang'), isFalse, reason: key);
    }
  });

  test('every Vedic method with lang sends it as lang (and locale)', () {
    for (final e in manifest) {
      final lang = e.params.where((p) => p['name'] == 'lang');
      if (lang.isEmpty) continue;
      final wires = (lang.single['wires'] as List).cast<String>();
      expect(wires, contains('lang'), reason: e.key);
      expect(lang.single['type'], 'Lang', reason: e.key);
    }
  });

  group('every method sends the API\'s required params', () {
    for (final e in manifest) {
      test(e.key, () async {
        final built = buildInput(e);
        expect(built.missing, isEmpty,
            reason: 'no sample for ${built.missing}');
        final calls = <http.Request>[];
        final client = LifeAstro(
          apiKey: 'dv_live_test',
          maxRetries: 0,
          httpClient: MockClient((req) async {
            calls.add(req);
            return http.Response('{}', 200);
          }),
        );
        await invokers[e.key]!(client, built.input);
        final url = calls.single.url;
        expect(url.path, matches(templatePattern(e.path)));

        final ex = exampleFor(e.path);
        if (ex == null) return;
        final sent = url.queryParameters.keys.toSet();
        for (final name in (ex['required'] as List).cast<String>()) {
          if (e.path.contains('{$name}') ||
              (ex.containsKey('path') && '${ex['path']}'.contains('{$name}')) ||
              (notReallyRequired[e.path]?.contains(name) ?? false)) {
            continue;
          }
          expect(sent, contains(name),
              reason: '${e.key} (${e.path}) must send "$name"; sent $sent');
        }
      });
    }
  });
}
