/// Colour math for branded reports: read a CSS colour and keep it readable on
/// paper. Port of the Node SDK's src/pdf/colors.ts: whole numbers where it
/// prints, so every SDK prints the same bytes.
library;

import 'dart:math' as math;

import 'js.dart';

/// Red, green and blue, 0 to 255.
typedef Rgb = (int, int, int);

// The CSS named colours, by lower-case name (`node tool/ts_tables.mjs
// colors.ts NAMED_COLORS:_namedColors`).
const _namedColors = {
  'aliceblue': 'f0f8ff',
  'antiquewhite': 'faebd7',
  'aqua': '00ffff',
  'aquamarine': '7fffd4',
  'azure': 'f0ffff',
  'beige': 'f5f5dc',
  'bisque': 'ffe4c4',
  'black': '000000',
  'blanchedalmond': 'ffebcd',
  'blue': '0000ff',
  'blueviolet': '8a2be2',
  'brown': 'a52a2a',
  'burlywood': 'deb887',
  'cadetblue': '5f9ea0',
  'chartreuse': '7fff00',
  'chocolate': 'd2691e',
  'coral': 'ff7f50',
  'cornflowerblue': '6495ed',
  'cornsilk': 'fff8dc',
  'crimson': 'dc143c',
  'cyan': '00ffff',
  'darkblue': '00008b',
  'darkcyan': '008b8b',
  'darkgoldenrod': 'b8860b',
  'darkgray': 'a9a9a9',
  'darkgreen': '006400',
  'darkgrey': 'a9a9a9',
  'darkkhaki': 'bdb76b',
  'darkmagenta': '8b008b',
  'darkolivegreen': '556b2f',
  'darkorange': 'ff8c00',
  'darkorchid': '9932cc',
  'darkred': '8b0000',
  'darksalmon': 'e9967a',
  'darkseagreen': '8fbc8f',
  'darkslateblue': '483d8b',
  'darkslategray': '2f4f4f',
  'darkslategrey': '2f4f4f',
  'darkturquoise': '00ced1',
  'darkviolet': '9400d3',
  'deeppink': 'ff1493',
  'deepskyblue': '00bfff',
  'dimgray': '696969',
  'dimgrey': '696969',
  'dodgerblue': '1e90ff',
  'firebrick': 'b22222',
  'floralwhite': 'fffaf0',
  'forestgreen': '228b22',
  'fuchsia': 'ff00ff',
  'gainsboro': 'dcdcdc',
  'ghostwhite': 'f8f8ff',
  'gold': 'ffd700',
  'goldenrod': 'daa520',
  'gray': '808080',
  'green': '008000',
  'greenyellow': 'adff2f',
  'grey': '808080',
  'honeydew': 'f0fff0',
  'hotpink': 'ff69b4',
  'indianred': 'cd5c5c',
  'indigo': '4b0082',
  'ivory': 'fffff0',
  'khaki': 'f0e68c',
  'lavender': 'e6e6fa',
  'lavenderblush': 'fff0f5',
  'lawngreen': '7cfc00',
  'lemonchiffon': 'fffacd',
  'lightblue': 'add8e6',
  'lightcoral': 'f08080',
  'lightcyan': 'e0ffff',
  'lightgoldenrodyellow': 'fafad2',
  'lightgray': 'd3d3d3',
  'lightgreen': '90ee90',
  'lightgrey': 'd3d3d3',
  'lightpink': 'ffb6c1',
  'lightsalmon': 'ffa07a',
  'lightseagreen': '20b2aa',
  'lightskyblue': '87cefa',
  'lightslategray': '778899',
  'lightslategrey': '778899',
  'lightsteelblue': 'b0c4de',
  'lightyellow': 'ffffe0',
  'lime': '00ff00',
  'limegreen': '32cd32',
  'linen': 'faf0e6',
  'magenta': 'ff00ff',
  'maroon': '800000',
  'mediumaquamarine': '66cdaa',
  'mediumblue': '0000cd',
  'mediumorchid': 'ba55d3',
  'mediumpurple': '9370db',
  'mediumseagreen': '3cb371',
  'mediumslateblue': '7b68ee',
  'mediumspringgreen': '00fa9a',
  'mediumturquoise': '48d1cc',
  'mediumvioletred': 'c71585',
  'midnightblue': '191970',
  'mintcream': 'f5fffa',
  'mistyrose': 'ffe4e1',
  'moccasin': 'ffe4b5',
  'navajowhite': 'ffdead',
  'navy': '000080',
  'oldlace': 'fdf5e6',
  'olive': '808000',
  'olivedrab': '6b8e23',
  'orange': 'ffa500',
  'orangered': 'ff4500',
  'orchid': 'da70d6',
  'palegoldenrod': 'eee8aa',
  'palegreen': '98fb98',
  'paleturquoise': 'afeeee',
  'palevioletred': 'db7093',
  'papayawhip': 'ffefd5',
  'peachpuff': 'ffdab9',
  'peru': 'cd853f',
  'pink': 'ffc0cb',
  'plum': 'dda0dd',
  'powderblue': 'b0e0e6',
  'purple': '800080',
  'rebeccapurple': '663399',
  'red': 'ff0000',
  'rosybrown': 'bc8f8f',
  'royalblue': '4169e1',
  'saddlebrown': '8b4513',
  'salmon': 'fa8072',
  'sandybrown': 'f4a460',
  'seagreen': '2e8b57',
  'seashell': 'fff5ee',
  'sienna': 'a0522d',
  'silver': 'c0c0c0',
  'skyblue': '87ceeb',
  'slateblue': '6a5acd',
  'slategray': '708090',
  'slategrey': '708090',
  'snow': 'fffafa',
  'springgreen': '00ff7f',
  'steelblue': '4682b4',
  'tan': 'd2b48c',
  'teal': '008080',
  'thistle': 'd8bfd8',
  'tomato': 'ff6347',
  'turquoise': '40e0d0',
  'violet': 'ee82ee',
  'wheat': 'f5deb3',
  'white': 'ffffff',
  'whitesmoke': 'f5f5f5',
  'yellow': 'ffff00',
  'yellowgreen': '9acd32',
};

final _hexColorRe =
    RegExp(r'^#([0-9a-fA-F]{3,4}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$');
final _colorFunctionRe = RegExp(
    r'^(rgb|rgba|hsl|hsla)\(\s*([0-9.]+%?)(?:\s*,\s*|\s+)([0-9.]+%?)(?:\s*,\s*|\s+)([0-9.]+%?)(?:\s*[,/]\s*([0-9.]+%?))?\s*\)$');
final _cssNumberRe = RegExp(r'^([0-9]+(?:\.[0-9]+)?|\.[0-9]+)%?$');
final _nameRe = RegExp(r'^[a-zA-Z]+$');

// Longer than any real colour (UTF-16 units); also keeps the patterns fast.
const _maxColorLength = 64;

/// A number or percentage of a colour function as a fraction of [full], held
/// to 0..1.
double _fraction(String value, int full) {
  final percent = value.endsWith('%');
  final n = jsNumber(percent ? value.substring(0, value.length - 1) : value);
  return math.min(1.0, n / (percent ? 100 : full));
}

Rgb _hslToRgb(double hue, double saturation, double lightness) {
  final spread = saturation * math.min(lightness, 1 - lightness);
  int channel(int n) {
    final k = (n + (hue % 360) / 30) % 12;
    return jsRound(255 *
            (lightness -
                spread * math.max(-1.0, math.min(math.min(k - 3, 9 - k), 1.0))))
        .toInt();
  }

  return (channel(0), channel(8), channel(4));
}

Rgb _fromHex(String h) => (
      int.parse(h.substring(0, 2), radix: 16),
      int.parse(h.substring(2, 4), radix: 16),
      int.parse(h.substring(4, 6), radix: 16),
    );

/// Reads a CSS colour (hex, name, rgb / hsl) as it looks on white paper.
/// `null` for anything that is not a colour a printer can show: an unknown
/// word, a keyword such as `inherit`, a fully transparent colour.
Rgb? parseColor(String? value) {
  if (value == null) return null;
  final v = jsTrim(value);
  if (v.isEmpty || v.length > _maxColorLength) return null;
  Rgb rgb;
  var alpha = 1.0;
  final hex = _hexColorRe.firstMatch(v);
  if (hex != null) {
    var h = hex[1]!;
    if (h.length <= 4) h = h.split('').map((digit) => '$digit$digit').join();
    rgb = _fromHex(h);
    if (h.length == 8) alpha = int.parse(h.substring(6, 8), radix: 16) / 255;
  } else if (_nameRe.hasMatch(v)) {
    // ASCII letters only, so lower case does not depend on the culture.
    final named = _namedColors[v.toLowerCase()];
    if (named == null) return null;
    rgb = _fromHex(named);
  } else {
    final m = _colorFunctionRe.firstMatch(v);
    if (m == null) return null;
    final (a, b, c, d) = (m[2]!, m[3]!, m[4]!, m[5]);
    for (final part in [a, b, c, if (d != null) d]) {
      if (!_cssNumberRe.hasMatch(part)) return null;
    }
    if (m[1]!.startsWith('rgb')) {
      rgb = (
        jsRound(255 * _fraction(a, 255)).toInt(),
        jsRound(255 * _fraction(b, 255)).toInt(),
        jsRound(255 * _fraction(c, 255)).toInt(),
      );
    } else {
      if (a.endsWith('%') || !b.endsWith('%') || !c.endsWith('%')) return null;
      rgb = _hslToRgb(jsNumber(a), _fraction(b, 100), _fraction(c, 100));
    }
    if (d != null) alpha = _fraction(d, 1);
  }
  if (alpha == 0) return null;
  int onWhite(int c) =>
      alpha == 1 ? c : jsRound(255 - (255 - c) * alpha).toInt();
  return (onWhite(rgb.$1), onWhite(rgb.$2), onWhite(rgb.$3));
}

/// WCAG contrast against white: 1 (white) to 21 (black).
double contrastOnWhite(Rgb rgb) {
  double linear(int c) {
    final x = c / 255;
    return x <= 0.04045
        ? x / 12.92
        : math.pow((x + 0.055) / 1.055, 2.4).toDouble();
  }

  final luminance = 0.2126 * linear(rgb.$1) +
      0.7152 * linear(rgb.$2) +
      0.0722 * linear(rgb.$3);
  return 1.05 / (luminance + 0.05);
}

/// The same hue, darkened in 1% steps only as far as [minContrast] against
/// white needs.
Rgb darkenToContrast(Rgb rgb, num minContrast) {
  for (var percent = 100; percent > 0; percent--) {
    int scale(int c) => c * percent ~/ 100;
    final next = (scale(rgb.$1), scale(rgb.$2), scale(rgb.$3));
    if (contrastOnWhite(next) >= minContrast) return next;
  }
  return (0, 0, 0);
}

/// [percent] of the colour mixed into white.
Rgb tintOnWhite(Rgb rgb, int percent) {
  int mix(int c) => (255 * (100 - percent) + c * percent + 50) ~/ 100;
  return (mix(rgb.$1), mix(rgb.$2), mix(rgb.$3));
}

/// `#rrggbb`.
String toHex(Rgb rgb) {
  String two(int c) => c.toRadixString(16).padLeft(2, '0');
  return '#${two(rgb.$1)}${two(rgb.$2)}${two(rgb.$3)}';
}

/// A light fill as a see-through colour that looks the same on white paper,
/// so a watermark behind it still shows. White itself becomes `transparent`.
String seeThrough(Rgb rgb) {
  final int lowest = math.min(math.min(rgb.$1, rgb.$2), rgb.$3);
  final depth = 255 - lowest;
  if (depth == 0) return 'transparent';
  int unmix(int c) => 255 - ((255 - c) * 510 + depth) ~/ (2 * depth);
  return '${toHex((unmix(rgb.$1), unmix(rgb.$2), unmix(rgb.$3)))}'
      '${depth.toRadixString(16).padLeft(2, '0')}';
}

// Below this against white, text in the colour and white text on it can no
// longer be read.
const _tooPale = 3;
const _readable = 4.5;

/// The colour a report prints: as given, or a darker shade of it when it is
/// too pale to read, or [fallback] when it is not a colour at all.
String printableColor(String value, String fallback) {
  final rgb = parseColor(value);
  if (rgb == null) return fallback;
  return contrastOnWhite(rgb) < _tooPale
      ? toHex(darkenToContrast(rgb, _readable))
      : jsTrim(value);
}
