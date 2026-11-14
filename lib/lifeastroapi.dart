/// Official Dart and Flutter SDK for LifeAstroAPI: Vedic astrology and the
/// Hindu calendar (panchang, festivals, kundli, dasha, kundli matching,
/// muhurta, transits, numerology, Lal Kitab, remedies, readings, horoscopes,
/// JSON reports), plus Western astrology and tarot.
///
/// ```dart
/// final client = LifeAstro(apiKey: 'dv_live_...');
/// final day = await client.panchang.basic(
///   lat: 19.076, lon: 72.8777, tz: 'Asia/Kolkata', lang: Lang.gu,
/// );
/// ```
///
/// Docs: https://lifeastroapi.com/docs/
library;

export 'src/client.dart' show LifeAstro;
export 'src/errors.dart' hide errorFromResponse;
export 'src/resources/all.dart';
export 'src/transport.dart' show ClientCore, RequestOptions;
export 'src/types.dart';
export 'src/version.dart';
