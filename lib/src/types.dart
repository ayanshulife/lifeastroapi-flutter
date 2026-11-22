/// Input types shared by the generated methods.
library;

/// Response language, passed as `lang` on Vedic methods.
///
/// Named `Lang` (not `Locale`) so it does not clash with Flutter's `Locale`.
///
/// - Complete: [en], [hi], [mr], [te], [ta], [kn], [ml], [gu], [bn], [pa]. Names,
///   terms and prose all come back in the language.
///
/// Ids, dates, numbers and explicit `*_en` / `*_hi` fields stay the same in
/// every language. Western, tarot, geo and meta methods answer in English
/// (the Western narrative methods also in [hi] and [mr]).
enum Lang {
  /// English (default).
  en,

  /// Hindi.
  hi,

  /// Marathi.
  mr,

  /// Telugu.
  te,

  /// Tamil.
  ta,

  /// Kannada.
  kn,

  /// Malayalam.
  ml,

  /// Gujarati.
  gu,

  /// Bengali.
  bn,

  /// Punjabi.
  pa;

  /// The code sent to the API, for example `gu`.
  String get code => name;

  /// The [Lang] for [code] (`'hi'`, `'GU'`), or `null` if it is not one.
  static Lang? fromCode(String code) {
    final c = code.trim().toLowerCase();
    for (final l in Lang.values) {
      if (l.name == c) return l;
    }
    return null;
  }
}

/// Sidereal ayanamsa systems.
enum Ayanamsa {
  /// Lahiri (Chitrapaksha), the API default.
  lahiri('lahiri'),

  /// Krishnamurti (KP).
  krishnamurti('krishnamurti'),

  /// B. V. Raman.
  raman('raman'),

  /// Fagan-Bradley.
  fagan('fagan'),

  /// Sri Yukteshwar.
  yukteshwar('yukteshwar'),

  /// True Chitrapaksha.
  trueChitrapaksha('true_chitrapaksha');

  const Ayanamsa(this.wire);

  /// The value sent to the API.
  final String wire;
}

/// House systems.
enum HouseSystem {
  /// Whole sign.
  wholeSign('whole-sign'),

  /// Equal.
  equal('equal'),

  /// Placidus.
  placidus('placidus'),

  /// Koch.
  koch('koch'),

  /// Porphyry.
  porphyry('porphyry'),

  /// Campanus.
  campanus('campanus'),

  /// Regiomontanus.
  regiomontanus('regiomontanus');

  const HouseSystem(this.wire);

  /// The value sent to the API.
  final String wire;
}

/// A birth moment whose place is optional.
///
/// Used by the window methods (`transit.sadeSatiWindows`, `transit.windows`):
/// date, time and tz give the natal Moon; [lat] and [lon] add the
/// lagna-based fields. A [BirthInput] can be passed wherever this is asked for.
class NatalWindowBirth {
  /// Creates a birth moment; [lat] and [lon] are optional.
  const NatalWindowBirth({
    required this.date,
    required this.time,
    required this.tz,
    this.lat,
    this.lon,
  });

  /// ISO date, `YYYY-MM-DD`.
  final String date;

  /// 24-hour time, `HH:MM`.
  final String time;

  /// IANA name (`Asia/Kolkata`) or fixed offset (`+05:30`).
  final String tz;

  /// Latitude in decimal degrees, north positive.
  final num? lat;

  /// Longitude in decimal degrees, east positive.
  final num? lon;
}

/// A birth (or event) moment with its place.
///
/// The SDK sends it under the wire names each endpoint expects: unprefixed
/// (`date`, `lat`, ...) for a chart, `birth.*` for the natal chart of
/// transit-style methods, `boy.*` / `girl.*` for matching, and
/// `personA.*` / `personB.*` for Western pairs.
///
/// ```dart
/// const arjun = BirthInput(
///   date: '1990-01-15', time: '10:30', tz: 'Asia/Kolkata',
///   lat: 19.076, lon: 72.8777,
/// );
/// ```
class BirthInput extends NatalWindowBirth {
  /// Creates a birth moment with its place.
  const BirthInput({
    required super.date,
    required super.time,
    required super.tz,
    required num super.lat,
    required num super.lon,
  });

  /// Latitude in decimal degrees, north positive.
  @override
  num get lat => super.lat!;

  /// Longitude in decimal degrees, east positive.
  @override
  num get lon => super.lon!;

  /// A copy with the given fields replaced.
  BirthInput copyWith(
      {String? date, String? time, String? tz, num? lat, num? lon}) {
    return BirthInput(
      date: date ?? this.date,
      time: time ?? this.time,
      tz: tz ?? this.tz,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
    );
  }
}
