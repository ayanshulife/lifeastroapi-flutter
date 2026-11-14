/// Locale tables shared by the report templates. Port of the Node SDK's
/// src/pdf/locales.ts; the tables are copied by tool/ts_tables.mjs.
library;

// ignore_for_file: public_member_api_docs

const devanagariLocales = [
  'hi',
  'mr',
];

const southLocales = [
  'te',
  'ta',
  'kn',
  'ml',
  'gu',
  'bn',
];

const indicFontStack =
    '\'Noto Sans\', \'Noto Sans Devanagari\', \'Noto Sans Telugu\', \'Noto Sans Tamil\', \'Noto Sans Kannada\', \'Noto Sans Bengali\', \'Noto Sans Gujarati\', \'Noto Sans Gurmukhi\', \'Noto Sans Malayalam\', sans-serif';

const indicFontStackAttr =
    'Noto Sans, Noto Sans Devanagari, Noto Sans Telugu, Noto Sans Tamil, Noto Sans Kannada, Noto Sans Bengali, Noto Sans Gujarati, Noto Sans Gurmukhi, Noto Sans Malayalam, sans-serif';

const planetNames = {
  'te': {
    'Sun': 'సూర్యుడు',
    'Moon': 'చంద్రుడు',
    'Mars': 'కుజుడు',
    'Mercury': 'బుధుడు',
    'Jupiter': 'గురువు',
    'Venus': 'శుక్రుడు',
    'Saturn': 'శని',
    'Rahu': 'రాహువు',
    'Ketu': 'కేతువు',
    'Lagna': 'లగ్నం',
  },
  'ta': {
    'Sun': 'சூரியன்',
    'Moon': 'சந்திரன்',
    'Mars': 'செவ்வாய்',
    'Mercury': 'புதன்',
    'Jupiter': 'குரு',
    'Venus': 'சுக்கிரன்',
    'Saturn': 'சனி',
    'Rahu': 'ராகு',
    'Ketu': 'கேது',
    'Lagna': 'லக்னம்',
  },
  'kn': {
    'Sun': 'ಸೂರ್ಯ',
    'Moon': 'ಚಂದ್ರ',
    'Mars': 'ಮಂಗಳ',
    'Mercury': 'ಬುಧ',
    'Jupiter': 'ಗುರು',
    'Venus': 'ಶುಕ್ರ',
    'Saturn': 'ಶನಿ',
    'Rahu': 'ರಾಹು',
    'Ketu': 'ಕೇತು',
    'Lagna': 'ಲಗ್ನ',
  },
  'ml': {
    'Sun': 'സൂര്യൻ',
    'Moon': 'ചന്ദ്രൻ',
    'Mars': 'ചൊവ്വ',
    'Mercury': 'ബുധൻ',
    'Jupiter': 'വ്യാഴം',
    'Venus': 'ശുക്രൻ',
    'Saturn': 'ശനി',
    'Rahu': 'രാഹു',
    'Ketu': 'കേതു',
    'Lagna': 'ലഗ്നം',
  },
  'gu': {
    'Sun': 'સૂર્ય',
    'Moon': 'ચંદ્ર',
    'Mars': 'મંગળ',
    'Mercury': 'બુધ',
    'Jupiter': 'ગુરુ',
    'Venus': 'શુક્ર',
    'Saturn': 'શનિ',
    'Rahu': 'રાહુ',
    'Ketu': 'કેતુ',
    'Lagna': 'લગ્ન',
  },
  'bn': {
    'Sun': 'সূর্য',
    'Moon': 'চন্দ্র',
    'Mars': 'মঙ্গল',
    'Mercury': 'বুধ',
    'Jupiter': 'বৃহস্পতি',
    'Venus': 'শুক্র',
    'Saturn': 'শনি',
    'Rahu': 'রাহু',
    'Ketu': 'কেতু',
    'Lagna': 'লগ্ন',
  },
};

const yoginiNames = {
  'te': {
    'Mangala': 'మంగళా',
    'Pingala': 'పింగళా',
    'Dhanya': 'ధాన్యా',
    'Bhramari': 'భ్రమరి',
    'Bhadrika': 'భద్రికా',
    'Ulka': 'ఉల్కా',
    'Siddha': 'సిద్ధా',
    'Sankata': 'సంకటా',
  },
  'ta': {
    'Mangala': 'மங்களா',
    'Pingala': 'பிங்களா',
    'Dhanya': 'தான்யா',
    'Bhramari': 'ப்ரமரி',
    'Bhadrika': 'பத்ரிகா',
    'Ulka': 'உல்கா',
    'Siddha': 'சித்தா',
    'Sankata': 'சங்கடா',
  },
  'kn': {
    'Mangala': 'ಮಂಗಳಾ',
    'Pingala': 'ಪಿಂಗಳಾ',
    'Dhanya': 'ಧಾನ್ಯಾ',
    'Bhramari': 'ಭ್ರಮರಿ',
    'Bhadrika': 'ಭದ್ರಿಕಾ',
    'Ulka': 'ಉಲ್ಕಾ',
    'Siddha': 'ಸಿದ್ಧಾ',
    'Sankata': 'ಸಂಕಟಾ',
  },
  'ml': {
    'Mangala': 'മംഗള',
    'Pingala': 'പിംഗള',
    'Dhanya': 'ധാന്യ',
    'Bhramari': 'ഭ്രമരി',
    'Bhadrika': 'ഭദ്രിക',
    'Ulka': 'ഉൽക',
    'Siddha': 'സിദ്ധ',
    'Sankata': 'സങ്കട',
  },
  'gu': {
    'Mangala': 'મંગલા',
    'Pingala': 'પિંગલા',
    'Dhanya': 'ધાન્યા',
    'Bhramari': 'ભ્રમરી',
    'Bhadrika': 'ભદ્રિકા',
    'Ulka': 'ઉલ્કા',
    'Siddha': 'સિદ્ધા',
    'Sankata': 'સંકટા',
  },
  'bn': {
    'Mangala': 'মঙ্গলা',
    'Pingala': 'পিঙ্গলা',
    'Dhanya': 'ধান্যা',
    'Bhramari': 'ভ্রমরী',
    'Bhadrika': 'ভদ্রিকা',
    'Ulka': 'উল্কা',
    'Siddha': 'সিদ্ধা',
    'Sankata': 'সঙ্কটা',
  },
};

const rashiNames = {
  'te': [
    'మేషం',
    'వృషభం',
    'మిథునం',
    'కర్కాటకం',
    'సింహం',
    'కన్య',
    'తుల',
    'వృశ్చికం',
    'ధనుస్సు',
    'మకరం',
    'కుంభం',
    'మీనం',
  ],
  'ta': [
    'மேஷம்',
    'ரிஷபம்',
    'மிதுனம்',
    'கடகம்',
    'சிம்மம்',
    'கன்னி',
    'துலாம்',
    'விருச்சிகம்',
    'தனுசு',
    'மகரம்',
    'கும்பம்',
    'மீனம்',
  ],
  'kn': [
    'ಮೇಷ',
    'ವೃಷಭ',
    'ಮಿಥುನ',
    'ಕರ್ಕಾಟಕ',
    'ಸಿಂಹ',
    'ಕನ್ಯಾ',
    'ತುಲಾ',
    'ವೃಶ್ಚಿಕ',
    'ಧನು',
    'ಮಕರ',
    'ಕುಂಭ',
    'ಮೀನ',
  ],
  'ml': [
    'മേടം',
    'ഇടവം',
    'മിഥുനം',
    'കർക്കടകം',
    'ചിങ്ങം',
    'കന്നി',
    'തുലാം',
    'വൃശ്ചികം',
    'ധനു',
    'മകരം',
    'കുംഭം',
    'മീനം',
  ],
  'gu': [
    'મેષ',
    'વૃષભ',
    'મિથુન',
    'કર્ક',
    'સિંહ',
    'કન્યા',
    'તુલા',
    'વૃશ્ચિક',
    'ધનુ',
    'મકર',
    'કુંભ',
    'મીન',
  ],
  'bn': [
    'মেষ',
    'বৃষ',
    'মিথুন',
    'কর্কট',
    'সিংহ',
    'কন্যা',
    'তুলা',
    'বৃশ্চিক',
    'ধনু',
    'মকর',
    'কুম্ভ',
    'মীন',
  ],
};

const _weekdaysEn = [
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];

const weekdayNames = {
  'te': [
    'ఆదివారం',
    'సోమవారం',
    'మంగళవారం',
    'బుధవారం',
    'గురువారం',
    'శుక్రవారం',
    'శనివారం',
  ],
  'ta': [
    'ஞாயிற்றுக்கிழமை',
    'திங்கட்கிழமை',
    'செவ்வாய்க்கிழமை',
    'புதன்கிழமை',
    'வியாழக்கிழமை',
    'வெள்ளிக்கிழமை',
    'சனிக்கிழமை',
  ],
  'kn': [
    'ಭಾನುವಾರ',
    'ಸೋಮವಾರ',
    'ಮಂಗಳವಾರ',
    'ಬುಧವಾರ',
    'ಗುರುವಾರ',
    'ಶುಕ್ರವಾರ',
    'ಶನಿವಾರ',
  ],
  'ml': [
    'ഞായറാഴ്ച',
    'തിങ്കളാഴ്ച',
    'ചൊവ്വാഴ്ച',
    'ബുധനാഴ്ച',
    'വ്യാഴാഴ്ച',
    'വെള്ളിയാഴ്ച',
    'ശനിയാഴ്ച',
  ],
  'gu': [
    'રવિવાર',
    'સોમવાર',
    'મંગળવાર',
    'બુધવાર',
    'ગુરુવાર',
    'શુક્રવાર',
    'શનિવાર',
  ],
  'bn': [
    'রবিবার',
    'সোমবার',
    'মঙ্গলবার',
    'বুধবার',
    'বৃহস্পতিবার',
    'শুক্রবার',
    'শনিবার',
  ],
};

const _planetToEn = {
  'సూర్యుడు': 'Sun',
  'చంద్రుడు': 'Moon',
  'కుజుడు': 'Mars',
  'బుధుడు': 'Mercury',
  'గురువు': 'Jupiter',
  'శుక్రుడు': 'Venus',
  'శని': 'Saturn',
  'రాహువు': 'Rahu',
  'కేతువు': 'Ketu',
  'లగ్నం': 'Lagna',
  'சூரியன்': 'Sun',
  'சந்திரன்': 'Moon',
  'செவ்வாய்': 'Mars',
  'புதன்': 'Mercury',
  'குரு': 'Jupiter',
  'சுக்கிரன்': 'Venus',
  'சனி': 'Saturn',
  'ராகு': 'Rahu',
  'கேது': 'Ketu',
  'லக்னம்': 'Lagna',
  'ಸೂರ್ಯ': 'Sun',
  'ಚಂದ್ರ': 'Moon',
  'ಮಂಗಳ': 'Mars',
  'ಬುಧ': 'Mercury',
  'ಗುರು': 'Jupiter',
  'ಶುಕ್ರ': 'Venus',
  'ಶನಿ': 'Saturn',
  'ರಾಹು': 'Rahu',
  'ಕೇತು': 'Ketu',
  'ಲಗ್ನ': 'Lagna',
  'സൂര്യൻ': 'Sun',
  'ചന്ദ്രൻ': 'Moon',
  'ചൊവ്വ': 'Mars',
  'ബുധൻ': 'Mercury',
  'വ്യാഴം': 'Jupiter',
  'ശുക്രൻ': 'Venus',
  'ശനി': 'Saturn',
  'രാഹു': 'Rahu',
  'കേതു': 'Ketu',
  'ലഗ്നം': 'Lagna',
  'સૂર્ય': 'Sun',
  'ચંદ્ર': 'Moon',
  'મંગળ': 'Mars',
  'બુધ': 'Mercury',
  'ગુરુ': 'Jupiter',
  'શુક્ર': 'Venus',
  'શનિ': 'Saturn',
  'રાહુ': 'Rahu',
  'કેતુ': 'Ketu',
  'લગ્ન': 'Lagna',
  'সূর্য': 'Sun',
  'চন্দ্র': 'Moon',
  'মঙ্গল': 'Mars',
  'বুধ': 'Mercury',
  'বৃহস্পতি': 'Jupiter',
  'শুক্র': 'Venus',
  'শনি': 'Saturn',
  'রাহু': 'Rahu',
  'কেতু': 'Ketu',
  'লগ্ন': 'Lagna',
};

const southSignIndex = {
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

const tocHeading = {
  'en': 'Table of Contents',
  'hi': 'विषय-सूची',
  'mr': 'विषय-सूची',
  'te': 'విషయ సూచిక',
  'ta': 'பொருளடக்கம்',
  'kn': 'ವಿಷಯ ಸೂಚಿ',
  'ml': 'ഉള്ളടക്കം',
  'gu': 'અનુક્રમણિકા',
  'bn': 'সূচিপত্র',
};

final partPrefixRe = RegExp('^(part|भाग|భాగం|பகுதி|ಭಾಗ|ഭാഗം|ભાગ|ভাগ)[\\s\\d]',
    caseSensitive: false);

const indicLocales = [...devanagariLocales, ...southLocales];

bool isDevanagariLocale(String? locale) =>
    locale != null && devanagariLocales.contains(locale);

bool isSouthLocale(String? locale) =>
    locale != null && southLocales.contains(locale);

bool isIndicLocale(String? locale) =>
    locale != null && indicLocales.contains(locale);

/// A te/ta/kn/ml/gu/bn planet name back to its English key (`''` if unknown).
String southPlanetToEn(String? name) =>
    (name != null && name.isNotEmpty ? _planetToEn[name] : null) ?? '';

/// Localizes an English planet or Yogini lord key for te/ta/kn/ml/gu/bn.
String localizeLord(String? locale, String? english) {
  final en = english ?? '';
  if (locale == null || locale.isEmpty) return en;
  return planetNames[locale]?[en] ?? yoginiNames[locale]?[en] ?? en;
}

/// Localizes an English weekday name for te/ta/kn/ml/gu/bn.
String localizeWeekday(String? locale, String? english) {
  final en = english ?? '';
  final table = locale != null ? weekdayNames[locale] : null;
  if (table == null) return en;
  final i = _weekdaysEn.indexOf(en);
  return i >= 0 ? table[i] : en;
}

/// The lord label a template shows: the API's Devanagari field for hi/mr, the
/// native name for te/ta/kn/ml/gu/bn, else the English key.
String lordLabel(String? locale, String? english, [String? hindi]) {
  if (isDevanagariLocale(locale) && hindi != null && hindi.isNotEmpty) {
    return hindi;
  }
  if (isSouthLocale(locale)) return localizeLord(locale, english);
  return english ?? '';
}
