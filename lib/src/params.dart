/// Query helpers used by the generated methods: skipping empty values, path
/// parameters, query encoding and the "today" default.
library;

/// Adds a query value only when it is meaningful (not null, not empty).
extension QueryPut on Map<String, Object?> {
  /// Sets [key] to [value] unless [value] is null or an empty string.
  void put(String key, Object? value) {
    if (value == null || value == '') return;
    this[key] = value;
  }
}

/// Substitutes `{name}` placeholders in [template], percent-encoding each value.
///
/// Throws [ArgumentError] when a value is empty.
String buildPath(String template, Map<String, Object?> values) {
  var path = template;
  values.forEach((name, value) {
    if (value == null || value == '') {
      throw ArgumentError.value(
          value, name, 'Missing required path parameter "$name" for $template');
    }
    path = path.replaceAll('{$name}', Uri.encodeComponent(value.toString()));
  });
  return path;
}

/// Encodes [params] as a query string with sorted keys, skipping empty values.
String encodeQuery(Map<String, Object?> params) {
  final keys = params.keys.toList()..sort();
  final parts = <String>[];
  for (final key in keys) {
    final value = params[key];
    if (value == null || value == '') continue;
    parts.add(
        '${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent(value.toString())}');
  }
  return parts.isEmpty ? '' : '?${parts.join('&')}';
}

/// Today's date (`YYYY-MM-DD`) in [tz].
///
/// The API has no "today" default (every moment endpoint rejects a request
/// without `date`), so the SDK supplies one. Dart has no time zone database,
/// so [tz] is resolved from a fixed offset (`+05:30`, `UTC`, `Etc/GMT-5`) or
/// a built-in table of common zones with their daylight-saving rules. For a
/// zone not in the table the UTC date is used, as the Node SDK does when it
/// cannot resolve a zone; pass `date` yourself to be exact.
String todayIn(String? tz, [DateTime? now]) {
  final utc = (now ?? DateTime.now()).toUtc();
  final offset = tz == null ? null : utcOffsetAt(tz, utc);
  final local = utc.add(offset ?? Duration.zero);
  String two(int n) => n.toString().padLeft(2, '0');
  return '${local.year.toString().padLeft(4, '0')}-${two(local.month)}-${two(local.day)}';
}

/// The UTC offset of [tz] at the instant [utc], or `null` if [tz] is unknown.
Duration? utcOffsetAt(String tz, DateTime utc) {
  final t = tz.trim();
  final fixed = _fixedOffset(t);
  if (fixed != null) return fixed;
  final zone = _zones[t];
  if (zone == null) return null;
  final std = zone.$1;
  final rule = zone.$2;
  final dst = rule != null && _inDst(rule, std, utc.toUtc());
  return Duration(minutes: std + (dst ? 60 : 0));
}

final _offsetRe = RegExp(r'^(?:UTC|GMT)?([+-])(\d{1,2})(?::?(\d{2}))?$');
final _etcRe = RegExp(r'^Etc/GMT([+-])(\d{1,2})$');
final _hoursRe = RegExp(r'^[+-]?\d{1,2}(?:\.\d+)?$');

Duration? _fixedOffset(String t) {
  const utcNames = {
    'UTC',
    'GMT',
    'Z',
    'Etc/UTC',
    'Etc/GMT',
    'Etc/Universal',
    'Etc/Zulu',
    'Universal',
    'Zulu',
  };
  if (utcNames.contains(t)) return Duration.zero;
  final m = _offsetRe.firstMatch(t);
  if (m != null) {
    final sign = m.group(1) == '-' ? -1 : 1;
    final minutes = int.parse(m.group(2)!) * 60 + int.parse(m.group(3) ?? '0');
    return Duration(minutes: sign * minutes);
  }
  final etc = _etcRe.firstMatch(t);
  if (etc != null) {
    // POSIX style: Etc/GMT-5 is five hours AHEAD of UTC.
    final sign = etc.group(1) == '-' ? 1 : -1;
    return Duration(hours: sign * int.parse(etc.group(2)!));
  }
  if (_hoursRe.hasMatch(t)) {
    return Duration(minutes: (double.parse(t) * 60).round());
  }
  return null;
}

enum _Rule { us, eu, au, nz }

DateTime _nthSunday(int year, int month, int n) {
  final first = DateTime.utc(year, month, 1);
  final delta = (DateTime.sunday - first.weekday) % 7;
  return DateTime.utc(year, month, 1 + delta + 7 * (n - 1));
}

DateTime _lastSunday(int year, int month) {
  final last = DateTime.utc(year, month + 1, 0);
  final delta = (last.weekday - DateTime.sunday) % 7;
  return DateTime.utc(year, month, last.day - delta);
}

/// Whether daylight saving is in effect at [utc] for a zone with standard
/// offset [std] (minutes) and [rule].
bool _inDst(_Rule rule, int std, DateTime utc) {
  final y = utc.year;
  // A local standard-time wall clock hour on a given day, as a UTC instant.
  DateTime at(DateTime day, int hour) =>
      day.add(Duration(hours: hour)).subtract(Duration(minutes: std));
  switch (rule) {
    case _Rule.us:
      // Second Sunday of March 02:00 to first Sunday of November 02:00 (daylight).
      final start = at(_nthSunday(y, 3, 2), 2);
      final end = at(_nthSunday(y, 11, 1), 1);
      return !utc.isBefore(start) && utc.isBefore(end);
    case _Rule.eu:
      // Last Sunday of March 01:00 UTC to last Sunday of October 01:00 UTC.
      final start = _lastSunday(y, 3).add(const Duration(hours: 1));
      final end = _lastSunday(y, 10).add(const Duration(hours: 1));
      return !utc.isBefore(start) && utc.isBefore(end);
    case _Rule.au:
      // First Sunday of October 02:00 to first Sunday of April 03:00 (daylight).
      final start = at(_nthSunday(y, 10, 1), 2);
      final end = at(_nthSunday(y, 4, 1), 2);
      return !utc.isBefore(start) || utc.isBefore(end);
    case _Rule.nz:
      // Last Sunday of September 02:00 to first Sunday of April 03:00 (daylight).
      final start = at(_lastSunday(y, 9), 2);
      final end = at(_nthSunday(y, 4, 1), 2);
      return !utc.isBefore(start) || utc.isBefore(end);
  }
}

/// Standard offset in minutes and daylight-saving rule of common zones.
const Map<String, (int, _Rule?)> _zones = {
  // South Asia and the Indian Ocean
  'Asia/Kolkata': (330, null),
  'Asia/Calcutta': (330, null),
  'Asia/Kathmandu': (345, null),
  'Asia/Katmandu': (345, null),
  'Asia/Colombo': (330, null),
  'Asia/Dhaka': (360, null),
  'Asia/Thimphu': (360, null),
  'Asia/Karachi': (300, null),
  'Asia/Kabul': (270, null),
  'Indian/Maldives': (300, null),
  'Indian/Mauritius': (240, null),
  // West and Central Asia
  'Asia/Tehran': (210, null),
  'Asia/Dubai': (240, null),
  'Asia/Muscat': (240, null),
  'Asia/Riyadh': (180, null),
  'Asia/Qatar': (180, null),
  'Asia/Bahrain': (180, null),
  'Asia/Kuwait': (180, null),
  'Asia/Baghdad': (180, null),
  'Asia/Tashkent': (300, null),
  'Asia/Almaty': (300, null),
  'Europe/Istanbul': (180, null),
  'Europe/Moscow': (180, null),
  // East and South-East Asia, Oceania without DST
  'Asia/Yangon': (390, null),
  'Asia/Rangoon': (390, null),
  'Asia/Bangkok': (420, null),
  'Asia/Jakarta': (420, null),
  'Asia/Ho_Chi_Minh': (420, null),
  'Asia/Singapore': (480, null),
  'Asia/Kuala_Lumpur': (480, null),
  'Asia/Manila': (480, null),
  'Asia/Shanghai': (480, null),
  'Asia/Hong_Kong': (480, null),
  'Asia/Taipei': (480, null),
  'Asia/Tokyo': (540, null),
  'Asia/Seoul': (540, null),
  'Australia/Brisbane': (600, null),
  'Australia/Perth': (480, null),
  'Australia/Darwin': (570, null),
  'Pacific/Fiji': (720, null),
  'Pacific/Honolulu': (-600, null),
  // Africa
  'Africa/Nairobi': (180, null),
  'Africa/Dar_es_Salaam': (180, null),
  'Africa/Kampala': (180, null),
  'Africa/Lagos': (60, null),
  'Africa/Johannesburg': (120, null),
  'Africa/Accra': (0, null),
  'Atlantic/Reykjavik': (0, null),
  // The Americas without DST
  'America/Phoenix': (-420, null),
  'America/Mexico_City': (-360, null),
  'America/Bogota': (-300, null),
  'America/Lima': (-300, null),
  'America/Jamaica': (-300, null),
  'America/Port_of_Spain': (-240, null),
  'America/Guyana': (-240, null),
  'America/Paramaribo': (-180, null),
  'America/Sao_Paulo': (-180, null),
  'America/Argentina/Buenos_Aires': (-180, null),
  // United States and Canada
  'America/New_York': (-300, _Rule.us),
  'America/Detroit': (-300, _Rule.us),
  'America/Toronto': (-300, _Rule.us),
  'America/Montreal': (-300, _Rule.us),
  'America/Chicago': (-360, _Rule.us),
  'America/Winnipeg': (-360, _Rule.us),
  'America/Denver': (-420, _Rule.us),
  'America/Edmonton': (-420, _Rule.us),
  'America/Los_Angeles': (-480, _Rule.us),
  'America/Vancouver': (-480, _Rule.us),
  'America/Anchorage': (-540, _Rule.us),
  'America/Halifax': (-240, _Rule.us),
  'America/St_Johns': (-210, _Rule.us),
  'US/Eastern': (-300, _Rule.us),
  'US/Central': (-360, _Rule.us),
  'US/Mountain': (-420, _Rule.us),
  'US/Pacific': (-480, _Rule.us),
  // Europe
  'Europe/London': (0, _Rule.eu),
  'Europe/Dublin': (0, _Rule.eu),
  'Europe/Lisbon': (0, _Rule.eu),
  'Atlantic/Canary': (0, _Rule.eu),
  'Europe/Paris': (60, _Rule.eu),
  'Europe/Berlin': (60, _Rule.eu),
  'Europe/Amsterdam': (60, _Rule.eu),
  'Europe/Brussels': (60, _Rule.eu),
  'Europe/Luxembourg': (60, _Rule.eu),
  'Europe/Madrid': (60, _Rule.eu),
  'Europe/Rome': (60, _Rule.eu),
  'Europe/Vienna': (60, _Rule.eu),
  'Europe/Zurich': (60, _Rule.eu),
  'Europe/Stockholm': (60, _Rule.eu),
  'Europe/Oslo': (60, _Rule.eu),
  'Europe/Copenhagen': (60, _Rule.eu),
  'Europe/Prague': (60, _Rule.eu),
  'Europe/Warsaw': (60, _Rule.eu),
  'Europe/Budapest': (60, _Rule.eu),
  'Europe/Belgrade': (60, _Rule.eu),
  'Europe/Zagreb': (60, _Rule.eu),
  'Europe/Malta': (60, _Rule.eu),
  'Europe/Athens': (120, _Rule.eu),
  'Europe/Helsinki': (120, _Rule.eu),
  'Europe/Kiev': (120, _Rule.eu),
  'Europe/Kyiv': (120, _Rule.eu),
  'Europe/Bucharest': (120, _Rule.eu),
  'Europe/Sofia': (120, _Rule.eu),
  'Europe/Riga': (120, _Rule.eu),
  'Europe/Tallinn': (120, _Rule.eu),
  'Europe/Vilnius': (120, _Rule.eu),
  'Asia/Nicosia': (120, _Rule.eu),
  // Australia (south-east) and New Zealand
  'Australia/Sydney': (600, _Rule.au),
  'Australia/Melbourne': (600, _Rule.au),
  'Australia/Canberra': (600, _Rule.au),
  'Australia/Hobart': (600, _Rule.au),
  'Australia/Adelaide': (570, _Rule.au),
  'Pacific/Auckland': (720, _Rule.nz),
};
