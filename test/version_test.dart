// The version lives in pubspec.yaml and lib/src/version.dart.
@TestOn('vm')
library;

import 'dart:io';

import 'package:lifeastroapi/lifeastroapi.dart';
import 'package:test/test.dart';

void main() {
  test('packageVersion is the pubspec version', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version =
        RegExp(r'^version: (\S+)$', multiLine: true).firstMatch(pubspec)![1];
    expect(packageVersion, version);
    expect(File('CHANGELOG.md').readAsStringSync(), contains('## $version '));
  });
}
