# Changelog

## 1.0.0 — 2026-11-27

This is the first stable release. From 1.0.0 on, a change that needs a code change on your side
only comes with a new major version.

New:

- The API key is trimmed of spaces and line breaks around it, so a key read from a file or a
  quoted `.env` value works as it is. A key that is only whitespace is reported as missing.
- A reply that is not JSON did not come from the API: a proxy, firewall or CDN in between
  answered, usually with an HTML page. It now throws the exception of its HTTP status with code
  `non_json_response`; the message gives the status and the start of the body.
- README: the `non_json_response` error.

Changes that may need a code change:

- A 200 reply with a body that is not JSON now throws instead of returning the text.
  Before: the call returned the body as a `String`.
  Now: `on LifeAstroException catch (e) { if (e.code == 'non_json_response') { /* ... */ } }`
- **Breaking:** `numerology.full` requires `dob`. The API always required it; a call without it
  no longer compiles.
  Before: `client.numerology.full(name: 'Arjun Mehta')` compiled and the API answered 400.
  Now: `client.numerology.full(dob: '1990-01-15', name: 'Arjun Mehta')`

## 0.3.0 — 2026-11-22

**Breaking:** a class of your own that `implements HtmlToPdfOptions` must now use
`extends HtmlToPdfOptions`. Code that only creates or passes the options needs no change.

Punjabi:

- Punjabi (`Lang.pa`) is now a complete language, in the PDF reports too: all 10 reports print
  Gurmukhi labels, text, chart labels, table of contents and bookmarks.

Branding:

- The Brihad Kundli follows your brand colours, or the report's: headings, banners, table heads,
  contents, charts, header and footer. The API's default colours keep the saffron design.
- The Brihad Kundli prints `watermarkText` on every page, behind the content. In every report a
  long watermark is sized to stay on the page.
- A colour too pale to read prints as a darker shade of itself, and a word that is not a colour
  falls back to the default. The footer line follows the same rule.
- Company and footer text print as you wrote them, dashes included. A `//host/logo.png` logo is
  fetched over https, and a logo URL is never reworded.

Print options:

- `margin` (side by side), `format`, `landscape` and `printBackground: false` now work on the
  report templates. A `footerTemplate` with `displayHeaderFooter` replaces the report's footer
  line.
- Note for your own HTML given to `htmlToPdf`: a margin side you set, `landscape` and a `format`
  other than A4 now win over its `@page` rule. Pass `preferCssPageSize: true` to keep its page
  size.
- `kundliBrihadPdf` takes your `headerTemplate`, `footerTemplate` and `displayHeaderFooter: false`,
  and merges your margins side by side over its own.

PDF reports, what you will see after upgrading:

- The English and Malayalam Brihad Kundli print at full size. A wide friendship table made Chrome
  shrink the whole report to about 92%, so their text is now larger and the two reports are about
  10% longer.
- Brihad Kundli pages: Part 1 starts after the contents with its charts and planet table on one
  page, a section's last few lines or rows no longer get a page of their own, very short sections
  share a page, and the contents take fewer pages.
- The Brihad gem note in English, Hindi and Marathi no longer refers the reader to an astrologer.
- English Brihad tables print words where they showed API codes such as `TempFriend` and
  `graha_shanti`.
- Mangal Dosha without a dosha no longer shows a house row that holds only a dash.
- Marathi Brihad charts show all nine planets: Mars, Jupiter, Saturn, Rahu and Ketu were missing
  in the Navamsa and the other divisional charts.
- Numerology prints the person's name, and each label sits above its own value.
- Varshaphal prints the solar return in readable form: in the time zone of the birth when the
  report carries `SolarReturnLocal`, else as `2027-01-15 16:39 UTC` instead of a raw timestamp.
- Match making says 36 guna (not 8) in Hindi, Marathi, Gujarati, Bengali and Punjabi, and the max
  and score headings line up with their numbers.
- Headings no longer leave cut-off glyph tops at the foot of a page, and stay with the text that
  follows. Page counts change.
- North Indian charts lay out 1 to 9 planets by the shape of the cell, inside it and clear of the
  sign number, in every script. Long dasha level names no longer touch the lord's name.
- Gujarati, Bengali and Punjabi text is no longer letter-spaced.
- Brihad Kundli PDF: the running header and footer use a sans-serif face, Malayalam bookmarks show
  in Malayalam script, the document title is kept, and the page-locator tokens (`⟦T0⟧`, ...) are
  gone from the PDF's text.
- A timestamp without a zone, such as `2027-01-15T16:39:17` or `2027-01-15 16:39`, is read as UTC
  whatever the machine's time zone. A `Locale` that is not a language, such as `toString`, renders
  as English.
- A lone value where a list is expected prints as it is in the KP significators and Raj yoga planets
  (it printed nothing), and a malformed one no longer prints `[object Object]` in Sade Sati.
- A null item in a list of rows is left out of every report (it printed an empty row or block).
- Two Brihad sections now HTML-escape their values. The HTML carries no CSS comments.
- Reports with long texts render much faster (a Tamil Brihad Kundli's HTML is 10 times faster or
  more in compiled Dart).
- The HTML is byte-identical to the Node.js SDK 0.14.0 templates, checked on 432 full reports (12
  report endpoints, all 10 languages, with and without branding), on servers and on the web.

PDF engines:

- New `a4PrintOptions`: the A4 page and the reports' margins in points, for print APIs of web
  views.
- New `HtmlToPdfOptions.abortTrigger` cancels a PDF (`PdfAbortedException`); the engine stays
  usable. `ChromePdfEngine.launch` takes `abortTrigger` too, and `connect` takes a `timeout`.
- `ChromePdfEngine`: every DevTools call has a timeout, a launch that fails leaves no temporary
  profile behind, and a browser that is missing or cannot start gives an error that says what to
  install. `noSandbox` now defaults to true only when running as root; pass `false` to keep the
  sandbox there.
- `GotenbergPdfEngine`: the deadline (five times `timeout`) covers the download too, and an answer
  that is not a PDF is an error.

## 0.2.0 — 2026-11-15

- New `prashna.kpHorary(number: 23, lat: ..., lon: ..., tz: ..., date: ..., time: ...)`: the KP
  horary chart for a number from 1 to 249, cast for the moment and place of judgement. Returns the
  horary ascendant (the first degree of that number's part), the 12 Placidus cusps with star, sub
  and sub-sub lords and significators, the planets with KP lords and houses, planet significators,
  the KP 4-step chain and the ruling planets. Uses the Krishnamurti ayanamsa unless `ayanamsa` is
  sent. 30 credits. Same method as the Node.js SDK 0.13.0.
- `chart.kpSublord` now also returns the KP ruling planets (`ruling_planets`), and
  `chart.kpHouseSignificator` returns each cusp's significator planets, the houses every planet
  signifies and the 4-step chain (new fields from the API; nothing removed).
- `chart.kpSublord`'s `planet` and `chart.kpHouseSignificator`'s `cusp` are now optional. The API
  never read them: it always returns every planet and all 12 cusps. Code that passes them keeps
  working.
- 323 methods (322 endpoints).

## 0.1.0 — 2026-11-15

First release of the official Dart and Flutter SDK.

- `LifeAstro` client with all 322 methods of the Node SDK 0.8.0, in the same 23 groups and with the same method names (`client.panchang.basic`, `client.chart.planets`, `client.milan.ashtakoota`, `client.narrative.lagna`, `client.western.natal.chart`, ...). Generated from the same endpoint manifest as the Node SDK.
- Named parameters; birth charts are passed as `BirthInput` and sent under the wire names each endpoint expects (`date`, `birth.date`, `boy.date`, `personA.date`).
- `lang:` on every Vedic method that answers in a language: `en`, `hi`, `mr`, `gu`, `bn`, `te`, `ta`, `kn`, `ml` complete, `pa` names and terms (`Lang` enum, named so it does not clash with Flutter's `Locale`). `Ayanamsa` and `HouseSystem` enums.
- Bearer auth, `LIFEASTRO_API_KEY` from the environment on native platforms, configurable `baseUrl` (a local server or your own backend), timeout, cancellation (`RequestOptions.abortTrigger`), automatic retries with backoff on 429/5xx/network errors honouring `Retry-After`.
- Typed exceptions: `LifeAstroException` with `status`, `code`, `message`, `requestId`; `BadRequestException`, `AuthenticationException`, `PaymentRequiredException`, `PermissionException`, `NotFoundException`, `RateLimitException`, `ServerException`, `LifeAstroConnectionException`.
- Moment endpoints get today's date in the given time zone when `date` is omitted (fixed offsets plus a built-in table of common zones with daylight saving).
- `client.request(path, query: ...)` escape hatch for any `/v1/*` endpoint.
- Branded PDF reports (`package:lifeastroapi/pdf.dart`): `render*Html` for all 10 reports (Kundli lite / detailed / Brihad, match making, mangal dosha, dasha analysis, numerology, sade sati, varshaphal, horoscope) in 9 languages, byte-identical to the Node SDK's HTML; `*Pdf` helpers and `htmlToPdf` through `ChromePdfEngine` (local or remote Chrome, Chromium or Edge, no extra dependency) or `GotenbergPdfEngine` (any platform). `kundliBrihadPdf` adds a table of contents with real page numbers, a running header and footer, and PDF bookmarks.
- `tool/live_sweep.dart` calls every method against a real server.
- New `onResponse` hook, as a client parameter and per call (`RequestOptions(onResponse: ...)`): receives a `ResponseInfo` with the request id, `creditsRemaining`, the rate limit (`RateLimit` with `limit`, `remaining` and a UTC `resetAt`), the cache result and the answer's language for every call, success or error. Exported `ResponseInfo`, `RateLimit` and `ResponseHook`. See "Credits, rate limit and request id" in the README. Same as the Node SDK 0.10.0 `onResponse`.
- PDF reports: the report HTML now asks for exact print colours (`print-color-adjust: exact`), so the coloured table headers and cards print on iOS and Android through the `printing` package as they do in Chromium. Same change as the Node SDK 0.9.1; the Dart and Node HTML stay byte-for-byte identical.
- New optional parameters the API already reads (same additions as the Node SDK): `purpose`, `topN`, `birthDate` and `ayanamsa` on `muhurta.bestTime`; `at` on `dasha.charCurrent` and `lalkitab.dashaCurrent`; `week` on `reports.horoscopeWeekly`; `ayanamsa` on `calendar.*` and `planetMoments.ingress` / `combustionWindow`; Western `orb*` overrides, `rulership`, `houseSystem` for pairs, `compositeMethod`, and `relocateLat` / `relocateLon` on returns.
