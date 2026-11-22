/// Chrome / Chromium / Edge over the DevTools protocol (`dart:io` only).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'engine.dart';
import 'guard.dart';
import 'print_css.dart';

/// Prints HTML to PDF with a local or remote Chrome, Chromium or Edge, the
/// way Puppeteer does (DevTools protocol, `Page.printToPDF`). No Dart
/// package and no Node are needed, only the browser. Nothing is sent to
/// LifeAstroAPI.
///
/// Launching a browser takes a moment; on a server, launch one engine, use
/// it for every PDF (concurrent calls each get their own tab), then [close]
/// it on shutdown. Each launched engine has a profile of its own in the temp
/// directory, which [close] deletes.
///
/// ```dart
/// final engine = await ChromePdfEngine.launch();
/// try {
///   final pdf = await kundliLitePdf(report, engine: engine);
/// } finally {
///   await engine.close();
/// }
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
  var _disconnected = false;
  Future<void>? _closing;

  /// Launches a headless browser.
  ///
  /// [executablePath] defaults to `LIFEASTRO_CHROME`, `CHROME_PATH` or
  /// `PUPPETEER_EXECUTABLE_PATH` from the environment, then the usual install
  /// locations of Chrome, Chromium and Edge. [noSandbox] defaults to true
  /// only when running as root (typically in a container), where Chromium
  /// cannot start with its sandbox; pass true or false to decide yourself.
  /// [args] are extra command-line switches. [abortTrigger] cancels the
  /// launch when it completes.
  static Future<ChromePdfEngine> launch({
    String? executablePath,
    bool? noSandbox,
    List<String> args = const [],
    Duration timeout = const Duration(seconds: 30),
    Future<void>? abortTrigger,
  }) async {
    if (Platform.isAndroid || Platform.isIOS) {
      throw UnsupportedError(
          'lifeastroapi/pdf: ChromePdfEngine cannot start a browser on Android '
          'or iOS. Use GotenbergPdfEngine, or print the render*Html() output '
          'with the `printing` package (see the README).');
    }
    final exe = executablePath ?? findChromeExecutable();
    if (exe == null) throw StateError(_noBrowserMessage());
    final sandboxOff = noSandbox ?? await _runsAsRoot();
    final clock = Stopwatch()..start();
    final dir = await Directory.systemTemp.createTemp('lifeastro-chrome-');
    final Process process;
    try {
      process = await Process.start(exe, [
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
        if (sandboxOff) '--no-sandbox',
        ...args,
        'about:blank',
      ]);
    } on ProcessException catch (e) {
      await _deleteDir(dir);
      // The type callers of 0.2.0 catch, with what to do in the message.
      throw ProcessException(
          exe,
          const [],
          'lifeastroapi/pdf: cannot start the browser "$exe" '
          '(${e.message}). ${_installHint()}',
          e.errorCode);
    } catch (_) {
      await _deleteDir(dir);
      rethrow;
    }

    final url = Completer<String>();
    final log = StringBuffer();
    final stderrDone = process.stderr
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter())
        .forEach((line) {
      if (log.length < 4000) log.writeln(line);
      final m = RegExp(r'DevTools listening on (ws://\S+)').firstMatch(line);
      if (m != null && !url.isCompleted) url.complete(m[1]);
    }).catchError((Object _) {});
    unawaited(process.stdout.drain<void>().catchError((Object _) {}));
    unawaited(process.exitCode.then((code) async {
      // Let the last lines of the log arrive first.
      await stderrDone.timeout(const Duration(seconds: 1), onTimeout: () {});
      if (url.isCompleted) return;
      url.completeError(
          StateError('lifeastroapi/pdf: the browser exited with code $code '
              'before it was ready. ${_installHint()}\n$log'));
    }));
    // The exit can come after a timeout has stopped anyone waiting for it.
    unawaited(url.future.then<void>((_) {}, onError: (Object _) {}));

    try {
      final endpoint = await guard(url.future,
          timeout: timeout,
          what: 'starting the browser',
          abortTrigger: abortTrigger);
      final ws = await _connectSocket(endpoint,
          timeout: timeout - clock.elapsed, abortTrigger: abortTrigger);
      return ChromePdfEngine._(ws, process, dir);
    } catch (_) {
      process.kill(ProcessSignal.sigkill);
      await process.exitCode.timeout(_shutdownGrace, onTimeout: () => -1);
      await _deleteDir(dir);
      rethrow;
    }
  }

  /// Connects to a browser that is already running with remote debugging,
  /// for example a Chrome container. [webSocketDebuggerUrl] is the browser's
  /// `ws://.../devtools/browser/...` URL (from `http://host:9222/json/version`).
  /// [close] disconnects and leaves that browser running.
  static Future<ChromePdfEngine> connect(String webSocketDebuggerUrl,
      {Duration timeout = const Duration(seconds: 10)}) async {
    final ws = await _connectSocket(webSocketDebuggerUrl, timeout: timeout);
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
    if (c == null) return; // the answer to a call that was given up
    final error = msg['error'];
    if (error is Map) {
      c.completeError(StateError('DevTools: ${error['message']}'));
    } else {
      c.complete((msg['result'] as Map?)?.cast<String, Object?>() ?? {});
    }
  }

  void _onDone() {
    _disconnected = true;
    for (final c in _pending.values) {
      c.completeError(StateError('lifeastroapi/pdf: the connection to the '
          'browser closed (it was closed, crashed, or ran out of memory)'));
    }
    _pending.clear();
  }

  Future<Map<String, Object?>> _send(
    String method,
    Map<String, Object?> params,
    Duration timeout, {
    String? sessionId,
    Future<void>? abortTrigger,
  }) {
    if (_disconnected) {
      return Future.error(StateError(
          'lifeastroapi/pdf: ChromePdfEngine is closed or lost its browser'));
    }
    final id = ++_nextId;
    final c = Completer<Map<String, Object?>>();
    final message = jsonEncode({
      'id': id,
      'method': method,
      'params': params,
      if (sessionId != null) 'sessionId': sessionId,
    });
    try {
      _ws.add(message);
    } on StateError {
      // The socket is closing. The call must not wait in _pending: nothing
      // would listen to the error that _onDone gives it.
      return Future.error(StateError(
          'lifeastroapi/pdf: ChromePdfEngine is closed or lost its browser'));
    }
    _pending[id] = c;
    return guard(c.future,
        timeout: timeout,
        what: method,
        abortTrigger: abortTrigger,
        onCancel: () => _pending.remove(id));
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
  Future<T> _withPage<T>(
    String html,
    Duration timeout,
    Future<void>? abortTrigger,
    Future<T> Function(String sessionId) body,
  ) async {
    if (_closing != null) {
      throw StateError('lifeastroapi/pdf: ChromePdfEngine is closed');
    }
    // Not cancellable: the id of the new tab is needed to close it again.
    final target =
        await _send('Target.createTarget', {'url': 'about:blank'}, timeout);
    final targetId = target['targetId'] as String;
    try {
      final attach = await _send('Target.attachToTarget',
          {'targetId': targetId, 'flatten': true}, timeout,
          abortTrigger: abortTrigger);
      final sid = attach['sessionId'] as String;
      Future<Map<String, Object?>> call(
              String method, Map<String, Object?> params) =>
          _send(method, params, timeout,
              sessionId: sid, abortTrigger: abortTrigger);
      await call('Page.enable', const {});
      final tree = await call('Page.getFrameTree', const {});
      final frameId = ((tree['frameTree'] as Map)['frame'] as Map)['id'];
      await call('Page.setDocumentContent', {'frameId': frameId, 'html': html});
      await call('Runtime.evaluate', {
        'expression': _waitForLoad,
        'awaitPromise': true,
        'returnByValue': true,
      });
      return await body(sid);
    } finally {
      if (!_disconnected) {
        await _send('Target.closeTarget', {'targetId': targetId},
                const Duration(seconds: 10))
            .catchError((Object _) => <String, Object?>{});
      }
    }
  }

  @override
  Future<Uint8List> htmlToPdf(String html,
      [HtmlToPdfOptions options = const HtmlToPdfOptions()]) async {
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
    final page = withPrintOptionsCss(html, options);
    return _withPage(page, options.timeout, options.abortTrigger, (sid) async {
      final res = await _send('Page.printToPDF', params, options.timeout * 4,
          sessionId: sid, abortTrigger: options.abortTrigger);
      return base64Decode(res['data'] as String);
    });
  }

  /// Runs [expression] (it may return a promise) in a page showing [html] and
  /// returns its JSON value.
  Future<Object?> evaluate(String html, String expression,
      {Duration timeout = const Duration(seconds: 30)}) {
    return _withPage(html, timeout, null, (sid) async {
      final res = await _send(
          'Runtime.evaluate',
          {
            'expression': expression,
            'awaitPromise': true,
            'returnByValue': true,
          },
          timeout,
          sessionId: sid);
      return (res['result'] as Map?)?['value'];
    });
  }

  /// Closes the browser the engine launched and deletes its profile. Safe to
  /// call more than once; PDFs still printing fail.
  @override
  Future<void> close() => _closing ??= _shutDown();

  Future<void> _shutDown() async {
    final process = _process;
    if (process != null && !_disconnected) {
      await _send('Browser.close', const {}, _shutdownGrace)
          .catchError((Object _) => <String, Object?>{});
    }
    unawaited(_ws.close().catchError((Object _) {}));
    // From here nothing can be sent: fail what is waiting now, not after the
    // browser has exited.
    _onDone();
    if (process != null) {
      await process.exitCode.timeout(_shutdownGrace, onTimeout: () async {
        process.kill(ProcessSignal.sigkill);
        return process.exitCode.timeout(_shutdownGrace, onTimeout: () => -1);
      });
    }
    final dir = _userDataDir;
    if (dir != null) await _deleteDir(dir);
  }
}

const _shutdownGrace = Duration(seconds: 5);

String _installHint() {
  if (Platform.isMacOS) {
    return 'Install Google Chrome (https://www.google.com/chrome/), Chromium '
        'or Microsoft Edge.';
  }
  if (Platform.isWindows) {
    return 'Install Google Chrome (https://www.google.com/chrome/) or '
        'Microsoft Edge.';
  }
  return 'Install Chromium, Google Chrome or Microsoft Edge and the Noto '
      'fonts (Debian/Ubuntu: apt install chromium fonts-noto-core '
      'fonts-noto-extra).';
}

String _noBrowserMessage() =>
    'lifeastroapi/pdf: no Chrome, Chromium or Edge found. ${_installHint()} '
    'If it is installed elsewhere, pass executablePath: or set '
    'LIFEASTRO_CHROME or CHROME_PATH. Without a browser on this machine, use '
    'GotenbergPdfEngine.';

/// Whether the effective user is root: only then is the sandbox switched off
/// unasked.
Future<bool> _runsAsRoot() async {
  if (Platform.isWindows) return false;
  try {
    if (Platform.isLinux) {
      for (final line in await File('/proc/self/status').readAsLines()) {
        // Uid: real, effective, saved, file system.
        if (!line.startsWith('Uid:')) continue;
        return line.substring(4).trim().split(RegExp(r'\s+'))[1] == '0';
      }
    }
    final id = await Process.run('/usr/bin/id', ['-u'])
        .timeout(const Duration(seconds: 5));
    return id.exitCode == 0 && '${id.stdout}'.trim() == '0';
  } catch (_) {
    return false; // unknown: keep the sandbox
  }
}

Future<WebSocket> _connectSocket(String url,
    {required Duration timeout, Future<void>? abortTrigger}) async {
  final host = Uri.parse(url).host;
  final client = HttpClient();
  // A proxy of the environment must not get in between us and a local browser.
  if (const ['127.0.0.1', 'localhost', '::1'].contains(host)) {
    client.findProxy = (_) => 'DIRECT';
  }
  final connecting = WebSocket.connect(url, customClient: client);
  try {
    return await guard(
      connecting,
      timeout: timeout,
      what: 'connecting to the browser',
      abortTrigger: abortTrigger,
      onCancel: () {
        unawaited(connecting.then<void>((ws) async {
          await ws.close();
        }, onError: (Object _) {}));
      },
    );
  } finally {
    client.close(); // the socket is detached from it
  }
}

Future<void> _deleteDir(Directory dir) async {
  // Browser helper processes can write for a moment after the browser exits.
  for (var i = 0; i < 25; i++) {
    try {
      if (await dir.exists()) await dir.delete(recursive: true);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      if (!await dir.exists()) return;
    } on FileSystemException {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  }
}

/// The engine `htmlToPdf` uses when none is passed: a launched Chrome.
Future<PdfEngine> launchDefaultEngine({Future<void>? abortTrigger}) =>
    ChromePdfEngine.launch(abortTrigger: abortTrigger);
