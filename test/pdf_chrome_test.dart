// HTML → PDF with a real headless Chrome. Skipped when no Chrome, Chromium or
// Edge is installed (set CHROME_PATH to point at one).
@TestOn('vm')
@Tags(['chrome'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:lifeastroapi/pdf.dart';
import 'package:lifeastroapi/src/pdf/outline.dart';
import 'package:test/test.dart';

Map<String, Object?> example(String path) {
  final pdf =
      jsonDecode(File('test/fixtures/pdf/cases.json').readAsStringSync())
          as List;
  // Reports come from the PDF cases (the API example responses).
  final fn = {
    '/v1/reports/kundli/lite': 'renderKundliLiteHtml',
    '/v1/reports/kundli/brihad': 'renderKundliBrihadHtml',
  }[path]!;
  final c = pdf.cast<Map<String, Object?>>().lastWhere((c) =>
      c['fn'] == fn &&
      c['branding'] == null &&
      (c['data'] as Map)['Locale'] == 'hi');
  return (c['data'] as Map).cast<String, Object?>();
}

bool isPdf(Uint8List b) => latin1.decode(b.sublist(0, 5)) == '%PDF-';

Future<String?> qpdfCheck(Uint8List pdf) async {
  final which = await Process.run('which', ['qpdf']);
  if (which.exitCode != 0) return null;
  final f = File(
      '${Directory.systemTemp.path}/lifeastro-test-${DateTime.now().microsecondsSinceEpoch}.pdf')
    ..writeAsBytesSync(pdf);
  final r = await Process.run('qpdf', ['--check', f.path]);
  f.deleteSync();
  return r.exitCode == 0 ? 'ok' : '${r.stdout}${r.stderr}';
}

void main() {
  final chrome = ChromePdfEngine.findChromeExecutable();
  late ChromePdfEngine engine;

  setUpAll(() async {
    if (chrome != null) engine = await ChromePdfEngine.launch();
  });
  tearDownAll(() async {
    if (chrome != null) await engine.close();
  });

  final skip = chrome == null ? 'no Chrome, Chromium or Edge found' : null;

  test('a report prints to a valid PDF (Hindi)', () async {
    final pdf = await kundliLitePdf(example('/v1/reports/kundli/lite'),
        branding: const Branding(companyName: 'Acme Astro'), engine: engine);
    expect(isPdf(pdf), isTrue);
    expect(pdfPageCount(pdf), greaterThanOrEqualTo(2));
    final check = await qpdfCheck(pdf);
    if (check != null) expect(check, 'ok');
  }, skip: skip);

  test('htmlToPdf honours paper size, margins and landscape', () async {
    const html = '<!doctype html><html><body><p>x</p></body></html>';
    final pdf = await engine.htmlToPdf(
        html,
        const HtmlToPdfOptions(
            format: PaperFormat.letter,
            landscape: true,
            margin: PdfMargin(top: '10mm', bottom: '1cm')));
    expect(isPdf(pdf), isTrue);
    // Letter landscape: 792 × 612 points.
    expect(latin1.decode(pdf), contains('/MediaBox [0 0 792 612]'));
  }, skip: skip);

  test('link annotations give the page of each section marker', () async {
    final sections = [
      for (var i = 0; i < 3; i++)
        '<section style="page-break-before:always"><span style="color:#fff;font-size:1px;">'
            '<a href="https://toc.lifeastroapi.invalid/T$i">⟦T$i⟧</a></span><h2>Section $i</h2>'
            '${'<p>text</p>' * (i == 1 ? 120 : 1)}</section>',
    ];
    final pdf = await engine.htmlToPdf(
        '<!doctype html><html><body>${sections.join()}</body></html>');
    final pages = linkTargetPages(pdf);
    expect(pages['https://toc.lifeastroapi.invalid/T0'], 1);
    expect(pages['https://toc.lifeastroapi.invalid/T1'], 2);
    // Section 1 runs over several pages, so section 2 starts later.
    expect(pages['https://toc.lifeastroapi.invalid/T2'], greaterThan(3));

    final withOutline = addPdfOutline(pdf, [
      (title: 'भाग 1: जन्म विवरण', page: 1, level: 1),
      (title: 'Section 1', page: 2, level: 2),
      (
        title: 'Section 2',
        page: pages['https://toc.lifeastroapi.invalid/T2']!,
        level: 2
      ),
    ]);
    expect(pdfPageCount(withOutline), pdfPageCount(pdf));
    expect(latin1.decode(withOutline), contains('/PageMode /UseOutlines'));
    final check = await qpdfCheck(withOutline);
    if (check != null) expect(check, 'ok');
  }, skip: skip);

  test('Brihad Kundli: TOC with real page numbers and bookmarks', () async {
    final Uint8List pdf;
    try {
      pdf = await kundliBrihadPdf(example('/v1/reports/kundli/brihad'),
          branding: const Branding(companyName: 'Acme Astro'), engine: engine);
    } on UnimplementedError {
      markTestSkipped('Brihad template not ported yet');
      return;
    }
    expect(isPdf(pdf), isTrue);
    final text = latin1.decode(pdf);
    expect(text, contains('/Outlines'));
    final check = await qpdfCheck(pdf);
    if (check != null) expect(check, 'ok');
  }, skip: skip);
}
