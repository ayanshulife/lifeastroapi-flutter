// Colour math and print CSS against the Node SDK (test/fixtures/pdf/colors.json
// and options.json, from tool/pdf_goldens.mjs).
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:lifeastroapi/pdf.dart';
import 'package:lifeastroapi/src/pdf/colors.dart';
import 'package:lifeastroapi/src/pdf/print_css.dart';
import 'package:test/test.dart';

List<Map<String, Object?>> _fixture(String name) =>
    (jsonDecode(File('test/fixtures/pdf/$name').readAsStringSync()) as List)
        .cast<Map<String, Object?>>();

void main() {
  test('colours: every name, form and trap reads like Node', () {
    final rows = _fixture('colors.json');
    expect(rows.length, greaterThan(400));
    for (final row in rows) {
      final value = row['value'] as String;
      final why = jsonEncode(value);
      final rgb = parseColor(value);
      expect(rgb == null ? null : [rgb.$1, rgb.$2, rgb.$3], row['rgb'],
          reason: why);
      expect(printableColor(value, '#1a1a1a'), row['printable'], reason: why);
      if (rgb == null) continue;
      expect(toHex(rgb), row['hex'], reason: why);
      expect(toHex(darkenToContrast(rgb, 5.2)), row['brihad'], reason: why);
      expect([
        for (final p in [3, 5, 25]) toHex(tintOnWhite(rgb, p))
      ], row['tint'], reason: why);
      expect(seeThrough(rgb), row['seeThrough'], reason: why);
    }
  });

  test('printOptionsCss gives what Node gives', () {
    final rows = _fixture('options.json');
    expect(rows.length, greaterThan(50));
    for (final row in rows) {
      final o = row['options'] as Map;
      final m = o['margin'] as Map?;
      final format = (o['format'] as String? ?? 'A4').toLowerCase();
      final options = HtmlToPdfOptions(
        format: PaperFormat.values.byName(format),
        landscape: o['landscape'] as bool? ?? false,
        printBackground: o['printBackground'] as bool? ?? true,
        preferCssPageSize: o['preferCSSPageSize'] as bool?,
        displayHeaderFooter: o['displayHeaderFooter'] as bool?,
        footerTemplate: o['footerTemplate'] as String?,
        margin: m == null
            ? null
            : PdfMargin(
                top: m['top'] as String?,
                right: m['right'] as String?,
                bottom: m['bottom'] as String?,
                left: m['left'] as String?,
              ),
      );
      expect(printOptionsCss(options), row['css'], reason: jsonEncode(o));
    }
  });
}
