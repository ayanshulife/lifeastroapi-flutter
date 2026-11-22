// The process culture and time zone do not change the HTML.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  const environments = [
    ('de_DE.UTF-8', 'Asia/Kathmandu', 345),
    ('ar_SA.UTF-8', 'Pacific/Kiritimati', 840),
    ('tr_TR.UTF-8', 'America/St_Johns', -210),
  ];
  for (final (culture, zone, offset) in environments) {
    test('$culture in $zone renders the goldens', () async {
      final child = await Process.run(
        Platform.resolvedExecutable,
        [
          '--packages=.dart_tool/package_config.json',
          'test/support/render_cases.dart',
        ],
        environment: {'LANG': culture, 'LC_ALL': culture, 'TZ': zone},
      );
      expect(child.exitCode, 0, reason: '${child.stderr}');
      final out = jsonDecode('${child.stdout}') as Map<String, Object?>;
      expect(out['offsetMinutes'], offset, reason: 'the zone was applied');
      expect(out['cases'], greaterThan(300));
      expect(out['differs'], isEmpty);
    },
        skip: Platform.isWindows ? 'TZ names need a POSIX system' : null,
        timeout: const Timeout(Duration(minutes: 3)));
  }
}
