/// JavaScript semantics used by the report templates.
///
/// The templates are a port of the Node SDK's TypeScript templates and must
/// produce byte-identical HTML (test/pdf_golden_test.dart). These helpers give
/// the JS behaviours that differ from Dart: truthiness, `||`, `String(x)`,
/// `Number(x)`, `toFixed`, `trim`, `new Date(iso)`, object key order, stable
/// sort, and loose JSON access.
///
/// Dart's [RegExp] follows JavaScript (ASCII `\d`, `\w` and `\b`, Unicode
/// `\s`), but [String.trim] does not: use [jsTrim].
library;

/// JS truthiness: `null`, `false`, `0`, `NaN` and `''` are falsy.
bool truthy(Object? v) {
  if (v == null || v == false) return false;
  if (v is num) return v != 0 && !v.isNaN;
  if (v is String) return v.isNotEmpty;
  return true;
}

/// JS `a || b`.
T? jsOr<T>(T? a, T? b) => truthy(a) ? a : b;

const _maxExactInt = 9007199254740992; // 2^53

/// JS `String(n)` for a number: `28.0` prints as `28`, `-0.0` as `0`, and an
/// integer beyond 2^53 as the double JS reads from that JSON.
String jsNum(num n) {
  if (n == 0) return '0'; // before `is int`: on the web -0.0 is an int too
  if (n is int && n >= -_maxExactInt && n <= _maxExactInt) return '$n';
  final d = n.toDouble();
  // Dart prints a double like JS does, apart from the `.0` of whole numbers.
  final s = '$d';
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}

/// JS `String(v)` (and template-literal `${v}`).
///
/// `null` prints as `undefined`, because a missing JSON field is `undefined`
/// in JS; pass [nullAs] when the original printed an explicit `null`.
String jsStr(Object? v, {String nullAs = 'undefined'}) {
  if (v == null) return nullAs;
  if (v is String) return v;
  if (v is num) return jsNum(v);
  if (v is bool) return v ? 'true' : 'false';
  if (v is List) {
    return v.map((e) => e == null ? '' : jsStr(e)).join(',');
  }
  if (v is Map) return '[object Object]';
  return v.toString();
}

/// JS `n.toFixed(digits)`: no sign for a negative zero.
String toFixed(num n, int digits) =>
    (n == 0 ? 0.0 : n.toDouble()).toStringAsFixed(digits);

// What JS `trim` strips: WhiteSpace and LineTerminator. Dart's `trim` also
// strips U+0085.
bool _isJsSpace(int c) =>
    c == 0x20 ||
    (c >= 0x09 && c <= 0x0d) ||
    c == 0xa0 ||
    c == 0x1680 ||
    (c >= 0x2000 && c <= 0x200a) ||
    c == 0x2028 ||
    c == 0x2029 ||
    c == 0x202f ||
    c == 0x205f ||
    c == 0x3000 ||
    c == 0xfeff;

/// JS `s.trim()`.
String jsTrim(String s) {
  var start = 0;
  var end = s.length;
  while (start < end && _isJsSpace(s.codeUnitAt(start))) {
    start++;
  }
  while (end > start && _isJsSpace(s.codeUnitAt(end - 1))) {
    end--;
  }
  return s.substring(start, end);
}

/// JS `Math.round`: a half rounds up, towards +infinity.
double jsRound(num x) {
  // Not (x + 0.5).floor(): that sum already rounds 0.49999999999999994 up.
  final floor = x.floorToDouble();
  return x - floor >= 0.5 ? floor + 1 : floor;
}

/// JS `Object.keys` order: integer-like keys first (ascending), then the rest
/// in insertion order.
List<String> jsKeys(Map<Object?, Object?> m) {
  final ints = <String>[];
  final rest = <String>[];
  for (final k in m.keys) {
    final s = '$k';
    if (RegExp(r'^(0|[1-9]\d{0,8})$').hasMatch(s)) {
      ints.add(s);
    } else {
      rest.add(s);
    }
  }
  ints.sort((a, b) => int.parse(a).compareTo(int.parse(b)));
  return [...ints, ...rest];
}

/// A stable sort (JS `Array.prototype.sort` is stable; Dart's is not).
List<T> stableSorted<T>(Iterable<T> items, int Function(T a, T b) compare) {
  final indexed = items.toList().asMap().entries.toList();
  indexed.sort((a, b) {
    final c = compare(a.value, b.value);
    return c != 0 ? c : a.key.compareTo(b.key);
  });
  return [for (final e in indexed) e.value];
}

final _decimalRe = RegExp(r'^[+-]?(\d+\.?\d*|\.\d+)([eE][+-]?\d+)?$');
final _radixRe = RegExp(r'^0(?:[xX]([0-9a-fA-F]+)|[oO]([0-7]+)|[bB]([01]+))$');

/// JS `Number(v)`, the coercion behind `h > 0` and `total >= 24` as well.
/// `null` is JSON's null, so it gives 0.
double jsNumber(Object? v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  if (v is bool) return v ? 1 : 0;
  if (v is List) return jsNumber(jsStr(v));
  if (v is! String) return double.nan;
  final s = jsTrim(v);
  if (s.isEmpty) return 0;
  if (_decimalRe.hasMatch(s)) return double.parse(s);
  final m = _radixRe.firstMatch(s);
  if (m != null) {
    final group = m[1] != null ? 1 : (m[2] != null ? 2 : 3);
    final radix = const [16, 8, 2][group - 1];
    return BigInt.parse(m[group]!, radix: radix).toDouble();
  }
  if (s == 'Infinity' || s == '+Infinity') return double.infinity;
  if (s == '-Infinity') return double.negativeInfinity;
  return double.nan;
}

/// The value as a JSON object, or an empty map.
Map<String, Object?> asMap(Object? v) {
  if (v is Map<String, Object?>) return v;
  if (v is Map) return v.map((k, val) => MapEntry('$k', val));
  return const {};
}

/// The value as a JSON object, or `null` when it is not one.
Map<String, Object?>? asMapOrNull(Object? v) => v is Map ? asMap(v) : null;

/// The value as a JSON array, or an empty list.
List<Object?> asList(Object? v) => v is List ? v : const [];

/// The value when it is a string, else `null`.
String? asStr(Object? v) => v is String ? v : null;

/// The value when it is a number, else `null`.
num? asNum(Object? v) => v is num ? v : null;

/// JS `Array.isArray(v) && v.length > 0`.
bool nonEmptyList(Object? v) => v is List && v.isNotEmpty;

final _isoDateRe = RegExp(r'^(\d{4}|[+-]\d{6})(?:-(\d{2})(?:-(\d{2}))?)?'
    r'(?:[Tt ](\d{2}):(\d{2})(?::(\d{2})(?:\.\d+)?)?)?'
    r'([Zz]|[+-]\d{2}:?\d{2})?$');

/// JS `new Date(v)` for an ISO-8601 string or epoch milliseconds, in UTC;
/// `null` for an invalid date. As in JS, a date without a time is UTC
/// midnight, a time without a zone is local, 30 February rolls over and
/// month 13 is invalid.
DateTime? jsDate(Object? v) {
  if (v is num) {
    return v.abs() <= 8640000000000000
        ? DateTime.fromMillisecondsSinceEpoch(v.toInt(), isUtc: true)
        : null;
  }
  if (v is! String) return null;
  final m = _isoDateRe.firstMatch(v);
  if (m == null) return null;
  int part(int group, int absent) =>
      m[group] == null ? absent : int.parse(m[group]!);
  final year = int.parse(m[1]!);
  final month = part(2, 1);
  final day = part(3, 1);
  final hour = part(4, 0);
  final minute = part(5, 0);
  final second = part(6, 0);
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  if (minute > 59 || second > 59) return null;
  if (hour > 24 || (hour == 24 && minute + second > 0)) return null;
  final zone = m[7];
  if (zone == null && m[4] != null) {
    return DateTime(year, month, day, hour, minute, second).toUtc();
  }
  var offset = 0;
  if (zone != null && zone.length > 1) {
    final digits = zone.substring(1).replaceAll(':', '');
    final h = int.parse(digits.substring(0, 2));
    final min = int.parse(digits.substring(2));
    if (h > 23 || min > 59) return null;
    offset = (h * 60 + min) * (zone.startsWith('-') ? -1 : 1);
  }
  return DateTime.utc(year, month, day, hour, minute - offset, second);
}

final _timestampWithoutZoneRe =
    RegExp(r'^\d{4}-\d{2}-\d{2}[Tt ]\d{2}:\d{2}(?::\d{2}(?:\.\d+)?)?$');

/// The templates' `parseTimestamp`: an ISO timestamp without a zone (a `T`, a
/// `t` or a space before the time) is UTC, so the output does not depend on
/// the machine's zone.
DateTime? parseTimestamp(Object? v) =>
    jsDate(v is String && _timestampWithoutZoneRe.hasMatch(v)
        ? '${v.replaceFirst(RegExp('[t ]'), 'T')}Z'
        : v);

/// `YYYY-MM-DD HH:MM UTC` from an ISO-8601 timestamp (the templates'
/// `formatGenerated`). Returns the input when it is not a date, and `''` for
/// an empty value. The process locale and time zone play no part: a timestamp
/// without a zone is UTC ([parseTimestamp]).
String formatGenerated(Object? iso) {
  if (!truthy(iso)) return '';
  final u = parseTimestamp(iso);
  if (u == null) return jsStr(iso);
  String p(int n) => n.toString().padLeft(2, '0');
  return '${u.year}-${p(u.month)}-${p(u.day)} ${p(u.hour)}:${p(u.minute)} UTC';
}

/// `String.replace(re, fn)` with a JS-style callback over the match groups.
String replaceAllJs(String s, RegExp re, String Function(Match m) replace) =>
    s.replaceAllMapped(re, replace);
