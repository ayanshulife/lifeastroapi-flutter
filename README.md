# lifeastroapi

Official **Dart and Flutter SDK** for [LifeAstroAPI](https://lifeastroapi.com), a REST
[astrology API](https://lifeastroapi.com/apis/) for Vedic astrology, panchang, Hindu festivals,
kundli, muhurat and Western charts, with location-aware calculations and pay-per-call billing.
Free tier: 1,500 credits a month, no card. [Get a key](https://lifeastroapi.com/signup/).

- **Every endpoint**: all 322 endpoints (323 methods, with a shortcut for the navamsa chart) in 23 groups: panchang, charts, dashas, matching, transits,
  horoscopes, numerology, Lal Kitab, remedies, muhurta, narrative readings, JSON reports, tarot and
  a complete Western (tropical) module.
- **Pure Dart**, one dependency (`http`): Flutter (Android, iOS, web, desktop) and Dart servers.
- **10 languages**: `lang: Lang.gu` on every Vedic method.
- Typed exceptions, automatic retries on 429/5xx with `Retry-After`, timeouts, cancellation, and a
  generic escape hatch for any endpoint.
- **Branded PDF reports**: this package turns report JSON into white-label kundli, matching,
  numerology and horoscope documents in all 10 languages, on your side (HTML anywhere, PDF through
  Chrome, Edge or a Gotenberg service). See [Branded PDF reports](#branded-pdf-reports).

```bash
dart pub add lifeastroapi
# or, in a Flutter app
flutter pub add lifeastroapi
```

Get an API key at **https://lifeastroapi.com/dashboard/keys**.

## Quick start

```dart
import 'package:lifeastroapi/lifeastroapi.dart';

Future<void> main() async {
  final client = LifeAstro(apiKey: 'dv_live_...');

  // Today's panchang for Mumbai, in Gujarati
  final day = await client.panchang.basic(
    lat: 19.076, lon: 72.8777, tz: 'Asia/Kolkata',
    lang: Lang.gu,
  );
  print(day['tithi']);

  // A Vedic birth chart
  const arjun = BirthInput(
    date: '1990-01-15', time: '10:30', tz: 'Asia/Kolkata',
    lat: 19.076, lon: 72.8777,
  );
  final planets = await client.chart.planets(birth: arjun);

  // Kundli matching score
  final match = await client.milan.ashtakootaTotal(
    boy: arjun,
    girl: const BirthInput(
      date: '1992-03-20', time: '21:40', tz: 'Asia/Kolkata',
      lat: 28.6139, lon: 77.209,
    ),
  );

  client.close();
}
```

Every method returns the parsed JSON (`Map<String, dynamic>` or `List`), exactly as the API sends
it. Field names are listed in the [API reference](https://lifeastroapi.com/docs/).

See [`example/`](example/) for a runnable example and a Flutter widget.

## Authentication

Your API key (`dv_live_...`) is sent as an `Authorization: Bearer ...` header.

```dart
LifeAstro(apiKey: 'dv_live_...'); // explicit
LifeAstro();                      // reads LIFEASTRO_API_KEY (Dart on servers / desktop)
```

Without a key the constructor throws an `ArgumentError`.

> **Keep your key secret.** A `dv_live_...` key carries your account's full billing access. Use it
> on a server, never inside a mobile, desktop or web app, where users can extract it.
>
> **Flutter apps:** call LifeAstroAPI from your own backend. The SDK can talk to that backend
> directly: point `baseUrl` at it and pass your user's session token as `apiKey`. Your backend
> checks the token and forwards the request (same path and query) with your real key.
>
> ```dart
> final client = LifeAstro(
>   apiKey: userSessionToken,
>   baseUrl: 'https://api.your-app.example/astro', // forwards /v1/... to LifeAstroAPI
> );
> ```

## Configuration

```dart
final client = LifeAstro(
  apiKey: 'dv_live_...',
  baseUrl: 'https://api.lifeastroapi.com', // or a local server / your backend
  timeout: const Duration(seconds: 30),    // per request
  maxRetries: 2,                           // on 429 / 5xx / network errors
  httpClient: myClient,                    // your own http.Client (proxies, tests)
  defaultHeaders: {'X-Trace': 'abc'},      // extra headers on every request
  onResponse: null,                        // see "Credits, rate limit and request id"
);
// ...
client.close(); // closes the HTTP client the SDK created
```

## Compatibility

| | |
|---|---|
| **Dart / Flutter** | Dart 3.4 or newer, which is Flutter 3.22 or newer. |
| **Platforms** | Android, iOS, web (JavaScript and WebAssembly), macOS, Windows, Linux, and Dart servers and CLIs. |
| **Dependencies** | Only [`http`](https://pub.dev/packages/http) 1.5 or newer. No Flutter plugin, no native code, no code generation. |
| **Build setup** | Nothing to add to Gradle, CocoaPods, `minSdkVersion`, the iOS deployment target or ProGuard. |

A few things belong to your app, as with any package that uses the network:

- **Android:** release builds need `<uses-permission android:name="android.permission.INTERNET"/>`
  in `android/app/src/main/AndroidManifest.xml` (Flutter adds it to debug builds only).
- **macOS:** add the `com.apple.security.network.client` entitlement to
  `macos/Runner/DebugProfile.entitlements` and `Release.entitlements`.
- **Flutter web:** browsers block direct calls to `api.lifeastroapi.com` from your site (CORS), and
  the call fails with `LifeAstroConnectionException`. Point `baseUrl` at your own backend, as
  [Authentication](#authentication) describes; that also keeps your key out of the page.
- **Other HTTP packages:** the SDK works next to `dio`, `chopper`, `retrofit` and others. If a file
  imports two packages that both export a name such as `RequestOptions`, import this one with a
  prefix: `import 'package:lifeastroapi/lifeastroapi.dart' as astro;`.
- **Your own HTTP stack:** pass `httpClient:` to reuse a client with certificate pinning, a proxy,
  logging, or `cupertino_http` / `cronet_http`.

## Inputs

Methods take named parameters. Birth charts are passed as a `BirthInput`; the SDK sends them
under the wire names each endpoint expects (`date`, `birth.date`, `boy.date`, `personA.date`, ...).

| Input | Used by | Parameters |
|-------|---------|------------|
| **Moment** | `panchang.*`, `muhurta.*` (one date), `prashna.*`, `narrative.prashna` | `lat`, `lon`, `tz`, `date?`, `time?` |
| **Instant** | `transit.positions`, `transit.doubleTransit`, `meta.ayanamsas` | `date?`, `time?`, `tz?` |
| **Birth chart** | `chart.*`, `dasha.*`, `narrative.*`, `reports.*`, `western.natal.*` | `birth: BirthInput` |
| **Pair** | `milan.*`, `reports.matchMaking`, `narrative.milan` | `boy:`, `girl:` |
| **Western pair** | `western.synastry.*`, `western.composite.*`, `western.davison.*` | `personA:`, `personB:` |
| **Rashi** | `horoscope.*`, `reports.horoscope*` | `rashi`, `date?`, `lang?` |
| **Date range** | `eclipses.*`, `western.ingresses` | `startDate`, `endDate` |
| **Muhurta search** | `muhurta.bestTime` | `lat`, `lon`, `tz`, `startDate`, `endDate` |
| **Natal + window** | `transit.sadeSatiWindows`, `transit.windows` (`birth` optional) | `birth: NatalWindowBirth`, `from?`, `tz?` |
| **Natal + transit** | `transit.tarabala`, `transit.vedha`, `transit.smallPanoti`, `ashtakavarga.kaksha`, `ashtakavarga.transitScore`, `western.transits.toNatal`, `narrative.transitPhal`, `narrative.dashaPhal`, `narrative.transitDouble`, `narrative.sadeSati*` | `birth:`, `date`, `time`, `tz` |

**Dates.** The API needs a `date` on every moment endpoint. Where `date` is optional, the SDK sends
today's date in the `tz` you gave. Dart has no time zone database, so the SDK knows fixed offsets
(`+05:30`), `UTC`, and a built-in list of common zones with their daylight-saving rules (India,
the Gulf, South-East Asia, the US, Canada, Europe, Australia, New Zealand and more). For any other
zone it uses the UTC date; pass `date` yourself to be exact.

**Settings.** Vedic methods accept `ayanamsa: Ayanamsa.krishnamurti` (default Lahiri), and chart
methods `houseSystem: HouseSystem.placidus`.

**Personalised horoscopes** (`narrative.horoscopeDailyByLagna`, `...ByMoon`, `...Tamil`,
`horoscopeWeeklyBy...`) take the birth chart; pass `onDate: 'YYYY-MM-DD'` for a day other than today.

**Data endpoints** (`chart.kundliFacts`, `chart.yogas`, `chart.doshas`, `chart.sensitivity`,
`transit.sadeSatiWindows`, `transit.windows`, `remedies.forGraha`, `milan.overlay`, `milan.summary`)
return ids and numbers, no prose: planet ids `sun` ... `ketu`, `sign_index` 0-based (0 = Aries),
`house` 1-based whole-sign from the lagna, nakshatra index 0-based (0 = Ashwini), every instant as
`*_local` (RFC 3339) plus `*_jd` (Julian Day, UT), and a `skipped` object naming anything that could
not be computed.

```dart
final facts = await client.chart.kundliFacts(birth: arjun, include: 'all');
final sadeSati = await client.transit.sadeSatiWindows(birth: arjun, years: 30);
```

## Languages

Every Vedic method whose response carries names or text takes an optional `lang`. The same fields
come back in that language; ids, dates, numbers and explicit `*_en` / `*_hi` fields do not change.

```dart
final day = await client.panchang.basic(
  lat: 19.076, lon: 72.8777, tz: 'Asia/Kolkata', date: '2027-01-15',
  lang: Lang.gu,
);
// tithi, nakshatra, yoga, karana and vara names are in Gujarati

final chart = await client.chart.planets(birth: arjun, lang: Lang.bn);
```

| `Lang` | Language | Coverage |
|--------|----------|----------|
| `Lang.en` | English (default) | complete |
| `Lang.hi` | Hindi | complete |
| `Lang.mr` | Marathi | complete |
| `Lang.gu` | Gujarati | complete |
| `Lang.bn` | Bengali | complete |
| `Lang.te` | Telugu | complete |
| `Lang.ta` | Tamil | complete |
| `Lang.kn` | Kannada | complete |
| `Lang.ml` | Malayalam | complete |
| `Lang.pa` | Punjabi | complete |

The enum is called `Lang`, not `Locale`, so it does not clash with Flutter's `Locale`.
`Lang.fromCode('gu')` turns a code into a value.

- **Where it works:** `panchang`, `calendar`, `festivals`, `eclipses`, `planetMoments`, `transit`,
  `milan`, `muhurta`, `chart`, `prashna`, `numerology`, `dasha`, `varshaphal`, `ashtakavarga`,
  `lalkitab`, `horoscope`, `reports`, `narrative` and `remedies`. `festivals.*`, `panchang.monthly`
  and some `remedies.*` methods also keep the older `locale:` parameter; `lang` wins when both are
  given.
- **Methods without `lang`:** those that return only times, numbers or ids, such as
  `panchang.rahuKaal`, `panchang.sunriseSunset`, `chart.yogas`, `chart.doshas`, `transit.windows`
  and `milan.overlay`.
- **English only:** `western.*`, `tarot.*`, `geo.*` and `meta.*`. The `western.narrative.*`
  methods take `lang` for `en`, `hi` and `mr`.
- **Stable keys under a language.** Muhurta `factors[]` items carry an English `id` (`Tithi`,
  `RahuKaal`, ...) next to the localized `name`, so match on `id`.

## Groups

`client.<group>.<method>(...)`

| Group | What it covers |
|-------|----------------|
| `panchang` | tithi, nakshatra, yoga, karana, vara, sunrise/sunset, rahu kaal, choghadiya, hora, muhurtas, monthly calendar, composite `basic` / `advanced` |
| `chart` | planets, ascendant, houses, divisional (D1-D60), dignity, aspects, shadbala, ashtakvarga, avakhada, KP (sub lords, ruling planets, significators, 4-step chain); data bundles `kundliFacts`, `yogas`, `doshas`, `sensitivity` |
| `dasha` | Vimshottari (5 levels), Yogini, Chara |
| `milan` | Ashtakoota (total, full, per koota), mangal / nadi / shani dosha, navamsa and dasha compatibility, `overlay`, `summary` |
| `transit` | positions, sade sati, small panoti, tarabala, vedha, double transit, dated `sadeSatiWindows` and `windows` |
| `horoscope` | daily, weekly, monthly by rashi |
| `numerology` | driver, conductor, soul, personality, destiny, full, advanced, challenges, personal periods |
| `muhurta` | vivah, naamkaran, griha pravesh, vyapar, yatra, best time, chandra / tara bala |
| `varshaphal` | annual chart, lord, muntha, mudda dasha, harsha bala, tajika yogas |
| `prashna` | horary answer, chart, arudha, significators, KP horary (1-249) |
| `eclipses` | solar, lunar, all (date range; local contact times and sutak with a place) |
| `calendar` | Hindu month, ritu, samvatsara, adhik maas, solstices |
| `festivals` | festival calendar by month, on a date, vrat lists by year; location-aware |
| `planetMoments` | retrograde windows, ingress, combustion window, speed |
| `ashtakavarga` | sarva, bhinna, kaksha, transit score |
| `geo` | place search, reverse geocoding, time zone, place by id |
| `tarot` | cards, a card, daily card, spreads, yes/no |
| `reports` | JSON reports: kundli (lite, detailed, brihad), match making, mangal dosha, sade sati, varshaphal, numerology, dasha analysis, horoscopes |
| `narrative` | authored Vedic readings: lagna, planets, yogas, doshas, dasha phal, transit phal, prashna, horoscopes and more |
| `remedies` | remedies by id, `forGraha`, mantra / pooja / vrat / daan / rudraksha / yantra, Lal Kitab |
| `lalkitab` | Lal Kitab chart and dasha |
| `meta` | free catalogs: `endpoints` (credit cost of every route), `ayanamsas`, `vedicYogas`, `vedicDoshas`, `vedicLocales`, `version` |
| `western` | the tropical module (below) |

Each method's documentation gives the endpoint and what it returns; the credit cost of every route
is in `client.meta.endpoints()` and on [lifeastroapi.com](https://lifeastroapi.com/docs/).

### Western (tropical)

```dart
await client.western.natal.chart(birth: arjun, houseSystem: HouseSystem.placidus);
await client.western.synastry.score(personA: arjun, personB: asha);
await client.western.transits.toNatal(birth: arjun, date: '2026-06-16', time: '12:00', tz: 'UTC');
await client.western.returns.solar(birth: arjun, returnYear: 2026);
await client.western.profections.annual(birthDate: '1990-01-15', ascSign: 'capricorn');
```

Sub-groups: `natal`, `horoscope`, `synastry`, `composite`, `davison`, `transits`, `progressions`,
`solarArc`, `returns`, `dignities`, `profections`, `zodiacalReleasing`, `primaryDirections`,
`interpretation`, `narrative`, `heliocentric`, `astrocartography`, `eclipses`, `lunar`,
`compatibility`, plus `firdaria`, `ingresses` and `retrogradeWindow`.

## Error handling

Every non-2xx response throws a typed exception with the API's `code`, the HTTP `status` and the
`requestId`:

```dart
try {
  await client.chart.planets(birth: arjun);
} on PaymentRequiredException {
  // 402: out of credits
} on RateLimitException catch (e) {
  print('retry after ${e.retryAfter}');
} on LifeAstroException catch (e) {
  print('${e.status} ${e.code} ${e.message} ${e.requestId}');
}
```

| Exception | When |
|-----------|------|
| `BadRequestException` | 400: a parameter is missing, malformed or out of range |
| `AuthenticationException` | 401: missing or invalid key |
| `PaymentRequiredException` | 402: out of credits |
| `PermissionException` | 403: key not allowed (plan, IP allow-list) |
| `NotFoundException` | 404: unknown path or id |
| `RateLimitException` | 429: rate limit or daily quota; `retryAfter` |
| `ServerException` | 5xx |
| `LifeAstroConnectionException` | network failure, timeout (`code: 'timeout'`) or cancellation (`code: 'aborted'`) |

A response that is not JSON (an HTML page from a proxy or firewall in between, for example) throws
the exception of its status with code `non_json_response`; the message carries the HTTP status and
the start of the body.

All extend `LifeAstroException`. 429, 5xx and network errors are retried `maxRetries` times with
exponential backoff (honouring `Retry-After`) before they are thrown.

## Typing the response

Responses are the API's JSON, typed `dynamic` by default. Pass a type argument to narrow it:

```dart
final tithi = await client.panchang.tithi<Map<String, dynamic>>(
  lat: 28.61, lon: 77.2, tz: 'Asia/Kolkata',
);
print(tithi['name']);
```

## Escape hatch

Call any `/v1/*` endpoint, for example one newer than your SDK version:

```dart
final data = await client.request('/v1/panchang/tithi', query: {
  'lat': 28.61, 'lon': 77.2, 'tz': 'Asia/Kolkata', 'date': '2027-01-15',
});
// client.get(...) is an alias
```

## Per-call options

```dart
final cancel = Completer<void>();
final f = client.chart.planets(
  birth: arjun,
  options: RequestOptions(
    timeout: const Duration(seconds: 5),
    abortTrigger: cancel.future, // complete it to cancel the call
  ),
);
```

`RequestOptions(raw: true)` returns the body exactly as received; `RequestOptions(onResponse: ...)`
is the hook below, for one call.

## Credits, rate limit and request id

Every response carries your credit balance, your plan's rate limit and a request id in its
headers. `onResponse` hands them to you as a `ResponseInfo`, for every call (client parameter) or
for one call (`RequestOptions`):

```dart
final client = LifeAstro(
  apiKey: 'dv_live_...',
  onResponse: (info) {
    final credits = info.creditsRemaining;
    if (credits != null && credits < 5000) {
      print('LifeAstroAPI credits low: $credits');
    }
  },
);

await client.panchang.basic(
  lat: 19.076, lon: 72.8777, tz: 'Asia/Kolkata',
  options: RequestOptions(
    onResponse: (info) => print('${info.requestId} ${info.rateLimit?.remaining}'),
  ),
);
```

| Field | From header | Meaning |
|---|---|---|
| `status` | | HTTP status |
| `path` | | Endpoint path, e.g. `/v1/panchang/basic` |
| `requestId` | `X-Request-ID` | Quote it to support |
| `creditsRemaining` | `X-Credits-Remaining` | Balance after the call; unchanged after a failed call (failed calls are free). `null` on the free tier, whose allowance is daily/monthly rather than a balance |
| `rateLimit` | `X-RateLimit-*` | `RateLimit` with `limit`, `remaining` and `resetAt` (a UTC `DateTime`), per minute for your plan |
| `cache` | `X-Cache` | `HIT` when the API answered from its cache (billed the same) |
| `language` | `Content-Language` | Language of the answer |

A field is `null` when the API did not send its header. The hook runs once per call with the final
response, success or error (not for retried attempts or network failures); the client-level hook
runs first, then the per-call one. An error thrown inside it, or by the future of an `async` hook,
is ignored, so logging can never break a call. When your app calls through your own backend
(Flutter web, or to keep the key off the device), the fields are filled only if the backend passes
these headers on.

## Branded PDF reports

`package:lifeastroapi/pdf.dart` turns the JSON from `client.reports.*` into **branded,
print-ready reports**: cover page, charts, planet and dasha tables, narrative sections,
white-labelled with your logo, colours, footer and an optional watermark. The document is built
by this package, on your server or in your app: pass the report as the client returned it. Nothing
is sent to LifeAstroAPI to render, so your branding and your customers' reports stay with you.

### Two layers

| Layer | Functions | Runs on |
|-------|-----------|---------|
| **HTML** | `render*Html(data, branding)`, `a4PrintOptions` | Everywhere: Flutter (mobile, desktop, web), Dart servers. Pure Dart: no browser, process, file or network access. |
| **PDF** | `*Pdf(data, ...)`, `htmlToPdf(html, ...)` | A Chromium-based `PdfEngine`: local Chrome / Chromium / Edge, a remote Chrome, or a Gotenberg service. |

The HTML is the same document the Node SDK produces (the Dart templates are tested byte-for-byte
against it), so a report looks the same whichever SDK made it. Reports are printed by a browser
engine because Indic scripts need proper text shaping; Chromium shapes Devanagari, Gujarati,
Bengali, Gurmukhi, Tamil, Telugu, Kannada and Malayalam.

### Reports

| Report | API method | HTML | PDF |
|---|---|---|---|
| Kundli (lite) | `reports.kundliLite` | `renderKundliLiteHtml` | `kundliLitePdf` |
| Kundli (detailed) | `reports.kundliDetailed` | `renderKundliDetailedHtml` | `kundliDetailedPdf` |
| Brihad Kundli | `reports.kundliBrihad` | `renderKundliBrihadHtml` | `kundliBrihadPdf` |
| Match making | `reports.matchMaking` | `renderMatchMakingHtml` | `matchMakingPdf` |
| Mangal Dosha | `reports.mangalDosha` | `renderMangalDoshaHtml` | `mangalDoshaPdf` |
| Dasha analysis | `reports.dashaAnalysis` | `renderDashaAnalysisHtml` | `dashaAnalysisPdf` |
| Numerology | `reports.numerology` | `renderNumerologyHtml` | `numerologyPdf` |
| Sade Sati | `reports.sadeSati` | `renderSadeSatiHtml` | `sadeSatiPdf` |
| Varshaphal | `reports.varshaphal` | `renderVarshaphalHtml` | `varshaphalPdf` |
| Horoscope (daily / weekly / monthly) | `reports.horoscopeDaily` ... | `renderHoroscopeHtml` | `horoscopePdf` |

All render in the 10 languages `en`, `hi`, `mr`, `gu`, `bn`, `te`, `ta`, `kn`, `ml` and `pa`:
pass `lang` when you request the report. Pass `name` and `place` (`boyName`, `girlName`, ... for match making) so the
cover shows them.

### On a server or desktop (Chrome)

```dart
import 'package:lifeastroapi/lifeastroapi.dart';
import 'package:lifeastroapi/pdf.dart';

final report = await client.reports.kundliDetailed(
  birth: arjun, name: 'Arjun Mehta', place: 'Mumbai', lang: Lang.hi,
);

const branding = Branding(
  companyName: 'Acme Astro',
  logoUrl: 'https://cdn.example.com/logo.png', // or a data: URI
  primaryColor: '#6b21a8',
  secondaryColor: '#9333ea',
  footerText: '© Acme Astro',
  watermarkText: 'SAMPLE', // optional
);

// One call: launches headless Chrome, prints, closes it.
final pdf = await kundliDetailedPdf(report, branding: branding);
await File('kundli.pdf').writeAsBytes(pdf);

// On a server, launch once and reuse (concurrent calls are fine):
final engine = await ChromePdfEngine.launch();
final pdf2 = await kundliDetailedPdf(report, branding: branding, engine: engine);
final pdf3 = await htmlToPdf('<h1>Any HTML</h1>', engine: engine);
await engine.close(); // on shutdown
```

`ChromePdfEngine` drives Chrome, Chromium or Edge over the DevTools protocol (the way Puppeteer
does) with no extra Dart package and no Node. It looks for the browser in `LIFEASTRO_CHROME`,
`CHROME_PATH` and `PUPPETEER_EXECUTABLE_PATH`, then in the usual install locations (`PATH` on
Linux, Applications on macOS, Program Files on Windows); `executablePath:` overrides them all.
`ChromePdfEngine.connect(wsUrl)` uses a browser that is already running, for example a Chrome
container.

Each engine gets a temporary browser profile of its own, which `close()` deletes. The sandbox
stays on, except when running as root, where Chromium cannot start with it (`noSandbox:` decides
either way).

A Linux image with Chromium and the fonts for the Indic scripts:

```dockerfile
FROM dart:stable AS build
WORKDIR /app
COPY . .
RUN dart pub get && dart compile exe bin/server.dart -o /server

FROM debian:stable-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
      chromium fonts-noto-core fonts-noto-extra ca-certificates \
    && rm -rf /var/lib/apt/lists/*
COPY --from=build /server /server
CMD ["/server"]
```

Chromium is found there without configuration, and a container that runs as root needs no
`noSandbox:`.

### In a Flutter app

The HTML layer runs in the app. The report JSON comes from your own backend, so the API key never
ships in the app (see [Authentication](#authentication)). Ways to get a PDF:

1. **The platform's web view** prints the HTML, with no server involved. Any plugin that prints
   HTML with the system web view takes it; give it `a4PrintOptions` (A4 and the margins, in
   points), because some web views, iOS among them, ignore the CSS `@page` rule. With the
   `printing` and `pdf` packages:

   ```dart
   import 'package:lifeastroapi/pdf.dart';
   import 'package:pdf/pdf.dart';
   import 'package:printing/printing.dart';

   Future<void> shareKundli(Map<String, dynamic> report) async {
     final html = renderKundliLiteHtml(report);
     // printing marks convertHtml as deprecated; check that the platform has it.
     if (!(await Printing.info()).canConvertHtml) return;
     final m = a4PrintOptions.margins;
     // ignore: deprecated_member_use
     final bytes = await Printing.convertHtml(
       html: html,
       format: PdfPageFormat(a4PrintOptions.width, a4PrintOptions.height,
           marginTop: m.top, marginRight: m.right,
           marginBottom: m.bottom, marginLeft: m.left),
     );
     await Printing.sharePdf(bytes: bytes, filename: 'kundli.pdf');
   }
   ```

   The table of contents, running header and bookmarks of the Brihad Kundli are added by
   `kundliBrihadPdf`, through an engine.

2. **A Gotenberg service** you run (`docker run --rm -p 3000:3000 gotenberg/gotenberg:8`) gives PDF
   bytes on every platform, the web included (allow your origin with its CORS settings):

   ```dart
   final engine = GotenbergPdfEngine(Uri.parse('https://pdf.your-app.example'));
   final bytes = await kundliLitePdf(report, engine: engine);
   ```

On Flutter web you can also open the HTML in a new tab and let the user print it to PDF. A desktop
app can use `ChromePdfEngine` when the app may start processes (a sandboxed macOS app prints
through the web view or Gotenberg instead).

### Brihad Kundli

The large report (about 300 pages). `kundliBrihadPdf` renders it twice so the table of contents
shows the real page of every section, adds a running header and footer, and writes PDF bookmarks.
Short sections share a page, so two lines of the contents can show the same page. The plain
`renderKundliBrihadHtml` has no table of contents or running header.

Your `primaryColor` and `secondaryColor` colour the headings, banners, table heads, contents,
charts, header and footer. Without brand colours, or with the API's default pair, the report keeps
its saffron design. A `watermarkText` prints on every page, behind the content.

`kundliBrihadPdf` also takes your own `headerTemplate` and `footerTemplate`, or
`displayHeaderFooter: false`. It merges your margins side by side over its own (26 mm top, 16 mm
bottom). It is the slowest report to produce: on a busy server give it more time and run it in a
background job.

```dart
final brihad = await kundliBrihadPdf(report,
    options: const HtmlToPdfOptions(timeout: Duration(minutes: 2)));
```

### Branding

| Field | Effect |
|---|---|
| `companyName` | Shown on the cover (and in the Brihad running header), as written. |
| `logoUrl` | Cover logo: `http(s)`, `data:image/...` or a relative URL. `//host/logo.png` is fetched over https. |
| `primaryColor` / `secondaryColor` | Headings, table headers, accents, and the Brihad design. Hex, a CSS colour name, `rgb()` or `hsl()`. |
| `footerText` | Line printed at the bottom of every page, as written. |
| `watermarkText` | Optional diagonal watermark on every page, sized to stay on the page. |

The branding you pass wins over the branding stored on your account (embedded in the report
JSON), which falls back to neutral defaults; a blank field counts as not set. A colour too pale to
read prints as a darker shade of itself, and a word that is not a colour falls back to the default.
Text is escaped, and `logoUrl` is limited to `http(s)`, `data:image/...` and relative URLs. Chromium fetches
`logoUrl` while printing; if you accept logo URLs from your users, run the browser with restricted
network access.

### PDF options

`HtmlToPdfOptions` (all engines): `format` (`PaperFormat.a4` default, `a3`, `a5`, `letter`, `legal`,
`tabloid`), `landscape`, `printBackground` (default true), `margin: PdfMargin(top: '10mm', ...)`,
`scale`, `timeout`, `abortTrigger`, and `displayHeaderFooter` with `headerTemplate` /
`footerTemplate`.

| Option | With a report |
|---|---|
| `margin` | A side you set wins over the page's own CSS; the other sides keep it. No unit means px. |
| `format`, `landscape` | Set the paper, also over an `@page` size in your own HTML. `preferCssPageSize: true` keeps the CSS size. |
| `printBackground: false` | No backgrounds; text that was white on a colour prints dark. |
| `displayHeaderFooter` with `footerTemplate` | Your footer replaces the report's footer line. |

With default options the HTML is printed untouched.

`timeout` (30 seconds by default) is for loading the page; printing may take four times as long,
and a Gotenberg request gets five times `timeout` in all. Too slow throws a `TimeoutException`.
To cancel, complete the future you passed as `abortTrigger`: the call throws `PdfAbortedException`
and the engine stays usable.

```dart
final cancel = Completer<void>();
final pdf = kundliBrihadPdf(report,
    engine: engine, options: HtmlToPdfOptions(abortTrigger: cancel.future));
// cancel.complete();
```

### Fonts

The templates name the Noto Sans families and fall back to the system's fonts. The fonts must be
on the machine that prints.

| Prints on | Fonts for the Indic scripts |
|---|---|
| Debian, Ubuntu, Docker | `apt install fonts-noto-core fonts-noto-extra` |
| macOS | Built in. |
| Windows | Built in (Nirmala UI). |
| Android, iOS | The system's fonts for the Indian scripts. |
| Gotenberg | The fonts in its image: add Noto there if a script prints as boxes. |

### Troubleshooting

| Symptom | Fix |
|---|---|
| Indic text prints as boxes | The machine that prints has no font for that script: see [Fonts](#fonts). |
| `no Chrome, Chromium or Edge found` | Install one, or pass `executablePath:` / set `LIFEASTRO_CHROME` or `CHROME_PATH`. |
| `the browser exited with code ...` | The message ends with the browser's own log. In Docker use the image above. |
| `TimeoutException` | Raise `timeout`, and check that `logoUrl` answers. |
| No footer line on pages | The page footer needs Chromium 131 or newer. |
| Cover says "Subject" | Pass `name` (and `place`) when requesting the report. |

## Contributing

The 323 methods are generated from the endpoint manifest that the Node SDK also uses, so both SDKs
stay in step. The generator imports the Node SDK's `scripts/manifest.mjs` (endpoint list, method
names, `lang` rules) from a sibling checkout:

```bash
node tool/generate.mjs        # regenerates lib/src/resources/, tool/manifest.json, tool/src/dispatch.g.dart
dart analyze
dart test
```

Set `LIFEASTRO_NODE_SDK` if the Node SDK is not at `../lifeastroapi-node`.

The report templates are a port of the Node SDK's `src/pdf/templates`; `test/pdf_golden_test.dart`
checks the Dart HTML byte-for-byte against the Node output, and `test/pdf_options_test.dart` the
colour math and print CSS. After a template changes in Node,
run `node tool/pdf_goldens.mjs` to refresh the goldens, then update the Dart template until the test
passes (`node tool/ts_tables.mjs` copies label tables exactly). `test/pdf_deep_test.dart` also
checks 432 full reports when their shared reference is checked out (`LIFEASTRO_PDF_WORK`, default
`../LifeAstroAPI/pdf_work`), and is skipped otherwise. The browser tests (tag `chrome`) are skipped
without a browser. `dart test -p chrome test/pdf_js_test.dart test/pdf_html_test.dart
test/pdf_regressions_test.dart test/pdf_branding_test.dart` checks the HTML layer on the web.

Unit tests use a mock HTTP client, so they cannot tell whether the API really accepts a parameter.
The live sweep calls **every** method against a real server and lists each one the API rejects:

```bash
LIFEASTRO_API_KEY=dv_live_... dart run tool/live_sweep.dart                     # skips /v1/reports/
LIFEASTRO_API_URL=http://localhost:8080 LIFEASTRO_API_KEY=... dart run tool/live_sweep.dart
```

It spends credits on a real account (one request per endpoint).

## License

MIT © Ayanshu Life
