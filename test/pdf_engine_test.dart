// The PDF engines without a browser: options, Gotenberg against a stand-in
// server, the safety rules of ChromePdfEngine with a fake browser, and the
// report helpers with a recording engine.
@TestOn('vm')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lifeastroapi/lifeastroapi.dart';
import 'package:lifeastroapi/pdf.dart';
import 'package:lifeastroapi/src/pdf/print_css.dart';
import 'package:lifeastroapi/src/pdf/templates/kundli_brihad_sections.dart';
import 'package:test/test.dart';

import 'support/pdf_builder.dart';

class _RecordingEngine implements PdfEngine {
  _RecordingEngine([this.answers = const []]);
  final List<Uint8List> answers;
  final html = <String>[];
  final options = <HtmlToPdfOptions>[];
  var closed = false;

  @override
  Future<Uint8List> htmlToPdf(String document,
      [HtmlToPdfOptions o = const HtmlToPdfOptions()]) async {
    html.add(document);
    options.add(o);
    return html.length <= answers.length
        ? answers[html.length - 1]
        : Uint8List.fromList(latin1.encode('%PDF-test'));
  }

  @override
  Future<void> close() async => closed = true;
}

/// A browser's DevTools side: records every call, answers at once, and
/// answers `Page.printToPDF` after [printTakes].
class _DevTools {
  _DevTools._(this._server) {
    _server.listen((request) async {
      final ws = await WebSocketTransformer.upgrade(request);
      ws.listen((raw) async {
        final call = (jsonDecode(raw as String) as Map).cast<String, Object?>();
        calls.add(call);
        final Map<String, Object?> result;
        switch (call['method']) {
          case 'Target.createTarget':
            result = {'targetId': 't'};
          case 'Target.attachToTarget':
            result = {'sessionId': 's'};
          case 'Page.getFrameTree':
            result = {
              'frameTree': {
                'frame': {'id': 'f'},
              },
            };
          case 'Page.printToPDF':
            await Future<void>.delayed(printTakes);
            result = {'data': base64Encode(latin1.encode('%PDF-test'))};
          default:
            result = {};
        }
        ws.add(jsonEncode({'id': call['id'], 'result': result}));
      });
    });
  }

  static Future<_DevTools> start() async =>
      _DevTools._(await HttpServer.bind(InternetAddress.loopbackIPv4, 0));

  final HttpServer _server;
  final calls = <Map<String, Object?>>[];
  var printTakes = Duration.zero;

  Future<ChromePdfEngine> connect() => ChromePdfEngine.connect(
      'ws://127.0.0.1:${_server.port}/devtools/browser/x');

  Map<String, Object?> sent(String method) =>
      (calls.lastWhere((c) => c['method'] == method)['params'] as Map)
          .cast<String, Object?>();

  Future<void> stop() => _server.close(force: true);
}

Map<String, Object?> _case(String fn, String locale) {
  final cases =
      (jsonDecode(File('test/fixtures/pdf/cases.json').readAsStringSync())
              as List)
          .cast<Map<String, Object?>>();
  final found = cases.lastWhere((c) =>
      c['fn'] == fn &&
      c['branding'] == null &&
      (c['data'] as Map)['Locale'] == locale);
  return (found['data'] as Map).cast<String, Object?>();
}

void main() {
  group('options', () {
    test('CSS lengths', () {
      expect(cssLengthToInches('25.4mm'), closeTo(1, 1e-12));
      expect(cssLengthToInches('2.54cm'), closeTo(1, 1e-12));
      expect(cssLengthToInches('0.5in'), 0.5);
      expect(cssLengthToInches('96'), 1);
      expect(cssLengthToInches(null), 0);
      expect(() => cssLengthToInches('1em'), throwsArgumentError);
    });

    test('landscape, header and footer, copyWith', () {
      const o = HtmlToPdfOptions(format: PaperFormat.letter, landscape: true);
      expect(o.paperInches, (11, 8.5));
      expect(o.effectivePreferCssPageSize, isTrue);
      final h = o.copyWith(displayHeaderFooter: true);
      expect(h.effectivePreferCssPageSize, isFalse);
      final trigger = Completer<void>().future;
      expect(
          HtmlToPdfOptions(abortTrigger: trigger)
              .copyWith(scale: 1)
              .abortTrigger,
          same(trigger));
    });
  });

  group('Gotenberg', () {
    late HttpServer server;
    late Uri base;
    late List<(HttpHeaders, String, String)> seen;
    var status = 200;
    var answer = '%PDF-test';
    var delay = Duration.zero;
    var dribble = false;

    setUp(() async {
      status = 200;
      answer = '%PDF-test';
      delay = Duration.zero;
      dribble = false;
      seen = [];
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((req) async {
        final body = await utf8.decodeStream(req);
        seen.add((req.headers, req.uri.path, body));
        final res = req.response;
        try {
          if (dribble) {
            res.add(utf8.encode('%PDF-'));
            await res.flush();
          }
          if (delay > Duration.zero) await Future<void>.delayed(delay);
          if (!dribble) res.statusCode = status;
          res.add(utf8.encode(answer));
          await res.close();
        } catch (_) {
          // The client went away (timeout and abort tests).
        }
      });
      base = Uri.parse('http://127.0.0.1:${server.port}/gotenberg/');
    });
    tearDown(() => server.close(force: true));

    String? field(String body, String name) =>
        RegExp('name="$name"[\\s\\S]*?\\r\\n\\r\\n([^\\r]*)\\r\\n')
            .firstMatch(body)?[1];

    test('sends the HTML and the page geometry', () async {
      final engine = GotenbergPdfEngine(base,
          headers: const {'Authorization': 'Basic dXNlcjpwYXNz'});
      addTearDown(engine.close);
      final pdf = await engine.htmlToPdf(
          '<p>ਸਤਿ ਸ੍ਰੀ ਅਕਾਲ</p>',
          const HtmlToPdfOptions(
              format: PaperFormat.letter,
              landscape: true,
              margin: PdfMargin(top: '25.4mm', left: '1in')));
      expect(latin1.decode(pdf), '%PDF-test');
      final (headers, path, body) = seen.single;
      expect(path, '/gotenberg/forms/chromium/convert/html');
      expect(headers.value('authorization'), 'Basic dXNlcjpwYXNz');
      const fields = {
        'paperWidth': '11',
        'paperHeight': '8.5',
        'marginTop': '1',
        'marginBottom': '0',
        'marginLeft': '1',
        'marginRight': '0',
        'preferCssPageSize': 'true',
        'printBackground': 'true',
        'landscape': 'false',
        'scale': '1',
      };
      fields.forEach((k, v) => expect(field(body, k), v, reason: k));
      expect(body, contains('filename="index.html"'));
      expect(body, contains('<p>ਸਤਿ ਸ੍ਰੀ ਅਕਾਲ</p>'));
      expect(body, isNot(contains('filename="header.html"')));
    });

    test('sends the running header and footer as documents', () async {
      final engine = GotenbergPdfEngine(base.replace(path: '/gotenberg'));
      addTearDown(engine.close);
      await engine.htmlToPdf(
          '<p>x</p>',
          const HtmlToPdfOptions(
              displayHeaderFooter: true,
              headerTemplate: '<b>ਸਿਰਲੇਖ</b>',
              footerTemplate: '<i>F</i>'));
      final (_, path, body) = seen.single;
      expect(path, '/gotenberg/forms/chromium/convert/html');
      expect(field(body, 'preferCssPageSize'), 'false');
      expect(body, contains('<body style="margin:0"><b>ਸਿਰਲੇਖ</b></body>'));
      expect(body, contains('<body style="margin:0"><i>F</i></body>'));
    });

    test('gets the print CSS, once, beside the normal fields', () async {
      final engine = GotenbergPdfEngine(base);
      addTearDown(engine.close);
      const options = HtmlToPdfOptions(
          landscape: true,
          printBackground: false,
          margin: PdfMargin(top: '40mm'));
      await engine.htmlToPdf('<p>direct</p>', options);
      await htmlToPdf('<p>helper</p>', options: options, engine: engine);
      await engine.htmlToPdf('<p>plain</p>');
      for (final (i, text) in [(0, 'direct'), (1, 'helper')]) {
        final body = seen[i].$3;
        expect(
            body,
            contains(
                '<p>$text</p>\n<style>@page { margin-top: 40mm !important; '
                'size: 297mm 210mm !important; }\n'));
        expect('<style>'.allMatches(body), hasLength(1));
        expect(body, contains('print-color-adjust: economy !important'));
        expect(field(body, 'paperWidth'), startsWith('11.69'));
        expect(field(body, 'printBackground'), 'false');
        expect(field(body, 'marginTop'), startsWith('1.57'));
      }
      expect(seen[2].$3, contains('<p>plain</p>\r\n'));
      expect(seen[2].$3, isNot(contains('<style>')));
    });

    test('an error status throws with the message', () async {
      status = 503;
      answer = 'ਰੁੱਝਿਆ busy';
      final engine = GotenbergPdfEngine(base);
      addTearDown(engine.close);
      await expectLater(
          engine.htmlToPdf('<p>x</p>'),
          throwsA(isA<StateError>().having((e) => e.message, 'message',
              'Gotenberg returned 503: ਰੁੱਝਿਆ busy')));
    });

    test('an answer that is not a PDF throws', () async {
      answer = '<html>login</html>';
      final engine = GotenbergPdfEngine(base);
      addTearDown(engine.close);
      await expectLater(engine.htmlToPdf('<p>x</p>'), throwsStateError);
    });

    test('times out', () async {
      delay = const Duration(seconds: 3);
      final engine = GotenbergPdfEngine(base);
      addTearDown(engine.close);
      await expectLater(
          engine.htmlToPdf('<p>x</p>',
              const HtmlToPdfOptions(timeout: Duration(milliseconds: 40))),
          throwsA(isA<TimeoutException>()));
    });

    test('the deadline covers the download too', () async {
      delay = const Duration(seconds: 3);
      dribble = true;
      final engine = GotenbergPdfEngine(base);
      addTearDown(engine.close);
      await expectLater(
          engine.htmlToPdf('<p>x</p>',
              const HtmlToPdfOptions(timeout: Duration(milliseconds: 40))),
          throwsA(isA<TimeoutException>()));
    });

    test('can be cancelled', () async {
      delay = const Duration(seconds: 3);
      final engine = GotenbergPdfEngine(base);
      addTearDown(engine.close);
      final abort = Completer<void>();
      final pdf = engine.htmlToPdf(
          '<p>x</p>', HtmlToPdfOptions(abortTrigger: abort.future));
      Timer(const Duration(milliseconds: 100), abort.complete);
      await expectLater(pdf, throwsA(isA<PdfAbortedException>()));
    });

    test('cancelled before the call: nothing is sent', () async {
      final engine = GotenbergPdfEngine(base);
      addTearDown(engine.close);
      await expectLater(
          engine.htmlToPdf(
              '<p>x</p>', HtmlToPdfOptions(abortTrigger: Future.value())),
          throwsA(isA<PdfAbortedException>()));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(seen, isEmpty);
    });

    test('concurrent calls each get their answer', () async {
      final engine = GotenbergPdfEngine(base);
      addTearDown(engine.close);
      final all = await Future.wait(
          [for (var i = 0; i < 8; i++) engine.htmlToPdf('<p>call-$i</p>')]);
      expect(all, hasLength(8));
      for (var i = 0; i < 8; i++) {
        expect(
            seen.where((s) => s.$3.contains('<p>call-$i</p>')), hasLength(1));
      }
    });
  });

  group('ChromePdfEngine options', () {
    late _DevTools devTools;
    late ChromePdfEngine engine;
    setUp(() async {
      devTools = await _DevTools.start();
      engine = await devTools.connect();
    });
    tearDown(() async {
      await engine.close();
      await devTools.stop();
    });

    Object? loaded() => devTools.sent('Page.setDocumentContent')['html'];

    test('all defaults leave the HTML untouched', () async {
      const html = '<!doctype html><p>x</p>\n';
      await engine.htmlToPdf(html);
      expect(loaded(), html);
      await htmlToPdf(html, engine: engine);
      expect(loaded(), html);
    });

    test('print CSS, once, beside the normal print parameters', () async {
      const options = HtmlToPdfOptions(
        format: PaperFormat.a5,
        printBackground: false,
        displayHeaderFooter: true,
        footerTemplate: '<b>mine</b>',
        margin: PdfMargin(top: '25.4mm', left: '0'),
      );
      final want = '<p>x</p>\n<style>${printOptionsCss(options)}</style>';
      expect(want, contains('size: 148mm 210mm !important;'));
      expect(want, contains('@bottom-center { content: none !important; }'));
      await engine.htmlToPdf('<p>x</p>', options);
      expect(loaded(), want, reason: 'a direct engine call');
      await htmlToPdf('<p>x</p>', options: options, engine: engine);
      expect(loaded(), want, reason: 'through the helper');
      final print = devTools.sent('Page.printToPDF');
      expect(print['printBackground'], isFalse);
      expect(print['marginTop'], closeTo(1, 1e-9));
      expect(print['paperWidth'], closeTo(5.8268, 1e-3));
      expect(print['footerTemplate'], '<b>mine</b>');
    });

    test('timeout gives a long print more time', () async {
      devTools.printTakes = const Duration(milliseconds: 1500);
      await expectLater(
          engine.htmlToPdf('<p>long</p>',
              const HtmlToPdfOptions(timeout: Duration(milliseconds: 150))),
          throwsA(isA<TimeoutException>()));
      final pdf = await engine.htmlToPdf(
          '<p>long</p>', const HtmlToPdfOptions(timeout: Duration(seconds: 1)));
      expect(latin1.decode(pdf), '%PDF-test');
    });
  });

  group('ChromePdfEngine safety', () {
    late Directory box;
    setUp(() => box = Directory.systemTemp.createTempSync('lifeastro-test-'));
    tearDown(() => box.deleteSync(recursive: true));

    // A stand-in browser that records its switches, then runs [then].
    String fakeBrowser(String then) {
      final f = File('${box.path}/browser.sh')
        ..writeAsStringSync('#!/bin/sh\n'
            'printf "%s\\n" "\$@" > "${box.path}/args"\n'
            '$then\n');
      Process.runSync('chmod', ['+x', f.path]);
      return f.path;
    }

    List<String> switches() => File('${box.path}/args').readAsLinesSync();

    Directory profile() => Directory(switches()
        .singleWhere((a) => a.startsWith('--user-data-dir='))
        .substring('--user-data-dir='.length));

    test('a browser that cannot start says what to install', () async {
      await expectLater(
          ChromePdfEngine.launch(executablePath: '${box.path}/missing'),
          throwsA(isA<ProcessException>().having(
              (e) => e.message,
              'message',
              allOf(
                  contains('cannot start the browser'), contains('Install')))));
    });

    final posix = Platform.isWindows ? 'needs a POSIX shell' : null;

    test('a browser that exits: its log, and the profile is gone', () async {
      final exe = fakeBrowser('echo "no usable sandbox" >&2\nexit 21');
      await expectLater(
          ChromePdfEngine.launch(executablePath: exe),
          throwsA(isA<StateError>().having((e) => e.message, 'message',
              allOf(contains('code 21'), contains('no usable sandbox')))));
      expect(profile().existsSync(), isFalse);
    }, skip: posix);

    test('a launch timeout kills it and deletes the profile', () async {
      final exe = fakeBrowser('exec sleep 30');
      await expectLater(
          ChromePdfEngine.launch(
              executablePath: exe, timeout: const Duration(seconds: 2)),
          throwsA(isA<TimeoutException>()));
      expect(profile().existsSync(), isFalse);
    }, skip: posix);

    test('a launch can be cancelled', () async {
      final exe = fakeBrowser('exec sleep 30');
      final abort = Completer<void>();
      Timer(const Duration(seconds: 1), abort.complete);
      await expectLater(
          ChromePdfEngine.launch(
              executablePath: exe, abortTrigger: abort.future),
          throwsA(isA<PdfAbortedException>()));
      expect(profile().existsSync(), isFalse);
    }, skip: posix);

    test('the sandbox is only off as root or when asked', () async {
      final exe = fakeBrowser('exit 1');
      final uid = '${Process.runSync('id', ['-u']).stdout}'.trim();
      for (final (asked, off) in [
        (null, uid == '0'),
        (true, true),
        (false, false)
      ]) {
        await expectLater(
            ChromePdfEngine.launch(executablePath: exe, noSandbox: asked),
            throwsStateError);
        expect(switches().contains('--no-sandbox'), off,
            reason: 'noSandbox: $asked');
      }
    }, skip: posix);

    test('close() while printing: the print fails, with no stray error',
        () async {
      // A DevTools stand-in that answers the pending load only after close()
      // has begun, and does not read the close frame (a busy browser).
      final devTools = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => devTools.close(force: true));
      final loading = Completer<void>();
      devTools.listen((request) async {
        final ws = await WebSocketTransformer.upgrade(request);
        Object? load;
        late final StreamSubscription<Object?> calls;
        void answer(Object? id, Map<String, Object?> result) =>
            ws.add(jsonEncode({'id': id, 'result': result}));
        calls = ws.listen((raw) {
          final call = jsonDecode(raw as String) as Map;
          final id = call['id'];
          switch (call['method']) {
            case 'Target.createTarget':
              answer(id, {'targetId': 't'});
            case 'Target.attachToTarget':
              answer(id, {'sessionId': 's'});
            case 'Page.getFrameTree':
              answer(id, {
                'frameTree': {
                  'frame': {'id': 'f'},
                },
              });
            case 'Runtime.evaluate':
              load = id;
              loading.complete();
            case 'Browser.close':
              calls.pause();
              answer(id, {});
              Timer(const Duration(milliseconds: 100), () => answer(load, {}));
              Timer(const Duration(seconds: 1), calls.resume);
            default:
              answer(id, {});
          }
        });
      });
      final exe = fakeBrowser('echo "DevTools listening on '
          'ws://127.0.0.1:${devTools.port}/devtools/browser/x" >&2\n'
          'exec sleep 2');
      final engine = await ChromePdfEngine.launch(executablePath: exe);
      final printing = engine.htmlToPdf('<p>x</p>');
      final failed = expectLater(
          printing,
          throwsA(isA<StateError>().having(
              (e) => e.message, 'message', contains('lifeastroapi/pdf:'))));
      await loading.future;
      await engine.close();
      await failed;
      expect(profile().existsSync(), isFalse);
    }, skip: posix);

    test('no browser on the machine: the error says what to do', () async {
      final script = File('${box.path}/none.dart');
      // A child process with an empty PATH and no browser variables. Only
      // Linux finds browsers through PATH alone.
      script.writeAsStringSync("import 'package:lifeastroapi/pdf.dart';\n"
          'Future<void> main() async {\n'
          '  try { await htmlToPdf("<p>x</p>"); } on StateError catch (e) { print(e.message); }\n'
          '}\n');
      final out = await Process.run(
        Platform.resolvedExecutable,
        [
          '--packages=${Directory.current.path}/.dart_tool/package_config.json',
          script.path
        ],
        environment: {'PATH': box.path, 'HOME': box.path},
        includeParentEnvironment: false,
      );
      expect('${out.stdout}', contains('no Chrome, Chromium or Edge found'));
      expect('${out.stdout}', contains('apt install chromium'));
    },
        skip: !Platform.isLinux ||
                File('/usr/bin/chromium').existsSync() ||
                File('/snap/bin/chromium').existsSync()
            ? 'needs a Linux machine without a browser in the fixed paths'
            : null);
  });

  group('report helpers', () {
    test('client JSON goes straight into the PDF helper', () async {
      final data = _case('renderKundliLiteHtml', 'pa');
      final client = LifeAstro(
          apiKey: 'dv_test_key',
          httpClient: MockClient((_) async => http.Response(
              jsonEncode(data), 200,
              headers: {'content-type': 'application/json; charset=utf-8'})));
      final report = await client.reports.kundliLite(
          birth: const BirthInput(
              date: '1990-01-15',
              time: '10:30',
              tz: 'Asia/Kolkata',
              lat: 19.076,
              lon: 72.8777),
          lang: Lang.pa);
      final engine = _RecordingEngine();
      await kundliLitePdf(report, engine: engine);
      expect(engine.html.single, renderKundliLiteHtml(data));
      expect(engine.closed, isFalse, reason: 'your engine is not closed');
    });

    test('Brihad: two passes, real page numbers, bookmarks', () async {
      final data = _case('renderKundliBrihadHtml', 'pa');
      final probe = _RecordingEngine();
      await kundliBrihadPdf(data, engine: probe)
          .catchError((_) => Uint8List(0));
      final markers =
          RegExp(r'<a href="(https://toc\.lifeastroapi\.invalid/T\d+)"')
              .allMatches(probe.html.first)
              .map((m) => m[1]!)
              .toList();
      expect(markers, isNotEmpty);

      // Pass 1 puts marker i on page i + 2.
      final pass1 = buildPdf([
        const [],
        for (final m in markers) [m]
      ]);
      final pass2 =
          buildPdf([for (var i = 0; i <= markers.length; i++) const []]);
      final engine = _RecordingEngine([pass1, pass2]);
      final pdf = await kundliBrihadPdf(data,
          branding: const Branding(companyName: 'Acme & Co'), engine: engine);

      expect(engine.html, hasLength(2));
      expect(engine.html.first, contains('ਵਿਸ਼ਾ-ਸੂਚੀ'));
      expect(engine.html.last, isNot(contains('toc.lifeastroapi.invalid')));
      expect(engine.html.first, contains('⟦T0⟧'));
      expect(engine.html.last, isNot(contains('⟦T')));
      expect(
          '<span style="color:#fff;font-size:1px;">&nbsp;</span>'
              .allMatches(engine.html.last),
          hasLength(markers.length),
          reason: 'the same line boxes as in pass 1');
      expect(engine.html.last, contains('>${markers.length + 1}<'));
      final o = engine.options.last;
      expect(o.displayHeaderFooter, isTrue);
      expect(o.margin!.top, '26mm');
      expect(o.headerTemplate, contains('Acme &amp; Co'));
      expect(latin1.decode(pdf), contains('/Type /Outlines'));
    });

    test('Brihad: blank caller branding is the same as none', () async {
      final data = {
        'Branding': {
          'CompanyName': 'Json Co',
          'PrimaryColor': '#0b5cad',
          'FooterText': 'Json footer',
        },
      };
      Future<List<String?>> bands(Branding? branding) async {
        final engine = _RecordingEngine();
        await kundliBrihadPdf(data, branding: branding, engine: engine);
        final o = engine.options.last;
        return [o.headerTemplate, o.footerTemplate];
      }

      final none = await bands(null);
      expect(none.first, allOf(contains('Json Co'), contains('color:#0b5cad')));
      expect(none.last, contains('Json footer'));
      expect(
          await bands(const Branding(
              companyName: ' ',
              logoUrl: '\t',
              primaryColor: '  ',
              secondaryColor: '\n',
              footerText: ' ',
              watermarkText: ' ')),
          none);
      final brand = await bands(const Branding(primaryColor: '#0b6b36'));
      expect(brand.first, contains('color:#0b6b36'));
    });

    test('Brihad: caller header and footer templates win', () async {
      Future<HtmlToPdfOptions> printed(String header, String footer) async {
        final engine = _RecordingEngine();
        await kundliBrihadPdf(const {},
            options: HtmlToPdfOptions(
                headerTemplate: header, footerTemplate: footer),
            engine: engine);
        return engine.options.last;
      }

      final mine = await printed('<p>my header</p>', '<p>my footer</p>');
      expect(mine.headerTemplate, '<p>my header</p>');
      expect(mine.footerTemplate, '<p>my footer</p>');
      expect(mine.displayHeaderFooter, isTrue);
      final empty = await printed('', '');
      expect(empty.headerTemplate, brihadHeaderTemplate(null));
      expect(empty.footerTemplate, brihadFooterTemplate(null));
    });

    test('Brihad: header and footer are on unless the caller said false',
        () async {
      for (final (options, on) in [
        (const HtmlToPdfOptions(), true),
        (const HtmlToPdfOptions(displayHeaderFooter: true), true),
        (const HtmlToPdfOptions().copyWith(scale: 0.9), true),
        (const HtmlToPdfOptions(displayHeaderFooter: false), false),
        (
          const HtmlToPdfOptions(displayHeaderFooter: false)
              .copyWith(scale: 0.9),
          false
        ),
      ]) {
        final engine = _RecordingEngine();
        await kundliBrihadPdf(const {}, options: options, engine: engine);
        expect(engine.options.last.displayHeaderFooter, on);
        expect(engine.html.first.contains('content: none !important'), on);
      }
    });

    test('Brihad: margins merge side by side, and reach every print', () async {
      final engine = _RecordingEngine();
      await kundliBrihadPdf(_case('renderKundliBrihadHtml', 'hi'),
          options: const HtmlToPdfOptions(
              format: PaperFormat.a5,
              margin: PdfMargin(top: '40mm', bottom: ' ', left: '0')),
          engine: engine);
      final m = engine.options.last.margin!;
      expect([m.top, m.bottom, m.left, m.right], ['40mm', '16mm', '0', '0mm']);
      expect(engine.html, hasLength(2));
      for (final html in engine.html) {
        expect(html, contains('margin-top: 40mm !important;'));
        expect(html, contains('margin-left: 0px !important;'));
        expect(html, contains('size: 148mm 210mm !important;'));
        expect('<style>@page'.allMatches(html), hasLength(1));
      }
    });

    test('Brihad: two sections may start on one page', () async {
      final data = _case('renderKundliBrihadHtml', 'pa');
      final probe = _RecordingEngine();
      await kundliBrihadPdf(data, engine: probe);
      final markers =
          RegExp(r'<a href="(https://toc\.lifeastroapi\.invalid/T\d+)"')
              .allMatches(probe.html.first)
              .map((m) => m[1]!)
              .toList();
      // The cover and the contents, then every four markers share a page.
      final pages = <List<String>>[[], []];
      for (var i = 0; i < markers.length; i += 4) {
        pages.add(markers.sublist(
            i, i + 4 < markers.length ? i + 4 : markers.length));
      }
      final engine = _RecordingEngine([
        buildPdf(pages),
        buildPdf([for (final _ in pages) const <String>[]]),
      ]);
      final pdf = await kundliBrihadPdf(data, engine: engine);

      final printed = RegExp(r'<span class="toc-page"[^>]*>(\d+)</span>')
          .allMatches(engine.html.last)
          .map((m) => int.parse(m[1]!));
      expect(printed, [for (var i = 0; i < markers.length; i++) i ~/ 4 + 3]);
      final destinations =
          RegExp(r'/Dest \[(\d+) 0 R').allMatches(latin1.decode(pdf));
      expect(destinations, hasLength(markers.length));
      expect(destinations.map((m) => m[1]).toSet(), hasLength(pages.length - 2),
          reason: 'bookmarks of one page share their destination');
    });

    test('a custom engine gets the print CSS, and defaults nothing', () async {
      final engine = _RecordingEngine();
      await kundliLitePdf(const {}, engine: engine);
      expect(engine.html.single, renderKundliLiteHtml(const {}));
      await kundliLitePdf(const {},
          options: const HtmlToPdfOptions(margin: PdfMargin(top: '40mm')),
          engine: engine);
      expect(
          engine.html.last,
          '${renderKundliLiteHtml(const {})}\n<style>@page '
          '{ margin-top: 40mm !important; }\n</style>');
    });

    test('Brihad: caller branding goes over the report field by field',
        () async {
      final data = {
        'Branding': {
          'CompanyName': 'Report Co',
          'FooterText': 'report.example',
        },
      };
      Future<HtmlToPdfOptions> printed(Branding? branding) async {
        final engine = _RecordingEngine();
        await kundliBrihadPdf(data, branding: branding, engine: engine);
        return engine.options.last;
      }

      final name = await printed(const Branding(companyName: 'Acme Astro'));
      expect(name.headerTemplate, contains('Acme Astro'));
      expect(name.footerTemplate, contains('report.example'));
      final footer = await printed(
          const Branding(companyName: '', footerText: 'acme.example'));
      expect(footer.headerTemplate, contains('Report Co'));
      expect(footer.footerTemplate, contains('acme.example'));
      final none = await printed(null);
      expect(none.headerTemplate, contains('Report Co'));
    });

    test('Brihad: a Locale that is an Object property gets English contents',
        () async {
      final data = {
        ..._case('renderKundliBrihadHtml', 'en'),
        'Locale': 'toString',
      };
      final engine = _RecordingEngine();
      await kundliBrihadPdf(data, engine: engine);
      expect(engine.html.first,
          contains('<div class="toc-banner">Table of Contents</div>'));
      expect(engine.html.first, contains('<html lang="en">'));
      expect(data['Locale'], 'toString', reason: 'the input is not changed');
    });

    test('Brihad: the running header and footer use the print font stack',
        () async {
      final engine = _RecordingEngine();
      await kundliBrihadPdf(const {}, engine: engine);
      final o = engine.options.last;
      for (final template in [o.headerTemplate, o.footerTemplate]) {
        expect(
            template,
            contains('Helvetica Neue, Helvetica, Arial, Liberation Sans, '
                'sans-serif'));
      }
    });

    test('Brihad without page numbers prints without a contents page',
        () async {
      final data = _case('renderKundliBrihadHtml', 'pa');
      final engine = _RecordingEngine([
        buildPdf([const []])
      ]);
      await kundliBrihadPdf(data, engine: engine);
      expect(engine.html, hasLength(2));
      expect(
          engine.html.last,
          withPrintOptionsCss(
              renderKundliBrihadHtml(data), engine.options.last));
    });
  });
}
