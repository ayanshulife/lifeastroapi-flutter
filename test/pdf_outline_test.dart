// Bookmarks and link pages (lib/src/pdf/outline.dart) on synthetic PDFs.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:lifeastroapi/src/pdf/outline.dart';
import 'package:test/test.dart';

import 'support/pdf_builder.dart';

/// A literal string as a PDF reader takes it (ISO 32000-1, 7.3.4.2): an end
/// of line that is not escaped is a line feed.
String _readTitle(String literal) {
  final bytes = <int>[];
  for (var i = 0; i < literal.length; i++) {
    final c = literal.codeUnitAt(i);
    if (c == 0x5c) {
      final next = literal[++i];
      bytes.add(switch (next) {
        'r' => 0x0d,
        'n' => 0x0a,
        _ => next.codeUnitAt(0),
      });
    } else if (c == 0x0d) {
      if (i + 1 < literal.length && literal.codeUnitAt(i + 1) == 0x0a) i++;
      bytes.add(0x0a);
    } else {
      bytes.add(c);
    }
  }
  return String.fromCharCodes([
    for (var i = 2; i + 1 < bytes.length; i += 2) bytes[i] << 8 | bytes[i + 1],
  ]);
}

bool _has(String tool) {
  try {
    Process.runSync(tool, ['--version']);
    return true;
  } on ProcessException {
    return false;
  }
}

void main() {
  test('link targets give the first page of each URI', () {
    final pdf = buildPdf([
      [],
      ['https://a.example/T0', r'https://a.example/\(x\)'],
      ['https://a.example/T1', 'https://a.example/T0'],
    ]);
    expect(linkTargetPages(pdf), {
      'https://a.example/T0': 2,
      'https://a.example/(x)': 2,
      'https://a.example/T1': 3,
    });
  });

  test('stream data is never read as objects, however large', () {
    final decoy = '9 0 obj << /Type /Page >> endobj stream\n trailer '
        '<< /Root 9 0 R >> ${'\u00ff\u0000x ' * 2000000}';
    final pdf = buildPdf([
      ['https://a.example/T0'],
      [],
    ], stream: decoy);
    final watch = Stopwatch()..start();
    expect(pdfPageCount(pdf), 2);
    expect(linkTargetPages(pdf), {'https://a.example/T0': 1});
    expect(watch.elapsed, lessThan(const Duration(seconds: 15)));
  });

  test('tens of thousands of objects after the last stream stay fast', () {
    final pdf = buildPdf([
      [],
      [for (var i = 0; i < 50000; i++) 'https://a.example/T$i'],
    ], stream: 'x');
    final watch = Stopwatch()..start();
    expect(linkTargetPages(pdf), hasLength(50000));
    expect(watch.elapsed, lessThan(const Duration(seconds: 5)));
  });

  test('bookmarks nest, clamp and are appended', () {
    final pdf = buildPdf([[], [], []]);
    final out = addPdfOutline(pdf, [
      (title: 'ਭਾਗ 1 (ਜਨਮ)', page: 1, level: 1),
      (title: 'Planets', page: 2, level: 2),
      (title: 'Dasha', page: 99, level: 2),
      (title: '  ', page: 1, level: 1),
      (title: 'Part 2', page: 0, level: 1),
    ]);
    expect(out.sublist(0, pdf.length), pdf, reason: 'incremental update');
    expect(pdfPageCount(out), 3);

    final s = latin1.decode(out).substring(pdf.length);
    expect(s, contains('/Type /Outlines /First 7 0 R /Last 10 0 R /Count 4'));
    expect(s, contains('/PageMode /UseOutlines'));
    expect(s, contains('/First 8 0 R /Last 9 0 R /Count 2 /Dest [3 0 R /Fit]'));
    expect(s, contains('/Parent 7 0 R /Prev 8 0 R /Dest [5 0 R /Fit]'));
    // UTF-16BE with a BOM; the brackets are escaped.
    final bom = String.fromCharCodes([0xfe, 0xff]);
    expect(s, contains('/Title ($bom\\n-'));
    expect(s, contains('\u0000\\('));
    // /Prev of the new trailer points at the old cross-reference table.
    final oldXref =
        RegExp(r'startxref\n(\d+)').firstMatch(latin1.decode(pdf))![1];
    expect(s, contains('/Prev $oldXref >>'));
  });

  group('titles', () {
    // U+0D0A and U+0A0D have both bytes special; U+200D and U+0A15 end or
    // start with one.
    final titles = [
      'ഭാഗം 1: അടിസ്ഥാനം',
      'ലഗ്നം (ജനനം) \\ ਕੁੰਡਲੀ',
      String.fromCharCodes([0x0d0a, 0x0a0d, 0x200d, 0x0a15, 0x0d0d]),
      'भाग 2: दशा',
    ];
    final pdf = addPdfOutline(
      buildPdf([[]]),
      [for (final t in titles) (title: t, page: 1, level: 1)],
    );

    test('CR and LF bytes are escaped, so every script reads back', () {
      final written = RegExp(r'/Title \(((?:\\[\s\S]|[^\\)])*)\) /Parent')
          .allMatches(latin1.decode(pdf))
          .map((m) => m[1]!)
          .toList();
      expect(written, hasLength(titles.length));
      for (final w in written) {
        expect(w, isNot(contains('\r')));
        expect(w, isNot(contains('\n')));
      }
      expect(written.first, contains(r'\r'));
      expect(written.map(_readTitle), titles);
    });

    test('qpdf reads the Malayalam titles back', () {
      final dir = Directory.systemTemp.createTempSync('lifeastro-test-');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/outline.pdf')..writeAsBytesSync(pdf);
      final out = Process.runSync(
          'qpdf', ['--json', '--json-key=outlines', file.path],
          stdoutEncoding: utf8);
      expect(out.exitCode, 0, reason: '${out.stderr}');
      final outlines =
          ((jsonDecode(out.stdout as String) as Map)['outlines'] as List)
              .cast<Map<String, Object?>>();
      expect([for (final o in outlines) o['title']], titles);
    }, skip: _has('qpdf') ? null : 'qpdf is not installed');
  });

  test('the appended trailer keeps /Info, also when appended twice', () {
    final pdf = buildPdf([[]], title: 'Janma Kundli');
    final info = RegExp(r'/Info \d+ 0 R').firstMatch(latin1.decode(pdf))![0]!;
    final once = addPdfOutline(pdf, [(title: 'One', page: 1, level: 1)]);
    final twice = addPdfOutline(once, [(title: 'Two', page: 1, level: 1)]);
    for (final out in [once, twice]) {
      expect(latin1.decode(out).split('trailer').last, contains(info));
    }
    final bare =
        addPdfOutline(buildPdf([[]]), [(title: 'One', page: 1, level: 1)]);
    expect(latin1.decode(bare), isNot(contains('/Info')));
  });

  test('every byte survives (Latin-1, not windows-1252)', () {
    final c1 = String.fromCharCodes([for (var b = 0x80; b < 0xa0; b++) b]);
    final pdf = buildPdf([[]],
        stream: String.fromCharCodes([for (var b = 0; b < 256; b++) b]),
        catalog: '/Lang ($c1) ');
    final out = addPdfOutline(pdf, [(title: 'One', page: 1, level: 1)]);
    expect(out.sublist(0, pdf.length), pdf);
    // The catalog is written again: its bytes must be the same.
    expect(latin1.decode(out.sublist(pdf.length)), contains('/Lang ($c1)'));
  });

  test('an outline can be replaced', () {
    final once =
        addPdfOutline(buildPdf([[]]), [(title: 'One', page: 1, level: 1)]);
    final twice = addPdfOutline(once, [(title: 'Two', page: 1, level: 1)]);
    expect(pdfPageCount(twice), 1);
    final last = latin1.decode(twice).substring(once.length);
    expect('/Outlines '.allMatches(last).length, greaterThanOrEqualTo(1));
    expect('/PageMode'.allMatches(last).length, 1);
  });

  test('nothing to add leaves the bytes alone', () {
    final pdf = buildPdf([[]]);
    expect(addPdfOutline(pdf, []), same(pdf));
    expect(addPdfOutline(pdf, [(title: ' ', page: 1, level: 1)]), same(pdf));
  });

  test('not a PDF throws FormatException', () {
    expect(() => pdfPageCount(latin1.encode('hello')), throwsFormatException);
  });
}
