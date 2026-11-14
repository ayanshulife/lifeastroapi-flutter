// Live API sweep: calls EVERY SDK method once against a real API and lists
// each one the API rejects. This checks that the manifest's paths and
// parameter names match what the server accepts; unit tests with a mock HTTP
// client cannot see that. Port of the Node SDK's scripts/live-sweep.mjs.
//
//   LIFEASTRO_API_KEY=dv_live_... dart run tool/live_sweep.dart
//
// Environment:
//   LIFEASTRO_API_URL    base URL (default: production). Point it at a local
//                        server to sweep without spending production credits.
//   LIFEASTRO_LIVE_SKIP  comma-separated path prefixes to leave out. Default
//                        "/v1/reports/" (composed reports cost 500-8000
//                        credits each). Set it to "" to include them.
//   LIFEASTRO_LIVE_ONLY  comma-separated substrings; only matching paths run.
//   LIFEASTRO_LIVE_LANG  a language code (gu, bn, ...) sent to every method
//                        that takes `lang`.
//   LIFEASTRO_LIVE_DUMP  directory to write each response into as JSON.
//   LIFEASTRO_LIVE_DELAY_MS  pause between calls (default 450, to stay under
//                        the per-minute rate limit).
//
// Spends credits: one request per endpoint.
import 'dart:convert';
import 'dart:io';

import 'package:lifeastroapi/lifeastroapi.dart';

import 'src/dispatch.g.dart';
import 'src/samples.dart';

Future<void> main() async {
  final env = Platform.environment;
  final apiKey = env['LIFEASTRO_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    stderr.writeln('LIFEASTRO_API_KEY is required.');
    exit(2);
  }
  List<String> list(String? v) =>
      (v ?? '').split(',').where((s) => s.isNotEmpty).toList();
  final skip = list(env['LIFEASTRO_LIVE_SKIP'] ?? '/v1/reports/');
  final only = list(env['LIFEASTRO_LIVE_ONLY']);
  final lang = env['LIFEASTRO_LIVE_LANG'];
  final dumpDir = env['LIFEASTRO_LIVE_DUMP'];
  final delay = Duration(
      milliseconds: int.tryParse(env['LIFEASTRO_LIVE_DELAY_MS'] ?? '') ?? 450);
  if (dumpDir != null) Directory(dumpDir).createSync(recursive: true);

  final client = LifeAstro(
    apiKey: apiKey,
    baseUrl: env['LIFEASTRO_API_URL'],
    timeout: const Duration(seconds: 90),
    maxRetries: 0, // a retried failure is still a failure worth seeing
  );

  final failures = <String>[];
  var ran = 0;
  for (final e in loadManifest()) {
    if (skip.any(e.path.startsWith)) continue;
    if (only.isNotEmpty && !only.any(e.path.contains)) continue;
    final call = invokers[e.key];
    if (call == null) {
      failures.add(
          'FAIL ${e.key}  (${e.path})\n     no method in the dispatch table '
          '(run `node tool/generate.mjs`)');
      continue;
    }
    final built = buildInput(e);
    if (built.missing.isNotEmpty) {
      failures.add('FAIL ${e.key}  (${e.path})\n     no sample value for '
          '${built.missing.join(', ')}');
      continue;
    }
    final input = built.input;
    if (lang != null && e.hasParam('lang')) input['lang'] = lang;
    ran++;
    try {
      final data = await call(client, input);
      if (dumpDir != null) {
        File('$dumpDir/${e.key}.json').writeAsStringSync(
            const JsonEncoder.withIndent('  ').convert(data));
      }
      stdout.writeln('ok   ${e.key}');
    } on LifeAstroException catch (err) {
      failures.add('FAIL ${e.key}  (${e.path})\n     ${err.status} ${err.code} '
          '${err.message}\n     input=${_show(input)}');
    } catch (err) {
      failures.add('FAIL ${e.key}  (${e.path})\n     $err');
    }
    await Future<void>.delayed(delay);
  }
  client.close();

  failures.forEach(stdout.writeln);
  stdout.writeln(
      '\nlive sweep: $ran endpoints called, ${failures.length} failed');
  exit(failures.isEmpty ? 0 : 1);
}

String _show(Map<String, Object?> input) => jsonEncode(input, toEncodable: (v) {
      if (v is NatalWindowBirth) {
        return {
          'date': v.date,
          'time': v.time,
          'tz': v.tz,
          'lat': v.lat,
          'lon': v.lon
        };
      }
      return v.toString();
    });
