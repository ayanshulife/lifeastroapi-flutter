// Loose-to-typed conversions for the generated dispatch table, so sample
// inputs (and JSON) can use plain strings and numbers.
import 'package:lifeastroapi/lifeastroapi.dart';

String? asStr(Object? v) => v?.toString();

num? asNum(Object? v) => v is num ? v : (v == null ? null : num.parse('$v'));

int? asInt(Object? v) =>
    v is int ? v : (v == null ? null : num.parse('$v').toInt());

bool? asBool(Object? v) => v is bool ? v : (v == null ? null : '$v' == 'true');

Lang? asLang(Object? v) =>
    v is Lang ? v : (v == null ? null : Lang.fromCode('$v'));

Ayanamsa? asAyanamsa(Object? v) => v is Ayanamsa
    ? v
    : (v == null ? null : Ayanamsa.values.firstWhere((a) => a.wire == '$v'));

HouseSystem? asHouseSystem(Object? v) => v is HouseSystem
    ? v
    : (v == null ? null : HouseSystem.values.firstWhere((h) => h.wire == '$v'));

BirthInput? asBirth(Object? v) {
  if (v == null || v is BirthInput) return v as BirthInput?;
  final m = v as Map;
  return BirthInput(
    date: m['date'] as String,
    time: m['time'] as String,
    tz: m['tz'] as String,
    lat: asNum(m['lat'])!,
    lon: asNum(m['lon'])!,
  );
}

NatalWindowBirth? asWindowBirth(Object? v) {
  if (v == null || v is NatalWindowBirth) return v as NatalWindowBirth?;
  final m = v as Map;
  return NatalWindowBirth(
    date: m['date'] as String,
    time: m['time'] as String,
    tz: m['tz'] as String,
    lat: asNum(m['lat']),
    lon: asNum(m['lon']),
  );
}
