/// Match Making (Kundli Milan) report as HTML. Port of the Node SDK's src/pdf/templates/matchMaking.ts
/// (byte-identical output, golden-tested).
library;

import '../js.dart';
import '../shared.dart';

const _labels = {
  'en': {
    'title_match': 'Kundli Milan — Match Compatibility',
    'born': 'Born',
    'generated': 'Generated on',
    'section_ashtakoota': 'Ashtakoota — 8-Fold Compatibility',
    'section_doshas': 'Doshas',
    'section_final': 'Final Verdict',
    'koota': 'Koota',
    'max': 'Max',
    'score': 'Score',
    'details': 'Details',
    'total': 'Total',
    'nakshatra': 'Nakshatra',
    'ashtakoota_verdict': 'Ashtakoota Verdict',
    'mangal_dosha': 'Mangal Dosha',
    'nadi_dosha': 'Nadi Dosha',
  },
  'hi': {
    'title_match': 'कुंडली मिलान — मिलान पात्रता',
    'born': 'जन्म',
    'generated': 'तैयार',
    'section_ashtakoota': 'अष्टकूट — 36 गुण मिलान',
    'section_doshas': 'दोष',
    'section_final': 'अंतिम निष्कर्ष',
    'koota': 'कूट',
    'max': 'अधिकतम',
    'score': 'अंक',
    'details': 'विवरण',
    'total': 'कुल',
    'nakshatra': 'नक्षत्र',
    'ashtakoota_verdict': 'अष्टकूट निष्कर्ष',
    'mangal_dosha': 'मंगल दोष',
    'nadi_dosha': 'नाड़ी दोष',
  },
  'mr': {
    'title_match': 'कुंडली जुळवणी — मिलन पात्रता',
    'born': 'जन्म',
    'generated': 'तयार',
    'section_ashtakoota': 'अष्टकूट — 36 गुण जुळवणी',
    'section_doshas': 'दोष',
    'section_final': 'अंतिम निष्कर्ष',
    'koota': 'कूट',
    'max': 'कमाल',
    'score': 'गुण',
    'details': 'तपशील',
    'total': 'एकूण',
    'nakshatra': 'नक्षत्र',
    'ashtakoota_verdict': 'अष्टकूट निष्कर्ष',
    'mangal_dosha': 'मंगळ दोष',
    'nadi_dosha': 'नाडी दोष',
  },
  'te': {
    'title_match': 'జాతక పొంతన: వివాహ అనుకూలత',
    'born': 'జననం',
    'generated': 'రూపొందించిన తేదీ',
    'section_ashtakoota': 'అష్టకూట: 8 కూటాల పొంతన',
    'section_doshas': 'దోషాలు',
    'section_final': 'తుది నిర్ణయం',
    'koota': 'కూటం',
    'max': 'గరిష్ఠం',
    'score': 'గుణాలు',
    'details': 'వివరాలు',
    'total': 'మొత్తం',
    'nakshatra': 'నక్షత్రం',
    'ashtakoota_verdict': 'అష్టకూట నిర్ణయం',
    'mangal_dosha': 'కుజ దోషం',
    'nadi_dosha': 'నాడీ దోషం',
  },
  'ta': {
    'title_match': 'ஜாதகப் பொருத்தம்: திருமண இணக்கம்',
    'born': 'பிறப்பு',
    'generated': 'தயாரித்த நாள்',
    'section_ashtakoota': 'அஷ்டகூடம்: 8 கூடப் பொருத்தம்',
    'section_doshas': 'தோஷங்கள்',
    'section_final': 'இறுதி முடிவு',
    'koota': 'கூடம்',
    'max': 'அதிகபட்சம்',
    'score': 'புள்ளிகள்',
    'details': 'விவரம்',
    'total': 'மொத்தம்',
    'nakshatra': 'நட்சத்திரம்',
    'ashtakoota_verdict': 'அஷ்டகூட முடிவு',
    'mangal_dosha': 'செவ்வாய் தோஷம்',
    'nadi_dosha': 'நாடி தோஷம்',
  },
  'kn': {
    'title_match': 'ಜಾತಕ ಹೊಂದಾಣಿಕೆ: ವಿವಾಹ ಅನುರೂಪತೆ',
    'born': 'ಜನನ',
    'generated': 'ತಯಾರಿಸಿದ ದಿನಾಂಕ',
    'section_ashtakoota': 'ಅಷ್ಟಕೂಟ: 8 ಕೂಟಗಳ ಹೊಂದಾಣಿಕೆ',
    'section_doshas': 'ದೋಷಗಳು',
    'section_final': 'ಅಂತಿಮ ನಿರ್ಣಯ',
    'koota': 'ಕೂಟ',
    'max': 'ಗರಿಷ್ಠ',
    'score': 'ಗುಣ',
    'details': 'ವಿವರ',
    'total': 'ಒಟ್ಟು',
    'nakshatra': 'ನಕ್ಷತ್ರ',
    'ashtakoota_verdict': 'ಅಷ್ಟಕೂಟ ನಿರ್ಣಯ',
    'mangal_dosha': 'ಮಂಗಳ ದೋಷ',
    'nadi_dosha': 'ನಾಡಿ ದೋಷ',
  },
  'ml': {
    'title_match': 'ജാതകപ്പൊരുത്തം: വിവാഹയോഗ്യത',
    'born': 'ജനനം',
    'generated': 'തയ്യാറാക്കിയ തീയതി',
    'section_ashtakoota': 'അഷ്ടകൂടം: 8 കൂടങ്ങളുടെ പൊരുത്തം',
    'section_doshas': 'ദോഷങ്ങൾ',
    'section_final': 'അന്തിമ നിഗമനം',
    'koota': 'കൂടം',
    'max': 'പരമാവധി',
    'score': 'ഗുണം',
    'details': 'വിശദാംശം',
    'total': 'ആകെ',
    'nakshatra': 'നക്ഷത്രം',
    'ashtakoota_verdict': 'അഷ്ടകൂട നിഗമനം',
    'mangal_dosha': 'ചൊവ്വാദോഷം',
    'nadi_dosha': 'നാഡീദോഷം',
  },
  'gu': {
    'title_match': 'કુંડળી મેળાપ: વિવાહ પાત્રતા',
    'born': 'જન્મ',
    'generated': 'તૈયાર',
    'section_ashtakoota': 'અષ્ટકૂટ: 36 ગુણ મેળાપ',
    'section_doshas': 'દોષ',
    'section_final': 'અંતિમ નિષ્કર્ષ',
    'koota': 'કૂટ',
    'max': 'મહત્તમ',
    'score': 'ગુણ',
    'details': 'વિગત',
    'total': 'કુલ',
    'nakshatra': 'નક્ષત્ર',
    'ashtakoota_verdict': 'અષ્ટકૂટ નિષ્કર્ષ',
    'mangal_dosha': 'મંગળ દોષ',
    'nadi_dosha': 'નાડી દોષ',
  },
  'bn': {
    'title_match': 'কুণ্ডলী মিলন: যোটক বিচার',
    'born': 'জন্ম',
    'generated': 'তৈরি',
    'section_ashtakoota': 'অষ্টকূট: 36 গুণের মিলন',
    'section_doshas': 'দোষ',
    'section_final': 'চূড়ান্ত সিদ্ধান্ত',
    'koota': 'কূট',
    'max': 'সর্বোচ্চ',
    'score': 'প্রাপ্ত গুণ',
    'details': 'বিবরণ',
    'total': 'মোট',
    'nakshatra': 'নক্ষত্র',
    'ashtakoota_verdict': 'অষ্টকূটের সিদ্ধান্ত',
    'mangal_dosha': 'মাঙ্গলিক দোষ',
    'nadi_dosha': 'নাড়ী দোষ',
  },
  'pa': {
    'title_match': 'ਕੁੰਡਲੀ ਮਿਲਾਨ: ਮੇਲ ਦੀ ਯੋਗਤਾ',
    'born': 'ਜਨਮ',
    'generated': 'ਤਿਆਰ',
    'section_ashtakoota': 'ਅਸ਼ਟਕੂਟ: 36 ਗੁਣਾਂ ਦਾ ਮਿਲਾਨ',
    'section_doshas': 'ਦੋਸ਼',
    'section_final': 'ਅੰਤਿਮ ਨਤੀਜਾ',
    'koota': 'ਕੂਟ',
    'max': 'ਵੱਧ ਤੋਂ ਵੱਧ',
    'score': 'ਅੰਕ',
    'details': 'ਵੇਰਵਾ',
    'total': 'ਕੁੱਲ',
    'nakshatra': 'ਨਛੱਤਰ',
    'ashtakoota_verdict': 'ਅਸ਼ਟਕੂਟ ਦਾ ਨਤੀਜਾ',
    'mangal_dosha': 'ਮਾਂਗਲਿਕ ਦੋਸ਼',
    'nadi_dosha': 'ਨਾੜੀ ਦੋਸ਼',
  },
};

const _verdictLabels = {
  'en': {
    'poor': 'Poor',
    'fair': 'Fair',
    'good': 'Good',
    'excellent': 'Excellent',
  },
  'hi': {
    'poor': 'अल्प',
    'fair': 'सामान्य',
    'good': 'अच्छा',
    'excellent': 'उत्तम',
  },
  'mr': {
    'poor': 'अल्प',
    'fair': 'सामान्य',
    'good': 'चांगला',
    'excellent': 'उत्तम',
  },
  'te': {
    'poor': 'తక్కువ',
    'fair': 'సాధారణం',
    'good': 'మంచిది',
    'excellent': 'ఉత్తమం',
  },
  'ta': {
    'poor': 'குறைவு',
    'fair': 'சுமார்',
    'good': 'நல்லது',
    'excellent': 'உத்தமம்',
  },
  'kn': {
    'poor': 'ಕಡಿಮೆ',
    'fair': 'ಸಾಧಾರಣ',
    'good': 'ಉತ್ತಮ',
    'excellent': 'ಅತ್ಯುತ್ತಮ',
  },
  'ml': {
    'poor': 'കുറവ്',
    'fair': 'സാധാരണം',
    'good': 'നല്ലത്',
    'excellent': 'ഉത്തമം',
  },
  'gu': {
    'poor': 'અલ્પ',
    'fair': 'સામાન્ય',
    'good': 'સારું',
    'excellent': 'ઉત્તમ',
  },
  'bn': {
    'poor': 'অল্প',
    'fair': 'সাধারণ',
    'good': 'ভালো',
    'excellent': 'উত্তম',
  },
  'pa': {
    'poor': 'ਪ੍ਰਤੀਕੂਲ',
    'fair': 'ਸਾਧਾਰਨ',
    'good': 'ਚੰਗਾ',
    'excellent': 'ਉੱਤਮ',
  },
};

const _extraCss =
    '\n.cover .subjects { display: flex; justify-content: space-around; align-items: flex-start; margin-top: 8mm; }\n.cover .subject-col { flex: 1; max-width: 40%; }\n.cover .subject-col h2 { color: var(--brand-primary); border: none; font-size: 18pt; margin-bottom: 4mm; padding: 0; }\n.cover .subject-col .meta { color: var(--brand-secondary); font-size: 10pt; }\n.cover .vs { align-self: center; font-size: 24pt; color: var(--brand-secondary); padding: 0 8mm; }\nth.score { text-align: right; }\ntd.score { text-align: right; font-weight: 600; font-variant-numeric: tabular-nums; }\ntr.total td { background: #fafafa; font-weight: 700; border-top: 2px solid var(--brand-primary); border-bottom: none; }\n.verdict { margin-top: 6mm; padding: 5mm; border: 1px solid var(--brand-primary); border-radius: 3mm; background: #fafafa; }\n.verdict.excellent { border-color: #166534; }\n.verdict.good { border-color: #65a30d; }\n.verdict.fair { border-color: #ca8a04; }\n.verdict.poor { border-color: #dc2626; }\n.verdict h3 { margin: 0 0 2mm; font-size: 14pt; }\n.dosha-block { margin-top: 4mm; padding: 4mm; background: #fafafa; border-left: 3px solid var(--brand-secondary); }\n.dosha-block.has-dosha { border-left-color: #dc2626; }\n.dosha-block.cancelled { border-left-color: #ca8a04; }\n.dosha-block.no-dosha { border-left-color: #166534; }\n';

/// Verdict, dosha and nadi prose for te / ta / kn / ml / gu / bn (written from
/// the Hindi).
class _SouthMatchProse {
  _SouthMatchProse({
    required this.verdict,
    required this.mangalNotComputed,
    required this.mangalNone,
    required this.typePurn,
    required this.typeMild,
    required this.fromLagna,
    required this.fromMoon,
    required this.mangal,
    required this.cancelled,
    required this.nadiNone,
    required this.nadiExempted,
    required this.nadiHigh,
  });

  final Map<String, String> verdict;
  final String mangalNotComputed;
  final String mangalNone;
  final String typePurn;
  final String typeMild;
  final String Function(String hs) fromLagna;
  final String Function(String hs) fromMoon;
  final String Function(String type, String houses) mangal;
  final String cancelled;
  final String Function(String boy, String girl) nadiNone;
  final String Function(String exc) nadiExempted;
  final String Function(String boy) nadiHigh;
}

final _southMatch = <String, _SouthMatchProse>{
  'te': _SouthMatchProse(
    verdict: {
      'excellent': 'ఉత్తమ పొంతన: అన్ని రంగాలలో సామరస్యానికి అవకాశం ఎక్కువ.',
      'good': 'మంచి పొంతన: వివాహానికి అనుకూల సూచనలు ఉన్నాయి.',
      'fair': 'సాధారణ పొంతన: కొన్ని కూటాలలో లోటు ఉంది, అయినా ముందుకు సాగవచ్చు.',
      'poor':
          'తక్కువ పొంతన: చాలా కూటాలలో లోటు ఉంది, జాగ్రత్తగా ఆలోచించడం అవసరం.',
    },
    mangalNotComputed:
        'కుజ దోషం పరిశీలించలేదు: జన్మ స్థలం (అక్షాంశం/రేఖాంశం) ఇవ్వలేదు.',
    mangalNone: 'కుజ దోషం లేదు.',
    typePurn: 'పూర్ణ',
    typeMild: 'స్వల్ప',
    fromLagna: (String hs) => 'లగ్నం నుండి $hs',
    fromMoon: (String hs) => 'చంద్రుని నుండి $hs',
    mangal: (String type, String houses) => 'కుజ దోషం ($type), భావం: $houses.',
    cancelled: ' నివృత్తి: ',
    nadiNone: (String boy, String girl) =>
        'నాడీ దోషం లేదు. (వరుడు: $boy, వధువు: $girl)',
    nadiExempted: (String exc) =>
        'నాడీ దోషం ఉంది, కానీ శాస్త్రీయ మినహాయింపు వల్ల రద్దయింది ($exc)',
    nadiHigh: (String boy) =>
        'నాడీ దోషం: ఇద్దరిదీ ఒకే నాడి ($boy). శాస్త్రపరంగా ప్రతికూలం.',
  ),
  'ta': _SouthMatchProse(
    verdict: {
      'excellent':
          'உத்தமப் பொருத்தம்: எல்லாத் துறைகளிலும் இணக்கத்துக்கான வாய்ப்பு அதிகம்.',
      'good': 'நல்ல பொருத்தம்: திருமணத்துக்குச் சாதகமான அறிகுறிகள் உள்ளன.',
      'fair':
          'சுமாரான பொருத்தம்: சில கூடங்களில் குறை உள்ளது, ஆனாலும் முன்னேறலாம்.',
      'poor':
          'குறைவான பொருத்தம்: பல கூடங்களில் குறை உள்ளது, கவனமாக யோசிப்பது அவசியம்.',
    },
    mangalNotComputed:
        'செவ்வாய் தோஷம் சரிபார்க்கப்படவில்லை: பிறந்த இடம் (அட்சரேகை/தீர்க்கரேகை) கொடுக்கப்படவில்லை.',
    mangalNone: 'செவ்வாய் தோஷம் இல்லை.',
    typePurn: 'முழு',
    typeMild: 'லேசான',
    fromLagna: (String hs) => 'லக்னத்திலிருந்து $hs',
    fromMoon: (String hs) => 'சந்திரனிலிருந்து $hs',
    mangal: (String type, String houses) =>
        'செவ்வாய் தோஷம் ($type), வீடு: $houses.',
    cancelled: ' நிவர்த்தி: ',
    nadiNone: (String boy, String girl) =>
        'நாடி தோஷம் இல்லை. (மணமகன்: $boy, மணமகள்: $girl)',
    nadiExempted: (String exc) =>
        'நாடி தோஷம் உள்ளது, ஆனால் சாஸ்திர விதிவிலக்கால் நீங்குகிறது ($exc)',
    nadiHigh: (String boy) =>
        'நாடி தோஷம்: இருவருக்கும் ஒரே நாடி ($boy). சாஸ்திரப்படி பாதகமானது.',
  ),
  'kn': _SouthMatchProse(
    verdict: {
      'excellent':
          'ಅತ್ಯುತ್ತಮ ಹೊಂದಾಣಿಕೆ: ಎಲ್ಲಾ ಕ್ಷೇತ್ರಗಳಲ್ಲೂ ಸಾಮರಸ್ಯದ ಸಾಧ್ಯತೆ ಹೆಚ್ಚು.',
      'good': 'ಉತ್ತಮ ಹೊಂದಾಣಿಕೆ: ವಿವಾಹಕ್ಕೆ ಅನುಕೂಲಕರ ಸೂಚನೆಗಳಿವೆ.',
      'fair':
          'ಸಾಧಾರಣ ಹೊಂದಾಣಿಕೆ: ಕೆಲವು ಕೂಟಗಳಲ್ಲಿ ಕೊರತೆ ಇದೆ, ಆದರೂ ಮುಂದುವರಿಯಬಹುದು.',
      'poor':
          'ಕಡಿಮೆ ಹೊಂದಾಣಿಕೆ: ಹಲವು ಕೂಟಗಳಲ್ಲಿ ಕೊರತೆ ಇದೆ, ಎಚ್ಚರಿಕೆಯಿಂದ ಯೋಚಿಸುವುದು ಅಗತ್ಯ.',
    },
    mangalNotComputed:
        'ಮಂಗಳ ದೋಷ ಪರಿಶೀಲಿಸಿಲ್ಲ: ಜನ್ಮ ಸ್ಥಳ (ಅಕ್ಷಾಂಶ/ರೇಖಾಂಶ) ನೀಡಿಲ್ಲ.',
    mangalNone: 'ಮಂಗಳ ದೋಷ ಇಲ್ಲ.',
    typePurn: 'ಪೂರ್ಣ',
    typeMild: 'ಅಲ್ಪ',
    fromLagna: (String hs) => 'ಲಗ್ನದಿಂದ $hs',
    fromMoon: (String hs) => 'ಚಂದ್ರನಿಂದ $hs',
    mangal: (String type, String houses) => 'ಮಂಗಳ ದೋಷ ($type), ಭಾವ: $houses.',
    cancelled: ' ನಿವಾರಣೆ: ',
    nadiNone: (String boy, String girl) =>
        'ನಾಡಿ ದೋಷ ಇಲ್ಲ. (ವರ: $boy, ವಧು: $girl)',
    nadiExempted: (String exc) =>
        'ನಾಡಿ ದೋಷ ಇದೆ, ಆದರೆ ಶಾಸ್ತ್ರೀಯ ವಿನಾಯಿತಿಯಿಂದ ರದ್ದಾಗಿದೆ ($exc)',
    nadiHigh: (String boy) =>
        'ನಾಡಿ ದೋಷ: ಇಬ್ಬರದೂ ಒಂದೇ ನಾಡಿ ($boy). ಶಾಸ್ತ್ರದ ಪ್ರಕಾರ ಪ್ರತಿಕೂಲ.',
  ),
  'ml': _SouthMatchProse(
    verdict: {
      'excellent':
          'ഉത്തമ പൊരുത്തം: എല്ലാ മേഖലകളിലും ഐക്യത്തിനുള്ള സാധ്യത കൂടുതലാണ്.',
      'good': 'നല്ല പൊരുത്തം: വിവാഹത്തിന് അനുകൂലമായ സൂചനകളുണ്ട്.',
      'fair':
          'സാധാരണ പൊരുത്തം: ചില കൂടങ്ങളിൽ കുറവുണ്ട്, എങ്കിലും മുന്നോട്ട് പോകാം.',
      'poor':
          'കുറഞ്ഞ പൊരുത്തം: പല കൂടങ്ങളിലും കുറവുണ്ട്, ശ്രദ്ധാപൂർവം ആലോചിക്കേണ്ടതുണ്ട്.',
    },
    mangalNotComputed:
        'ചൊവ്വാദോഷം പരിശോധിച്ചിട്ടില്ല: ജനനസ്ഥലം (അക്ഷാംശം/രേഖാംശം) നൽകിയിട്ടില്ല.',
    mangalNone: 'ചൊവ്വാദോഷം ഇല്ല.',
    typePurn: 'പൂർണ',
    typeMild: 'അൽപ',
    fromLagna: (String hs) => 'ലഗ്നത്തിൽ നിന്ന് $hs',
    fromMoon: (String hs) => 'ചന്ദ്രനിൽ നിന്ന് $hs',
    mangal: (String type, String houses) =>
        'ചൊവ്വാദോഷം ($type), ഭാവം: $houses.',
    cancelled: ' പരിഹാരം: ',
    nadiNone: (String boy, String girl) =>
        'നാഡീദോഷം ഇല്ല. (വരൻ: $boy, വധു: $girl)',
    nadiExempted: (String exc) =>
        'നാഡീദോഷം ഉണ്ട്, എന്നാൽ ശാസ്ത്രീയ ഇളവിനാൽ റദ്ദാകുന്നു ($exc)',
    nadiHigh: (String boy) =>
        'നാഡീദോഷം: ഇരുവർക്കും ഒരേ നാഡി ($boy). ശാസ്ത്രപ്രകാരം പ്രതികൂലം.',
  ),
  'gu': _SouthMatchProse(
    verdict: {
      'excellent': 'ઉત્તમ મેળાપ: તમામ ક્ષેત્રોમાં સામંજસ્યની સંભાવના વધુ છે.',
      'good': 'સારો મેળાપ: વિવાહ માટે અનુકૂળ યોગ છે.',
      'fair': 'સામાન્ય મેળાપ: કેટલાક કૂટોમાં ઊણપ છે, છતાં આગળ વધી શકાય છે.',
      'poor':
          'અલ્પ મેળાપ: ઘણા કૂટોમાં ઊણપ છે, કાળજીપૂર્વક વિચાર કરવો આવશ્યક છે.',
    },
    mangalNotComputed:
        'મંગળ દોષની તપાસ થઈ નથી: જન્મસ્થળ (અક્ષાંશ/રેખાંશ) આપવામાં આવ્યું નથી.',
    mangalNone: 'મંગળ દોષ નથી.',
    typePurn: 'પૂર્ણ',
    typeMild: 'અલ્પ',
    fromLagna: (String hs) => 'લગ્નથી $hs',
    fromMoon: (String hs) => 'ચંદ્રથી $hs',
    mangal: (String type, String houses) => 'મંગળ દોષ ($type), ભાવ: $houses.',
    cancelled: ' નિવારણ: ',
    nadiNone: (String boy, String girl) =>
        'નાડી દોષ નથી. (વર: $boy, વધૂ: $girl)',
    nadiExempted: (String exc) =>
        'નાડી દોષ છે, પરંતુ શાસ્ત્રીય અપવાદને કારણે રદ થાય છે ($exc)',
    nadiHigh: (String boy) =>
        'નાડી દોષ: બંનેની નાડી એક જ છે ($boy). શાસ્ત્રીય રીતે પ્રતિકૂળ.',
  ),
  'bn': _SouthMatchProse(
    verdict: {
      'excellent': 'উত্তম মিলন: সব ক্ষেত্রে সামঞ্জস্যের সম্ভাবনা বেশি।',
      'good': 'ভালো মিলন: বিবাহের জন্য অনুকূল যোগ।',
      'fair': 'সাধারণ মিলন: কয়েকটি কূটে ঘাটতি আছে, তবু এগোনো যায়।',
      'poor':
          'অল্প মিলন: অনেক কূটে ঘাটতি আছে, ভেবেচিন্তে সিদ্ধান্ত নেওয়া জরুরি।',
    },
    mangalNotComputed:
        'মাঙ্গলিক দোষের পরীক্ষা হয়নি: জন্মস্থান (অক্ষাংশ/দ্রাঘিমাংশ) দেওয়া হয়নি।',
    mangalNone: 'মাঙ্গলিক দোষ নেই।',
    typePurn: 'পূর্ণ',
    typeMild: 'অল্প',
    fromLagna: (String hs) => 'লগ্ন থেকে $hs',
    fromMoon: (String hs) => 'চন্দ্র থেকে $hs',
    mangal: (String type, String houses) =>
        'মাঙ্গলিক দোষ ($type), ভাব: $houses।',
    cancelled: ' নিবারণ: ',
    nadiNone: (String boy, String girl) =>
        'নাড়ী দোষ নেই। (পাত্র: $boy, পাত্রী: $girl)',
    nadiExempted: (String exc) =>
        'নাড়ী দোষ আছে, তবে শাস্ত্রীয় ব্যতিক্রমের কারণে তা খণ্ডিত হয় ($exc)',
    nadiHigh: (String boy) =>
        'নাড়ী দোষ: দুজনেরই একই নাড়ী ($boy)। শাস্ত্রমতে প্রতিকূল।',
  ),
  'pa': _SouthMatchProse(
    verdict: {
      'excellent': 'ਉੱਤਮ ਮਿਲਾਨ: ਸਾਰੇ ਖੇਤਰਾਂ ਵਿੱਚ ਤਾਲਮੇਲ ਦੀ ਸੰਭਾਵਨਾ ਵੱਧ ਹੈ।',
      'good': 'ਚੰਗਾ ਮਿਲਾਨ: ਵਿਆਹ ਲਈ ਅਨੁਕੂਲ ਯੋਗ।',
      'fair': 'ਸਾਧਾਰਨ ਮਿਲਾਨ: ਕੁਝ ਕੂਟਾਂ ਵਿੱਚ ਕਮੀ ਹੈ, ਪਰ ਅੱਗੇ ਵਧਿਆ ਜਾ ਸਕਦਾ ਹੈ।',
      'poor':
          'ਘੱਟ ਮਿਲਾਨ: ਕਈ ਕੂਟਾਂ ਵਿੱਚ ਕਮੀ ਹੈ, ਸੋਚ-ਸਮਝ ਕੇ ਵਿਚਾਰ ਕਰਨਾ ਜ਼ਰੂਰੀ ਹੈ।',
    },
    mangalNotComputed:
        'ਮਾਂਗਲਿਕ ਦੋਸ਼ ਦੀ ਜਾਂਚ ਨਹੀਂ ਹੋਈ: ਜਨਮ ਸਥਾਨ (ਅਕਸ਼ਾਂਸ਼/ਦੇਸ਼ਾਂਤਰ) ਨਹੀਂ ਦਿੱਤਾ ਗਿਆ।',
    mangalNone: 'ਮਾਂਗਲਿਕ ਦੋਸ਼ ਨਹੀਂ ਹੈ।',
    typePurn: 'ਪੂਰਨ',
    typeMild: 'ਹਲਕਾ',
    fromLagna: (String hs) => 'ਲਗਨ ਤੋਂ $hs',
    fromMoon: (String hs) => 'ਚੰਦਰਮਾ ਤੋਂ $hs',
    mangal: (String type, String houses) =>
        'ਮਾਂਗਲਿਕ ਦੋਸ਼ ($type), ਭਾਵ: $houses।',
    cancelled: ' ਨਿਵਾਰਨ: ',
    nadiNone: (String boy, String girl) =>
        'ਨਾੜੀ ਦੋਸ਼ ਨਹੀਂ ਹੈ। (ਵਰ: $boy, ਲਾੜੀ: $girl)',
    nadiExempted: (String exc) =>
        'ਨਾੜੀ ਦੋਸ਼ ਹੈ, ਪਰ ਸ਼ਾਸਤਰੀ ਛੋਟ ਕਾਰਨ ਇਸ ਦਾ ਨਿਵਾਰਨ ਹੋ ਜਾਂਦਾ ਹੈ ($exc)',
    nadiHigh: (String boy) =>
        'ਨਾੜੀ ਦੋਸ਼: ਦੋਹਾਂ ਦੀ ਨਾੜੀ ਇੱਕੋ ਹੈ ($boy)। ਸ਼ਾਸਤਰ ਅਨੁਸਾਰ ਪ੍ਰਤੀਕੂਲ।',
  ),
};

/// Narrows a request locale to one with labels (fail-open to `en`).
String _pickLocale(String? loc) =>
    loc != null && loc.isNotEmpty && _labels[loc] != null ? loc : 'en';

/// The verdict key ("poor" | "fair" | "good" | "excellent") in [loc], or the
/// raw verdict when it has no label.
Object _verdictLabel(String? loc, Object? verdict) {
  final v = verdict ?? '';
  final table = _verdictLabels[_pickLocale(loc)] ??
      _verdictLabels['en'] ??
      const <String, String>{};
  return table[jsStr(v)] ?? v;
}

/// Short prose describing what the Ashtakoota score band means.
String _verdictDescription(String? loc, Object? verdict) {
  final l = _pickLocale(loc);
  final south = _southMatch[l];
  if (south != null) {
    if (verdict == 'excellent' || verdict == 'good' || verdict == 'fair') {
      return south.verdict[verdict]!;
    }
    return south.verdict['poor']!;
  }
  switch (verdict) {
    case 'excellent':
      if (l == 'hi') {
        return 'उत्तम मिलान — सभी क्षेत्रों में सामंजस्य की संभावना अधिक है।';
      }
      if (l == 'mr') {
        return 'उत्तम जुळवणी — सर्व क्षेत्रांत सामंजस्याची शक्यता अधिक आहे.';
      }
      return 'Excellent match — high compatibility across all areas.';
    case 'good':
      if (l == 'hi') {
        return 'अच्छा मिलान — विवाह के लिए अनुकूल योग।';
      }
      if (l == 'mr') {
        return 'चांगली जुळवणी — विवाहासाठी अनुकूल योग.';
      }
      return 'Good match — favorable indications for marriage.';
    case 'fair':
      if (l == 'hi') {
        return 'सामान्य मिलान — कुछ कूटों में कमी, परंतु आगे बढ़ने योग्य।';
      }
      if (l == 'mr') {
        return 'सामान्य जुळवणी — काही कूटांमध्ये कमतरता, परंतु पुढे जाण्यायोग्य.';
      }
      return 'Fair match — some kootas underscore but workable with awareness.';
    default:
      if (l == 'hi') {
        return 'अल्प मिलान — कई कूटों में कमी, सावधानीपूर्वक विचार आवश्यक।';
      }
      if (l == 'mr') {
        return 'अल्प जुळवणी — अनेक कूटांमध्ये कमतरता, काळजीपूर्वक विचार आवश्यक.';
      }
      return 'Low score — multiple kootas underscore; careful consideration advised.';
  }
}

/// CSS class for a Mangal Dosha block.
String _doshaClass(Map<String, Object?> d) {
  if (!truthy(d['Computed'])) return 'not-computed';
  if (truthy(d['HasDosha']) && truthy(d['Cancelled'])) return 'cancelled';
  if (truthy(d['HasDosha'])) return 'has-dosha';
  return 'no-dosha';
}

/// JS `Array.isArray(items) ? items.join(sep) : ""`.
String _joinStrings(Object? items, String sep) =>
    items is List ? items.map((e) => e == null ? '' : jsStr(e)).join(sep) : '';

/// Mangal Dosha trigger houses: positive = from the Lagna, negative (its
/// absolute value) = from the Moon. JS `hs.filter((h) => h > 0).map(String)`
/// and `hs.filter((h) => h < 0).map((h) => String(-h))`.
(List<String>, List<String>) _splitHouses(Object? housesOccupied) {
  final hs = asList(housesOccupied);
  return (
    [
      for (final h in hs)
        if (jsNumber(h) > 0) jsStr(h)
    ],
    [
      for (final h in hs)
        if (jsNumber(h) < 0) jsNum(-jsNumber(h))
    ],
  );
}

/// Mangal Dosha summary text, including the Computed=false honesty guard.
String _doshaSummary(String? loc, Map<String, Object?> d) {
  final l = _pickLocale(loc);
  final south = _southMatch[l];
  final rawType = jsStr(d['Type'] ?? '');
  if (south != null) {
    if (!truthy(d['Computed'])) return south.mangalNotComputed;
    if (!truthy(d['HasDosha'])) return south.mangalNone;
    final type = d['Type'] == 'purn'
        ? south.typePurn
        : d['Type'] == 'mild'
            ? south.typeMild
            : rawType;
    final (lag, moon) = _splitHouses(d['HousesOccupied']);
    final parts = <String>[];
    if (lag.isNotEmpty) parts.add(south.fromLagna(lag.join(', ')));
    if (moon.isNotEmpty) parts.add(south.fromMoon(moon.join(', ')));
    var out = south.mangal(type, parts.join('; '));
    if (truthy(d['Cancelled'])) {
      out += south.cancelled + _joinStrings(d['CancelReasons'], ', ');
    }
    return out;
  }
  if (!truthy(d['Computed'])) {
    if (l == 'hi') {
      return 'मंगल दोष की जाँच नहीं हुई — जन्म स्थान (अक्षांश/देशांतर) नहीं दिया गया।';
    }
    if (l == 'mr') {
      return 'मंगळ दोष तपासला नाही — जन्मस्थान (अक्षांश/रेखांश) दिलेले नाही.';
    }
    return 'Mangal Dosha not evaluated — birth latitude/longitude not provided.';
  }
  if (!truthy(d['HasDosha'])) {
    if (l == 'hi') {
      return 'मंगल दोष नहीं है।';
    }
    if (l == 'mr') {
      return 'मंगळ दोष नाही.';
    }
    return 'No Mangal Dosha present.';
  }
  // Type is a code ("purn"/"mild"): show a readable label, not the raw code.
  final typeLabel = l == 'hi' || l == 'mr'
      ? d['Type'] == 'purn'
          ? 'पूर्ण'
          : d['Type'] == 'mild'
              ? 'अल्प'
              : rawType
      : d['Type'] == 'purn'
          ? 'full'
          : d['Type'] == 'mild'
              ? 'mild'
              : rawType;
  final (lagnaH, moonH) = _splitHouses(d['HousesOccupied']);
  final houseParts = <String>[];
  if (l == 'hi') {
    if (lagnaH.isNotEmpty) {
      houseParts.add('लग्न से ${lagnaH.join(", ")}');
    }
    if (moonH.isNotEmpty) {
      houseParts.add('चंद्र से ${moonH.join(", ")}');
    }
  } else if (l == 'mr') {
    if (lagnaH.isNotEmpty) {
      houseParts.add('लग्नापासून ${lagnaH.join(", ")}');
    }
    if (moonH.isNotEmpty) {
      houseParts.add('चंद्रापासून ${moonH.join(", ")}');
    }
  } else {
    if (lagnaH.isNotEmpty) {
      houseParts.add('${lagnaH.join(", ")} from lagna');
    }
    if (moonH.isNotEmpty) {
      houseParts.add('${moonH.join(", ")} from Moon');
    }
  }
  final houses = houseParts.join('; ');
  String out;
  if (l == 'hi') {
    out = 'मंगल दोष ($typeLabel) — भाव: $houses।';
  } else if (l == 'mr') {
    out = 'मंगळ दोष ($typeLabel) — स्थाने: $houses.';
  } else {
    out = 'Mangal Dosha ($typeLabel) — house(s): $houses.';
  }
  if (truthy(d['Cancelled'])) {
    final reasons = _joinStrings(d['CancelReasons'], ', ');
    if (l == 'hi') {
      out += ' रद्द: $reasons';
    } else if (l == 'mr') {
      out += ' रद्द: $reasons';
    } else {
      out += ' Cancelled: $reasons';
    }
  }
  return out;
}

/// CSS class for the nadi block.
String _nadiClass(Map<String, Object?> n) {
  switch (n['Severity']) {
    case 'exempted':
      return 'cancelled';
    case 'high':
      return 'has-dosha';
    default:
      return 'no-dosha';
  }
}

/// Nadi Dosha summary text.
String _nadiSummary(String? loc, Map<String, Object?> n) {
  final l = _pickLocale(loc);
  final boy = jsStr(n['BoyNadi'] ?? '');
  final girl = jsStr(n['GirlNadi'] ?? '');
  final south = _southMatch[l];
  if (south != null) {
    if (n['Severity'] == 'none') return south.nadiNone(boy, girl);
    if (n['Severity'] == 'exempted') {
      return south.nadiExempted(_joinStrings(n['Exceptions'], ', '));
    }
    return south.nadiHigh(boy);
  }
  switch (n['Severity']) {
    case 'none':
      if (l == 'hi') {
        return 'नाड़ी दोष नहीं है। (वर: $boy, वधू: $girl)';
      }
      if (l == 'mr') {
        return 'नाडी दोष नाही. (वर: $boy, वधू: $girl)';
      }
      return 'No Nadi Dosha. (Boy: $boy, Girl: $girl)';
    case 'exempted':
      final exc = _joinStrings(n['Exceptions'], ', ');
      if (l == 'hi') {
        return 'नाड़ी दोष है परन्तु शास्त्रीय अपवाद से रद्द ($exc)';
      }
      if (l == 'mr') {
        return 'नाडी दोष आहे परंतु शास्त्रीय अपवादाने रद्द ($exc)';
      }
      return 'Nadi Dosha present but exempted by classical rule ($exc)';
    default: // "high"
      if (l == 'hi') {
        return 'नाड़ी दोष — दोनों की नाड़ी समान ($boy)। शास्त्रीय रूप से प्रतिकूल।';
      }
      if (l == 'mr') {
        return 'नाडी दोष — दोघांची नाडी समान ($boy). शास्त्रानुसार प्रतिकूल.';
      }
      return 'Nadi Dosha — both share $boy nadi. Classically unfavorable.';
  }
}

/// Final verdict line: the handler-supplied `FinalVerdict` when present, else
/// derived from the total.
Object _matchVerdict(Map<String, Object?> data) {
  final finalVerdict = data['FinalVerdict'];
  if (finalVerdict != null && truthy(finalVerdict)) return finalVerdict;
  final total = asMap(data['Ashtakoota'])['Total'] ?? 0;
  if (jsNumber(total) >= 24) {
    return 'Marriage indications are favorable. Study both charts for the timing.';
  }
  return 'Score is below conventional threshold (24/36). Consider remedies and a detailed study of both charts.';
}

/// Renders the Match Making (Kundli Milan) report
/// (`client.reports.matchMaking`) as a complete HTML document. [branding]
/// fields win over the branding in the report JSON.
String renderMatchMakingHtml(Map<String, Object?> data, [Branding? branding]) {
  data = withoutNullItems(withSafeLocale(data));
  final resolved = resolveBranding(data['Branding'], branding);
  final localeRaw = data['Locale'];
  final locale = localeRaw == null ? null : jsStr(localeRaw);
  final t = makeLabeler(_labels, locale);

  final boy = asMap(data['Boy']);
  final girl = asMap(data['Girl']);
  final ashtakoota = asMap(data['Ashtakoota']);
  final kootas = asList(ashtakoota['Kootas']);
  final verdict = ashtakoota['Verdict'] ?? '';
  final boyName = boy['name'] ?? '';
  final girlName = girl['name'] ?? '';

  // Cover page: two subjects side by side, a marriage symbol between.
  String subjectMeta(Map<String, Object?> s) =>
      '${esc(t('born'))} ${esc(s['birth_date'])}<br>${esc(s['birth_time'])}<br>${esc(s['birth_place'])}<br>${esc(t('nakshatra'))}: ${esc(s['nakshatra'])}';
  final cover = '''<section class="cover">
  ${coverBrandingHtml(resolved)}
  <h1>${esc(t('title_match'))}</h1>
  <div class="subjects">
    <div class="subject-col">
      <h2>${esc(boyName)}</h2>
      <div class="meta">${subjectMeta(boy)}</div>
    </div>
    <div class="vs">\u{26AD}</div>
    <div class="subject-col">
      <h2>${esc(girlName)}</h2>
      <div class="meta">${subjectMeta(girl)}</div>
    </div>
  </div>
  <div class="generated">${esc(t('generated'))} ${esc(formatGenerated(data['GeneratedAt']))}</div>
</section>''';

  // Ashtakoota score table (koota / max / score / details), then total row.
  final kootaRows = kootas.map((raw) {
    final k = asMap(raw);
    return '<tr><td>${esc(k['name'])}</td><td class="score">${esc(k['Max'])}</td><td class="score">${esc(k['score'])}</td><td>${esc(k['Reason'])}</td></tr>';
  }).join();
  final totalRow =
      '<tr class="total"><td>${esc(t('total'))}</td><td class="score">${esc(ashtakoota['Max'])}</td><td class="score">${esc(ashtakoota['Total'])}</td><td>${esc(_verdictLabel(locale, verdict))}</td></tr>';
  final ashtakootaTable = '''<h2>${esc(t('section_ashtakoota'))}</h2>
<table>
  <thead>
    <tr>
      <th>${esc(t('koota'))}</th>
      <th class="score">${esc(t('max'))}</th>
      <th class="score">${esc(t('score'))}</th>
      <th>${esc(t('details'))}</th>
    </tr>
  </thead>
  <tbody>$kootaRows$totalRow</tbody>
</table>
<div class="verdict ${esc(verdict)}">
  <h3>${esc(t('ashtakoota_verdict'))}: ${esc(_verdictLabel(locale, verdict))}</h3>
  <p>${esc(_verdictDescription(locale, verdict))}</p>
</div>''';

  // Dosha analysis: Mangal (boy + girl) + Nadi.
  final mangalBoy = asMap(data['MangalDoshaBoy']);
  final mangalGirl = asMap(data['MangalDoshaGirl']);
  final nadi = asMap(data['NadiDosha']);
  final doshas = '''<h2>${esc(t('section_doshas'))}</h2>
<h3>${esc(t('mangal_dosha'))} — ${esc(boyName)}</h3>
<div class="dosha-block ${esc(_doshaClass(mangalBoy))}">${esc(_doshaSummary(locale, mangalBoy))}</div>
<h3>${esc(t('mangal_dosha'))} — ${esc(girlName)}</h3>
<div class="dosha-block ${esc(_doshaClass(mangalGirl))}">${esc(_doshaSummary(locale, mangalGirl))}</div>
<h3>${esc(t('nadi_dosha'))}</h3>
<div class="dosha-block ${esc(_nadiClass(nadi))}">${esc(_nadiSummary(locale, nadi))}</div>''';

  // Final verdict band.
  final finalVerdict = '''<h2>${esc(t('section_final'))}</h2>
<div class="verdict ${esc(verdict)}">
  <p>${esc(_matchVerdict(data))}</p>
</div>''';

  final bodyHtml = [cover, ashtakootaTable, doshas, finalVerdict].join('\n\n');

  return layoutDocument(
    lang: locale,
    title: '${t('title_match')} — ${jsStr(boyName)} × ${jsStr(girlName)}',
    branding: resolved,
    bodyHtml: bodyHtml,
    extraCss: _extraCss,
  );
}
