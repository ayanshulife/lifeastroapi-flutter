// The Dart report templates must render byte-identical HTML to the Node SDK's
// TypeScript templates. Goldens come from tool/pdf_goldens.mjs.
//
//   dart test test/pdf_golden_test.dart -N kundliLite
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:lifeastroapi/src/pdf/renderers.dart';
import 'package:lifeastroapi/src/pdf/shared.dart';
import 'package:test/test.dart';

import 'support/html_diff.dart';

Branding? brandingFrom(Object? v) =>
    v is Map ? Branding.fromJson(v.cast<String, Object?>()) : null;

void main() {
  final dir = 'test/fixtures/pdf';
  final cases = (jsonDecode(File('$dir/cases.json').readAsStringSync()) as List)
      .cast<Map<String, Object?>>();

  for (final c in cases) {
    final id = c['id'] as String;
    final fn = c['fn'] as String;
    test(id, () {
      final render = reportRenderers[fn];
      expect(render, isNotNull, reason: 'no Dart renderer for $fn');
      final data = (c['data'] as Map).cast<String, Object?>();
      final html = render!(data, brandingFrom(c['branding']));
      final expected = File('$dir/golden/$id.html').readAsStringSync();
      if (html != expected) fail(firstDiff(expected, html));
    });
  }
}
