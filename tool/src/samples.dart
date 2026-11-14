// Sample inputs for every SDK method, shared by tool/live_sweep.dart and the
// unit tests. Ported from the Node SDK's scripts/live-sweep.mjs (same values,
// Dart parameter names).
import 'dart:convert';
import 'dart:io';

import 'package:lifeastroapi/lifeastroapi.dart';

/// Neutral sample person (Arjun Mehta, Mumbai).
const a = BirthInput(
    date: '1990-01-15',
    time: '10:30',
    tz: 'Asia/Kolkata',
    lat: 19.076,
    lon: 72.8777);

/// Second sample chart (Delhi).
const b = BirthInput(
    date: '1992-06-20',
    time: '14:15',
    tz: 'Asia/Kolkata',
    lat: 28.6139,
    lon: 77.209);

const _now = {
  'lat': 19.076,
  'lon': 72.8777,
  'tz': 'Asia/Kolkata',
  'date': '2026-11-20',
  'time': '12:00',
};

/// Sample input for each base shape.
Map<String, Object?> shapeInput(String shape) {
  switch (shape) {
    case 'moment':
      return {..._now};
    case 'birth':
    case 'birthPrefixed':
    case 'westernNatal':
      return {'birth': a};
    case 'boygirl':
      return {'boy': a, 'girl': b};
    case 'twoPerson':
      return {'personA': a, 'personB': b};
    case 'rashi':
      return {'rashi': 'Aries'};
    case 'numerology':
      return {'name': 'Arjun Mehta', 'dob': '1990-01-15'};
    case 'dateRange':
      return {'startDate': '2026-01-01', 'endDate': '2027-12-31'};
    case 'westernMoment':
      return {'date': _now['date'], 'time': _now['time'], 'tz': _now['tz']};
    case 'muhurta':
      return {
        'lat': _now['lat'],
        'lon': _now['lon'],
        'tz': _now['tz'],
        'startDate': '2026-11-01',
        'endDate': '2026-11-30',
      };
    case 'natalTransit':
    case 'natalTransitPlace':
      return {
        'birth': a,
        'date': _now['date'],
        'time': _now['time'],
        'tz': _now['tz'],
      };
    case 'natalWindow':
    case 'natalWindowOptional':
      return {'birth': a, 'from': _now['date'], 'tz': _now['tz']};
    // Deliberately empty: exercises the SDK's "today" + UTC defaults.
    case 'instant':
    case 'none':
    case 'custom':
      return {};
  }
  throw ArgumentError('unknown shape $shape');
}

/// Sample values for required extras, keyed by wire name.
const wire = <String, Object>{
  'age_in_years': 35.5,
  'asc_sign': 'leo',
  'asc_lon': 123.4,
  'aspect': 'trine',
  'kind': 'trine',
  'birth_date': '1990-01-15',
  'birth_nak': 7,
  'birth_moon_sign': 3,
  'cusp': 7,
  'date': '2026-11-20',
  'time': '12:00',
  'tz': 'Asia/Kolkata',
  'decan': 2,
  'degree': 100,
  'dob': '1990-01-15',
  'start_date': '2026-01-01',
  'end_date': '2027-12-31',
  'from': '2026-06-01T00:00:00Z',
  'to': '2027-01-01T00:00:00Z',
  'house': 5,
  'lat': 19.076,
  'lon': 72.8777,
  'lord': 'Jupiter',
  'lot_sign': 'cancer',
  'maha': 'Jupiter',
  'month': 11,
  'name': 'Arjun Mehta',
  'natal_planet': 'Sun',
  'transit_planet': 'Saturn',
  'observer_lat': 28.6139,
  'observer_lon': 77.209,
  'planet': 'Jupiter',
  'planet_a': 'Sun',
  'planet_b': 'Moon',
  'q': 'Mumbai',
  'return_year': 2026,
  'sign': 'Leo',
  'sign_a': 'Aries',
  'sign_b': 'Leo',
  'type': 'three',
  'week': '2026-W47',
  'week_start': '2026-11-16',
  'year': 2026,
  'year_month': '2026-11',
};

/// Sample values for path parameters, keyed by name.
const pathSample = <String, Object>{
  'md': 'Jupiter',
  'ad': 'Saturn',
  'pd': 'Mercury',
  'sd': 'Ketu',
  'component': 'sthana',
  'house': '8',
  'koota': 'nadi',
  'n': 5,
  'name': 'Jupiter',
  'number': 1,
  'planet': 'Jupiter',
  'star': 'Regulus',
  'varga': 'D9',
};

/// Per-path corrections where a generic sample is wrong for that endpoint.
const perPath = <String, Map<String, Object>>{
  '/v1/dasha/char/{md}': {'md': 'leo'},
  '/v1/dasha/char/{md}/{ad}': {'md': 'leo', 'ad': 'scorpio'},
  '/v1/dasha/yogini/{name}': {'name': 'mangala'},
  '/v1/western/natal/planet/{name}': {'name': 'Venus'},
  '/v1/western/natal/lot/{name}': {'name': 'fortune'},
  '/v1/western/natal/fixed-stars/{name}': {'name': 'Regulus'},
  '/v1/western/retrograde-window/{planet}': {'planet': 'Mercury'},
  '/v1/vedic/remedies/lal-kitab/{planet}/{house}': {
    'planet': 'saturn',
    'house': '8'
  },
  '/v1/geo/place/{id}': {'id': '1275339'},
  '/v1/vedic/narrative/yoga/{id}': {'id': 'hamsa'},
  '/v1/vedic/narrative/dosha/{id}': {'id': 'mangal_dosha'},
  '/v1/vedic/remedies/{id}': {'id': 'hanuman_chalisa'},
  '/v1/vedic/remedies/mantra/{id}': {'id': 'hanuman_chalisa'},
  '/v1/vedic/remedies/daan/{id}': {'id': 'sadesati_setting_shanti'},
  '/v1/vedic/remedies/vrat/{id}': {'id': 'kaalsarp_dosha_shanti'},
  '/v1/vedic/remedies/pooja/{id}': {'id': 'jupiter_dasha_shanti'},
  '/v1/vedic/remedies/yantra/{id}': {'id': 'vedic.L1.remedy.yantra.jupiter'},
  '/v1/vedic/remedies/rudraksha/{id}': {
    'id': 'vedic.L1.remedy.rudraksha.jupiter'
  },
  '/v1/tarot/card/{id}': {'id': '5'},
  // `type` is a vrat family here (the generic sample is a tarot spread).
  '/v1/festivals/vrat': {'type': 'ekadashi'},
  '/v1/vedic/narrative/prashna': {'topic': 'career'},
  '/v1/transit/windows': {'planet': 'saturn'},
  '/v1/vedic/remedies/for-graha': {'graha': 'saturn', 'reason': 'debilitated'},
  '/v1/milan/dasha-sync': {
    'marriageWindows': true,
    'from': '2026-11-20',
    'years': 3
  },
  '/v1/horoscope/monthly': {'month': '2026-11'},
  '/v1/reports/horoscope/monthly': {'month': '2026-11'},
  '/v1/western/dignities/receptions': {
    'sun': 294.78,
    'moon': 152.4,
    'venus': 300.1,
    'mars': 250.2
  },
  '/v1/muhurta/naamkaran': {'birthDate': '2026-11-05'},
  '/v1/western/transits/calendar': {'from': '2026-11-01', 'to': '2026-11-20'},
  '/v1/western/transits/exact': {
    'from': '2026-01-01T00:00:00Z',
    'to': '2027-01-01T00:00:00Z'
  },
  '/v1/vedic/narrative/reference/{family}': {'family': 'yoga'},
  '/v1/chart/ashtakvarga/{planet}': {'planet': 'Jupiter'},
};

/// One method of tool/manifest.json.
class Endpoint {
  Endpoint(this.json);
  final Map<String, Object?> json;

  String get key => json['key'] as String;
  String get ns => json['ns'] as String;
  String get method => json['method'] as String;
  String get path => json['path'] as String;
  String get shape => json['shape'] as String;
  List<Map<String, Object?>> get params =>
      (json['params'] as List).cast<Map<String, Object?>>();

  bool hasParam(String name) => params.any((p) => p['name'] == name);
}

/// Loads tool/manifest.json (path relative to the package root).
List<Endpoint> loadManifest([String path = 'tool/manifest.json']) {
  final list = jsonDecode(File(path).readAsStringSync()) as List;
  return [for (final e in list) Endpoint(e as Map<String, Object?>)];
}

/// A sample input for [e], and the required parameters that have no sample.
({Map<String, Object?> input, List<String> missing}) buildInput(Endpoint e) {
  final input = shapeInput(e.shape);
  final missing = <String>[];
  for (final p in e.params) {
    final name = p['name'] as String;
    final required = p['required'] as bool;
    switch (p['source']) {
      case 'path':
        final v = pathSample[name];
        if (v != null) input[name] = v;
      case 'group':
        if (required) input[name] = name == 'girl' ? b : a;
      case 'extra':
        if (!required) break;
        final wires = (p['wires'] as List).cast<String>();
        final v = wire[wires.first];
        if (v != null) input[name] = v;
    }
  }
  input.addAll(perPath[e.path] ?? const {});
  for (final p in e.params) {
    final name = p['name'] as String;
    if (p['required'] == true && input[name] == null) missing.add(name);
  }
  return (input: input, missing: missing);
}
