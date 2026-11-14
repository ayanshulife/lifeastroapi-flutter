/// Horoscope (daily, weekly, monthly) report as HTML. Port of the Node SDK's src/pdf/templates/horoscope.ts
/// (byte-identical output, golden-tested).
library;

import '../js.dart';
import '../shared.dart';

const _labels = {
  'en': {
    'title_daily': 'Daily Horoscope',
    'title_weekly': 'Weekly Horoscope',
    'title_monthly': 'Monthly Horoscope',
    'period': 'Period',
    'section_transits': 'Transit Influences',
    'section_panchang': 'Today\'s Panchang',
    'section_lucky': 'Lucky Factors',
    'tithi': 'Tithi',
    'nakshatra': 'Nakshatra',
    'yoga': 'Yoga',
    'karana': 'Karana',
    'vaar': 'Weekday',
    'rahu_kaal': 'Rahu Kaal',
    'auspicious_window': 'Auspicious Window',
    'sunrise': 'Sunrise',
    'sunset': 'Sunset',
    'lucky_color': 'Color',
    'lucky_number': 'Number',
    'lucky_direction': 'Direction',
    'lucky_time': 'Time',
    'sources': 'Sources',
  },
  'hi': {
    'title_daily': 'दैनिक राशिफल',
    'title_weekly': 'साप्ताहिक राशिफल',
    'title_monthly': 'मासिक राशिफल',
    'period': 'अवधि',
    'section_transits': 'गोचर प्रभाव',
    'section_panchang': 'आज का पंचांग',
    'section_lucky': 'शुभ तत्व',
    'tithi': 'तिथि',
    'nakshatra': 'नक्षत्र',
    'yoga': 'योग',
    'karana': 'करण',
    'vaar': 'वार',
    'rahu_kaal': 'राहु काल',
    'auspicious_window': 'शुभ समय',
    'sunrise': 'सूर्योदय',
    'sunset': 'सूर्यास्त',
    'lucky_color': 'रंग',
    'lucky_number': 'अंक',
    'lucky_direction': 'दिशा',
    'lucky_time': 'समय',
    'sources': 'स्रोत',
  },
  'mr': {
    'title_daily': 'दैनिक राशीभविष्य',
    'title_weekly': 'साप्ताहिक राशीभविष्य',
    'title_monthly': 'मासिक राशीभविष्य',
    'period': 'कालावधी',
    'section_transits': 'गोचर प्रभाव',
    'section_panchang': 'आजचे पंचांग',
    'section_lucky': 'शुभ घटक',
    'tithi': 'तिथी',
    'nakshatra': 'नक्षत्र',
    'yoga': 'योग',
    'karana': 'करण',
    'vaar': 'वार',
    'rahu_kaal': 'राहू काळ',
    'auspicious_window': 'शुभ वेळ',
    'sunrise': 'सूर्योदय',
    'sunset': 'सूर्यास्त',
    'lucky_color': 'रंग',
    'lucky_number': 'अंक',
    'lucky_direction': 'दिशा',
    'lucky_time': 'वेळ',
    'sources': 'स्रोत',
  },
  'te': {
    'title_daily': 'దిన రాశిఫలం',
    'title_weekly': 'వార రాశిఫలం',
    'title_monthly': 'మాస రాశిఫలం',
    'period': 'కాలం',
    'section_transits': 'గోచర ప్రభావాలు',
    'section_panchang': 'నేటి పంచాంగం',
    'section_lucky': 'శుభ అంశాలు',
    'tithi': 'తిథి',
    'nakshatra': 'నక్షత్రం',
    'yoga': 'యోగం',
    'karana': 'కరణం',
    'vaar': 'వారం',
    'rahu_kaal': 'రాహు కాలం',
    'auspicious_window': 'శుభ సమయం',
    'sunrise': 'సూర్యోదయం',
    'sunset': 'సూర్యాస్తమయం',
    'lucky_color': 'రంగు',
    'lucky_number': 'సంఖ్య',
    'lucky_direction': 'దిశ',
    'lucky_time': 'సమయం',
    'sources': 'ఆధారాలు',
  },
  'ta': {
    'title_daily': 'தினசரி ராசிபலன்',
    'title_weekly': 'வார ராசிபலன்',
    'title_monthly': 'மாத ராசிபலன்',
    'period': 'காலம்',
    'section_transits': 'கோசார தாக்கங்கள்',
    'section_panchang': 'இன்றைய பஞ்சாங்கம்',
    'section_lucky': 'அதிர்ஷ்ட அம்சங்கள்',
    'tithi': 'திதி',
    'nakshatra': 'நட்சத்திரம்',
    'yoga': 'யோகம்',
    'karana': 'கரணம்',
    'vaar': 'கிழமை',
    'rahu_kaal': 'ராகு காலம்',
    'auspicious_window': 'சுப நேரம்',
    'sunrise': 'சூரிய உதயம்',
    'sunset': 'சூரிய அஸ்தமனம்',
    'lucky_color': 'நிறம்',
    'lucky_number': 'எண்',
    'lucky_direction': 'திசை',
    'lucky_time': 'நேரம்',
    'sources': 'ஆதாரங்கள்',
  },
  'kn': {
    'title_daily': 'ದೈನಿಕ ರಾಶಿಫಲ',
    'title_weekly': 'ವಾರದ ರಾಶಿಫಲ',
    'title_monthly': 'ಮಾಸಿಕ ರಾಶಿಫಲ',
    'period': 'ಅವಧಿ',
    'section_transits': 'ಗೋಚರ ಪ್ರಭಾವಗಳು',
    'section_panchang': 'ಇಂದಿನ ಪಂಚಾಂಗ',
    'section_lucky': 'ಶುಭ ಅಂಶಗಳು',
    'tithi': 'ತಿಥಿ',
    'nakshatra': 'ನಕ್ಷತ್ರ',
    'yoga': 'ಯೋಗ',
    'karana': 'ಕರಣ',
    'vaar': 'ವಾರ',
    'rahu_kaal': 'ರಾಹು ಕಾಲ',
    'auspicious_window': 'ಶುಭ ಸಮಯ',
    'sunrise': 'ಸೂರ್ಯೋದಯ',
    'sunset': 'ಸೂರ್ಯಾಸ್ತ',
    'lucky_color': 'ಬಣ್ಣ',
    'lucky_number': 'ಸಂಖ್ಯೆ',
    'lucky_direction': 'ದಿಕ್ಕು',
    'lucky_time': 'ಸಮಯ',
    'sources': 'ಆಧಾರಗಳು',
  },
  'ml': {
    'title_daily': 'ദിനഫലം',
    'title_weekly': 'വാരഫലം',
    'title_monthly': 'മാസഫലം',
    'period': 'കാലയളവ്',
    'section_transits': 'ഗോചര സ്വാധീനങ്ങൾ',
    'section_panchang': 'ഇന്നത്തെ പഞ്ചാംഗം',
    'section_lucky': 'ശുഭ ഘടകങ്ങൾ',
    'tithi': 'തിഥി',
    'nakshatra': 'നക്ഷത്രം',
    'yoga': 'യോഗം',
    'karana': 'കരണം',
    'vaar': 'ആഴ്ച',
    'rahu_kaal': 'രാഹുകാലം',
    'auspicious_window': 'ശുഭസമയം',
    'sunrise': 'സൂര്യോദയം',
    'sunset': 'സൂര്യാസ്തമയം',
    'lucky_color': 'നിറം',
    'lucky_number': 'സംഖ്യ',
    'lucky_direction': 'ദിക്ക്',
    'lucky_time': 'സമയം',
    'sources': 'ആധാരങ്ങൾ',
  },
  'gu': {
    'title_daily': 'દૈનિક રાશિફળ',
    'title_weekly': 'સાપ્તાહિક રાશિફળ',
    'title_monthly': 'માસિક રાશિફળ',
    'period': 'અવધિ',
    'section_transits': 'ગોચર પ્રભાવ',
    'section_panchang': 'આજનું પંચાંગ',
    'section_lucky': 'શુભ તત્ત્વો',
    'tithi': 'તિથિ',
    'nakshatra': 'નક્ષત્ર',
    'yoga': 'યોગ',
    'karana': 'કરણ',
    'vaar': 'વાર',
    'rahu_kaal': 'રાહુકાળ',
    'auspicious_window': 'શુભ સમય',
    'sunrise': 'સૂર્યોદય',
    'sunset': 'સૂર્યાસ્ત',
    'lucky_color': 'રંગ',
    'lucky_number': 'અંક',
    'lucky_direction': 'દિશા',
    'lucky_time': 'સમય',
    'sources': 'સ્રોત',
  },
  'bn': {
    'title_daily': 'দৈনিক রাশিফল',
    'title_weekly': 'সাপ্তাহিক রাশিফল',
    'title_monthly': 'মাসিক রাশিফল',
    'period': 'সময়কাল',
    'section_transits': 'গোচরের প্রভাব',
    'section_panchang': 'আজকের পঞ্জিকা',
    'section_lucky': 'শুভ উপাদান',
    'tithi': 'তিথি',
    'nakshatra': 'নক্ষত্র',
    'yoga': 'যোগ',
    'karana': 'করণ',
    'vaar': 'বার',
    'rahu_kaal': 'রাহুকাল',
    'auspicious_window': 'শুভ সময়',
    'sunrise': 'সূর্যোদয়',
    'sunset': 'সূর্যাস্ত',
    'lucky_color': 'রং',
    'lucky_number': 'সংখ্যা',
    'lucky_direction': 'দিক',
    'lucky_time': 'সময়',
    'sources': 'সূত্র',
  },
};

String _row(String label, Object? value) {
  final v = esc(value);
  return v == '' ? '' : '<tr><th>${esc(label)}</th><td>$v</td></tr>';
}

String _card(String label, Object? value) {
  final v = esc(value);
  return v == ''
      ? ''
      : '<div class="card"><div class="label">${esc(label)}</div><div class="value">$v</div></div>';
}

/// Renders the Horoscope (daily, weekly, monthly) report as a complete HTML document.
///
/// The horoscope entry carries no branding of its own, so [branding] is the
/// only source of branding.
String renderHoroscopeHtml(Map<String, Object?> data, [Branding? branding]) {
  final b = resolveBranding(null, branding);
  final locale = jsStr(jsOr(data['language'], 'en'));
  final t = makeLabeler(_labels, locale);

  final periodRaw = data['period'];
  final period = periodRaw is String ? periodRaw : 'daily';
  final periodTitle = t('title_$period');
  final title = periodTitle.isNotEmpty ? periodTitle : t('title_daily');
  final subjectRaw = jsOr(data['rashi_label'], data['rashi']);
  final subject = esc(subjectRaw);

  final subjectHtml =
      subject.isNotEmpty ? '<div class="subject">$subject</div>' : '';
  final periodHtml = truthy(data['period_key'])
      ? '<div class="meta">${esc(t('period'))}: ${esc(data['period_key'])}</div>'
      : '';
  final cover = '''\n<section class="cover">
  ${coverBrandingHtml(b)}
  <h1>${esc(title)}</h1>
  $subjectHtml
  $periodHtml
</section>''';

  final headline = truthy(data['headline'])
      ? '<p><strong>${esc(data['headline'])}</strong></p>'
      : '';

  // Transit (slow-mover) narratives: heading and body are already localized.
  var transits = '';
  if (nonEmptyList(data['slow_movers'])) {
    final blocks = asList(data['slow_movers']).map((raw) {
      final sm = asMap(raw);
      final fallbackHead =
          [sm['planet'], sm['current_sign']].where(truthy).map(esc).join(' — ');
      final ownHead = esc(sm['heading']);
      final heading = ownHead.isNotEmpty ? ownHead : fallbackHead;
      final cites = nonEmptyList(sm['citations'])
          ? '<div class="citations">${esc(t('sources'))}: ${escList(sm['citations'])}</div>'
          : '';
      return '<div class="narrative-section"><h3>$heading</h3><div class="body">${esc(sm['body'])}</div>$cites</div>';
    }).join('\n');
    transits = '<h2>${esc(t('section_transits'))}</h2>\n$blocks';
  }

  // Panchang (daily).
  var panchang = '';
  if (truthy(data['panchang'])) {
    final p = asMap(data['panchang']);
    final rows = [
      _row(t('tithi'),
          [p['tithi'], p['paksha']].where(truthy).map(jsStr).join(' / ')),
      _row(t('nakshatra'), p['nakshatra']),
      _row(t('yoga'), p['yoga']),
      _row(t('karana'), p['karana']),
      _row(t('vaar'), p['vaar']),
      _row(t('rahu_kaal'), p['rahu_kaal']),
      _row(t('auspicious_window'), p['auspicious_window']),
      _row(t('sunrise'), p['sunrise']),
      _row(t('sunset'), p['sunset']),
    ].join();
    if (rows.isNotEmpty) {
      panchang = '<h2>${esc(t('section_panchang'))}</h2><table>$rows</table>';
    }
  }

  // Lucky factors (daily).
  var lucky = '';
  if (truthy(data['lucky'])) {
    final l = asMap(data['lucky']);
    final number = l['number'];
    final cards = [
      _card(t('lucky_color'), l['color']),
      _card(t('lucky_number'), number is num ? number : ''),
      _card(t('lucky_direction'), l['direction']),
      _card(t('lucky_time'), l['time']),
    ].join();
    if (cards.isNotEmpty) {
      lucky =
          '<h2>${esc(t('section_lucky'))}</h2><div class="cards">$cards</div>';
    }
  }

  final bodyHtml = '$cover\n$headline\n$transits\n$panchang\n$lucky';

  return layoutDocument(
    lang: locale,
    title: '$title${subject.isNotEmpty ? ' — ${jsStr(subjectRaw)}' : ''}',
    branding: b,
    bodyHtml: bodyHtml,
  );
}
