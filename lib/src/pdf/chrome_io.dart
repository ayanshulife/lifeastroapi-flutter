/// Chrome / Chromium / Edge over the DevTools protocol (`dart:io` only).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'engine.dart';

/// Prints HTML to PDF with a local or remote Chrome, Chromium or Edge, the
/// way Puppeteer does (DevTools protocol, `Page.printToPDF`). No Dart
/// package and no Node are needed, only the browser.
///
/// Launching a browser takes a moment; on a server, launch one engine and
/// reuse it for every PDF, then [close] it on shutdown.
///
/// ```dart
/// final engine = await ChromePdfEngine.launch();
/// final pdf = await kundliLitePdf(report, engine: engine);
/// await engine.close();
/// ```
class ChromePdfEngine implements PdfEngine {
  ChromePdfEngine._(this._ws, this._process, this._userDataDir) {
    _ws.listen(_onMessage, onDone: _onDone, onError: (_) => _onDone());
  }

  final WebSocket _ws;
  final Process? _process;
  final Directory? _userDataDir;
  final _pending = <int, Completer<Map<String, Object?>>>{};
  var _nextId = 0;
  var _closed = false;

  /// Launches a headless browser.
  ///
  /// [executablePath] defaults to `LIFEASTRO_CHROME`, `CHROME_PATH` or
  /// `PUPPETEER_EXECUTABLE_PATH` from the environment, then the usual install
  /// locations of Chrome, Chromium and Edge. Pass [noSandbox] when running as
  /// root in a container. [args] are extra command-line switches.
  static Future<ChromePdfEngine> launch({
    String? executablePath,
    bool noSandbox = false,
    List<String> args = const [],
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final exe = executablePath ?? findChromeExecutable();
    if (exe == null) {
      throw StateError(
          'lifeastroapi/pdf: no Chrome, Chromium or Edge found. Install one, '
          'or pass executablePath: (or set CHROME_PATH). On Debian/Ubuntu: '
          'apt install chromium fonts-noto-core');
    }
    final dir = await Directory.systemTemp.createTemp('lifeastro-chrome-');
    final process = await Process.start(exe, [
      '--headless=new',
      '--remote-debugging-port=0',
      '--user-data-dir=${dir.path}',
      '--no-first-run',
      '--no-default-browser-check',
      '--disable-background-networking',
      '--disable-extensions',
      '--disable-sync',
      '--disable-dev-shm-usage',
      '--hide-scrollbars',
      '--mute-audio',
      if (noSandbox) '--no-sandbox',
      ...args,
      'about:blank',
    ]);
    final url = Completer<String>();
    final log = StringBuffer();
    process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      if (log.length < 4000) log.writeln(line);
      final m = RegExp(r'DevTools listening on (ws://\S+)').firstMatch(line);
      if (m != null && !url.isCompleted) url.complete(m[1]);
    });
    unawaited(process.stdout.drain<void>());
    unawaited(process.exitCode.then((code) {
      if (!url.isCompleted) {
        url.completeError(StateError('Chrome exited with code $code: $log'));
      }
    }));
    try {
      final ws = await WebSocket.connect(await url.future.timeout(timeout));
      return ChromePdfEngine._(ws, process, dir);
    } catch (_) {
      process.kill();
      await _deleteDir(dir);
      rethrow;
    }
  }

  /// Connects to a browser that is already running with remote debugging,
  /// for example a Chrome container. [webSocketDebuggerUrl] is the browser's
  /// `ws://.../devtools/browser/...` URL (from `http://host:9222/json/version`).
  static Future<ChromePdfEngine> connect(String webSocketDebuggerUrl) async {
    final ws = await WebSocket.connect(webSocketDebuggerUrl);
    return ChromePdfEngine._(ws, null, null);
  }

  /// The first Chrome, Chromium or Edge found on this machine, or `null`.
  static String? findChromeExecutable() {
    final env = Platform.environment;
    for (final k in [
      'LIFEASTRO_CHROME',
      'CHROME_PATH',
      'PUPPETEER_EXECUTABLE_PATH'
    ]) {
      final v = env[k];
      if (v != null && v.isNotEmpty && File(v).existsSync()) return v;
    }
    final candidates = <String>[];
    if (Platform.isMacOS) {
      for (final root in ['/Applications', '${env['HOME']}/Applications']) {
        candidates.addAll([
          '$root/Google Chrome.app/Contents/MacOS/Google Chrome',
          '$root/Chromium.app/Contents/MacOS/Chromium',
          '$root/Microsoft Edge.app/Contents/MacOS/Microsoft Edge',
          '$root/Brave Browser.app/Contents/MacOS/Brave Browser',
        ]);
      }
    } else if (Platform.isWindows) {
      for (final root in [
        env['PROGRAMFILES'],
        env['PROGRAMFILES(X86)'],
        env['LOCALAPPDATA'],
      ]) {
        if (root == null) continue;
        candidates.addAll([
          '$root\\Google\\Chrome\\Application\\chrome.exe',
          '$root\\Chromium\\Application\\chrome.exe',
          '$root\\Microsoft\\Edge\\Application\\msedge.exe',
        ]);
      }
    } else {
      final names = [
        'google-chrome-stable',
        'google-chrome',
        'chromium',
        'chromium-browser',
        'microsoft-edge',
        'microsoft-edge-stable',
      ];
      for (final dir in (env['PATH'] ?? '').split(':')) {
        if (dir.isEmpty) continue;
        for (final n in names) {
          candidates.add('$dir/$n');
        }
      }
      candidates.addAll(['/usr/bin/chromium', '/snap/bin/chromium']);
    }
    for (final c in candidates) {
      if (File(c).existsSync()) return c;
    }
    return null;
  }

  void _onMessage(Object? raw) {
    if (raw is! String) return;
    final msg = jsonDecode(raw);
    if (msg is! Map) return;
    final id = msg['id'];
    if (id is! int) return; // an event
    final c = _pending.remove(id);
    if (c == null) return;
    final error = msg['error'];
    if (error is Map) {
      c.completeError(StateError('DevTools: ${error['message']}'));
    } else {
      c.complete((msg['result'] as Map?)?.cast<String, Object?>() ?? {});
    }
  }

  void _onDone() {
    _closed = true;
    for (final c in _pending.values) {
      c.completeError(StateError('DevTools connection closed'));
    }
    _pending.clear();
  }

  Future<Map<String, Object?>> _send(String method,
      [Map<String, Object?> params = const {}, String? sessionId]) {
    if (_closed) {
      return Future.error(StateError('ChromePdfEngine is closed'));
    }
    final id = ++_nextId;
    final c = Completer<Map<String, Object?>>();
    _pending[id] = c;
    _ws.add(jsonEncode({
      'id': id,
      'method': method,
      'params': params,
      if (sessionId != null) 'sessionId': sessionId,
    }));
    return c.future;
  }

  // Waits for the document, its images and its web fonts.
  static const _waitForLoad = '''
(async () => {
  if (document.readyState !== 'complete') {
    await new Promise((r) => window.addEventListener('load', r, { once: true }));
  }
  await Promise.all(Array.from(document.images).map((img) => img.complete ? null :
    new Promise((r) => { img.addEventListener('load', r, { once: true });
                         img.addEventListener('error', r, { once: true }); })));
  if (document.fonts && document.fonts.ready) await document.fonts.ready;
  return true;
})()''';

  /// Opens [html] in a new tab, runs [body] with the tab's session id, and
  /// closes the tab.
  Future<T> _withPage<T>(String html, Duration timeout,
      Future<T> Function(String sessionId) body) async {
    final target = await _send('Target.createTarget', {'url': 'about:blank'});
    final targetId = target['targetId'] as String;
    try {
      final attach = await _send(
          'Target.attachToTarget', {'targetId': targetId, 'flatten': true});
      final sid = attach['sessionId'] as String;
      await _send('Page.enable', const {}, sid);
      final tree = await _send('Page.getFrameTree', const {}, sid);
      final frameId = ((tree['frameTree'] as Map)['frame'] as Map)['id'];
      await _send(
          'Page.setDocumentContent', {'frameId': frameId, 'html': html}, sid);
      await _send(
              'Runtime.evaluate',
              {
                'expression': _waitForLoad,
                'awaitPromise': true,
                'returnByValue': true,
              },
              sid)
          .timeout(timeout);
      return await body(sid);
    } finally {
      if (!_closed) {
        await _send('Target.closeTarget', {'targetId': targetId})
            .catchError((_) => <String, Object?>{});
      }
    }
  }

  @override
  Future<Uint8List> htmlToPdf(String html,
      [HtmlToPdfOptions options = const HtmlToPdfOptions()]) {
    final (w, h) = options.paperInches;
    final m = options.margin;
    final params = <String, Object?>{
      'landscape': false, // orientation is already in paperWidth/Height
      'printBackground': options.printBackground,
      'preferCSSPageSize': options.effectivePreferCssPageSize,
      'paperWidth': w,
      'paperHeight': h,
      'marginTop': cssLengthToInches(m?.top),
      'marginBottom': cssLengthToInches(m?.bottom),
      'marginLeft': cssLengthToInches(m?.left),
      'marginRight': cssLengthToInches(m?.right),
      'scale': options.scale ?? 1,
      'displayHeaderFooter': options.displayHeaderFooter,
      if (options.displayHeaderFooter) ...{
        'headerTemplate': options.headerTemplate ?? '<span></span>',
        'footerTemplate': options.footerTemplate ?? '<span></span>',
      },
    };
    return _withPage(html, options.timeout, (sid) async {
      final res = await _send('Page.printToPDF', params, sid)
          .timeout(options.timeout * 4);
      return base64Decode(res['data'] as String);
    });
  }

  /// Runs [expression] (it may return a promise) in a page showing [html] and
  /// returns its JSON value.
  Future<Object?> evaluate(String html, String expression,
      {Duration timeout = const Duration(seconds: 30)}) {
    return _withPage(html, timeout, (sid) async {
      final res = await _send(
              'Runtime.evaluate',
              {
                'expression': expression,
                'awaitPromise': true,
                'returnByValue': true,
              },
              sid)
          .timeout(timeout);
      return (res['result'] as Map?)?['value'];
    });
  }

  @override
  Future<void> close() async {
    if (_process != null) {
      if (!_closed) {
        await _send('Browser.close')
            .timeout(const Duration(seconds: 5))
            .catchError((_) => <String, Object?>{});
      }
      await _process.exitCode.timeout(const Duration(seconds: 5),
          onTimeout: () {
        _process.kill(ProcessSignal.sigkill);
        return -1;
      });
    }
    _closed = true;
    await _ws.close().catchError((_) {});
    final dir = _userDataDir;
    if (dir != null) await _deleteDir(dir);
  }
}

Future<void> _deleteDir(Directory dir) async {
  for (var i = 0; i < 5; i++) {
    try {
      if (dir.existsSync()) await dir.delete(recursive: true);
      return;
    } catch (_) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  }
}

/// The engine `htmlToPdf` uses when none is passed: a launched Chrome.
Future<PdfEngine> launchDefaultEngine() => ChromePdfEngine.launch();
