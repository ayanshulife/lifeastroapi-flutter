// The HTML layer imports no dart:io, HTTP, browser or other platform library,
// so it also runs inside apps and on the web.
@TestOn('vm')
library;

import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('the renderers import only pure Dart', () {
    const allowed = {'dart:core', 'dart:math', 'dart:convert'};
    final seen = <String>{};
    final queue = [Uri.file('lib/src/pdf/renderers.dart', windows: false)];
    while (queue.isNotEmpty) {
      final file = queue.removeLast();
      if (!seen.add(file.path)) continue;
      final source = File(file.path).readAsStringSync();
      for (final m
          in RegExp(r"^(?:import|export)\s+'([^']+)'([^;]*);", multiLine: true)
              .allMatches(source)) {
        final target = m[1]!;
        expect(m[2], isNot(contains('dart.library')),
            reason: '${file.path}: no platform switch in the HTML layer');
        if (target.startsWith('dart:') || target.startsWith('package:')) {
          expect(allowed, contains(target), reason: file.path);
        } else {
          queue.add(file.resolve(target));
        }
      }
    }
    expect(seen, contains(endsWith('colors.dart')));
    expect(seen.length, greaterThan(15));
  });
}
