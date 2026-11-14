# lifeastroapi

Official **Dart and Flutter SDK** for [LifeAstroAPI](https://lifeastroapi.com), a REST
[astrology API](https://lifeastroapi.com/apis/) for Vedic astrology, panchang, Hindu festivals,
kundli, muhurat and Western charts, with location-aware calculations and pay-per-call billing.
Free tier: 1,500 credits a month, no card. [Get a key](https://lifeastroapi.com/signup/).

- **Every endpoint**: 322 methods in 23 groups: panchang, charts, dashas, matching, transits,
  horoscopes, numerology, Lal Kitab, remedies, muhurta, narrative readings, JSON reports, tarot and
  a complete Western (tropical) module.
- **Pure Dart**, one dependency (`http`): Flutter (Android, iOS, web, desktop) and Dart servers.
- **10 languages**: `lang: Lang.gu` on every Vedic method.
- Typed exceptions, automatic retries on 429/5xx with `Retry-After`, timeouts, cancellation, and a
  generic escape hatch for any endpoint.
- **Branded PDF reports**: turn report JSON into white-label kundli, matching, numerology and
  horoscope documents (HTML anywhere, PDF through Chrome or a Gotenberg service).

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
| `Lang.pa` | Punjabi | names and terms; longer prose is still English |

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
| `chart` | planets, ascendant, houses, divisional (D1-D60), dignity, aspects, shadbala, ashtakvarga, avakhada, KP; data bundles `kundliFacts`, `yogas`, `doshas`, `sensitivity` |
| `dasha` | Vimshottari (5 levels), Yogini, Chara |
| `milan` | Ashtakoota (total, full, per koota), mangal / nadi / shani dosha, navamsa and dasha compatibility, `overlay`, `summary` |
| `transit` | positions, sade sati, small panoti, tarabala, vedha, double transit, dated `sadeSatiWindows` and `windows` |
| `horoscope` | daily, weekly, monthly by rashi |
| `numerology` | driver, conductor, soul, personality, destiny, full, advanced, challenges, personal periods |
| `muhurta` | vivah, naamkaran, griha pravesh, vyapar, yatra, best time, chandra / tara bala |
| `varshaphal` | annual chart, lord, muntha, mudda dasha, harsha bala, tajika yogas |
| `prashna` | horary answer, chart, arudha, significators |
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

`RequestOptions(raw: true)` returns the body exactly as received.

## Branded PDF reports

`package:lifeastroapi/pdf.dart` turns the JSON from `client.reports.*` into **branded,
print-ready reports**: cover page, charts, planet and dasha tables, narrative sections,
white-labelled with your logo, colours, footer and an optional watermark. The API returns JSON
only; the document is built on your side, so your branding and your customers' reports stay with
you.

### Two layers

| Layer | Functions | Runs on |
|-------|-----------|---------|
| **HTML** | `render*Html(data, branding)` | Everywhere: Flutter (mobile, desktop, web), Dart servers. Pure Dart, no dependencies. |
| **PDF** | `*Pdf(data, ...)`, `htmlToPdf(html, ...)` | A Chromium-based `PdfEngine`: local Chrome / Chromium / Edge, a remote Chrome, or a Gotenberg service. |

The HTML is the same document the Node SDK produces (the Dart templates are tested byte-for-byte
against it), so a report looks the same whichever SDK made it. Reports are printed by a browser
engine because Indic scripts need proper text shaping; Chromium gets Devanagari, Gujarati,
Bengali, Tamil, Telugu, Kannada and Malayalam right.

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

All render in `en`, `hi`, `mr`, `gu`, `bn`, `te`, `ta`, `kn` and `ml`: pass `lang` when you
request the report. Pass `name` and `place` (`boyName`, `girlName`, ... for match making) so the
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

// On a server, launch once and reuse:
final engine = await ChromePdfEngine.launch(); // noSandbox: true in a root container
final pdf2 = await kundliDetailedPdf(report, branding: branding, engine: engine);
await engine.close(); // on shutdown
```

`ChromePdfEngine` drives Chrome, Chromium or Edge over the DevTools protocol (the way Puppeteer
does) with no extra Dart package and no Node. It finds the browser in the usual install
locations, or from `CHROME_PATH` / `executablePath:`. `ChromePdfEngine.connect(wsUrl)` uses a
browser that is already running, for example a Chrome container.

A minimal Linux image that renders every report, including Indic scripts:

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

with `ChromePdfEngine.launch(executablePath: '/usr/bin/chromium', noSandbox: true)` when the
container runs as root.

### In a Flutter app

The HTML layer runs in the app; the report JSON comes from your backend (see
[Authentication](#authentication)). Two ways to get a PDF:

1. **The `printing` package** (Android, iOS, macOS) prints the HTML with the platform's own web
   engine, so Indic text is shaped correctly, and opens the share / print sheet:

   ```dart
   import 'package:lifeastroapi/pdf.dart';
   import 'package:printing/printing.dart';

   final html = renderKundliLiteHtml(report, const Branding(companyName: 'Acme Astro'));
   await Printing.layoutPdf(
     onLayout: (format) => Printing.convertHtml(format: format, html: html),
   );
   ```

2. **A Gotenberg service** you run (`docker run --rm -p 3000:3000 gotenberg/gotenberg:8`) gives PDF
   bytes on every platform, the web included:

   ```dart
   final engine = GotenbergPdfEngine(Uri.parse('https://pdf.your-app.example'));
   final bytes = await kundliLitePdf(report, engine: engine);
   ```

On Flutter web you can also open the HTML in a new tab and let the user print it to PDF.

### Brihad Kundli

The large report (well over 100 pages). `kundliBrihadPdf` renders it twice so the table of
contents shows the real page of every section, adds a running header and footer, and writes PDF
bookmarks. It is the slowest report to produce: give it a generous `timeout` and run it in a
background job. The plain `renderKundliBrihadHtml` has no table of contents or running header.

### Branding

| Field | Effect |
|---|---|
| `companyName` | Shown on the cover (and in the Brihad running header). |
| `logoUrl` | Cover logo: `http(s)`, `data:image/...` or a relative URL. |
| `primaryColor` / `secondaryColor` | Headings, table headers, accents. |
| `footerText` | Line printed at the bottom of every page. |
| `watermarkText` | Optional diagonal watermark. |

The branding you pass wins over the branding stored on your account (embedded in the report
JSON), which falls back to neutral defaults. Colours are checked against a safe list, text is
escaped, and `logoUrl` is limited to `http(s)`, `data:image/...` and relative URLs. Chromium fetches
`logoUrl` while printing; if you accept logo URLs from your users, run the browser with restricted
network access.

### PDF options

`HtmlToPdfOptions` (all engines): `format` (`PaperFormat.a4` default, `a3`, `a5`, `letter`, `legal`,
`tabloid`), `landscape`, `printBackground` (default true), `margin: PdfMargin(top: '10mm', ...)`,
`scale`, `timeout`, and `displayHeaderFooter` with `headerTemplate` / `footerTemplate`.

### Fonts and troubleshooting

| Symptom | Fix |
|---|---|
| Indic text prints as boxes | The machine that prints has no font for that script. Debian/Ubuntu: `apt install fonts-noto-core fonts-noto-extra`. macOS and Windows already have them. |
| `no Chrome, Chromium or Edge found` | Install one, or pass `executablePath:` / set `CHROME_PATH`. |
| Chrome fails to start in Docker | Use `noSandbox: true` when running as root, and the image above. |
| No footer line on pages | The page footer needs Chromium 131 or newer. |
| Cover says "Subject" | Pass `name` (and `place`) when requesting the report. |

## Contributing

The 322 methods are generated from the endpoint manifest that the Node SDK also uses, so both SDKs
stay in step. The generator imports the Node SDK's `scripts/manifest.mjs` (endpoint list, method
names, `lang` rules) from a sibling checkout:

```bash
node tool/generate.mjs        # regenerates lib/src/resources/, tool/manifest.json, tool/src/dispatch.g.dart
dart analyze
dart test
```

Set `LIFEASTRO_NODE_SDK` if the Node SDK is not at `../lifeastroapi-node`.

The report templates are a port of the Node SDK's `src/pdf/templates`; `test/pdf_golden_test.dart`
checks the Dart HTML byte-for-byte against the Node output. After a template changes in Node,
run `node tool/pdf_goldens.mjs` to refresh the goldens, then update the Dart template until the test
passes (`node tool/ts_tables.mjs` copies label tables exactly).

Unit tests use a mock HTTP client, so they cannot tell whether the API really accepts a parameter.
The live sweep calls **every** method against a real server and lists each one the API rejects:

```bash
LIFEASTRO_API_KEY=dv_live_... dart run tool/live_sweep.dart                     # skips /v1/reports/
LIFEASTRO_API_URL=http://localhost:8080 LIFEASTRO_API_KEY=... dart run tool/live_sweep.dart
```

It spends credits on a real account (one request per endpoint).

## License

MIT © Ayanshu Life
