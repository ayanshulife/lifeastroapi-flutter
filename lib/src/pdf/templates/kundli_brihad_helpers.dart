/// Helpers of the Brihad Kundli template that the Detailed Kundli template
/// also uses. Port of the exported helpers of the Node SDK's
/// src/pdf/templates/kundliBrihad.ts.
library;

import '../js.dart';
import '../locales.dart';

/// House number 1..12 to its primary significations, per locale.
const houseTopics = {
  'en': {
    1: 'Self, Lagna, Personality',
    2: 'Wealth, Family, Speech',
    3: 'Siblings, Courage, Communication',
    4: 'Mother, Home, Comforts',
    5: 'Children, Education, Creativity',
    6: 'Enemies, Health, Service',
    7: 'Marriage, Partnership, Business',
    8: 'Longevity, Hidden, Transformation',
    9: 'Father, Fortune, Dharma',
    10: 'Career, Status, Action',
    11: 'Gains, Friends, Aspirations',
    12: 'Loss, Liberation, Foreign',
  },
  'hi': {
    1: 'आत्म, लग्न, व्यक्तित्व',
    2: 'धन, कुटुम्ब, वाणी',
    3: 'सहोदर, साहस, संचार',
    4: 'माता, गृह, सुख',
    5: 'सन्तान, शिक्षा, सृजन',
    6: 'शत्रु, स्वास्थ्य, सेवा',
    7: 'विवाह, साझेदारी, व्यवसाय',
    8: 'आयु, गुप्त, परिवर्तन',
    9: 'पिता, भाग्य, धर्म',
    10: 'कर्म, पद, कार्य',
    11: 'लाभ, मित्र, आकांक्षा',
    12: 'व्यय, मोक्ष, विदेश',
  },
  'mr': {
    1: 'स्व, लग्न, व्यक्तिमत्त्व',
    2: 'धन, कुटुंब, वाणी',
    3: 'भावंडे, धैर्य, संवाद',
    4: 'माता, घर, सुख',
    5: 'संतान, शिक्षण, सर्जनशीलता',
    6: 'शत्रू, आरोग्य, सेवा',
    7: 'विवाह, भागीदारी, व्यवसाय',
    8: 'आयुष्य, गुप्त, परिवर्तन',
    9: 'पिता, भाग्य, धर्म',
    10: 'कर्म, पद, कार्य',
    11: 'लाभ, मित्र, आकांक्षा',
    12: 'व्यय, मोक्ष, परदेश',
  },
  'te': {
    1: 'స్వభావం, లగ్నం, వ్యక్తిత్వం',
    2: 'ధనం, కుటుంబం, వాక్కు',
    3: 'తోబుట్టువులు, ధైర్యం, సంభాషణ',
    4: 'తల్లి, ఇల్లు, సుఖం',
    5: 'సంతానం, విద్య, సృజన',
    6: 'శత్రువులు, ఆరోగ్యం, సేవ',
    7: 'వివాహం, భాగస్వామ్యం, వ్యాపారం',
    8: 'ఆయుష్షు, రహస్యం, పరివర్తన',
    9: 'తండ్రి, భాగ్యం, ధర్మం',
    10: 'కర్మ, పదవి, కార్యం',
    11: 'లాభం, మిత్రులు, ఆకాంక్షలు',
    12: 'వ్యయం, మోక్షం, విదేశం',
  },
  'ta': {
    1: 'சுயம், லக்னம், ஆளுமை',
    2: 'செல்வம், குடும்பம், வாக்கு',
    3: 'உடன்பிறந்தோர், தைரியம், தொடர்பு',
    4: 'தாய், இல்லம், சுகம்',
    5: 'குழந்தைகள், கல்வி, படைப்பாற்றல்',
    6: 'எதிரிகள், உடல்நலம், சேவை',
    7: 'திருமணம், கூட்டாண்மை, வணிகம்',
    8: 'ஆயுள், மறைபொருள், மாற்றம்',
    9: 'தந்தை, பாக்கியம், தர்மம்',
    10: 'கர்மம், பதவி, செயல்',
    11: 'லாபம், நண்பர்கள், ஆசைகள்',
    12: 'விரயம், மோட்சம், வெளிநாடு',
  },
  'kn': {
    1: 'ಸ್ವಭಾವ, ಲಗ್ನ, ವ್ಯಕ್ತಿತ್ವ',
    2: 'ಧನ, ಕುಟುಂಬ, ವಾಕ್',
    3: 'ಸಹೋದರರು, ಧೈರ್ಯ, ಸಂವಹನ',
    4: 'ತಾಯಿ, ಮನೆ, ಸುಖ',
    5: 'ಸಂತಾನ, ವಿದ್ಯೆ, ಸೃಜನಶೀಲತೆ',
    6: 'ಶತ್ರುಗಳು, ಆರೋಗ್ಯ, ಸೇವೆ',
    7: 'ವಿವಾಹ, ಪಾಲುದಾರಿಕೆ, ವ್ಯವಹಾರ',
    8: 'ಆಯುಷ್ಯ, ರಹಸ್ಯ, ಪರಿವರ್ತನೆ',
    9: 'ತಂದೆ, ಭಾಗ್ಯ, ಧರ್ಮ',
    10: 'ಕರ್ಮ, ಸ್ಥಾನಮಾನ, ಕಾರ್ಯ',
    11: 'ಲಾಭ, ಸ್ನೇಹಿತರು, ಆಕಾಂಕ್ಷೆಗಳು',
    12: 'ವ್ಯಯ, ಮೋಕ್ಷ, ವಿದೇಶ',
  },
  'ml': {
    1: 'സ്വഭാവം, ലഗ്നം, വ്യക്തിത്വം',
    2: 'ധനം, കുടുംബം, വാക്ക്',
    3: 'സഹോദരങ്ങൾ, ധൈര്യം, ആശയവിനിമയം',
    4: 'മാതാവ്, വീട്, സുഖം',
    5: 'സന്താനം, വിദ്യ, സർഗാത്മകത',
    6: 'ശത്രുക്കൾ, ആരോഗ്യം, സേവനം',
    7: 'വിവാഹം, പങ്കാളിത്തം, വ്യാപാരം',
    8: 'ആയുസ്സ്, രഹസ്യം, പരിവർത്തനം',
    9: 'പിതാവ്, ഭാഗ്യം, ധർമം',
    10: 'കർമം, പദവി, പ്രവൃത്തി',
    11: 'ലാഭം, സുഹൃത്തുക്കൾ, ആഗ്രഹങ്ങൾ',
    12: 'വ്യയം, മോക്ഷം, വിദേശം',
  },
  'gu': {
    1: 'આત્મા, લગ્ન, વ્યક્તિત્વ',
    2: 'ધન, કુટુંબ, વાણી',
    3: 'ભાઈ-બહેન, સાહસ, સંચાર',
    4: 'માતા, ઘર, સુખ',
    5: 'સંતાન, શિક્ષણ, સર્જન',
    6: 'શત્રુ, સ્વાસ્થ્ય, સેવા',
    7: 'વિવાહ, ભાગીદારી, વ્યવસાય',
    8: 'આયુષ્ય, ગુપ્ત વિષયો, પરિવર્તન',
    9: 'પિતા, ભાગ્ય, ધર્મ',
    10: 'કર્મ, પદ, કાર્ય',
    11: 'લાભ, મિત્રો, આકાંક્ષા',
    12: 'વ્યય, મોક્ષ, વિદેશ',
  },
  'bn': {
    1: 'আত্মা, লগ্ন, ব্যক্তিত্ব',
    2: 'ধন, পরিবার, বাণী',
    3: 'ভাইবোন, সাহস, যোগাযোগ',
    4: 'মা, বাড়ি, সুখ',
    5: 'সন্তান, শিক্ষা, সৃজন',
    6: 'শত্রু, স্বাস্থ্য, সেবা',
    7: 'বিবাহ, অংশীদারি, ব্যবসা',
    8: 'আয়ু, গোপন বিষয়, রূপান্তর',
    9: 'বাবা, ভাগ্য, ধর্ম',
    10: 'কর্ম, পদ, কাজ',
    11: 'লাভ, বন্ধু, আকাঙ্ক্ষা',
    12: 'ব্যয়, মোক্ষ, বিদেশ',
  },
};

/// House number 1..12 to its primary significations, in [loc].
String houseTopic(String loc, int n) =>
    houseTopics[loc]?[n] ?? houseTopics['en']?[n] ?? '';

/// House lord label: `LordLocal`, else `LordHI` (hi/mr), else the native
/// name (te/ta/kn/ml/gu/bn), else `LordEN`.
String houseLordLabel(String loc, Map<String, Object?> h) {
  if (truthy(h['LordLocal'])) return jsStr(h['LordLocal']);
  return lordLabel(loc, asStr(h['LordEN']), asStr(h['LordHI']));
}

/// Yoga display name: `NameLocal`, else `NameHI` (hi/mr), else `NameEN`.
String yogaNameLabel(String loc, Map<String, Object?> y) {
  if (truthy(y['NameLocal'])) return jsStr(y['NameLocal']);
  if (isDevanagariLocale(loc) && truthy(y['NameHI'])) return jsStr(y['NameHI']);
  return y['NameEN'] == null ? '' : jsStr(y['NameEN']);
}

/// Dasha lord label: `LordLocal`, else as [lordLabel].
String dashaLordLabel(String loc, Map<String, Object?> d) {
  if (truthy(d['LordLocal'])) return jsStr(d['LordLocal']);
  return lordLabel(loc, asStr(d['Lord']), asStr(d['LordHI']));
}

/// Dosha display name: `NameLocal`, else the template label.
String doshaNameLabel(String Function(String) label, Map<String, Object?> entry,
        String nameKey) =>
    truthy(entry['NameLocal']) ? jsStr(entry['NameLocal']) : label(nameKey);

/// `dosha_severity_<severity>` label, falling back to the raw severity.
String severityLabel(String Function(String) label, Object? severity) {
  final s = severity == null ? '' : jsStr(severity);
  final found = label('dosha_severity_$s');
  return found.isNotEmpty ? found : s;
}

/// Whether any of the Mangal, Kaal Sarp or Pitra dosha entries is set.
bool anyDoshaPresent(Object? d) {
  if (d is! Map) return false;
  return truthy(d['Mangal']) || truthy(d['KaalSarp']) || truthy(d['Pitra']);
}
