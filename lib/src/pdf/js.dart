/// JavaScript semantics used by the report templates.
///
/// The templates are a port of the Node SDK's TypeScript templates and must
/// produce byte-identical HTML (test/pdf_golden_test.dart). These helpers give
/// the few JS behaviours that differ from Dart: truthiness, `||`, `String(x)`
/// for numbers, `Math.round`, object key order, stable sort, and loose JSON
/// access.
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

/// JS `String(n)` for a number: `28.0` prints as `28`.
String jsNum(num n) {
  if (n is int) return n.toString();
  if (n.isNaN) return 'NaN';
  if (n.isInfinite) return n > 0 ? 'Infinity' : '-Infinity';
  if (n == n.truncateToDouble() && n.abs() < 1e21) {
    return n.toInt().toString();
  }
  return n.toString();
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

/// JS `Math.round`: halves round up (towards +infinity).
int jsRound(num x) => (x + 0.5).floor();

/// JS `n.toFixed(digits)`.
String toFixed(num n, int digits) => n.toStringAsFixed(digits);

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

/// Formats an ISO-8601 timestamp as `YYYY-MM-DD HH:MM UTC` (what the
/// templates' `formatGenerated` does with `new Date(iso)`). Returns the input
/// when it cannot be parsed, and `''` for an empty value.
String formatGenerated(Object? iso) {
  if (!truthy(iso)) return '';
  final s = jsStr(iso);
  // JS reads a date-only ISO string as UTC midnight; Dart would read local.
  final d = RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s)
      ? DateTime.tryParse('${s}T00:00:00Z')
      : DateTime.tryParse(s);
  if (d == null) return s;
  final u = d.toUtc();
  String p(int n) => n.toString().padLeft(2, '0');
  return '${u.year}-${p(u.month)}-${p(u.day)} ${p(u.hour)}:${p(u.minute)} UTC';
}

/// `String.replace(re, fn)` with a JS-style callback over the match groups.
String replaceAllJs(String s, RegExp re, String Function(Match m) replace) =>
    s.replaceAllMapped(re, replace);
