// humanize / cleanNarrative / esc against the Node SDK, over every string in
// the PDF fixtures (test/fixtures/pdf/text.json, from tool/pdf_goldens.mjs).
import 'dart:convert';
import 'dart:io';

import 'package:lifeastroapi/src/pdf/shared.dart';
import 'package:test/test.dart';

void main() {
  final rows =
      (jsonDecode(File('test/fixtures/pdf/text.json').readAsStringSync())
              as List)
          .cast<Map<String, Object?>>();

  test('humanize, esc and cleanNarrative match Node for ${rows.length} strings',
      () {
    var failures = 0;
    for (final r in rows) {
      final s = r['s'] as String;
      void check(String what, String expected, String actual) {
        if (expected != actual && failures++ < 10) {
          printOnFailure(
              '$what(${jsonEncode(s)})\n  node: ${jsonEncode(expected)}\n  dart: ${jsonEncode(actual)}');
        }
      }

      check('humanize', r['humanize'] as String, humanize(s));
      check('esc', r['esc'] as String, esc(s));
      (r['clean'] as Map).forEach((loc, v) {
        check('cleanNarrative[$loc]', v as String,
            cleanNarrative(s, loc as String));
      });
    }
    expect(failures, 0);
  });
}
