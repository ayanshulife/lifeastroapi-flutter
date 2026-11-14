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

/// Where two strings first differ, with some context, for a readable failure.
String firstDiff(String expected, String actual) {
  final n = expected.length < actual.length ? expected.length : actual.length;
  var i = 0;
  while (i < n && expected.codeUnitAt(i) == actual.codeUnitAt(i)) {
    i++;
  }
  final line = '\n'.allMatches(expected.substring(0, i)).length + 1;
  String around(String s) {
    final a = (i - 120).clamp(0, s.length);
    final b = (i + 120).clamp(0, s.length);
    return jsonEncode(s.substring(a, b));
  }

  return 'first difference at offset $i (line $line); lengths '
      '${expected.length} vs ${actual.length}\n'
      'expected: ${around(expected)}\n'
      'actual:   ${around(actual)}';
}

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
      final String html;
      try {
        html = render!(data, brandingFrom(c['branding']));
      } on UnimplementedError {
        markTestSkipped('$fn is not ported yet');
        return;
      }
      final expected = File('$dir/golden/$id.html').readAsStringSync();
      if (html != expected) fail(firstDiff(expected, html));
    });
  }
}
