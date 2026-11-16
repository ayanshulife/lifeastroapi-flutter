# Changelog

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
