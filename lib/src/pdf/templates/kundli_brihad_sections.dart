/// Brihad Kundli sections, running header/footer and table of contents.
/// Port of the Node SDK's src/pdf/templates/kundliBrihadSections.ts
/// (byte-identical output, golden-tested).
///
/// The deep classical sections read the snake_case JSON keys of the report;
/// the narrative chapters read `narrative_chapters`.
library;

import '../js.dart';
import '../locales.dart';
import '../shared.dart';
import 'north_indian_chart.dart';
import 'planet_glyphs.dart';

/// A label lookup (`makeLabeler`).
typedef BrihadLabel = String Function(String key);

/// "Graha Sthiti" planet-cards grid: each graha as a card with its glyph,
/// name, sign and nakshatra. [planets] is the report's `Planets` array.
String renderGrahaSthiti(Object? planets, String title) {
  if (planets is! List || planets.isEmpty) return '';
  final cards = planets
      .map((raw) {
        final p = asMap(raw);
        final glyph = planetGlyph(p['name_en'] ?? p['name']);
        if (glyph.isEmpty) return '';
        final pl = asMap(p['placement']);
        final retro = truthy(p['retro'])
            ? ' <span style="color:#c0392b;">(R)</span>'
            : '';
        return '''<div class="graha-card">
  <div class="graha-glyph">$glyph</div>
  <div class="graha-info">
    <div class="graha-name">${esc(p['name'])}$retro</div>
    <div class="graha-pos">${esc(pl['sign'])}</div>
    <div class="graha-nak">${esc(pl['nakshatra'])}</div>
  </div>
</div>''';
      })
      .where((s) => s.isNotEmpty)
      .join('\n');
  if (cards.isEmpty) return '';
  return '''<section class="section graha-sthiti-section">
<h2>${esc(title)}</h2>
<div class="graha-grid">$cards</div>
</section>''';
}

// ── North-Indian chart glue ─────────────────────────────────────────────────

// Sign name to 0-based index: English, Hindi/Marathi, Malayalam month-style
// names and the te/ta/kn/ml/gu/bn names (locales.dart southSignIndex).
const _signIndex = {
  'Aries': 0,
  'Taurus': 1,
  'Gemini': 2,
  'Cancer': 3,
  'Leo': 4,
  'Virgo': 5,
  'Libra': 6,
  'Scorpio': 7,
  'Sagittarius': 8,
  'Capricorn': 9,
  'Aquarius': 10,
  'Pisces': 11,
  'मेष': 0,
  'वृषभ': 1,
  'मिथुन': 2,
  'कर्क': 3,
  'सिंह': 4,
  'कन्या': 5,
  'तुला': 6,
  'वृश्चिक': 7,
  'धनु': 8,
  'मकर': 9,
  'कुम्भ': 10,
  'कुंभ': 10,
  'मीन': 11,
  'तूळ': 6,
  'മേടം': 0,
  'ഇടവം': 1,
  'മിഥുനം': 2,
  'കർക്കടകം': 3,
  'ചിങ്ങം': 4,
  'കന്നി': 5,
  'തുലാം': 6,
  'വൃശ്ചികം': 7,
  'ധനു': 8,
  'മകരം': 9,
  'കുംഭം': 10,
  'മീനം': 11,
  'మేషం': 0,
  'వృషభం': 1,
  'మిథునం': 2,
  'కర్కాటకం': 3,
  'సింహం': 4,
  'కన్య': 5,
  'తుల': 6,
  'వృశ్చికం': 7,
  'ధనుస్సు': 8,
  'మకరం': 9,
  'కుంభం': 10,
  'మీనం': 11,
  'மேஷம்': 0,
  'ரிஷபம்': 1,
  'மிதுனம்': 2,
  'கடகம்': 3,
  'சிம்மம்': 4,
  'கன்னி': 5,
  'துலாம்': 6,
  'விருச்சிகம்': 7,
  'தனுசு': 8,
  'மகரம்': 9,
  'கும்பம்': 10,
  'மீனம்': 11,
  'ಮೇಷ': 0,
  'ವೃಷಭ': 1,
  'ಮಿಥುನ': 2,
  'ಕರ್ಕಾಟಕ': 3,
  'ಸಿಂಹ': 4,
  'ಕನ್ಯಾ': 5,
  'ತುಲಾ': 6,
  'ವೃಶ್ಚಿಕ': 7,
  'ಧನು': 8,
  'ಮಕರ': 9,
  'ಕುಂಭ': 10,
  'ಮೀನ': 11,
  'મેષ': 0,
  'વૃષભ': 1,
  'મિથુન': 2,
  'કર્ક': 3,
  'સિંહ': 4,
  'કન્યા': 5,
  'તુલા': 6,
  'વૃશ્ચિક': 7,
  'ધનુ': 8,
  'મકર': 9,
  'કુંભ': 10,
  'મીન': 11,
  'মেষ': 0,
  'বৃষ': 1,
  'মিথুন': 2,
  'কর্কট': 3,
  'সিংহ': 4,
  'কন্যা': 5,
  'তুলা': 6,
  'বৃশ্চিক': 7,
  'ধনু': 8,
  'মকর': 9,
  'কুম্ভ': 10,
  'মীন': 11,
};

const _planetNameToEn = {
  'सूर्य': 'Sun',
  'चंद्र': 'Moon',
  'चन्द्र': 'Moon',
  'मंगल': 'Mars',
  'बुध': 'Mercury',
  'गुरु': 'Jupiter',
  'बृहस्पति': 'Jupiter',
  'शुक्र': 'Venus',
  'शनि': 'Saturn',
  'राहु': 'Rahu',
  'केतु': 'Ketu',
};

/// Builds the chart planets from `{name, house, retro}` rows, labelled for
/// the locale.
List<ChartPlanet> _chartPlanets(List<Object?> rows, String locale) {
  final labels = planetLabelsFor(locale);
  final out = <ChartPlanet>[];
  for (final raw in rows) {
    final r = asMap(raw);
    final name = jsStr(r['name'] ?? '');
    // Normalise to the English key whether the JSON gave EN, Devanagari or a
    // south-Indian name.
    final key = planetLabelsEn[name] != null
        ? name
        : _planetNameToEn[name] ?? jsOr(southPlanetToEn(name), name)!;
    final lbl = labels[key];
    if (!truthy(lbl) || !truthy(r['house'])) continue;
    out.add(ChartPlanet(
      label: lbl!,
      house: r['house'],
      retro: r['retro'],
      color: planetColors[key],
    ));
  }
  return out;
}

/// Renders a North-Indian diamond chart from a lagna sign name and planet
/// rows (`{name, house, retro}` maps). Returns `''` if the lagna sign is
/// unknown.
String renderNorthChart(Object? lagnaSign, List<Object?> rows, String title,
    String locale, String accent,
    [num size = 210]) {
  final idx = _signIndex[lagnaSign == null ? '' : jsStr(lagnaSign)];
  if (idx == null) return '';
  return northIndianChartSvg(
    lagnaSignIndex: idx,
    planets: _chartPlanets(rows, locale),
    title: title,
    size: size,
    accent: accent,
  );
}

// ── Running header / footer (Puppeteer margin-box templates) ────────────────

/// Page margins the Brihad PDF uses (room for the running header/footer).
const brihadPdfMargin =
    (top: '26mm', bottom: '16mm', left: '0mm', right: '0mm');

// ── Table of contents — 2-pass page resolution ──────────────────────────────

String _unescapeTitle(String s) => s
    .replaceAll(RegExp(r'<[^>]+>'), '')
    .replaceAll('&amp;', '&')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .trim();

// Invisible page-locator marker (white, ~1px): the PDF step scans page text
// for ⟦T<idx>⟧ to resolve the page each TOC entry lands on.
String _tocMarker(int idx) =>
    '<span style="color:#fff;font-size:1px;">⟦T$idx⟧</span>';

final _tocSectionRe = RegExp(
    r'<section class="section([^"]*)">\s*(?:<div class="part-banner"><h2 class="part-h2">([\s\S]*?)</h2></div>\s*)?<h2>([\s\S]*?)</h2>');

/// Tags each top-level `<section class="section...">` with a `data-toc-title`
/// read from its first `<h2>` (or its Part banner) and an invisible
/// ⟦T<idx>⟧ marker. Returns the tagged HTML and the ordered titles found.
({String html, List<String> titles}) tagBrihadSectionsForToc(String html) {
  final titles = <String>[];
  final tagged = html.replaceAllMapped(_tocSectionRe, (m) {
    final cls = m[1]!;
    final partInner = m[2];
    final inner = m[3]!;
    var out = '<section class="section$cls"';
    var firstMarker = '';
    var dataAttr = '';

    if (partInner != null) {
      // Part banner: a level-1 TOC entry.
      final partTitle = _unescapeTitle(partInner);
      final pIdx = titles.length;
      titles.add(partTitle);
      firstMarker += _tocMarker(pIdx);
      dataAttr = ' data-toc-title="${partTitle.replaceAll('"', '&quot;')}"';
    }

    // The section heading: a level-2 TOC entry.
    final title = _unescapeTitle(inner);
    final sIdx = titles.length;
    titles.add(title);
    firstMarker += _tocMarker(sIdx);
    if (dataAttr.isEmpty) {
      dataAttr = ' data-toc-title="${title.replaceAll('"', '&quot;')}"';
    }

    out += '$dataAttr>$firstMarker';
    if (partInner != null) {
      out +=
          '<div class="part-banner"><h2 class="part-h2">$partInner</h2></div>';
    }
    out += '<h2>$inner</h2>';
    return out;
  });
  return (html: tagged, titles: titles);
}

/// Finds a section marker token (⟦T<idx>⟧) in extracted PDF text (use
/// `allMatches`).
final tocMarkerRe = RegExp('⟦T(\\d+)⟧');

const _tocPalette = [
  '#c25e10',
  '#9e2b25',
  '#b8860b',
  '#8a3324',
  '#9c6f1e',
  '#b5471f',
  '#a8451a',
  '#8a5a00',
  '#c0631e',
];

/// The table-of-contents section for [entries]. Part rows ("Part N: …" in
/// any locale) are level-1 rows; the rest are indented level-2 rows. Page
/// numbers use a rotating colour palette.
String buildBrihadToc(
    List<({String title, int page})> entries, String heading) {
  if (entries.isEmpty) return '';
  final rows = [
    for (var i = 0; i < entries.length; i++)
      _tocRow(entries[i], _tocPalette[i % _tocPalette.length]),
  ].join('\n');
  return '''<section class="section toc-section">
<div class="toc-banner">${esc(heading)}</div>
$rows
</section>''';
}

String _tocRow(({String title, int page}) e, String col) {
  final isPart = partPrefixRe.hasMatch(e.title.trim());
  final cls = isPart ? 'toc-row toc-part' : 'toc-row toc-sub';
  return '''<div class="$cls">
  <span class="toc-title">${esc(e.title)}</span>
  <span class="toc-dots"></span>
  <span class="toc-page" style="color:$col;">${e.page}</span>
</div>''';
}

/// Running header: page number (left) + company wordmark (right).
///
/// [branding] is read like the report's raw PascalCase `Branding` map (as
/// the Node SDK does), so a [Branding] object gives the defaults.
String brihadHeaderTemplate(Object? branding) {
  final b = resolveBranding(branding);
  final company = jsOr(esc(b.companyName), 'LifeAstro');
  return '''<div style="width:100%;font-family:$indicFontStackAttr;-webkit-print-color-adjust:exact;padding:8mm 14mm 0;">
  <div style="display:flex;align-items:center;justify-content:space-between;border-bottom:0.35mm solid #e3d9c0;padding-bottom:2mm;">
    <div style="color:#9e2b25;font-size:12px;font-weight:bold;letter-spacing:.5px;">
      <span style="color:#c25e10;">✦</span>&nbsp;<span class="pageNumber"></span>
    </div>
    <div style="color:#9e2b25;font-weight:bold;font-size:13px;letter-spacing:.4px;">
      <span style="color:#c25e10;">✦</span> $company
    </div>
  </div>
</div>''';
}

/// Running footer: star flourishes around the footer text.
///
/// [branding] is read like [brihadHeaderTemplate]'s.
String brihadFooterTemplate(Object? branding) {
  final b = resolveBranding(branding);
  final txt = jsOr(esc(b.footerText), 'www.lifeastroapi.com');
  const star =
      '<span style="color:#c25e10;font-size:10px;">✦</span><span style="color:#9e2b25;font-size:7px;">✦</span>';
  return '''<div style="width:100%;font-family:$indicFontStackAttr;-webkit-print-color-adjust:exact;
              text-align:center;font-size:9px;color:#9e2b25;padding-bottom:5mm;">
  $star<span style="margin:0 5mm;letter-spacing:.3px;">$txt</span>$star
</div>''';
}

// ── Small helpers ───────────────────────────────────────────────────────────

String _yesNo(BrihadLabel label, Object? v) =>
    esc(label(truthy(v) ? 'lk_present' : 'lk_absent'));

/// JS `(list ?? []).join(sep)` for a JSON array (not escaped).
String _join(Object? list, String sep) =>
    asList(list).map((e) => e == null ? '' : jsStr(e)).join(sep);

/// JS `(n ?? 0).toFixed(2)`.
String _fixed2(Object? n) => toFixed(asNum(n) ?? 0, 2);

String _table(List<String> headers, List<String> rows) => '''<table>
<thead><tr>${headers.map((h) => '<th>${esc(h)}</th>').join()}</tr></thead>
<tbody>
${rows.join('\n')}
</tbody>
</table>''';

/// Renders one narrative chapter (heading + body + bullets per section).
String renderChapter(Object? ch, [String locale = 'en']) {
  final c = asMap(ch);
  final secs = asList(c['sections']);
  if (secs.isEmpty) return '';
  final blocks = secs.map((raw) {
    final s = asMap(raw);
    final heading = truthy(s['Heading']) ? '<h3>${esc(s['Heading'])}</h3>' : '';
    final body =
        truthy(s['Body']) ? '<p>${escBody(s['Body'], locale)}</p>' : '';
    final b = s['Bullets'];
    final bullets = b is List && b.isNotEmpty
        ? '<ul>${b.map((x) => '<li>${escBody(x, locale)}</li>').join()}</ul>'
        : '';
    return '$heading$body$bullets';
  }).join('\n');
  return '''<section class="section narrative-chapter">
<h2>${esc(jsOr(jsOr(c['title'], c['key']), ''))}</h2>
$blocks
</section>''';
}

// ── Section renderers ───────────────────────────────────────────────────────

/// `<tr>` rows of label/value pairs whose value is truthy.
String _kvRows(BrihadLabel label, Map<String, Object?> m,
        List<(String, String)> keys) =>
    [
      for (final (k, f) in keys)
        if (truthy(m[f]))
          '<tr><td><strong>${esc(label(k))}</strong></td><td>${esc(m[f])}</td></tr>',
    ].join('\n');

String _renderAvakahada(BrihadLabel label, Object? a) {
  if (!truthy(a)) return '';
  final body = _kvRows(label, asMap(a), const [
    ('avk_paya', 'paya'),
    ('avk_varna', 'varna'),
    ('avk_vashya', 'vashya'),
    ('avk_yoni', 'yoni'),
    ('avk_gana', 'gana'),
    ('avk_nadi', 'nadi'),
    ('avk_tatva', 'tatva'),
    ('avk_nak_lord', 'nakshatra_lord'),
    ('avk_rashi_lord', 'rashi_lord'),
    ('avk_lagna_lord', 'lagna_lord'),
  ]);
  if (body.isEmpty) return '';
  return '''<section class="section">
<h2>${esc(label('section_avakahada'))}</h2>
<table><tbody>$body</tbody></table>
</section>''';
}

String _renderPanchang(BrihadLabel label, Object? p) {
  if (!truthy(p)) return '';
  final body = _kvRows(label, asMap(p), const [
    ('panchang_tithi', 'tithi'),
    ('panchang_vara', 'vara'),
    ('panchang_nakshatra', 'nakshatra'),
    ('panchang_yoga', 'yoga'),
    ('panchang_karana', 'karana'),
  ]);
  if (body.isEmpty) return '';
  return '''<section class="section">
<h2>${esc(label('section_panchang'))}</h2>
<p>${esc(label('panchang_intro'))}</p>
<table><tbody>$body</tbody></table>
</section>''';
}

String _renderGems(BrihadLabel label, Object? g) {
  final stones = asList(asMap(g)['stones']);
  if (stones.isEmpty) return '';
  final rows = stones.map((raw) {
    final s = asMap(raw);
    return '<tr><td><strong>${esc(s['kind'])}</strong></td><td>${esc(s['stone'])}</td><td>${esc(s['planet'])}</td><td>${esc(s['reason'])}</td></tr>';
  }).join('\n');
  return '''<section class="section">
<h2>${esc(label('section_gems'))}</h2>
<p>${esc(label('gems_intro'))}</p>
<table><thead><tr>
<th>${esc(label('gems_kind'))}</th><th>${esc(label('gems_stone'))}</th>
<th>${esc(label('gems_planet'))}</th><th>${esc(label('gems_reason'))}</th>
</tr></thead><tbody>$rows</tbody></table>
<p class="gems-note">${esc(label('gems_note'))}</p>
</section>''';
}

String _renderGhata(BrihadLabel label, Object? g) {
  if (!truthy(g)) return '';
  final m = asMap(g);
  const keys = [
    ('ghata_weekday', 'weekday'),
    ('ghata_tithi', 'tithi_text'),
    ('ghata_month', 'month'),
    ('ghata_nakshatra', 'nakshatra'),
    ('ghata_yoga', 'yoga'),
    ('ghata_karana', 'karana'),
    ('ghata_prahar', 'prahar'),
    ('ghata_rashi', 'ghata_rashi'),
  ];
  // JS `v !== undefined && v !== ""`: a present null still gets a row.
  final body = [
    for (final (k, f) in keys)
      if (m.containsKey(f) && m[f] != '')
        '<tr><td><strong>${esc(label(k))}</strong></td><td>${esc(m[f])}</td></tr>',
  ].join('\n');
  if (body.isEmpty) return '';
  return '''<section class="section">
<h2>${esc(label('section_ghata'))}</h2>
<p>${esc(label('ghata_intro'))}</p>
<table><tbody>$body</tbody></table>
</section>''';
}

String _renderChalit(BrihadLabel label, Object? c) {
  if (!truthy(c)) return '';
  final m = asMap(c);
  final houses = m['houses'];
  if (houses is! List || houses.isEmpty) return '';
  final hrows = houses.map((raw) {
    final h = asMap(raw);
    return '<tr><td>${esc(h['house'])}</td><td>${esc(h['begin_sign'])} ${esc(h['begin_dms'])}</td><td>${esc(h['madhya_sign'])} ${esc(h['madhya_dms'])}</td></tr>';
  }).join('\n');
  final prows = asList(m['planets']).map((raw) {
    final p = asMap(raw);
    return '<tr><td>${esc(p['name'])}</td><td>${esc(p['rashi_house'])}</td><td>${esc(p['chalit_house'])}</td><td>${truthy(p['shifted']) ? '✓' : ''}</td></tr>';
  }).join('\n');
  return '''<section class="section">
<h2>${esc(label('section_chalit'))}</h2>
<p>${esc(label('chalit_intro'))}</p>
${_table([
        label('chalit_house'),
        label('chalit_begin'),
        label('chalit_madhya')
      ], [
        hrows
      ])}
<h3>${esc(label('chalit_planets'))}</h3>
${_table([
        label('planet'),
        label('chalit_rashi_house'),
        label('chalit_bhava_house'),
        label('chalit_shifted')
      ], [
        prows
      ])}
</section>''';
}

String _renderKP(BrihadLabel label, Object? k) {
  if (!truthy(k)) return '';
  final m = asMap(k);
  final cusps = m['cusps'];
  if (cusps is! List || cusps.isEmpty) return '';
  final cuspRows = cusps.map((raw) {
    final c = asMap(raw);
    return '<tr><td>${esc(c['house'])}</td><td>${esc(c['sign'])} ${esc(c['dms'])}</td><td>${esc(c['star_lord'])}</td><td>${esc(c['sub_lord'])}</td><td>${esc(c['sub_sub_lord'])}</td></tr>';
  }).join('\n');
  final sigRows = asList(m['planet_significators']).map((raw) {
    final s = asMap(raw);
    return '<tr><td>${esc(s['key'])}</td><td>${_join(s['values'], ', ')}</td></tr>';
  }).join('\n');
  final rp = asMap(m['ruling_planets']);
  final rpRows = jsKeys(rp)
      .map((key) =>
          '<tr><td><strong>${esc(jsOr(label('kp_rp_$key'), key))}</strong></td><td>${esc(rp[key])}</td></tr>')
      .join('\n');
  final rpHtml = rpRows.isNotEmpty
      ? '<h3>${esc(label('kp_ruling_planets'))}</h3>${_table([
              label('kp_rp_role'),
              label('planet')
            ], [
              rpRows
            ])}'
      : '';
  return '''<section class="section">
<h2>${esc(label('section_kp'))}</h2>
<p>${esc(label('kp_intro'))}</p>
${_table([
        label('house'),
        label('sign'),
        label('kp_star_lord'),
        label('kp_sub_lord'),
        label('kp_subsub_lord')
      ], [
        cuspRows
      ])}
<h3>${esc(label('kp_significators'))}</h3>
${_table([label('planet'), label('kp_signifies_houses')], [sigRows])}
$rpHtml
</section>''';
}

String _renderJaimini(BrihadLabel label, Object? j) {
  if (!truthy(j)) return '';
  final m = asMap(j);
  final ckRows = asList(m['charakarakas']).map((raw) {
    final c = asMap(raw);
    return '<tr><td>${esc(c['karaka'])}</td><td>${esc(c['planet'])}</td></tr>';
  }).join('\n');
  final arRows = asList(m['arudha_padas']).map((raw) {
    final a = asMap(raw);
    return '<tr><td>${esc(a['label'])} (${esc(a['name'])})</td><td>${esc(a['sign'])}</td><td>${esc(a['house'])}</td></tr>';
  }).join('\n');
  if (ckRows.isEmpty && arRows.isEmpty) return '';
  final ckHtml = ckRows.isNotEmpty
      ? '<h3>${esc(label('jaimini_charakarakas'))}</h3>${_table([
              label('jaimini_karaka'),
              label('planet')
            ], [
              ckRows
            ])}'
      : '';
  final arHtml = arRows.isNotEmpty
      ? '<h3>${esc(label('jaimini_arudha'))}</h3>${_table([
              label('jaimini_pada'),
              label('sign'),
              label('house')
            ], [
              arRows
            ])}'
      : '';
  return '''<section class="section">
<h2>${esc(label('section_jaimini'))}</h2>
$ckHtml
<p><strong>${esc(label('jaimini_karakamsa'))}:</strong> ${esc(m['karakamsa_sign'])} &nbsp; <strong>${esc(label('jaimini_swamsa'))}:</strong> ${esc(m['swamsa_sign'])}</p>
$arHtml
</section>''';
}

String _renderIshta(BrihadLabel label, Object? i, [String locale = 'en']) {
  if (!truthy(i)) return '';
  final m = asMap(i);
  if (!truthy(m['deity'])) return '';
  final bodyHtml =
      truthy(m['body']) ? '<p>${escBody(m['body'], locale)}</p>' : '';
  return '''<section class="section">
<h2>${esc(label('section_ishta'))}</h2>
<p>${esc(label('ishta_intro'))}</p>
<p><strong>${esc(label('ishta_deity'))}:</strong> ${esc(m['deity'])}<br>
<strong>${esc(label('ishta_12th_sign'))}:</strong> ${esc(m['twelfth_sign'])} &nbsp;
<strong>${esc(label('ishta_graha'))}:</strong> ${esc(m['determining_graha'])}</p>
$bodyHtml
</section>''';
}

String _renderMaitri(BrihadLabel label, Object? mt) {
  if (!truthy(mt)) return '';
  final m = asMap(mt);
  final order = m['order'];
  if (order is! List || order.isEmpty) return '';
  String tbl(Object? rows) {
    if (rows is! List || rows.isEmpty) return '';
    final head =
        '<tr><th></th>${order.map((o) => '<th>${esc(o)}</th>').join()}</tr>';
    final body = rows.map((raw) {
      final r = asMap(raw);
      final rel = asMap(r['relations']);
      return '<tr><td><strong>${esc(r['planet'])}</strong></td>${order.map((o) => '<td>${esc(rel[jsStr(o)])}</td>').join()}</tr>';
    }).join('\n');
    return '<table><thead>$head</thead><tbody>$body</tbody></table>';
  }

  return '''<section class="section">
<h2>${esc(label('section_maitri'))}</h2>
<p>${esc(label('maitri_intro'))}</p>
<h3>${esc(label('maitri_naisargik'))}</h3>${tbl(m['naisargik'])}
<h3>${esc(label('maitri_tatkalik'))}</h3>${tbl(m['tatkalik'])}
<h3>${esc(label('maitri_panchadha'))}</h3>${tbl(m['panchadha'])}
</section>''';
}

String _renderAvasthas(BrihadLabel label, Object? a) {
  if (a is! List || a.isEmpty) return '';
  final rows = a.map((raw) {
    final x = asMap(raw);
    return '<tr><td>${esc(x['planet'])}</td><td>${esc(x['baladi'])}</td><td>${esc(x['jagradadi'])}</td><td>${esc(x['deeptadi'])}</td></tr>';
  }).join('\n');
  return '''<section class="section">
<h2>${esc(label('section_avastha'))}</h2>
<p>${esc(label('avastha_intro'))}</p>
${_table([
        label('planet'),
        label('avastha_baladi'),
        label('avastha_jagradadi'),
        label('avastha_deeptadi')
      ], [
        rows
      ])}
</section>''';
}

String _renderLalKitab(BrihadLabel label, Object? lk) {
  if (!truthy(lk)) return '';
  final m = asMap(lk);
  final planetRows = asList(m['planets']).map((raw) {
    final p = asMap(raw);
    return '<tr><td>${esc(p['name'])}</td><td>${esc(p['house'])}</td><td>${esc(p['sign'])}</td></tr>';
  }).join('\n');
  final rinRows = asList(m['rins']).map((raw) {
    final r = asMap(raw);
    return '<tr><td>${esc(r['name'])}</td><td>${_yesNo(label, r['present'])}</td></tr>';
  }).join('\n');
  if (planetRows.isEmpty && rinRows.isEmpty) return '';
  final planetsHtml = planetRows.isNotEmpty
      ? '<h3>${esc(label('lalkitab_planets'))}</h3>${_table([
              label('planet'),
              label('house'),
              label('sign')
            ], [
              planetRows
            ])}'
      : '';
  final rinsHtml = rinRows.isNotEmpty
      ? '<h3>${esc(label('lalkitab_rins'))}</h3>${_table([
              label('lalkitab_rin'),
              label('lalkitab_status')
            ], [
              rinRows
            ])}'
      : '';
  return '''<section class="section">
<h2>${esc(label('section_lalkitab'))}</h2>
<p>${esc(label('lalkitab_intro'))}</p>
$planetsHtml
$rinsHtml
</section>''';
}

String _renderShadbala(BrihadLabel label, Object? s) {
  if (s is! List || s.isEmpty) return '';
  final rows = s.map((raw) {
    final r = asMap(raw);
    return '<tr><td>${esc(r['planet'])}</td><td>${esc(_fixed2(r['total_rupas']))}</td><td>${esc(r['rank'])}</td></tr>';
  }).join('\n');
  return '''<section class="section">
<h2>${esc(label('section_shadbala'))}</h2>
<p>${esc(label('shadbala_intro'))}</p>
${_table([
        label('planet'),
        label('shadbala_rupas'),
        label('shadbala_rank')
      ], [
        rows
      ])}
</section>''';
}

String _renderBhavaBala(BrihadLabel label, Object? b) {
  if (b is! List || b.isEmpty) return '';
  final rows = b.map((raw) {
    final r = asMap(raw);
    return '<tr><td>${esc(r['house'])}</td><td>${esc(_fixed2(r['bhavadhipati']))}</td><td>${esc(_fixed2(r['bhava_dig_bala']))}</td><td>${esc(_fixed2(r['bhava_drsti']))}</td><td>${esc(_fixed2(r['total']))}</td></tr>';
  }).join('\n');
  return '''<section class="section">
<h2>${esc(label('section_bhavabala'))}</h2>
<p>${esc(label('bhavabala_intro'))}</p>
${_table([
        label('house'),
        label('bb_lord'),
        label('bb_dig'),
        label('bb_drsti'),
        label('bb_total')
      ], [
        rows
      ])}
</section>''';
}

String _renderAshtakavarga(BrihadLabel label, Object? av) {
  if (!truthy(av)) return '';
  final a = asMap(av);
  final sav = a['sav'];
  if (sav is! List || sav.isEmpty) return '';
  final savCells = sav.map((n) => '<td>${esc(n)}</td>').join();
  final prastarRows = asList(a['prastar']).map((raw) {
    final p = asMap(raw);
    return '<tr><td>${esc(p['planet'])}</td><td>${esc(p['total'])}</td></tr>';
  }).join('\n');
  final savHeads =
      [for (var i = 0; i < sav.length; i++) '<th>${i + 1}</th>'].join();
  final prastarHtml = prastarRows.isNotEmpty
      ? '<h3>${esc(label('ashtakavarga_prastar'))}</h3>${_table([
              label('planet'),
              label('ashtakavarga_planet_total')
            ], [
              prastarRows
            ])}'
      : '';
  return '''<section class="section">
<h2>${esc(label('section_ashtakavarga'))}</h2>
<p>${esc(label('ashtakavarga_intro'))}</p>
<table><thead><tr><th>${esc(label('ashtakavarga_sav'))}</th>$savHeads</tr></thead>
<tbody><tr><td><strong>${esc(label('ashtakavarga_bindus'))}</strong></td>$savCells</tr>
<tr><td colspan="${sav.length + 1}">${esc(label('ashtakavarga_total'))}: <strong>${esc(a['sav_total'])}</strong></td></tr></tbody></table>
$prastarHtml
</section>''';
}

String _renderVarshaphal(BrihadLabel label, Object? years,
    [String locale = 'en']) {
  if (years is! List || years.isEmpty) return '';
  final blocks = years.map((raw) {
    final y = asMap(raw);
    final sahamRows = asList(y['sahams']).map((r) {
      final s = asMap(r);
      return '<tr><td>${esc(s['name'])}</td><td>${esc(s['sign'])} ${esc(s['dms'])}</td><td>${esc(s['lord'])}</td></tr>';
    }).join('\n');
    final pvRows = asList(y['panchavargeeya']).map((r) {
      final p = asMap(r);
      return '<tr><td>${esc(p['planet'])}</td><td>${esc(_fixed2(p['vishwa']))}</td></tr>';
    }).join('\n');
    final summary =
        truthy(y['summary']) ? '<p>${escBody(y['summary'], locale)}</p>' : '';
    final sahamHtml = sahamRows.isNotEmpty
        ? '<h4>${esc(label('varshaphal_sahams'))}</h4>${_table([
                label('varshaphal_saham'),
                label('sign'),
                label('lord')
              ], [
                sahamRows
              ])}'
        : '';
    final pvHtml = pvRows.isNotEmpty
        ? '<h4>${esc(label('varshaphal_panchavargeeya'))}</h4>${_table([
                label('planet'),
                label('varshaphal_vishwa')
              ], [
                pvRows
              ])}'
        : '';
    return '''<h3>${esc(label('varshaphal_year'))} ${esc(y['year'])}</h3>
<p><strong>${esc(label('varshaphal_muntha'))}:</strong> ${esc(y['muntha_sign'])} (${esc(label('house'))} ${esc(y['muntha_house'])}) &nbsp;
<strong>${esc(label('varshaphal_lord'))}:</strong> ${esc(y['varsha_lord'])}</p>
$summary
$sahamHtml
$pvHtml''';
  }).join('\n<hr>\n');
  return '''<section class="section">
<h2>${esc(label('section_varshaphal'))}</h2>
<p>${esc(label('varshaphal_intro'))}</p>
$blocks
</section>''';
}

/// Month-wise Mudda-Dasha timeline: a card per period with a date range,
/// summary, life-area lines and a do / avoid / remedy box.
String _renderMuddaTimeline(BrihadLabel label, Object? tl,
    [String locale = 'en']) {
  if (!truthy(tl)) return '';
  final t = asMap(tl);
  final periods = t['periods'];
  if (periods is! List || periods.isEmpty) return '';
  final cards = periods.map((raw) {
    final p = asMap(raw);
    final areas = asList(p['areas'])
        .map(asMap)
        .where((a) => truthy(a['text']))
        .map((a) =>
            '<p class="mudda-area"><strong>${esc(a['label'])}:</strong> ${escBody(a['text'], locale)}</p>')
        .join('\n');
    String line(String key, String labelKey) => truthy(p[key])
        ? '<p><strong>${esc(p[labelKey])}:</strong> ${escBody(p[key], locale)}</p>'
        : '';
    final guidance = '''<div class="mudda-guidance">
${line('do', 'do_label')}
${line('avoid', 'avoid_label')}
${line('remedy', 'remedy_label')}
</div>''';
    final summary = truthy(p['summary'])
        ? '<p class="mudda-summary">${escBody(p['summary'], locale)}</p>'
        : '';
    return '''<div class="mudda-period">
<h3 class="mudda-head">${esc(p['date_from'])} ${esc(jsOr(label('varshaphal_to'), '–'))} ${esc(p['date_to'])} &nbsp;·&nbsp; ${esc(p['lord'])}</h3>
$summary
$areas
$guidance
</div>''';
  }).join('\n');
  final yr = truthy(t['year']) ? ' ${esc(t['year'])}' : '';
  return '''<section class="section mudda-section">
<h2>${esc(jsOr(t['heading'], label('section_mudda')))}$yr</h2>
$cards
</section>''';
}

String _renderRajyoga(BrihadLabel label, Object? rp) {
  if (!truthy(rp)) return '';
  final r = asMap(rp);
  final skRows = asList(r['swarnim_kaal']).map((raw) {
    final p = asMap(raw);
    return '<tr><td>${esc(p['lord'])}</td><td>${esc(p['start'])}</td><td>${esc(p['end'])}</td></tr>';
  }).join('\n');
  final skHtml = skRows.isNotEmpty
      ? '<h3>${esc(label('rajyoga_swarnim'))}</h3>${_table([
              label('planet'),
              label('rajyoga_from'),
              label('rajyoga_to')
            ], [
              skRows
            ])}'
      : '';
  return '''<section class="section">
<h2>${esc(label('section_rajyoga'))}</h2>
<div class="rajyoga-power">
<div class="rajyoga-pct">${esc(r['percent'])}%</div>
<div class="rajyoga-label">${esc(label('rajyoga_strength'))}</div>
</div>
<p>${esc(label('rajyoga_planets'))}: ${_join(r['planets'], ', ')}</p>
$skHtml
</section>''';
}

/// Renders all deep classical sections and the corpus-backed narrative
/// chapters in report order (the older flat layout), dropping empty ones.
List<String> renderBrihadDeepSections(BrihadLabel label, Map<String, Object?> d,
    [String locale = 'en']) {
  final out = <String>[
    _renderAvakahada(label, d['avakahada']),
    _renderGhata(label, d['ghata_chakra']),
    _renderChalit(label, d['chalit']),
    _renderShadbala(label, d['shadbala']),
    _renderBhavaBala(label, d['bhava_bala']),
    _renderAshtakavarga(label, d['ashtakavarga']),
    _renderMaitri(label, d['maitri']),
    _renderAvasthas(label, d['avasthas']),
    _renderKP(label, d['kp']),
    _renderJaimini(label, d['jaimini']),
    _renderIshta(label, d['ishta_devata'], locale),
    _renderLalKitab(label, d['lal_kitab']),
    _renderRajyoga(label, d['rajyoga_power']),
    _renderVarshaphal(label, d['varshaphal'], locale),
    _renderMuddaTimeline(label, d['mudda_timeline'], locale),
  ];
  // Corpus-backed narrative chapters. vistrit_bhavishya opens the document,
  // so it is skipped here.
  for (final ch in asList(d['narrative_chapters'])) {
    if (asMap(ch)['key'] == 'vistrit_bhavishya') continue;
    out.add(renderChapter(ch, locale));
  }
  return out.where((s) => s.isNotEmpty).toList();
}

/// The Brihad deep sections, rendered individually (each `''` when empty).
typedef BrihadDeepBlocks = ({
  String avakahada,
  String panchang,
  String gems,
  String ghata,
  String chalit,
  String shadbala,
  String bhavabala,
  String ashtakavarga,
  String maitri,
  String avasthas,
  String kp,
  String jaimini,
  String ishta,
  String lalkitab,
  String rajyoga,
  String varshaphal,
  String mudda,
});

/// The Brihad deep sections addressable by key, so the Part layout can place
/// each one.
BrihadDeepBlocks brihadDeepBlocks(BrihadLabel label, Map<String, Object?> d,
        [String locale = 'en']) =>
    (
      avakahada: _renderAvakahada(label, d['avakahada']),
      panchang: _renderPanchang(label, d['panchang']),
      gems: _renderGems(label, d['gems']),
      ghata: _renderGhata(label, d['ghata_chakra']),
      chalit: _renderChalit(label, d['chalit']),
      shadbala: _renderShadbala(label, d['shadbala']),
      bhavabala: _renderBhavaBala(label, d['bhava_bala']),
      ashtakavarga: _renderAshtakavarga(label, d['ashtakavarga']),
      maitri: _renderMaitri(label, d['maitri']),
      avasthas: _renderAvasthas(label, d['avasthas']),
      kp: _renderKP(label, d['kp']),
      jaimini: _renderJaimini(label, d['jaimini']),
      ishta: _renderIshta(label, d['ishta_devata'], locale),
      lalkitab: _renderLalKitab(label, d['lal_kitab']),
      rajyoga: _renderRajyoga(label, d['rajyoga_power']),
      varshaphal: _renderVarshaphal(label, d['varshaphal'], locale),
      mudda: _renderMuddaTimeline(label, d['mudda_timeline'], locale),
    );
