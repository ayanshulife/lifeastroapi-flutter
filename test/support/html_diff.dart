// A readable failure for two HTML strings that should be identical.
import 'dart:convert';

/// What the charts and the planet cards of a Brihad document draw, without
/// the language's labels: each row's place and size with the colours (one per
/// planet) in it, then each card's picture.
List<String> drawnPlanets(String html) {
  final out = <String>[];
  final charts = RegExp(r'<svg viewBox="0 0 100 100"[\s\S]*?</svg>')
      .allMatches(html)
      .toList();
  for (var i = 0; i < charts.length; i++) {
    for (final row in RegExp(
            r'<text x="([^"]+)" y="([^"]+)" font-size="([^"]+)"[^>]*>(<tspan fill=.*?)</text>')
        .allMatches(charts[i][0]!)) {
      final colours = RegExp('<tspan fill="([^"]+)"')
          .allMatches(row[4]!)
          .map((m) => m[1])
          .join(' ');
      out.add('chart $i at ${row[1]},${row[2]} size ${row[3]}: $colours');
    }
  }
  for (final card in RegExp(r'<div class="graha-glyph">([\s\S]*?)</div>')
      .allMatches(html)) {
    out.add('card ${card[1]}');
  }
  return out;
}

/// Where [expected] and [actual] first differ, with some context.
String firstDiff(String expected, String actual) {
  final n = expected.length < actual.length ? expected.length : actual.length;
  var i = 0;
  while (i < n && expected.codeUnitAt(i) == actual.codeUnitAt(i)) {
    i++;
  }
  final line = '\n'.allMatches(expected.substring(0, i)).length + 1;
  String around(String s) {
    final a = (i - 120).clamp(0, s.length);
    final b = (i + 120).clamp(0, s.length);
    return jsonEncode(s.substring(a, b));
  }

  return 'first difference at offset $i (line $line); lengths '
      '${expected.length} vs ${actual.length}\n'
      'expected: ${around(expected)}\n'
      'actual:   ${around(actual)}';
}
