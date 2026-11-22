/// North-Indian (diamond) chart SVG. Port of the Node SDK's
/// src/pdf/templates/northIndianChart.ts (byte-identical output).
///
/// The North-Indian kundli is a fixed diamond: an outer square crossed by both
/// diagonals, with a rotated inner square joining the four edge-midpoints.
/// House 1 (lagna) is the top-centre cell; houses run anticlockwise. The sign
/// number printed in each cell is fixed by the lagna (house-1 sign), then +1
/// per house. Planets are drawn in their house.
library;

import '../js.dart';
import '../locales.dart';
import '../shared.dart';

/// One planet to place: short label + house (1..12) + optional flags.
class ChartPlanet {
  /// Creates a chart planet.
  const ChartPlanet({
    required this.label,
    required this.house,
    this.retro,
    this.color,
  });

  /// Short label, for example `Su` or `सू`.
  final String label;

  /// House 1..12, as given in the report JSON (compared as a JS number).
  final Object? house;

  /// Retrograde flag (not drawn differently).
  final Object? retro;

  /// Optional per-planet colour.
  final String? color;
}

/// House cell centres for a 100x100 viewBox. The same centre is used for the
/// sign number and the planets of a house.
const _houseXy = {
  1: [50, 25],
  2: [25, 8],
  3: [9, 25],
  4: [25, 50],
  5: [9, 75],
  6: [25, 92],
  7: [50, 75],
  8: [75, 92],
  9: [91, 75],
  10: [75, 50],
  11: [91, 25],
  12: [75, 8],
};

// One layout list per cell shape (`node tool/ts_tables.mjs
// templates/northIndianChart.ts CELL_LAYOUTS:_cellLayouts`): `upTo` planets are
// set in `size` type, in `rows` of [offset toward the middle of the chart,
// offset down, capacity], in fill order. Offsets are from _houseXy.
const _cellLayouts = {
  'diamond': [
    {
      'upTo': 3,
      'size': 4.6,
      'rows': [
        [
          0,
          1.5,
          3,
        ],
      ],
    },
    {
      'upTo': 9,
      'size': 3.6,
      'rows': [
        [
          0,
          1,
          5,
        ],
        [
          0,
          6,
          4,
        ],
      ],
    },
  ],
  'top': [
    {
      'upTo': 2,
      'size': 4,
      'rows': [
        [
          0.5,
          8.5,
          2,
        ],
      ],
    },
    {
      'upTo': 6,
      'size': 3.5,
      'rows': [
        [
          0.5,
          8,
          2,
        ],
        [
          0.5,
          -3,
          4,
        ],
      ],
    },
    {
      'upTo': 9,
      'size': 2.8,
      'rows': [
        [
          0.5,
          7.5,
          3,
        ],
        [
          0.5,
          -3.2,
          6,
        ],
      ],
    },
  ],
  'bottom': [
    {
      'upTo': 3,
      'size': 4,
      'rows': [
        [
          0.5,
          1.5,
          3,
        ],
      ],
    },
    {
      'upTo': 9,
      'size': 3.1,
      'rows': [
        [
          0.5,
          -1,
          4,
        ],
        [
          0.5,
          3.9,
          5,
        ],
      ],
    },
  ],
  'side': [
    {
      'upTo': 2,
      'size': 4,
      'rows': [
        [
          3,
          1.5,
          2,
        ],
      ],
    },
    {
      'upTo': 5,
      'size': 3.3,
      'rows': [
        [
          2.8,
          0.8,
          3,
        ],
        [
          0.7,
          5.6,
          2,
        ],
      ],
    },
    {
      'upTo': 9,
      'size': 2.8,
      'rows': [
        [
          3.2,
          0.2,
          4,
        ],
        [
          1.2,
          4.4,
          3,
        ],
        [
          -1,
          8.6,
          2,
        ],
      ],
    },
  ],
};

/// JS `cellShape`. Its comparisons are strict, so a house given as the string
/// '1' is a side cell.
String _cellShape(Object? house) {
  if (const [1, 4, 7, 10].contains(house)) return 'diamond';
  if (house == 2 || house == 12) return 'top';
  if (house == 6 || house == 8) return 'bottom';
  return 'side';
}

/// A coordinate with at most one decimal, so every language prints the same
/// digits.
String _svgNumber(num value) => jsNum(jsRound(value * 10) / 10);

/// Renders a North-Indian diamond chart as an inline SVG string.
///
/// [lagnaSignIndex] is the 0-based sign index of house 1 (Aries = 0).
String northIndianChartSvg({
  required int lagnaSignIndex,
  required List<ChartPlanet> planets,
  String? title,
  num? size,
  String? accent,
}) {
  final sz = size ?? 200;
  final acc = accent ?? '#e0701c';
  const signColor = '#5a5a5a';
  final lagna = ((lagnaSignIndex % 12) + 12) % 12;

  // Group planet labels by house (JS Map: first-seen order).
  final byHouse = <Object?, List<ChartPlanet>>{};
  for (final p in planets) {
    final h = jsNumber(p.house);
    if (h < 1 || h > 12) continue;
    (byHouse[p.house] ??= []).add(p);
  }

  // Frame: outer square + two diagonals + inner diamond (edge midpoints).
  final frame = '\n'
      '    <rect x="1" y="1" width="98" height="98" fill="none" stroke="$acc" stroke-width="0.8"/>\n'
      '    <line x1="1" y1="1" x2="99" y2="99" stroke="$acc" stroke-width="0.5"/>\n'
      '    <line x1="99" y1="1" x2="1" y2="99" stroke="$acc" stroke-width="0.5"/>\n'
      '    <polygon points="50,1 99,50 50,99 1,50" fill="none" stroke="$acc" stroke-width="0.5"/>';

  // Sign (rashi) number per house, just above the cell centre (below it for
  // the two top corner cells, whose centre is near the top edge).
  final signs = StringBuffer();
  for (var h = 1; h <= 12; h++) {
    final sign = ((lagna + h - 1) % 12) + 1;
    final pos = _houseXy[h];
    if (pos == null) continue;
    final cx = pos[0];
    final cy = pos[1];
    final num ny = cy < 12 ? cy + 2.5 : cy - 6;
    signs.write(
        '<text x="${jsNum(cx)}" y="${jsNum(ny)}" font-size="4.4" fill="$signColor" font-weight="600" text-anchor="middle" dominant-baseline="middle">$sign</text>');
  }

  // Planets per house, laid out for the shape of the cell and how many share
  // it. The sign number keeps its place and the rows go around it.
  final planetsSvg = StringBuffer();
  for (final entry in byHouse.entries) {
    final pos = _houseXy[_propertyIndex(entry.key)];
    if (pos == null) continue;
    final arr = entry.value;
    final cx = pos[0];
    final cy = pos[1];
    final inward = cx > 50 ? -1 : 1;
    final layouts = _cellLayouts[_cellShape(entry.key)]!;
    final layout = layouts.firstWhere((l) => arr.length <= (l['upTo'] as num),
        orElse: () => layouts.last);
    final rows = layout['rows'] as List<List<num>>;
    final size = jsNum(layout['size'] as num);
    var next = 0;
    for (var ri = 0; ri < rows.length; ri++) {
      final [dx, dy, capacity] = rows[ri];
      // More bodies than the layout holds (outer planets) share its last row.
      final end = ri == rows.length - 1 || next + capacity > arr.length
          ? arr.length
          : next + capacity.toInt();
      final row = arr.sublist(next, end);
      next = end;
      if (row.isEmpty) continue;
      final text = [
        for (final p in row)
          '<tspan fill="${p.color ?? '#1a2a6c'}">${esc(p.label)}</tspan>',
      ].join('<tspan> </tspan>');
      planetsSvg.write(
          '<text x="${_svgNumber(cx + inward * dx)}" y="${_svgNumber(cy + dy)}" font-size="$size" font-weight="bold" text-anchor="middle" dominant-baseline="middle">$text</text>');
    }
  }

  final titleHtml = truthy(title)
      ? '<div style="font-size:10pt;font-weight:700;color:$acc;margin-bottom:1.5mm;">${esc(title)}</div>'
      : '';

  return '''<div class="north-chart" style="display:inline-block;text-align:center;margin:2mm 3mm;">
$titleHtml
<svg viewBox="0 0 100 100" width="${jsNum(sz)}" height="${jsNum(sz)}" style="font-family:$indicFontStackAttr;">
$frame
$signs
$planetsSvg
</svg>
</div>''';
}

/// The integer index a JS object property lookup `obj[v]` resolves to, or
/// `null` when the key is not a canonical integer.
int? _propertyIndex(Object? v) {
  final s = jsStr(v);
  final i = int.tryParse(s);
  return i != null && '$i' == s ? i : null;
}

/// Short English planet labels for chart cells.
const planetLabelsEn = {
  'Sun': 'Su',
  'Moon': 'Mo',
  'Mars': 'Ma',
  'Mercury': 'Me',
  'Jupiter': 'Ju',
  'Venus': 'Ve',
  'Saturn': 'Sa',
  'Rahu': 'Ra',
  'Ketu': 'Ke',
  'Uranus': 'Ur',
  'Neptune': 'Ne',
  'Pluto': 'Pl',
};

const _planetLabelsHi = {
  'Sun': 'सू',
  'Moon': 'चं',
  'Mars': 'मं',
  'Mercury': 'बु',
  'Jupiter': 'गु',
  'Venus': 'शु',
  'Saturn': 'श',
  'Rahu': 'रा',
  'Ketu': 'के',
  'Uranus': 'यू',
  'Neptune': 'ने',
  'Pluto': 'प्लू',
};

const _planetLabelsTe = {
  'Sun': 'సూ',
  'Moon': 'చం',
  'Mars': 'కు',
  'Mercury': 'బు',
  'Jupiter': 'గు',
  'Venus': 'శు',
  'Saturn': 'శ',
  'Rahu': 'రా',
  'Ketu': 'కే',
  'Uranus': 'యు',
  'Neptune': 'నె',
  'Pluto': 'ప్లు',
};

const _planetLabelsTa = {
  'Sun': 'சூ',
  'Moon': 'சந்',
  'Mars': 'செ',
  'Mercury': 'பு',
  'Jupiter': 'கு',
  'Venus': 'சு',
  'Saturn': 'சனி',
  'Rahu': 'ரா',
  'Ketu': 'கே',
  'Uranus': 'யு',
  'Neptune': 'நெ',
  'Pluto': 'ப்ளு',
};

const _planetLabelsKn = {
  'Sun': 'ಸೂ',
  'Moon': 'ಚಂ',
  'Mars': 'ಮಂ',
  'Mercury': 'ಬು',
  'Jupiter': 'ಗು',
  'Venus': 'ಶು',
  'Saturn': 'ಶ',
  'Rahu': 'ರಾ',
  'Ketu': 'ಕೇ',
  'Uranus': 'ಯು',
  'Neptune': 'ನೆ',
  'Pluto': 'ಪ್ಲು',
};

const _planetLabelsMl = {
  'Sun': 'സൂ',
  'Moon': 'ച',
  'Mars': 'ചൊ',
  'Mercury': 'ബു',
  'Jupiter': 'വ്യാ',
  'Venus': 'ശു',
  'Saturn': 'ശ',
  'Rahu': 'രാ',
  'Ketu': 'കേ',
  'Uranus': 'യു',
  'Neptune': 'നെ',
  'Pluto': 'പ്ലൂ',
};

const _planetLabelsGu = {
  'Sun': 'સૂ',
  'Moon': 'ચં',
  'Mars': 'મં',
  'Mercury': 'બુ',
  'Jupiter': 'ગુ',
  'Venus': 'શુ',
  'Saturn': 'શ',
  'Rahu': 'રા',
  'Ketu': 'કે',
  'Uranus': 'યુ',
  'Neptune': 'ને',
  'Pluto': 'પ્લૂ',
};

const _planetLabelsBn = {
  'Sun': 'সূ',
  'Moon': 'চ',
  'Mars': 'ম',
  'Mercury': 'বু',
  'Jupiter': 'বৃ',
  'Venus': 'শু',
  'Saturn': 'শ',
  'Rahu': 'রা',
  'Ketu': 'কে',
  'Uranus': 'ইউ',
  'Neptune': 'নে',
  'Pluto': 'প্লু',
};

const _planetLabelsPa = {
  'Sun': 'ਸੂ',
  'Moon': 'ਚੰ',
  'Mars': 'ਮੰ',
  'Mercury': 'ਬੁ',
  'Jupiter': 'ਬ੍ਰ',
  'Venus': 'ਸ਼ੁ',
  'Saturn': 'ਸ਼',
  'Rahu': 'ਰਾ',
  'Ketu': 'ਕੇ',
  'Uranus': 'ਯੂ',
  'Neptune': 'ਨੇ',
  'Pluto': 'ਪ੍ਲੂ',
};

/// Per-planet colours of the chart-cell labels.
const planetColors = {
  'Sun': '#e05e18',
  'Moon': '#3a7bd5',
  'Mars': '#c0392b',
  'Mercury': '#27928a',
  'Jupiter': '#b8860b',
  'Venus': '#c026a0',
  'Saturn': '#2c3e50',
  'Rahu': '#6d4c41',
  'Ketu': '#00897b',
};

/// The chart-cell label table for a locale (English abbreviations by default).
Map<String, String> planetLabelsFor(String? locale) {
  switch (locale) {
    case 'hi':
    case 'mr':
      return _planetLabelsHi;
    case 'te':
      return _planetLabelsTe;
    case 'ta':
      return _planetLabelsTa;
    case 'kn':
      return _planetLabelsKn;
    case 'ml':
      return _planetLabelsMl;
    case 'gu':
      return _planetLabelsGu;
    case 'bn':
      return _planetLabelsBn;
    case 'pa':
      return _planetLabelsPa;
    default:
      return planetLabelsEn;
  }
}
