// HTML → PDF with a real headless Chrome. Skipped when no Chrome, Chromium or
// Edge is installed (set CHROME_PATH to point at one).
@TestOn('vm')
@Tags(['chrome'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:lifeastroapi/pdf.dart';
import 'package:lifeastroapi/src/pdf/outline.dart';
import 'package:lifeastroapi/src/pdf/print_css.dart';
import 'package:lifeastroapi/src/pdf/templates/kundli_brihad_sections.dart';
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

/// Passes calls on to [inner] and keeps what went in and out.
class _SpyEngine implements PdfEngine {
  _SpyEngine(this.inner);
  final PdfEngine inner;
  final html = <String>[];
  final options = <HtmlToPdfOptions>[];
  final pdfs = <Uint8List>[];

  @override
  Future<Uint8List> htmlToPdf(String document,
      [HtmlToPdfOptions o = const HtmlToPdfOptions()]) async {
    html.add(document);
    options.add(o);
    final pdf = await inner.htmlToPdf(document, o);
    pdfs.add(pdf);
    return pdf;
  }

  @override
  Future<void> close() async {}
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
    final pdf = await kundliBrihadPdf(example('/v1/reports/kundli/brihad'),
        branding: const Branding(companyName: 'Acme Astro'), engine: engine);
    expect(isPdf(pdf), isTrue);
    final text = latin1.decode(pdf);
    expect(text, contains('/Outlines'));
    expect(pdfPageCount(pdf), greaterThan(10));
    // The markers are links only in the first print, not in the PDF.
    expect(linkTargetPages(pdf), isEmpty);
    final check = await qpdfCheck(pdf);
    if (check != null) expect(check, 'ok');
  }, skip: skip);

  test('Brihad pass 2: no markers, the same pages, the title kept', () async {
    final spy = _SpyEngine(engine);
    final pdf = await kundliBrihadPdf(example('/v1/reports/kundli/brihad'),
        engine: spy);
    expect(spy.html, hasLength(2));
    expect(spy.html.last, isNot(contains('⟦T')));

    // The shipped document again, with a link in each marker's place: its
    // sections must sit on the pages the table of contents was built from.
    var i = 0;
    var probe = spy.html.last.replaceAllMapped(
        '<span style="color:#fff;font-size:1px;">&nbsp;</span>',
        (_) => '<span style="color:#fff;font-size:1px;">'
            '<a href="https://toc.lifeastroapi.invalid/T${i++}" '
            'style="color:#fff;text-decoration:none;">&nbsp;</a></span>');
    // Also a link in the last row of the contents.
    const dots = '<span class="toc-dots"></span>';
    const tocEnd = 'https://toc.lifeastroapi.invalid/END';
    final lastRow = probe.lastIndexOf(dots);
    probe = probe.replaceFirst(dots,
        '<span class="toc-dots"><a href="$tocEnd">&nbsp;</a></span>', lastRow);
    final printed = await engine.htmlToPdf(probe, spy.options.last);
    expect(i, greaterThan(5));
    final targets = Map.of(linkTargetPages(printed));
    final endOfContents = targets.remove(tocEnd)!;
    expect(targets, linkTargetPages(spy.pdfs.first));
    expect(targets['https://toc.lifeastroapi.invalid/T0'], endOfContents + 1,
        reason: 'Part 1 starts on a page of its own after the contents');
    expect(pdfPageCount(printed), pdfPageCount(pdf));

    expect(latin1.decode(pdf).split('trailer').last,
        matches(RegExp(r'/Info \d+ 0 R')));

    // Poppler, when installed, sees the same.
    final dir = Directory.systemTemp.createTempSync('lifeastro-test-');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/brihad.pdf')..writeAsBytesSync(pdf);
    try {
      final info =
          Process.runSync('pdfinfo', [file.path], stdoutEncoding: utf8);
      expect(info.stdout, matches(RegExp(r'Title:\s+\S')));
      final words =
          Process.runSync('pdftotext', [file.path, '-'], stdoutEncoding: utf8);
      expect(words.stdout, isNot(contains('⟦')));
    } on ProcessException {
      // No Poppler: the checks above stand on their own.
    }
  }, skip: skip);

  test('the running header and footer print in a sans-serif face', () async {
    final pdf = await engine.htmlToPdf(
        '<!doctype html><html><body></body></html>',
        HtmlToPdfOptions(
          displayHeaderFooter: true,
          headerTemplate: brihadHeaderTemplate(null),
          footerTemplate: brihadFooterTemplate(null),
          margin: const PdfMargin(top: '26mm', bottom: '16mm'),
        ));
    final fonts = RegExp(r'/BaseFont\s*/([^\s/<>\[\]]+)')
        .allMatches(latin1.decode(pdf))
        .map((m) => m[1]!)
        .toSet();
    expect(fonts, isNotEmpty);
    expect(fonts.where((f) => RegExp('Times|LiberationSerif').hasMatch(f)),
        isEmpty,
        reason: '$fonts');
  }, skip: skip);

  (double, double) paper(Uint8List pdf) {
    final m = RegExp(r'/MediaBox\s*\[\s*0 0 ([0-9.]+) ([0-9.]+)\s*\]')
        .firstMatch(latin1.decode(pdf))!;
    return (double.parse(m[1]!), double.parse(m[2]!));
  }

  test('margin, format and landscape win over a report page rule', () async {
    final data = example('/v1/reports/kundli/lite');
    Future<Uint8List> print([HtmlToPdfOptions o = const HtmlToPdfOptions()]) =>
        kundliLitePdf(data, options: o, engine: engine);
    final plain = await print();
    expect(paper(plain).$1, closeTo(595, 1.5));

    final wide = paper(await print(const HtmlToPdfOptions(landscape: true)));
    expect(wide.$1, closeTo(842, 1.5));
    expect(wide.$2, closeTo(595, 1.5));
    expect(
        paper(await print(const HtmlToPdfOptions(format: PaperFormat.a5))).$1,
        closeTo(420, 1.5));
    expect(
        paper(await print(const HtmlToPdfOptions(
                format: PaperFormat.a5, preferCssPageSize: true)))
            .$1,
        closeTo(595, 1.5),
        reason: 'an explicit preferCssPageSize keeps the CSS size');

    final narrow = await print(const HtmlToPdfOptions(
        margin: PdfMargin(top: '120mm', bottom: '80mm')));
    expect(pdfPageCount(narrow), greaterThan(pdfPageCount(plain)));
  }, skip: skip);

  test('printBackground false prints dark text where it was white', () async {
    final html = renderKundliLiteHtml(example('/v1/reports/kundli/lite'));
    const script = 'getComputedStyle(document.querySelector("th")).color';
    const fill =
        'getComputedStyle(document.querySelector("th")).backgroundColor';
    expect(await engine.evaluate(html, script), 'rgb(255, 255, 255)');
    expect(await engine.evaluate(html, fill), isNot('rgba(0, 0, 0, 0)'));
    expect(
        await engine.evaluate(
            withPrintOptionsCss(
                html, const HtmlToPdfOptions(printBackground: false)),
            fill),
        'rgba(0, 0, 0, 0)',
        reason: 'a see-through fill would print solid white');
    expect(
        await engine.evaluate(
            withPrintOptionsCss(
                html, const HtmlToPdfOptions(printBackground: false)),
            script),
        'rgb(26, 26, 26)');
  }, skip: skip);

  test('Brihad: markers and watermark add no page', () async {
    final data = example('/v1/reports/kundli/brihad');
    final spy = _SpyEngine(engine);
    final pdf = await kundliBrihadPdf(data, engine: spy);
    final first =
        linkTargetPages(spy.pdfs.first)['https://toc.lifeastroapi.invalid/T0']!;
    final contents = first - 2; // after the cover
    final options = spy.options.last;

    final plain = await engine.htmlToPdf(renderKundliBrihadHtml(data), options);
    expect(pdfPageCount(pdf), pdfPageCount(plain) + contents,
        reason: 'the markers take no height');
    final marked = await engine.htmlToPdf(
        renderKundliBrihadHtml(data, const Branding(watermarkText: 'SAMPLE')),
        options);
    expect(pdfPageCount(marked), pdfPageCount(plain));
  }, skip: skip);

  test('evaluate runs JavaScript in the page', () async {
    expect(
        await engine.evaluate('<p id="x">ok</p>',
            'document.getElementById("x").textContent + " " + (1 + 2)'),
        'ok 3');
  }, skip: skip);

  test('concurrent prints each get their own page', () async {
    final pdfs = await Future.wait([
      for (var n = 1; n <= 8; n++)
        engine.htmlToPdf('<!doctype html><body>'
            '${'<p style="break-after:page">page</p>' * n}<p>end</p>'),
    ]);
    expect([for (final p in pdfs) pdfPageCount(p)],
        [for (var n = 1; n <= 8; n++) n + 1]);
  }, skip: skip);

  test('a page that never loads times out and the engine stays usable',
      () async {
    const hangs = '<p>x</p><script>document.fonts.load = null;'
        'Object.defineProperty(document.fonts, "ready", '
        '{ value: new Promise(() => {}) });</script>';
    await expectLater(
        engine.htmlToPdf(
            hangs, const HtmlToPdfOptions(timeout: Duration(seconds: 1))),
        throwsA(isA<TimeoutException>()));
    expect(isPdf(await engine.htmlToPdf('<p>still fine</p>')), isTrue);
  }, skip: skip);

  test('cancelling stops the PDF and the engine stays usable', () async {
    final abort = Completer<void>();
    final big = '<p>${'ਕੁੰਡਲੀ ' * 200000}</p>';
    final pdf =
        engine.htmlToPdf(big, HtmlToPdfOptions(abortTrigger: abort.future));
    Timer(const Duration(milliseconds: 150), abort.complete);
    await expectLater(pdf, throwsA(isA<PdfAbortedException>()));
    expect(isPdf(await engine.htmlToPdf('<p>still fine</p>')), isTrue);
  }, skip: skip);

  test('close is idempotent, fails what is printing and later calls', () async {
    final own = await ChromePdfEngine.launch();
    final printing = own.htmlToPdf('<p>${'word ' * 300000}</p>');
    final failed = expectLater(printing, throwsA(anything));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await Future.wait([own.close(), own.close()]);
    await failed;
    await expectLater(own.htmlToPdf('<p>x</p>'), throwsStateError);
  }, skip: skip);
}
