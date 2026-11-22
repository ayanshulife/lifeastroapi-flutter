// Child process of pdf_environment_test.dart: renders every golden case and
// prints the ids that differ, then the time zone offset it ran with.
import 'dart:convert';
import 'dart:io';

import 'package:lifeastroapi/src/pdf/renderers.dart';
import 'package:lifeastroapi/src/pdf/shared.dart';

void main() {
  const dir = 'test/fixtures/pdf';
  final cases = jsonDecode(File('$dir/cases.json').readAsStringSync()) as List;
  final differs = <String>[];
  for (final c in cases.cast<Map<String, Object?>>()) {
    final b = c['branding'];
    final html = reportRenderers[c['fn']]!(
        (c['data'] as Map).cast<String, Object?>(),
        b is Map ? Branding.fromJson(b.cast<String, Object?>()) : null);
    if (html != File('$dir/golden/${c['id']}.html').readAsStringSync()) {
      differs.add('${c['id']}');
    }
  }
  stdout.write(jsonEncode({
    'cases': cases.length,
    'differs': differs,
    'offsetMinutes': DateTime(2026, 1, 1).timeZoneOffset.inMinutes,
  }));
}
