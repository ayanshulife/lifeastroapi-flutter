# Changelog

## Unreleased

- PDF reports: the report HTML now asks for exact print colours (`print-color-adjust: exact`), so the coloured table headers and cards print on iOS and Android through the `printing` package as they do in Chromium. Same change as the Node SDK 0.9.1; the Dart and Node HTML stay byte-for-byte identical.
- New optional parameters the API already reads (same additions as the Node SDK): `purpose`, `topN`, `birthDate` and `ayanamsa` on `muhurta.bestTime`; `at` on `dasha.charCurrent` and `lalkitab.dashaCurrent`; `week` on `reports.horoscopeWeekly`; `ayanamsa` on `calendar.*` and `planetMoments.ingress` / `combustionWindow`; Western `orb*` overrides, `rulership`, `houseSystem` for pairs, `compositeMethod`, and `relocateLat` / `relocateLon` on returns.

## 0.1.0 — 2026-11-14

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
