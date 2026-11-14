/// Detailed Kundli report as HTML. Port of the Node SDK's src/pdf/templates/kundliDetailed.ts
/// (byte-identical output, golden-tested).
library;

import '../js.dart';
import '../shared.dart';
import 'kundli_brihad_helpers.dart';

const _labels = {
  'en': {
    'title_kundli': 'Detailed Kundli',
    'born': 'Born',
    'at': 'at',
    'generated': 'Generated on',
    'section_ascendant': 'Ascendant',
    'section_planets': 'Planetary Positions',
    'section_panchang': 'Panchang at Birth',
    'section_interpretation': 'Interpretation',
    'ascendant': 'Ascendant',
    'planet': 'Planet',
    'sign': 'Sign',
    'degree': 'Degree',
    'house': 'House',
    'nakshatra': 'Nakshatra',
    'pada': 'Pada',
    'lord': 'Lord',
    'tithi': 'Tithi',
    'yoga': 'Yoga',
    'karana': 'Karana',
    'sources': 'Sources',
  },
  'hi': {
    'title_kundli': 'विस्तृत कुंडली',
    'born': 'जन्म',
    'at': 'समय',
    'generated': 'तैयार',
    'section_ascendant': 'लग्न',
    'section_planets': 'ग्रह स्थिति',
    'section_panchang': 'जन्म पंचांग',
    'section_interpretation': 'व्याख्या',
    'ascendant': 'लग्न',
    'planet': 'ग्रह',
    'sign': 'राशि',
    'degree': 'अंश',
    'house': 'भाव',
    'nakshatra': 'नक्षत्र',
    'pada': 'पाद',
    'lord': 'स्वामी',
    'tithi': 'तिथि',
    'yoga': 'योग',
    'karana': 'करण',
    'sources': 'स्रोत',
  },
  'mr': {
    'title_kundli': 'तपशीलवार कुंडली',
    'born': 'जन्म',
    'at': 'वेळ',
    'generated': 'तयार',
    'section_ascendant': 'लग्न',
    'section_planets': 'ग्रह स्थिती',
    'section_panchang': 'जन्म पंचांग',
    'section_interpretation': 'व्याख्या',
    'ascendant': 'लग्न',
    'planet': 'ग्रह',
    'sign': 'राशी',
    'degree': 'अंश',
    'house': 'स्थान',
    'nakshatra': 'नक्षत्र',
    'pada': 'चरण',
    'lord': 'अधिपती',
    'tithi': 'तिथी',
    'yoga': 'योग',
    'karana': 'करण',
    'sources': 'स्रोत',
  },
  'te': {
    'title_kundli': 'వివరణాత్మక జాతకం',
    'born': 'జననం',
    'at': 'సమయం',
    'generated': 'రూపొందించిన తేదీ',
    'section_ascendant': 'లగ్నం',
    'section_planets': 'గ్రహ స్థితి',
    'section_panchang': 'జన్మ పంచాంగం',
    'section_interpretation': 'వివరణ',
    'ascendant': 'లగ్నం',
    'planet': 'గ్రహం',
    'sign': 'రాశి',
    'degree': 'భాగలు',
    'house': 'భావం',
    'nakshatra': 'నక్షత్రం',
    'pada': 'పాదం',
    'lord': 'అధిపతి',
    'tithi': 'తిథి',
    'yoga': 'యోగం',
    'karana': 'కరణం',
    'sources': 'ఆధారాలు',
  },
  'ta': {
    'title_kundli': 'விரிவான ஜாதகம்',
    'born': 'பிறப்பு',
    'at': 'நேரம்',
    'generated': 'தயாரித்த நாள்',
    'section_ascendant': 'லக்னம்',
    'section_planets': 'கிரக நிலை',
    'section_panchang': 'ஜனன பஞ்சாங்கம்',
    'section_interpretation': 'விளக்கம்',
    'ascendant': 'லக்னம்',
    'planet': 'கிரகம்',
    'sign': 'ராசி',
    'degree': 'பாகை',
    'house': 'வீடு',
    'nakshatra': 'நட்சத்திரம்',
    'pada': 'பாதம்',
    'lord': 'அதிபதி',
    'tithi': 'திதி',
    'yoga': 'யோகம்',
    'karana': 'கரணம்',
    'sources': 'ஆதாரங்கள்',
  },
  'kn': {
    'title_kundli': 'ವಿಸ್ತೃತ ಜಾತಕ',
    'born': 'ಜನನ',
    'at': 'ಸಮಯ',
    'generated': 'ತಯಾರಿಸಿದ ದಿನಾಂಕ',
    'section_ascendant': 'ಲಗ್ನ',
    'section_planets': 'ಗ್ರಹ ಸ್ಥಿತಿ',
    'section_panchang': 'ಜನ್ಮ ಪಂಚಾಂಗ',
    'section_interpretation': 'ವಿವರಣೆ',
    'ascendant': 'ಲಗ್ನ',
    'planet': 'ಗ್ರಹ',
    'sign': 'ರಾಶಿ',
    'degree': 'ಅಂಶ',
    'house': 'ಭಾವ',
    'nakshatra': 'ನಕ್ಷತ್ರ',
    'pada': 'ಪಾದ',
    'lord': 'ಅಧಿಪತಿ',
    'tithi': 'ತಿಥಿ',
    'yoga': 'ಯೋಗ',
    'karana': 'ಕರಣ',
    'sources': 'ಆಧಾರಗಳು',
  },
  'ml': {
    'title_kundli': 'വിശദ ജാതകം',
    'born': 'ജനനം',
    'at': 'സമയം',
    'generated': 'തയ്യാറാക്കിയ തീയതി',
    'section_ascendant': 'ലഗ്നം',
    'section_planets': 'ഗ്രഹസ്ഥിതി',
    'section_panchang': 'ജന്മ പഞ്ചാംഗം',
    'section_interpretation': 'വ്യാഖ്യാനം',
    'ascendant': 'ലഗ്നം',
    'planet': 'ഗ്രഹം',
    'sign': 'രാശി',
    'degree': 'അംശം',
    'house': 'ഭാവം',
    'nakshatra': 'നക്ഷത്രം',
    'pada': 'പാദം',
    'lord': 'അധിപൻ',
    'tithi': 'തിഥി',
    'yoga': 'യോഗം',
    'karana': 'കരണം',
    'sources': 'ആധാരങ്ങൾ',
  },
  'gu': {
    'title_kundli': 'વિસ્તૃત કુંડળી',
    'born': 'જન્મ',
    'at': 'સમય',
    'generated': 'તૈયાર',
    'section_ascendant': 'લગ્ન',
    'section_planets': 'ગ્રહ સ્થિતિ',
    'section_panchang': 'જન્મ પંચાંગ',
    'section_interpretation': 'વ્યાખ્યા',
    'ascendant': 'લગ્ન',
    'planet': 'ગ્રહ',
    'sign': 'રાશિ',
    'degree': 'અંશ',
    'house': 'ભાવ',
    'nakshatra': 'નક્ષત્ર',
    'pada': 'પાદ',
    'lord': 'સ્વામી',
    'tithi': 'તિથિ',
    'yoga': 'યોગ',
    'karana': 'કરણ',
    'sources': 'સ્રોત',
  },
  'bn': {
    'title_kundli': 'বিস্তারিত কুণ্ডলী',
    'born': 'জন্ম',
    'at': 'সময়',
    'generated': 'তৈরি',
    'section_ascendant': 'লগ্ন',
    'section_planets': 'গ্রহের অবস্থান',
    'section_panchang': 'জন্মের পঞ্জিকা',
    'section_interpretation': 'ব্যাখ্যা',
    'ascendant': 'লগ্ন',
    'planet': 'গ্রহ',
    'sign': 'রাশি',
    'degree': 'অংশ',
    'house': 'ভাব',
    'nakshatra': 'নক্ষত্র',
    'pada': 'পাদ',
    'lord': 'অধিপতি',
    'tithi': 'তিথি',
    'yoga': 'যোগ',
    'karana': 'করণ',
    'sources': 'সূত্র',
  },
};

const _midtierCss =
    '\n.house-block { margin: 4mm 0; padding: 4mm 5mm; background: #fafafa; border-left: 3px solid var(--brand-primary); page-break-inside: avoid; }\n.house-block .meta { color: var(--brand-secondary); font-size: 10pt; margin-bottom: 2mm; }\n.yoga-block { margin: 3mm 0; padding: 4mm 5mm; background: #fff7ed; border-left: 3px solid #ea580c; page-break-inside: avoid; }\n.yoga-block .name { font-size: 13pt; font-weight: 700; color: #ea580c; margin-bottom: 1mm; }\n.yoga-block .source, .dosha-block .source { color: var(--brand-secondary); font-size: 9pt; font-style: italic; margin-top: 2mm; }\n.dasha-block { margin: 4mm 0; padding: 5mm; background: #f0fdf4; border-left: 4px solid #16a34a; page-break-inside: avoid; }\n.dasha-block.upcoming { background: #fafafa; border-left-color: var(--brand-secondary); }\n.dasha-block .header-row, .dosha-block .header-row { display: flex; justify-content: space-between; align-items: baseline; margin-bottom: 2mm; }\n.dasha-block .lord { font-size: 14pt; font-weight: 700; color: var(--brand-primary); }\n.dasha-block .dates { color: var(--brand-secondary); font-size: 10pt; }\n.dosha-block { margin: 4mm 0; padding: 4mm 5mm; border-left: 4px solid #b91c1c; background: #fef2f2; page-break-inside: avoid; }\n.dosha-block.cancelled { border-left-color: #16a34a; background: #f0fdf4; }\n.dosha-block.mild { border-left-color: #ca8a04; background: #fefce8; }\n.dosha-block .name { font-size: 13pt; font-weight: 700; color: var(--brand-primary); }\n.dosha-block .severity { display: inline-block; padding: 1mm 3mm; font-size: 9pt; font-weight: 600; border-radius: 1mm; color: #fff; background: #b91c1c; }\n.dosha-block.cancelled .severity { background: #16a34a; }\n.dosha-block.mild .severity { background: #ca8a04; }\n.empty-list { margin: 3mm 0; color: var(--brand-secondary); font-style: italic; }\n';

// The Brihad template's LABELS, trimmed to the keys the mid-tier blocks read
// (section titles, house/lord/source/years and every dosha_severity_* key).
const _brihadLabels = {
  'en': {
    'in': 'in',
    'section_houses': 'House Analysis',
    'section_yogas': 'Yogas Detected in the Chart',
    'section_dashas': 'Vimshottari Dasha — Life Periods',
    'house': 'House',
    'lord': 'Lord',
    'current_dasha': 'Current Mahadasha',
    'upcoming_dashas': 'Upcoming Mahadashas',
    'years': 'years',
    'source': 'Source',
    'section_doshas': 'Doshas Detected',
    'dosha_mangal': 'Mangal Dosha',
    'dosha_kaalsarp': 'Kaal Sarp Dosha',
    'dosha_pitra': 'Pitra Dosha',
    'dosha_severity_present': 'Present',
    'dosha_severity_cancelled': 'Cancelled',
    'dosha_severity_mild': 'Mild',
  },
  'hi': {
    'in': 'में',
    'section_houses': 'भाव विश्लेषण',
    'section_yogas': 'कुंडली में योग',
    'section_dashas': 'विंशोत्तरी दशा — जीवन काल',
    'house': 'भाव',
    'lord': 'स्वामी',
    'current_dasha': 'वर्तमान महादशा',
    'upcoming_dashas': 'आगामी महादशाएँ',
    'years': 'वर्ष',
    'source': 'स्रोत',
    'section_doshas': 'दोष विश्लेषण',
    'dosha_mangal': 'मंगल दोष',
    'dosha_kaalsarp': 'काल सर्प दोष',
    'dosha_pitra': 'पितृ दोष',
    'dosha_severity_present': 'उपस्थित',
    'dosha_severity_cancelled': 'निवारित',
    'dosha_severity_mild': 'अल्प',
  },
  'mr': {
    'in': 'मध्ये',
    'section_houses': 'स्थान विश्लेषण',
    'section_yogas': 'कुंडलीतील योग',
    'section_dashas': 'विंशोत्तरी दशा — जीवन काल',
    'house': 'स्थान',
    'lord': 'अधिपती',
    'current_dasha': 'वर्तमान महादशा',
    'upcoming_dashas': 'आगामी महादशा',
    'years': 'वर्षे',
    'source': 'स्रोत',
    'section_doshas': 'दोष विश्लेषण',
    'dosha_mangal': 'मंगल दोष',
    'dosha_kaalsarp': 'काल सर्प दोष',
    'dosha_pitra': 'पितृ दोष',
    'dosha_severity_present': 'उपस्थित',
    'dosha_severity_cancelled': 'निवारित',
    'dosha_severity_mild': 'अल्प',
  },
  'te': {
    'in': 'స్థానం:',
    'section_houses': 'భావ విశ్లేషణ',
    'section_yogas': 'జాతకంలోని యోగాలు',
    'section_dashas': 'వింశోత్తరి దశ: జీవన కాలాలు',
    'house': 'భావం',
    'lord': 'అధిపతి',
    'current_dasha': 'ప్రస్తుత మహాదశ',
    'upcoming_dashas': 'రాబోయే మహాదశలు',
    'years': 'సంవత్సరాలు',
    'source': 'ఆధారం',
    'section_doshas': 'దోష విశ్లేషణ',
    'dosha_mangal': 'కుజ దోషం',
    'dosha_kaalsarp': 'కాలసర్ప దోషం',
    'dosha_pitra': 'పితృ దోషం',
    'dosha_severity_present': 'ఉంది',
    'dosha_severity_cancelled': 'నివారితం',
    'dosha_severity_mild': 'స్వల్పం',
  },
  'ta': {
    'in': 'நிலை:',
    'section_houses': 'வீடுகளின் பகுப்பாய்வு',
    'section_yogas': 'ஜாதகத்தில் உள்ள யோகங்கள்',
    'section_dashas': 'விம்சோத்தரி திசை: வாழ்க்கைக் காலங்கள்',
    'house': 'வீடு',
    'lord': 'அதிபதி',
    'current_dasha': 'நடப்பு திசை',
    'upcoming_dashas': 'வரவிருக்கும் திசைகள்',
    'years': 'ஆண்டுகள்',
    'source': 'ஆதாரம்',
    'section_doshas': 'தோஷ பகுப்பாய்வு',
    'dosha_mangal': 'செவ்வாய் தோஷம்',
    'dosha_kaalsarp': 'கால சர்ப்ப தோஷம்',
    'dosha_pitra': 'பித்ரு தோஷம்',
    'dosha_severity_present': 'உள்ளது',
    'dosha_severity_cancelled': 'நிவர்த்தி',
    'dosha_severity_mild': 'லேசானது',
  },
  'kn': {
    'in': 'ಸ್ಥಿತಿ:',
    'section_houses': 'ಭಾವ ವಿಶ್ಲೇಷಣೆ',
    'section_yogas': 'ಜಾತಕದಲ್ಲಿನ ಯೋಗಗಳು',
    'section_dashas': 'ವಿಂಶೋತ್ತರಿ ದಶೆ: ಜೀವನ ಕಾಲಗಳು',
    'house': 'ಭಾವ',
    'lord': 'ಅಧಿಪತಿ',
    'current_dasha': 'ಪ್ರಸ್ತುತ ಮಹಾದಶೆ',
    'upcoming_dashas': 'ಮುಂಬರುವ ಮಹಾದಶೆಗಳು',
    'years': 'ವರ್ಷಗಳು',
    'source': 'ಆಧಾರ',
    'section_doshas': 'ದೋಷ ವಿಶ್ಲೇಷಣೆ',
    'dosha_mangal': 'ಮಂಗಳ ದೋಷ',
    'dosha_kaalsarp': 'ಕಾಲಸರ್ಪ ದೋಷ',
    'dosha_pitra': 'ಪಿತೃ ದೋಷ',
    'dosha_severity_present': 'ಇದೆ',
    'dosha_severity_cancelled': 'ನಿವಾರಣೆಯಾಗಿದೆ',
    'dosha_severity_mild': 'ಅಲ್ಪ',
  },
  'ml': {
    'in': 'സ്ഥിതി:',
    'section_houses': 'ഭാവ വിശകലനം',
    'section_yogas': 'ജാതകത്തിലെ യോഗങ്ങൾ',
    'section_dashas': 'വിംശോത്തരി ദശ: ജീവിതകാലങ്ങൾ',
    'house': 'ഭാവം',
    'lord': 'അധിപൻ',
    'current_dasha': 'നിലവിലെ മഹാദശ',
    'upcoming_dashas': 'വരാനിരിക്കുന്ന മഹാദശകൾ',
    'years': 'വർഷം',
    'source': 'ആധാരം',
    'section_doshas': 'ദോഷ വിശകലനം',
    'dosha_mangal': 'ചൊവ്വാദോഷം',
    'dosha_kaalsarp': 'കാലസർപ്പദോഷം',
    'dosha_pitra': 'പിതൃദോഷം',
    'dosha_severity_present': 'ഉണ്ട്',
    'dosha_severity_cancelled': 'പരിഹൃതം',
    'dosha_severity_mild': 'നേരിയത്',
  },
  'gu': {
    'in': 'માં',
    'section_houses': 'ભાવ વિશ્લેષણ',
    'section_yogas': 'કુંડળીમાં યોગ',
    'section_dashas': 'વિંશોત્તરી દશા: જીવનકાળ',
    'house': 'ભાવ',
    'lord': 'સ્વામી',
    'current_dasha': 'વર્તમાન મહાદશા',
    'upcoming_dashas': 'આગામી મહાદશાઓ',
    'years': 'વર્ષ',
    'source': 'સ્રોત',
    'section_doshas': 'દોષ વિશ્લેષણ',
    'dosha_mangal': 'મંગળ દોષ',
    'dosha_kaalsarp': 'કાળસર્પ દોષ',
    'dosha_pitra': 'પિતૃ દોષ',
    'dosha_severity_present': 'ઉપસ્થિત',
    'dosha_severity_cancelled': 'નિવારિત',
    'dosha_severity_mild': 'અલ્પ',
  },
  'bn': {
    'in': 'রাশি:',
    'section_houses': 'ভাব বিশ্লেষণ',
    'section_yogas': 'কুণ্ডলীর যোগ',
    'section_dashas': 'বিংশোত্তরী দশা: জীবনকাল',
    'house': 'ভাব',
    'lord': 'অধিপতি',
    'current_dasha': 'বর্তমান মহাদশা',
    'upcoming_dashas': 'আগামী মহাদশা',
    'years': 'বছর',
    'source': 'সূত্র',
    'section_doshas': 'দোষ বিশ্লেষণ',
    'dosha_mangal': 'মাঙ্গলিক দোষ',
    'dosha_kaalsarp': 'কালসর্প দোষ',
    'dosha_pitra': 'পিতৃ দোষ',
    'dosha_severity_present': 'আছে',
    'dosha_severity_cancelled': 'নিবারিত',
    'dosha_severity_mild': 'অল্প',
  },
};

/// `houseTopic` with the JS lookup `HOUSE_TOPICS[loc]?.[n]`: the property key
/// is `String(n)`, so only a canonical integer string finds a house.
String _houseTopicOf(String loc, Object? n) {
  final key = jsStr(n, nullAs: 'null');
  final i = int.tryParse(key);
  if (i == null || '$i' != key) return '';
  return houseTopic(loc, i);
}

/// Renders the Detailed Kundli report (`client.reports.kundliDetailed`) as a
/// complete HTML document. [branding] fields win over the branding in the
/// report JSON.
String renderKundliDetailedHtml(Map<String, Object?> data,
    [Branding? branding]) {
  final resolved = resolveBranding(data['Branding'], branding);
  final localeRaw = data['Locale'];
  final locale = localeRaw == null ? null : jsStr(localeRaw);
  final t = makeLabeler(_labels, locale);

  final subject = asMap(data['Subject']);
  final asc = asMap(data['Ascendant']);
  final panchang = asMap(data['Panchang']);
  final planets = asList(data['Planets']);

  // Cover page.
  final coverMeta =
      '${esc(t('born'))} ${esc(subject['BirthDate'])} ${esc(t('at'))} ${esc(subject['BirthTime'])}<br>${esc(subject['BirthPlace'])}';
  final cover = '''<section class="cover">
  ${coverBrandingHtml(resolved)}
  <h1>${esc(t('title_kundli'))}</h1>
  <div class="subject">${esc(subject['Name'])}</div>
  <div class="meta">$coverMeta</div>
  <div class="generated">${esc(t('generated'))} ${esc(formatGenerated(data['GeneratedAt']))}</div>
</section>''';

  // Ascendant summary line.
  final ascendant = '''<h2>${esc(t('section_ascendant'))}</h2>
<p><strong>${esc(t('ascendant'))}:</strong> ${esc(asc['sign'])} (${esc(asc['dms_within'])}) — ${esc(t('nakshatra'))}: ${esc(asc['nakshatra'])}, ${esc(t('pada'))} ${esc(asc['pada'])}, ${esc(t('lord'))} ${esc(asc['nak_lord'])}</p>''';

  // Planetary positions table.
  final planetRows = planets.map((raw) {
    final pl = asMap(raw);
    final p = asMap(pl['placement']);
    final retro = truthy(pl['retro']) ? ' (R)' : '';
    return '<tr><td>${esc(pl['name'])}$retro</td><td>${esc(p['sign'])}</td><td>${esc(p['dms_within'])}</td><td>${esc(pl['house_num'])}</td><td>${esc(p['nakshatra'])} (${esc(p['pada'])})</td></tr>';
  }).join();
  final planetsTable = '''<h2>${esc(t('section_planets'))}</h2>
<table>
  <thead>
    <tr>
      <th>${esc(t('planet'))}</th>
      <th>${esc(t('sign'))}</th>
      <th>${esc(t('degree'))}</th>
      <th>${esc(t('house'))}</th>
      <th>${esc(t('nakshatra'))}</th>
    </tr>
  </thead>
  <tbody>$planetRows</tbody>
</table>''';

  // Panchang-at-birth table.
  final panchangTable = '''<h2>${esc(t('section_panchang'))}</h2>
<table>
  <tr><th>${esc(t('tithi'))}</th><td>${esc(panchang['tithi'])}</td></tr>
  <tr><th>${esc(t('nakshatra'))}</th><td>${esc(panchang['nakshatra'])}</td></tr>
  <tr><th>${esc(t('yoga'))}</th><td>${esc(panchang['yoga'])}</td></tr>
  <tr><th>${esc(t('karana'))}</th><td>${esc(panchang['karana'])}</td></tr>
</table>''';

  // Authored interpretation sections (optional).
  var narratives = '';
  if (nonEmptyList(data['Narratives'])) {
    narratives = '<h2>${esc(t('section_interpretation'))}</h2>\n'
        '${narrativeSectionsHtml(data['Narratives'], t('sources'))}';
  }

  // Mid-tier enrichment: dasha, houses, yogas and doshas, with the Brihad
  // labels and helpers so these blocks look the same as in Brihad.
  final loc = jsStr(localeRaw ?? 'en');
  final bl = makeLabeler(_brihadLabels, locale);
  final houses = asList(data['Houses']);
  final yogas = asList(data['Yogas']);
  final upcoming = asList(data['UpcomingDashas']);

  final housesSection = houses.isNotEmpty
      ? '<h2>${esc(bl('section_houses'))}</h2>\n${houses.map((raw) {
          final h = asMap(raw);
          final num = h['HouseNum'] ?? 0;
          final lordSign = truthy(h['LordSign'])
              ? ' (${esc(bl('in'))} ${esc(h['LordSign'])})'
              : '';
          final body = truthy(h['Body']) ? '<p>${esc(h['Body'])}</p>' : '';
          return '''<div class="house-block">
<h3>${esc(bl('house'))} ${esc(num)} — ${esc(_houseTopicOf(loc, num))}</h3>
<div class="meta">${esc(bl('lord'))}: ${esc(houseLordLabel(loc, h))}$lordSign</div>
$body
</div>''';
        }).join('\n')}'
      : '';

  final yogasSection = yogas.isNotEmpty
      ? '<h2>${esc(bl('section_yogas'))}</h2>\n${yogas.map((raw) {
          final y = asMap(raw);
          final src = truthy(y['Source'])
              ? '<div class="source">${esc(bl('source'))}: ${esc(y['Source'])}</div>'
              : '';
          return '<div class="yoga-block"><div class="name">${esc(yogaNameLabel(loc, y))}</div><p>${esc(y['Effect'])}</p>$src</div>';
        }).join('\n')}'
      : '';

  String dashaBlock(String cls, Map<String, Object?> d) =>
      '<div class="$cls"><div class="header-row"><span class="lord">${esc(dashaLordLabel(loc, d))}</span><span class="dates">${esc(d['StartDate'])} → ${esc(d['EndDate'])} (${esc(d['DurationY'])} ${esc(bl('years'))})</span></div><p>${esc(d['Body'])}</p></div>';

  var dashaInner = '';
  final cur = data['CurrentDasha'];
  if (truthy(cur)) {
    dashaInner += '<h3>${esc(bl('current_dasha'))}</h3>\n'
        '${dashaBlock('dasha-block', asMap(cur))}';
  }
  if (upcoming.isNotEmpty) {
    dashaInner += '\n<h3>${esc(bl('upcoming_dashas'))}</h3>\n'
        '${upcoming.map((d) => dashaBlock('dasha-block upcoming', asMap(d))).join('\n')}';
  }
  final dashaSection = dashaInner.isNotEmpty
      ? '<h2>${esc(bl('section_dashas'))}</h2>\n$dashaInner'
      : '';

  var doshasSection = '';
  final doshas = data['Doshas'];
  if (truthy(doshas) && anyDoshaPresent(doshas)) {
    final dd = asMap(doshas);
    String block(Object? raw, String nameKey) {
      if (!truthy(raw)) return '';
      final entry = asMap(raw);
      final sev = entry['Severity'] ?? '';
      final src = truthy(entry['Source'])
          ? '<div class="source">${esc(bl('source'))}: ${esc(entry['Source'])}</div>'
          : '';
      return '<div class="dosha-block ${esc(sev)}"><div class="header-row"><span class="name">${esc(doshaNameLabel(bl, entry, nameKey))}</span><span class="severity">${esc(severityLabel(bl, sev))}</span></div><p>${esc(entry['Body'])}</p>$src</div>';
    }

    doshasSection = '<h2>${esc(bl('section_doshas'))}</h2>\n'
        '${block(dd['Mangal'], 'dosha_mangal')}'
        '${block(dd['KaalSarp'], 'dosha_kaalsarp')}'
        '${block(dd['Pitra'], 'dosha_pitra')}';
  }

  final bodyHtml = [
    cover,
    ascendant,
    planetsTable,
    housesSection,
    yogasSection,
    dashaSection,
    doshasSection,
    panchangTable,
    narratives,
  ].where((s) => s.isNotEmpty).join('\n\n');

  return layoutDocument(
    lang: locale,
    title: '${t('title_kundli')} — ${jsStr(subject['Name'], nullAs: '')}',
    branding: resolved,
    bodyHtml: bodyHtml,
    extraCss: _midtierCss,
  );
}
