// Unit tests with a mock HTTP client. Same cases as the Node SDK's
// test/client.test.ts.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lifeastroapi/lifeastroapi.dart';
import 'package:lifeastroapi/src/client.dart' show environmentApiKey;
import 'package:lifeastroapi/src/params.dart' show todayIn;
import 'package:test/test.dart';

typedef Reply = ({int status, Object? body, Map<String, String> headers});

Reply reply(Object? body, {int status = 200, Map<String, String>? headers}) =>
    (status: status, body: body, headers: headers ?? const {});

/// A client whose HTTP calls are recorded and answered by [responder].
({LifeAstro client, List<http.Request> calls}) mock(
  Reply Function(Uri url) responder, {
  int maxRetries = 0,
  Map<String, String> defaultHeaders = const {},
}) {
  final calls = <http.Request>[];
  final inner = MockClient((req) async {
    calls.add(req);
    final r = responder(req.url);
    final body = r.body is String ? r.body as String : jsonEncode(r.body ?? {});
    return http.Response.bytes(utf8.encode(body), r.status,
        headers: {'content-type': 'application/json', ...r.headers});
  });
  final client = LifeAstro(
    apiKey: 'dv_live_test',
    httpClient: inner,
    maxRetries: maxRetries,
    defaultHeaders: defaultHeaders,
  );
  return (client: client, calls: calls);
}

LifeAstro clientWith(http.Client inner, {int maxRetries = 0}) => LifeAstro(
    apiKey: 'dv_live_test', httpClient: inner, maxRetries: maxRetries);

const birth = BirthInput(
    date: '1990-01-15',
    time: '10:30',
    tz: 'Asia/Kolkata',
    lat: 19.076,
    lon: 72.8777);
const girl = BirthInput(
    date: '1992-03-20',
    time: '08:15',
    tz: 'Asia/Kolkata',
    lat: 28.6139,
    lon: 77.209);

Future<Object> caught(Future<Object?> f) async {
  try {
    await f;
  } catch (e) {
    return e;
  }
  fail('expected an exception');
}

void main() {
  group('transport', () {
    test('builds an authenticated GET and unwraps `data`', () async {
      final m = mock((_) => reply({
            'data': {'number': 3},
            'meta': {'cache': 'miss'}
          }));
      final res = await m.client.panchang
          .tithi(lat: 28.61, lon: 77.2, tz: 'Asia/Kolkata');
      expect(res, {'number': 3});
      final call = m.calls.single;
      expect(call.method, 'GET');
      expect(call.url.path, '/v1/panchang/tithi');
      expect(call.url.queryParameters['lat'], '28.61');
      expect(call.url.queryParameters['tz'], 'Asia/Kolkata');
      expect(call.headers['Authorization'], 'Bearer dv_live_test');
      expect(call.headers['Accept'], 'application/json');
    });

    test('returns the full envelope with raw: true', () async {
      final m = mock((_) => reply({
            'data': {'x': 1},
            'meta': {'tier': 'standard'}
          }));
      final res = await m.client.request('/v1/panchang/tithi',
          query: {'lat': 1, 'lon': 2, 'tz': 'UTC'},
          options: const RequestOptions(raw: true));
      expect(res, {
        'data': {'x': 1},
        'meta': {'tier': 'standard'}
      });
    });

    test('omits empty params and sorts the query string', () async {
      final m = mock((_) => reply({}));
      await m.client.panchang
          .tithi(lat: 28.61, lon: 77.2, tz: 'Asia/Kolkata', date: '');
      final url = m.calls.single.url;
      expect(url.queryParameters.containsKey('date'), isFalse);
      expect(url.query, 'lat=28.61&lon=77.2&tz=Asia%2FKolkata');
    });

    test('parses a real response body (examples.json)', () async {
      final ex =
          jsonDecode(File('test/fixtures/examples.json').readAsStringSync())
              as Map<String, Object?>;
      final tithi =
          (ex['/v1/panchang/tithi'] as Map<String, Object?>)['response'];
      final m = mock((_) => reply(tithi));
      final Map<String, dynamic> res = await m.client.panchang.tithi(
          lat: 28.6139, lon: 77.209, tz: 'Asia/Kolkata', date: '2027-01-15');
      expect(res['name'], (tithi as Map)['name']);
      expect(res['paksha'], tithi['paksha']);
    });

    test('decodes UTF-8 text (Gujarati, Bengali)', () async {
      final m = mock((_) => reply({'name': 'સપ્તમી', 'bn': 'সপ্তমী'}));
      final Map<String, dynamic> res = await m.client.panchang
          .tithi(lat: 1, lon: 2, tz: 'UTC', lang: Lang.gu);
      expect(res['name'], 'સપ્તમી');
      expect(res['bn'], 'সপ্তমী');
    });
  });

  group('param shapes', () {
    test('flat birth params', () async {
      final m = mock((_) => reply({}));
      await m.client.chart.planets(birth: birth);
      final q = m.calls.single.url.queryParameters;
      expect(q['date'], '1990-01-15');
      expect(q['time'], '10:30');
      expect(q['lat'], '19.076');
      expect(q['lon'], '72.8777');
    });

    test('birth.* prefixed params (mangal-dosha)', () async {
      final m = mock((_) => reply({}));
      await m.client.milan.mangalDosha(birth: birth);
      final url = m.calls.single.url;
      expect(url.path, '/v1/milan/mangal-dosha');
      expect(url.queryParameters['birth.date'], '1990-01-15');
      expect(url.queryParameters['birth.lat'], '19.076');
      expect(url.queryParameters.containsKey('date'), isFalse);
    });

    test('boy.*/girl.* matchmaking params', () async {
      final m = mock((_) => reply({}));
      await m.client.milan.ashtakootaTotal(boy: birth, girl: girl);
      final q = m.calls.single.url.queryParameters;
      expect(q['boy.date'], '1990-01-15');
      expect(q['girl.date'], '1992-03-20');
    });

    test('personA.*/personB.* Western pairs', () async {
      final m = mock((_) => reply({}));
      await m.client.western.synastry.aspects(personA: birth, personB: girl);
      final q = m.calls.single.url.queryParameters;
      expect(q['personA.date'], '1990-01-15');
      expect(q['personB.lat'], '28.6139');
    });

    test('lowercases rashi', () async {
      final m = mock((_) => reply({}));
      await m.client.horoscope.daily(rashi: 'Aries');
      expect(m.calls.single.url.queryParameters['rashi'], 'aries');
    });

    test('substitutes path params (divisional varga)', () async {
      final m = mock((_) => reply({}));
      await m.client.chart.divisional(birth: birth, varga: 'D9');
      final url = m.calls.single.url;
      expect(url.path, '/v1/chart/divisional/D9');
      expect(url.queryParameters.containsKey('varga'), isFalse);
    });

    test('custom shape (festivals.month)', () async {
      final m = mock((_) => reply({}));
      await m.client.festivals.month(
          year: 2026,
          month: 11,
          tz: 'Asia/Kolkata',
          lat: 19.076,
          lon: 72.8777,
          locale: Lang.mr,
          monthSystem: 'amanta');
      final q = m.calls.single.url.queryParameters;
      expect(q['year'], '2026');
      expect(q['lat'], '19.076');
      expect(q['month_system'], 'amanta');
      expect(q['locale'], 'mr');
    });

    test('natalTransit shape maps natal to birth.* and transit flat', () async {
      final m = mock((_) => reply({}));
      await m.client.western.transits.toNatal(
          birth: birth, date: '2026-06-16', time: '12:00', tz: 'Asia/Kolkata');
      final q = m.calls.single.url.queryParameters;
      expect(q['birth.date'], '1990-01-15');
      expect(q['date'], '2026-06-16');
    });

    test('a chart listed as separate fields takes a BirthInput', () async {
      final m = mock((_) => reply({}));
      await m.client.narrative
          .yearlyBhavishyafal(birth: birth, year: 2027, lang: Lang.hi);
      var q = m.calls.last.url.queryParameters;
      expect(q['birth.date'], '1990-01-15');
      expect(q['birth.time'], '10:30');
      expect(q['birth.tz'], 'Asia/Kolkata');
      expect(q['lat'], '19.076');
      expect(q['lon'], '72.8777');
      expect(q['year'], '2027');

      await m.client.narrative.milan(boy: birth, girl: girl);
      q = m.calls.last.url.queryParameters;
      expect(q['boy.date'], '1990-01-15');
      expect(q['girl.time'], '08:15');
      expect(q.containsKey('boy.lat'), isFalse);
    });

    test('ayanamsa and house system send their wire values', () async {
      final m = mock((_) => reply({}));
      await m.client.chart.planets(
          birth: birth,
          ayanamsa: Ayanamsa.trueChitrapaksha,
          houseSystem: HouseSystem.wholeSign);
      final q = m.calls.single.url.queryParameters;
      expect(q['ayanamsa'], 'true_chitrapaksha');
      expect(q['house_system'], 'whole-sign');
    });

    test('exposes nested western groups', () {
      final m = mock((_) => reply({}));
      expect(m.client.western.natal, isA<WesternNatalApi>());
      expect(m.client.western.synastry, isA<WesternSynastryApi>());
      expect(m.client.western.firdaria, isA<Function>());
    });

    test('throws on an empty path parameter', () {
      final m = mock((_) => reply({}));
      expect(
          () => m.client.chart.divisional(birth: birth, varga: ''),
          throwsA(isA<ArgumentError>().having(
              (e) => e.message, 'message', contains('path parameter'))));
      expect(m.calls, isEmpty);
    });
  });

  group('errors', () {
    test('maps 401 to AuthenticationException with code + requestId', () async {
      final m = mock((_) => reply({
            'error': {
              'code': 'unauthorized',
              'message': 'bad key',
              'request_id': 'req_1'
            }
          }, status: 401));
      final err = await caught(m.client.chart.planets(birth: birth));
      expect(err, isA<AuthenticationException>());
      err as AuthenticationException;
      expect(err.name, 'AuthenticationException');
      expect(err.code, 'unauthorized');
      expect(err.status, 401);
      expect(err.message, 'bad key');
      expect(err.requestId, 'req_1');
      expect(err.toString(), contains('req_1'));
    });

    test('maps 402 to PaymentRequiredException', () async {
      final m = mock((_) => reply({
            'error': {'code': 'insufficient_credits', 'message': 'no credits'}
          }, status: 402));
      expect(await caught(m.client.chart.planets(birth: birth)),
          isA<PaymentRequiredException>());
    });

    test('maps 400 to BadRequestException', () async {
      final m = mock((_) => reply({
            'error': {'code': 'invalid_param', 'message': 'bad lat'}
          }, status: 400));
      expect(await caught(m.client.chart.planets(birth: birth)),
          isA<BadRequestException>());
    });

    test('maps 429 to RateLimitException with retryAfter', () async {
      final m = mock((_) => reply(
          {
            'error': {'code': 'rate_limited', 'message': 'slow down'}
          },
          status: 429,
          headers: {'retry-after': '7'}));
      final err = await caught(m.client.chart.planets(birth: birth));
      expect(err, isA<RateLimitException>());
      expect(
          (err as RateLimitException).retryAfter, const Duration(seconds: 7));
    });

    test('parses the HTTP-date form of Retry-After', () async {
      final m = mock((_) => reply(
          {
            'error': {'code': 'rate_limited'}
          },
          status: 429,
          headers: {'retry-after': 'Wed, 21 Oct 2099 07:28:00 GMT'}));
      final err = await caught(m.client.chart.planets(birth: birth));
      expect(err, isA<RateLimitException>());
      final ra = (err as RateLimitException).retryAfter;
      expect(ra, isNotNull);
      expect(ra! > Duration.zero, isTrue);
    });

    test('uses the HTTP status when the body has no error object', () async {
      final m = mock((_) => reply('upstream down', status: 502));
      final err = await caught(m.client.chart.planets(birth: birth));
      expect(err, isA<ServerException>());
      err as ServerException;
      expect(err.code, 'internal_error');
      expect(err.message, 'HTTP 502');
      expect(err.body, 'upstream down');
    });
  });

  group('error status mapping', () {
    final cases = {
      403: 'PermissionException',
      404: 'NotFoundException',
      500: 'ServerException',
      503: 'ServerException',
      418: 'LifeAstroException',
    };
    cases.forEach((status, name) {
      test('maps $status to $name', () async {
        final m = mock((_) => reply({
              'error': {'code': 'x', 'message': 'm'}
            }, status: status));
        final err = await caught(m.client.chart.planets(birth: birth))
            as LifeAstroException;
        expect(err.name, name);
        expect(err.status, status);
      });
    });

    test('every exception is a LifeAstroException', () async {
      final m = mock((_) => reply({
            'error': {'code': 'forbidden'}
          }, status: 403));
      final err = await caught(m.client.chart.planets(birth: birth));
      expect(err, isA<PermissionException>());
      expect(err, isA<LifeAstroException>());
    });

    test('does not retry a non-retryable 4xx (single call)', () async {
      final m = mock(
          (_) => reply({
                'error': {'code': 'invalid_param'}
              }, status: 400),
          maxRetries: 3);
      expect(await caught(m.client.chart.planets(birth: birth)),
          isA<BadRequestException>());
      expect(m.calls.length, 1);
    });
  });

  group('retries', () {
    test('retries a 429 then succeeds', () async {
      var n = 0;
      final m = mock((_) {
        n += 1;
        if (n == 1) {
          return reply(
              {
                'error': {'code': 'rate_limited'}
              },
              status: 429,
              headers: {'retry-after': '0'});
        }
        return reply({
          'data': {'ok': true}
        });
      }, maxRetries: 2);
      expect(await m.client.chart.planets(birth: birth), {'ok': true});
      expect(m.calls.length, 2);
    });

    test('gives up after maxRetries', () async {
      final m = mock(
          (_) => reply(
              {
                'error': {'code': 'unavailable'}
              },
              status: 503,
              headers: {'retry-after': '0'}),
          maxRetries: 2);
      final err = await caught(m.client.chart.planets(birth: birth));
      expect((err as LifeAstroException).status, 503);
      expect(m.calls.length, 3); // initial + 2 retries
    });

    test('clamps a negative maxRetries to 0 (still one request)', () async {
      final m = mock(
          (_) => reply(
              {
                'error': {'code': 'unavailable'}
              },
              status: 503,
              headers: {'retry-after': '0'}),
          maxRetries: -5);
      final err = await caught(m.client.chart.planets(birth: birth));
      expect((err as LifeAstroException).status, 503);
      expect(m.calls.length, 1);
    });

    test('retries a network error, then succeeds', () async {
      var n = 0;
      final inner = MockClient((req) async {
        n += 1;
        if (n == 1) throw http.ClientException('ECONNRESET', req.url);
        return http.Response(jsonEncode({'ok': true}), 200);
      });
      final res =
          await clientWith(inner, maxRetries: 2).chart.planets(birth: birth);
      expect(res, {'ok': true});
      expect(n, 2);
    });

    test('surfaces network failures as LifeAstroConnectionException', () async {
      final inner =
          MockClient((req) async => throw http.ClientException('boom'));
      final err = await caught(
          clientWith(inner).panchang.tithi(lat: 1, lon: 2, tz: 'UTC'));
      expect(err, isA<LifeAstroConnectionException>());
      err as LifeAstroConnectionException;
      expect(err.code, 'connection_error');
      expect(err.status, 0);
      expect(err.cause, isA<http.ClientException>());
    });
  });

  group('localization', () {
    test('sends both lang and locale for narrative endpoints', () async {
      final m = mock((_) => reply({}));
      await m.client.narrative.lagna(birth: birth, lang: Lang.hi);
      final q = m.calls.single.url.queryParameters;
      expect(q['lang'], 'hi');
      expect(q['locale'], 'hi');
    });

    const now =
        (lat: 19.076, lon: 72.8777, tz: 'Asia/Kolkata', date: '2027-01-15');

    // One method per Vedic group; `both` is false where the shape itself
    // sends `lang` only.
    final vedic = <(String, String, Future<Object?> Function(LifeAstro), bool)>[
      (
        'panchang.basic',
        '/v1/panchang/basic',
        (c) => c.panchang.basic(
            lat: now.lat,
            lon: now.lon,
            tz: now.tz,
            date: now.date,
            lang: Lang.gu),
        true
      ),
      (
        'panchang.panchaka',
        '/v1/panchang/panchaka',
        (c) => c.panchang.panchaka(
            lat: now.lat,
            lon: now.lon,
            tz: now.tz,
            date: now.date,
            lang: Lang.gu),
        true
      ),
      (
        'calendar.ritu',
        '/v1/calendar/ritu',
        (c) => c.calendar.ritu(date: now.date, tz: now.tz, lang: Lang.gu),
        true
      ),
      (
        'festivals.month',
        '/v1/festivals/month',
        (c) => c.festivals.month(year: 2027, month: 1, lang: Lang.gu),
        true
      ),
      (
        'eclipses.all',
        '/v1/eclipses/all',
        (c) => c.eclipses
            .all(startDate: '2027-01-01', endDate: '2027-12-31', lang: Lang.gu),
        true
      ),
      (
        'planetMoments.ingress',
        '/v1/planet-moments/ingress',
        (c) => c.planetMoments.ingress(
            planet: 'Jupiter', date: now.date, tz: now.tz, lang: Lang.gu),
        true
      ),
      (
        'transit.positions',
        '/v1/transit/positions',
        (c) => c.transit.positions(lang: Lang.gu),
        true
      ),
      (
        'transit.tarabala',
        '/v1/transit/tarabala',
        (c) => c.transit.tarabala(
            birth: birth,
            date: now.date,
            time: '06:00',
            tz: now.tz,
            lang: Lang.gu),
        true
      ),
      (
        'milan.ashtakoota',
        '/v1/milan/ashtakoota',
        (c) => c.milan.ashtakoota(boy: birth, girl: girl, lang: Lang.gu),
        true
      ),
      (
        'muhurta.vivah',
        '/v1/muhurta/vivah',
        (c) => c.muhurta.vivah(
            lat: now.lat,
            lon: now.lon,
            tz: now.tz,
            date: now.date,
            lang: Lang.gu),
        true
      ),
      (
        'muhurta.bestTime',
        '/v1/muhurta/best-time',
        (c) => c.muhurta.bestTime(
            lat: now.lat,
            lon: now.lon,
            tz: now.tz,
            startDate: '2027-01-15',
            endDate: '2027-01-17',
            lang: Lang.gu),
        true
      ),
      (
        'chart.planets',
        '/v1/chart/planets',
        (c) => c.chart.planets(birth: birth, lang: Lang.gu),
        true
      ),
      (
        'chart.kundliFacts',
        '/v1/chart/kundli-facts',
        (c) => c.chart.kundliFacts(birth: birth, lang: Lang.gu),
        true
      ),
      (
        'prashna.chart',
        '/v1/prashna/chart',
        (c) => c.prashna.chart(
            lat: now.lat,
            lon: now.lon,
            tz: now.tz,
            date: now.date,
            time: '12:00',
            lang: Lang.gu),
        true
      ),
      (
        'numerology.driver',
        '/v1/numerology/driver',
        (c) => c.numerology.driver(dob: '1990-01-15', lang: Lang.gu),
        true
      ),
      (
        'numerology.full',
        '/v1/numerology/full',
        (c) => c.numerology
            .full(name: 'Arjun Mehta', dob: '1990-01-15', lang: Lang.gu),
        false
      ),
      (
        'dasha.vimshottari',
        '/v1/dasha/vimshottari',
        (c) => c.dasha.vimshottari(birth: birth, lang: Lang.gu),
        true
      ),
      (
        'varshaphal.chart',
        '/v1/varshaphal/chart',
        (c) => c.varshaphal.chart(birth: birth, year: 2026, lang: Lang.gu),
        true
      ),
      (
        'ashtakavarga.bhinna',
        '/v1/ashtakavarga/bhinna/Jupiter',
        (c) => c.ashtakavarga
            .bhinna(birth: birth, planet: 'Jupiter', lang: Lang.gu),
        true
      ),
      (
        'lalkitab.chart',
        '/v1/lalkitab/chart',
        (c) => c.lalkitab.chart(birth: birth, lang: Lang.gu),
        true
      ),
      (
        'horoscope.daily',
        '/v1/horoscope/daily',
        (c) => c.horoscope.daily(rashi: 'aries', lang: Lang.gu),
        false
      ),
      (
        'reports.kundliLite',
        '/v1/reports/kundli/lite',
        (c) => c.reports.kundliLite(birth: birth, lang: Lang.gu),
        true
      ),
      (
        'narrative.yearlyBhavishyafal',
        '/v1/vedic/narrative/yearly-bhavishyafal',
        (c) => c.narrative
            .yearlyBhavishyafal(birth: birth, year: 2027, lang: Lang.gu),
        true
      ),
      (
        'remedies.forGraha',
        '/v1/vedic/remedies/for-graha',
        (c) => c.remedies.forGraha(graha: 'saturn', lang: Lang.gu),
        true
      ),
    ];
    for (final (name, path, call, both) in vedic) {
      test('$name sends the language', () async {
        final m = mock((_) => reply({}));
        await call(m.client);
        final url = m.calls.single.url;
        expect(url.path, path);
        expect(url.queryParameters['lang'], 'gu');
        if (both) expect(url.queryParameters['locale'], 'gu');
      });
    }

    test('accepts every Lang value, including pa', () async {
      final m = mock((_) => reply({}));
      for (final lang in Lang.values) {
        await m.client.panchang.tithi(
            lat: now.lat, lon: now.lon, tz: now.tz, date: now.date, lang: lang);
      }
      expect(m.calls.map((c) => c.url.queryParameters['locale']),
          ['en', 'hi', 'mr', 'te', 'ta', 'kn', 'ml', 'gu', 'bn', 'pa']);
      expect(Lang.fromCode('BN'), Lang.bn);
      expect(Lang.fromCode('xx'), isNull);
    });

    test('sends no language param when lang is omitted', () async {
      final m = mock((_) => reply({}));
      await m.client.panchang
          .basic(lat: now.lat, lon: now.lon, tz: now.tz, date: now.date);
      final q = m.calls.single.url.queryParameters;
      expect(q.containsKey('lang'), isFalse);
      expect(q.containsKey('locale'), isFalse);
    });

    test('keeps the older `locale` input; `lang` wins when both are given',
        () async {
      final m = mock((_) => reply({}));
      await m.client.festivals.month(year: 2027, month: 1, locale: Lang.hi);
      await m.client.panchang.monthly(
          lat: now.lat,
          lon: now.lon,
          year: 2027,
          month: 1,
          locale: Lang.hi,
          lang: Lang.gu);
      final a = m.calls[0].url.queryParameters;
      expect(a['locale'], 'hi');
      expect(a.containsKey('lang'), isFalse);
      final b = m.calls[1].url.queryParameters;
      expect(b['locale'], 'gu');
      expect(b['lang'], 'gu');
    });

    test('Western narrative keeps its own lang (en / hi / mr)', () async {
      final m = mock((_) => reply({}));
      await m.client.western.narrative.sabian(degree: 100, lang: Lang.hi);
      expect(m.calls.single.url.queryParameters['lang'], 'hi');
    });
  });

  group('configuration', () {
    late String? Function() saved;
    setUp(() {
      saved = environmentApiKey;
      environmentApiKey = () => null;
    });
    tearDown(() => environmentApiKey = saved);

    test('throws when no API key is provided', () {
      expect(
          () => LifeAstro(),
          throwsA(isA<ArgumentError>()
              .having((e) => e.message, 'message', contains('API key'))));
    });

    test('an empty apiKey is not a key', () {
      environmentApiKey = () => 'dv_live_env';
      expect(() => LifeAstro(apiKey: ''), throwsArgumentError);
    });

    test('reads the API key from the environment', () async {
      environmentApiKey = () => 'dv_live_env';
      final calls = <http.Request>[];
      final inner = MockClient((req) async {
        calls.add(req);
        return http.Response('{}', 200);
      });
      final client = LifeAstro(httpClient: inner, maxRetries: 0);
      await client.panchang.tithi(lat: 1, lon: 2, tz: 'UTC');
      expect(calls.single.headers['Authorization'], 'Bearer dv_live_env');
    });

    test('baseUrl override, trailing slash removed', () async {
      final calls = <http.Request>[];
      final inner = MockClient((req) async {
        calls.add(req);
        return http.Response('{}', 200);
      });
      final client = LifeAstro(
          apiKey: 'dv_live_test',
          baseUrl: 'http://127.0.0.1:18080/',
          httpClient: inner);
      await client.meta.version();
      expect(calls.single.url.toString(),
          'http://127.0.0.1:18080/v1/meta/version');
    });

    test('a baseUrl with a path prefix (your own backend)', () async {
      final calls = <http.Request>[];
      final inner = MockClient((req) async {
        calls.add(req);
        return http.Response('{}', 200);
      });
      final client = LifeAstro(
          apiKey: 'session-token',
          baseUrl: 'https://backend.example.com/astro',
          httpClient: inner);
      await client.meta.version();
      expect(calls.single.url.toString(),
          'https://backend.example.com/astro/v1/meta/version');
      expect(calls.single.headers['Authorization'], 'Bearer session-token');
    });

    test('close() leaves a client passed in open', () async {
      var closed = false;
      final inner = _CloseTracking(() => closed = true);
      LifeAstro(apiKey: 'dv_live_test', httpClient: inner).close();
      expect(closed, isFalse);
    });
  });

  group('query encoding edge cases', () {
    test('keeps a legitimate zero (lat=0, lon=0)', () async {
      final m = mock((_) => reply({}));
      await m.client.panchang.tithi(lat: 0, lon: 0, tz: 'UTC');
      final q = m.calls.single.url.queryParameters;
      expect(q['lat'], '0');
      expect(q['lon'], '0');
    });

    test('URL-encodes a fixed-offset tz (+05:30)', () async {
      final m = mock((_) => reply({}));
      await m.client.panchang.tithi(lat: 1, lon: 2, tz: '+05:30');
      expect(m.calls.single.url.toString(), contains('tz=%2B05%3A30'));
      expect(m.calls.single.url.queryParameters['tz'], '+05:30');
    });

    test('percent-encodes path parameters', () async {
      final m = mock((_) => reply({}));
      await m.client.chart.planet(birth: birth, name: 'a b/c');
      expect(m.calls.single.url.path, '/v1/chart/planet/a%20b%2Fc');
    });

    test('includes default headers and a User-Agent', () async {
      final m = mock((_) => reply({}), defaultHeaders: {'X-Trace': 'abc'});
      await m.client.panchang.tithi(lat: 1, lon: 2, tz: 'UTC');
      final h = m.calls.single.headers;
      expect(h['X-Trace'], 'abc');
      expect(h['User-Agent'], 'lifeastroapi-dart/$packageVersion');
    });
  });

  group('abort & timeout', () {
    // Never answers.
    MockClient hanging() =>
        MockClient((req) => Completer<http.Response>().future);

    test('rejects a pre-aborted call with code aborted', () async {
      final err = await caught(clientWith(hanging()).panchang.tithi(
          lat: 1,
          lon: 2,
          tz: 'UTC',
          options: RequestOptions(abortTrigger: Future.value())));
      expect(err, isA<LifeAstroConnectionException>());
      expect((err as LifeAstroConnectionException).code, 'aborted');
    });

    test('aborts an in-flight call', () async {
      final abort = Completer<void>();
      final f = clientWith(hanging()).panchang.tithi(
          lat: 1,
          lon: 2,
          tz: 'UTC',
          options: RequestOptions(abortTrigger: abort.future));
      Timer(const Duration(milliseconds: 20), abort.complete);
      final err = await caught(f);
      expect((err as LifeAstroConnectionException).code, 'aborted');
    });

    test('times out with code timeout', () async {
      final err = await caught(clientWith(hanging()).panchang.tithi(
          lat: 1,
          lon: 2,
          tz: 'UTC',
          options: const RequestOptions(timeout: Duration(milliseconds: 10))));
      expect(err, isA<LifeAstroConnectionException>());
      expect((err as LifeAstroConnectionException).code, 'timeout');
    });

    test('client timeout applies when no per-call timeout is given', () async {
      final client = LifeAstro(
          apiKey: 'dv_live_test',
          httpClient: hanging(),
          maxRetries: 0,
          timeout: const Duration(milliseconds: 10));
      final err =
          await caught(client.panchang.tithi(lat: 1, lon: 2, tz: 'UTC'));
      expect((err as LifeAstroConnectionException).code, 'timeout');
    });
  });

  group('escape hatch', () {
    test('client.request hits an arbitrary path and unwraps data', () async {
      final m = mock((_) => reply({
            'data': {'v': 1}
          }));
      final res = await m.client.request('/v1/anything', query: {'a': 'b'});
      expect(res, {'v': 1});
      expect(m.calls.single.url.path, '/v1/anything');
      expect(m.calls.single.url.queryParameters['a'], 'b');
    });

    test('client.get is an alias for request', () async {
      final m = mock((_) => reply({
            'data': {'ok': 1}
          }));
      expect(await m.client.get('/v1/x'), {'ok': 1});
    });
  });

  group('non-enveloped success bodies', () {
    test('returns a bare array body as-is', () async {
      final m = mock((_) => reply([1, 2, 3]));
      expect(await m.client.request('/v1/list'), [1, 2, 3]);
    });

    test('returns a no-`data` object body as-is', () async {
      final m = mock((_) => reply({'foo': 1, 'bar': 2}));
      expect(await m.client.request('/v1/raw'), {'foo': 1, 'bar': 2});
    });

    test('returns a non-JSON success body as the raw string', () async {
      final m = mock((_) => reply('plain text'));
      expect(await m.client.request('/v1/text'), 'plain text');
    });

    test('a type argument narrows the result', () async {
      final m = mock((_) => reply({'number': 3}));
      final res = await m.client.panchang
          .tithi<Map<String, dynamic>>(lat: 1, lon: 2, tz: 'UTC');
      expect(res['number'], 3);
    });
  });

  group('date defaults', () {
    test('fills today for a moment endpoint when date is omitted', () async {
      final m = mock((_) => reply({}));
      await m.client.panchang
          .tithi(lat: 19.076, lon: 72.8777, tz: 'Asia/Kolkata');
      expect(m.calls.single.url.queryParameters['date'],
          matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
    });

    test('keeps an explicit date', () async {
      final m = mock((_) => reply({}));
      await m.client.panchang.tithi(
          lat: 19.076, lon: 72.8777, tz: 'Asia/Kolkata', date: '2026-11-20');
      expect(m.calls.single.url.queryParameters['date'], '2026-11-20');
    });

    test('todayIn resolves the date in the zone and falls back to UTC', () {
      final now = DateTime.utc(2026, 3, 1, 20); // already 2 March in Kolkata
      expect(todayIn('Asia/Kolkata', now), '2026-03-02');
      expect(todayIn('America/Los_Angeles', now), '2026-03-01');
      expect(todayIn('Not/AZone', now), '2026-03-01');
      expect(todayIn(null, now), '2026-03-01');
      expect(todayIn('+05:30', now), '2026-03-02');
      expect(todayIn('UTC+05:30', now), '2026-03-02');
      expect(todayIn('Etc/GMT-6', now), '2026-03-02');
      expect(todayIn('-04:00', DateTime.utc(2026, 3, 2, 3)), '2026-03-01');
    });

    test('todayIn follows daylight saving', () {
      // New York: EDT (-4) in July, EST (-5) in January.
      expect(todayIn('America/New_York', DateTime.utc(2026, 7, 1, 3, 30)),
          '2026-06-30');
      expect(todayIn('America/New_York', DateTime.utc(2026, 7, 1, 4, 30)),
          '2026-07-01');
      expect(todayIn('America/New_York', DateTime.utc(2026, 1, 15, 4, 30)),
          '2026-01-14');
      // London: BST (+1) in July, GMT in January.
      expect(todayIn('Europe/London', DateTime.utc(2026, 7, 1, 23, 30)),
          '2026-07-02');
      expect(todayIn('Europe/London', DateTime.utc(2026, 1, 1, 23, 30)),
          '2026-01-01');
      // Sydney: AEDT (+11) in January, AEST (+10) in July.
      expect(todayIn('Australia/Sydney', DateTime.utc(2026, 1, 15, 13, 30)),
          '2026-01-16');
      expect(todayIn('Australia/Sydney', DateTime.utc(2026, 7, 15, 13, 30)),
          '2026-07-15');
      // Auckland: NZDT (+13) in January.
      expect(todayIn('Pacific/Auckland', DateTime.utc(2026, 1, 15, 11, 30)),
          '2026-01-16');
      // Toronto across the March 2026 change (8 March).
      expect(todayIn('America/Toronto', DateTime.utc(2026, 3, 9, 4, 30)),
          '2026-03-09');
      expect(todayIn('America/Toronto', DateTime.utc(2026, 3, 7, 4, 30)),
          '2026-03-06');
    });

    test('transit.positions needs no arguments (today, UTC)', () async {
      final m = mock((_) => reply({}));
      await m.client.transit.positions();
      final q = m.calls.single.url.queryParameters;
      expect(q['tz'], 'UTC');
      expect(q['date'], matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
    });
  });

  group('endpoints corrected against the live API', () {
    test('personalised horoscope: chart unprefixed, the day as transit_date',
        () async {
      final m = mock((_) => reply({}));
      await m.client.narrative
          .horoscopeDailyByLagna(birth: birth, onDate: '2026-10-10');
      final q = m.calls.single.url.queryParameters;
      expect(q['date'], '1990-01-15');
      expect(q['transit_date'], '2026-10-10');
      expect(q.containsKey('birth.date'), isFalse);
    });

    test('reports accept the name and place for the cover page', () async {
      final m = mock((_) => reply({}));
      await m.client.reports
          .kundliLite(birth: birth, name: 'Arjun Mehta', place: 'Mumbai');
      final one = m.calls[0].url.queryParameters;
      expect(one['name'], 'Arjun Mehta');
      expect(one['place'], 'Mumbai');
      await m.client.reports.matchMaking(
          boy: birth,
          girl: birth,
          boyName: 'A',
          girlName: 'B',
          boyPlace: 'Pune');
      final q = m.calls[1].url.queryParameters;
      expect(q['boy.name'], 'A');
      expect(q['girl.name'], 'B');
      expect(q['boy.place'], 'Pune');
    });

    test('monthly horoscope report takes month as YYYY-MM', () async {
      final m = mock((_) => reply({}));
      await m.client.reports.horoscopeMonthly(rashi: 'Aries', month: '2026-11');
      final q = m.calls.single.url.queryParameters;
      expect(q['month'], '2026-11');
      expect(q.containsKey('year'), isFalse);
    });

    test('exposes the meta catalogs', () async {
      final m = mock((_) => reply({}));
      await m.client.meta.endpoints();
      await m.client.meta.vedicYogas();
      expect(m.calls.map((c) => c.url.path),
          ['/v1/meta/endpoints', '/v1/meta/vedic/yogas']);
    });
  });

  group('natal chart + transit moment are separate', () {
    final cases = <(String, Future<Object?> Function(LifeAstro), bool)>[
      (
        '/v1/vedic/narrative/transit-phal',
        (c) => c.narrative.transitPhal(
            birth: birth,
            date: '2027-01-15',
            time: '06:00',
            tz: 'Asia/Kolkata'),
        true
      ),
      (
        '/v1/vedic/narrative/dasha-phal',
        (c) => c.narrative.dashaPhal(
            birth: birth,
            date: '2027-01-15',
            time: '06:00',
            tz: 'Asia/Kolkata'),
        true
      ),
      (
        '/v1/vedic/narrative/transit-double',
        (c) => c.narrative.transitDouble(
            birth: birth,
            date: '2027-01-15',
            time: '06:00',
            tz: 'Asia/Kolkata'),
        false
      ),
      (
        '/v1/vedic/narrative/sade-sati-status',
        (c) => c.narrative.sadeSatiStatus(
            birth: birth,
            date: '2027-01-15',
            time: '06:00',
            tz: 'Asia/Kolkata'),
        false
      ),
      (
        '/v1/vedic/narrative/sade-sati-phase',
        (c) => c.narrative.sadeSatiPhase(
            birth: birth,
            date: '2027-01-15',
            time: '06:00',
            tz: 'Asia/Kolkata'),
        false
      ),
      (
        '/v1/vedic/narrative/sade-sati-history',
        (c) => c.narrative.sadeSatiHistory(
            birth: birth,
            date: '2027-01-15',
            time: '06:00',
            tz: 'Asia/Kolkata'),
        false
      ),
      (
        '/v1/ashtakavarga/kaksha',
        (c) => c.ashtakavarga.kaksha(
            birth: birth,
            date: '2027-01-15',
            time: '06:00',
            tz: 'Asia/Kolkata'),
        false
      ),
      (
        '/v1/ashtakavarga/transit-score',
        (c) => c.ashtakavarga.transitScore(
            birth: birth,
            date: '2027-01-15',
            time: '06:00',
            tz: 'Asia/Kolkata'),
        false
      ),
      (
        '/v1/transit/small-panoti',
        (c) => c.transit.smallPanoti(
            birth: birth,
            date: '2027-01-15',
            time: '06:00',
            tz: 'Asia/Kolkata'),
        false
      ),
    ];
    for (final (path, call, place) in cases) {
      test('$path: birth.* is the chart, date is the transit moment', () async {
        final m = mock((_) => reply({}));
        await call(m.client);
        final url = m.calls.single.url;
        expect(url.path, path);
        final q = url.queryParameters;
        expect(q['birth.date'], '1990-01-15');
        expect(q['birth.time'], '10:30');
        expect(q['birth.lat'], '19.076');
        expect(q['date'], '2027-01-15');
        expect(q['tz'], 'Asia/Kolkata');
        // Endpoints that cast the natal lagna read the birth place unprefixed.
        expect(q['lat'], place ? '19.076' : null);
      });
    }

    test('narrative.prashna sends the question moment, topic and house',
        () async {
      final m = mock((_) => reply({}));
      await m.client.narrative.prashna(
          lat: 19.076,
          lon: 72.8777,
          tz: 'Asia/Kolkata',
          date: '2027-01-15',
          time: '10:00',
          topic: 'career',
          questionHouse: 10,
          lang: Lang.hi);
      final url = m.calls.single.url;
      expect(url.path, '/v1/vedic/narrative/prashna');
      final q = url.queryParameters;
      expect(q['date'], '2027-01-15');
      expect(q['time'], '10:00');
      expect(q['topic'], 'career');
      expect(q['question_house'], '10');
      expect(q['locale'], 'hi');
    });
  });

  group('chart, transit, remedy and milan data endpoints', () {
    Future<Uri> query(Future<Object?> Function(LifeAstro) call) async {
      final m = mock((_) => reply({}));
      await call(m.client);
      return m.calls.single.url;
    }

    test('kundliFacts / yogas / doshas / sensitivity read the chart unprefixed',
        () async {
      final cases =
          <(String, Future<Object?> Function(LifeAstro), Map<String, String>)>[
        (
          '/v1/chart/kundli-facts',
          (c) => c.chart.kundliFacts(
              birth: birth, vargas: 'D9,D10', include: 'all', gender: 'male'),
          {'vargas': 'D9,D10', 'include': 'all', 'gender': 'male'}
        ),
        (
          '/v1/chart/yogas',
          (c) => c.chart.yogas(birth: birth, all: true),
          {'all': 'true'}
        ),
        (
          '/v1/chart/doshas',
          (c) => c.chart.doshas(birth: birth, gender: 'female'),
          {'gender': 'female'}
        ),
        (
          '/v1/chart/sensitivity',
          (c) => c.chart.sensitivity(
              birth: birth, window: 60, vargas: 'D9', topocentricMoon: true),
          {'window': '60', 'vargas': 'D9', 'topocentric_moon': 'true'}
        ),
      ];
      for (final (path, call, extra) in cases) {
        final url = await query(call);
        expect(url.path, path);
        final q = url.queryParameters;
        expect(q['date'], '1990-01-15');
        expect(q['time'], '10:30');
        expect(q['lat'], '19.076');
        expect(q['birth.date'], isNull);
        extra.forEach((k, v) => expect(q[k], v, reason: '$path $k'));
      }
    });

    test('transit.sadeSatiWindows sends birth.* plus unprefixed from/tz',
        () async {
      final url = await query((c) => c.transit.sadeSatiWindows(
          birth: const NatalWindowBirth(
              date: '1990-01-15', time: '10:30', tz: 'Asia/Kolkata'),
          from: '2027-01-15',
          tz: 'UTC',
          years: 30,
          includePast: true));
      expect(url.path, '/v1/transit/sade-sati/windows');
      final q = url.queryParameters;
      expect(q['birth.date'], '1990-01-15');
      expect(q['birth.time'], '10:30');
      expect(q['birth.tz'], 'Asia/Kolkata');
      expect(q['birth.lat'], isNull);
      expect(q['date'], isNull);
      expect(q['from'], '2027-01-15');
      expect(q['tz'], 'UTC');
      expect(q['years'], '30');
      expect(q['include_past'], 'true');
    });

    test('transit.windows: planet required, birth optional', () async {
      var url = await query((c) =>
          c.transit.windows(planet: 'jupiter', from: '2027-01-15', years: 12));
      expect(url.path, '/v1/transit/windows');
      expect(url.queryParameters['planet'], 'jupiter');
      expect(url.queryParameters['from'], '2027-01-15');
      expect(url.queryParameters['years'], '12');
      expect(
          url.queryParameters.keys.any((k) => k.startsWith('birth.')), isFalse);
      // A BirthInput is accepted where a NatalWindowBirth is asked for.
      url =
          await query((c) => c.transit.windows(planet: 'saturn', birth: birth));
      expect(url.queryParameters['birth.date'], '1990-01-15');
      expect(url.queryParameters['birth.lat'], '19.076');
      expect(url.queryParameters['birth.lon'], '72.8777');
      expect(url.queryParameters['lat'], isNull);
    });

    test('remedies.forGraha maps graha, reason, include, category, language',
        () async {
      final url = await query((c) => c.remedies.forGraha(
          graha: 'saturn',
          reason: 'dosha:sade_sati',
          include: 'pooja,yantra',
          category: 'mantra',
          lang: Lang.hi));
      expect(url.path, '/v1/vedic/remedies/for-graha');
      final q = url.queryParameters;
      expect(q['graha'], 'saturn');
      expect(q['reason'], 'dosha:sade_sati');
      expect(q['include'], 'pooja,yantra');
      expect(q['category'], 'mantra');
      expect(q['locale'], 'hi');
    });

    test('milan.overlay / summary send boy.* and girl.*', () async {
      var url = await query((c) => c.milan.overlay(boy: birth, girl: girl));
      expect(url.path, '/v1/milan/overlay');
      expect(url.queryParameters['boy.date'], '1990-01-15');
      expect(url.queryParameters['girl.date'], '1992-03-20');
      expect(url.queryParameters['girl.lat'], '28.6139');
      url = await query((c) => c.milan.summary(
          boy: birth,
          girl: girl,
          from: '2027-01-15',
          tz: 'Asia/Kolkata',
          include: 'kundli_facts'));
      expect(url.path, '/v1/milan/summary');
      final q = url.queryParameters;
      expect(q['boy.time'], '10:30');
      expect(q['girl.time'], '08:15');
      expect(q['from'], '2027-01-15');
      expect(q['tz'], 'Asia/Kolkata');
      expect(q['include'], 'kundli_facts');
    });

    test('milan.dashaSync maps the timeline options and the check moment',
        () async {
      final url = await query((c) => c.milan.dashaSync(
          boy: birth,
          girl: girl,
          timeline: true,
          years: 5,
          from: '2027-01-15',
          marriageWindows: true,
          date: '2027-02-01',
          tz: 'Asia/Kolkata'));
      expect(url.path, '/v1/milan/dasha-sync');
      final q = url.queryParameters;
      expect(q['boy.lat'], '19.076');
      expect(q['girl.lon'], '77.209');
      expect(q['timeline'], 'true');
      expect(q['years'], '5');
      expect(q['from'], '2027-01-15');
      expect(q['marriage_windows'], 'true');
      expect(q['date'], '2027-02-01');
      expect(q['tz'], 'Asia/Kolkata');
    });
  });

  group('optional params the API reads (added to the manifest)', () {
    Future<Map<String, String>> query(
        Future<Object?> Function(LifeAstro) call) async {
      final m = mock((_) => reply({}));
      await call(m.client);
      return m.calls.single.url.queryParameters;
    }

    test('muhurta.bestTime: purpose, top_n, birth_date, ayanamsa', () async {
      final q = await query((c) => c.muhurta.bestTime(
          lat: 19.076,
          lon: 72.8777,
          tz: 'Asia/Kolkata',
          startDate: '2027-01-15',
          endDate: '2027-01-31',
          purpose: 'vivah',
          topN: 3,
          birthDate: '1990-01-15',
          ayanamsa: Ayanamsa.raman));
      expect(q['purpose'], 'vivah');
      expect(q['top_n'], '3');
      expect(q['birth_date'], '1990-01-15');
      expect(q['ayanamsa'], 'raman');
    });

    test('`at` on char / Lal Kitab current dasha, `week` on the weekly report',
        () async {
      var q = await query(
          (c) => c.dasha.charCurrent(birth: birth, at: '2027-01-15T06:00:00Z'));
      expect(q['at'], '2027-01-15T06:00:00Z');
      q = await query(
          (c) => c.lalkitab.dashaCurrent(birth: birth, at: '2027-01-15'));
      expect(q['at'], '2027-01-15');
      q = await query(
          (c) => c.reports.horoscopeWeekly(rashi: 'Aries', week: '2026-W47'));
      expect(q['week'], '2026-W47');
    });

    test('Western orbs, rulership, house system, composite, relocation',
        () async {
      var q = await query((c) => c.western.natal
          .chart(birth: birth, orbTrine: 6, rulership: 'traditional'));
      expect(q['orb_trine'], '6');
      expect(q['rulership'], 'traditional');
      q = await query((c) => c.western.synastry.aspects(
          personA: birth,
          personB: birth,
          houseSystem: HouseSystem.koch,
          orbConjunction: 8));
      expect(q['house_system'], 'koch');
      expect(q['orb_conjunction'], '8');
      q = await query((c) => c.western.composite.chart(
          personA: birth, personB: birth, compositeMethod: 'midpoint_cusps'));
      expect(q['composite_method'], 'midpoint_cusps');
      q = await query((c) => c.western.returns.solar(
          birth: birth,
          returnYear: 2027,
          relocateLat: 51.5,
          relocateLon: -0.12));
      expect(q['relocate_lat'], '51.5');
      expect(q['relocate_lon'], '-0.12');
    });

    test('ayanamsa on calendar.ritu', () async {
      final q = await query((c) => c.calendar.ritu(
          date: '2027-01-15', tz: 'Asia/Kolkata', ayanamsa: Ayanamsa.raman));
      expect(q['ayanamsa'], 'raman');
    });
  });
}

class _CloseTracking extends http.BaseClient {
  _CloseTracking(this.onClose);
  final void Function() onClose;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      throw UnimplementedError();

  @override
  void close() => onClose();
}
