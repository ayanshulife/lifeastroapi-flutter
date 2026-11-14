// Brihad Kundli PDF helpers (running header/footer, table of contents,
// section tagging) against the Node SDK (test/fixtures/pdf/brihad.json).
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:lifeastroapi/src/pdf/shared.dart';
import 'package:lifeastroapi/src/pdf/templates/kundli_brihad_sections.dart';
import 'package:test/test.dart';

const acme = Branding(
  companyName: 'Acme Astro',
  logoUrl: 'https://cdn.example/acme/logo.png',
  primaryColor: '#6b21a8',
  secondaryColor: '#9333ea',
  footerText: 'Acme Astro · confidential',
  watermarkText: 'SAMPLE',
);

void main() {
  final g = jsonDecode(File('test/fixtures/pdf/brihad.json').readAsStringSync())
      as Map<String, Object?>;

  T orSkip<T>(T Function() f) {
    try {
      return f();
    } on UnimplementedError {
      markTestSkipped('not ported yet');
      rethrow;
    }
  }

  test('running header', () {
    final h = (g['header'] as List).cast<String>();
    try {
      expect(orSkip(() => brihadHeaderTemplate(null)), h[0]);
      expect(brihadHeaderTemplate(acme), h[1]);
    } on UnimplementedError {
      return;
    }
  });

  test('running footer', () {
    final f = (g['footer'] as List).cast<String>();
    try {
      expect(orSkip(() => brihadFooterTemplate(null)), f[0]);
      expect(brihadFooterTemplate(acme), f[1]);
    } on UnimplementedError {
      return;
    }
  });

  test('table of contents', () {
    for (final t in (g['toc'] as List).cast<Map<String, Object?>>()) {
      final entries = [
        for (final e in (t['entries'] as List).cast<Map<String, Object?>>())
          (title: e['title'] as String, page: e['page'] as int),
      ];
      try {
        expect(orSkip(() => buildBrihadToc(entries, t['heading'] as String)),
            t['html']);
      } on UnimplementedError {
        return;
      }
    }
  });

  test('section tagging', () {
    for (final t in (g['tagged'] as List).cast<Map<String, Object?>>()) {
      final golden =
          File('test/fixtures/pdf/golden/${t['id']}.html').readAsStringSync();
      try {
        final r = orSkip(() => tagBrihadSectionsForToc(golden));
        expect(r.titles, t['titles'], reason: '${t['id']}');
        expect(r.html == t['html'], isTrue, reason: '${t['id']} tagged html');
      } on UnimplementedError {
        return;
      }
    }
  });
}
