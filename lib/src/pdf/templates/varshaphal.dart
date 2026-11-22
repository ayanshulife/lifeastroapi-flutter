/// Varshaphal report as HTML. Port of the Node SDK's src/pdf/templates/varshaphal.ts
/// (byte-identical output, golden-tested).
library;

import '../js.dart';
import '../shared.dart';

const _labels = {
  'en': {
    'title_varsha': 'Varshaphal — Annual Forecast',
    'born': 'Born',
    'at': 'at',
    'generated': 'Generated on',
    'section_solar_return': 'Solar Return Moment',
    'section_planets_sr': 'Planetary Positions at Solar Return',
    'section_outlook': 'Year Outlook',
    'solar_return_at': 'Solar Return at',
    'ascendant': 'Ascendant',
    'nakshatra': 'Nakshatra',
    'pada': 'Pada',
    'muntha': 'Muntha',
    'varsha_lord': 'Varsha Lord',
    'house': 'House',
    'from_natal_lagna': 'from natal lagna',
    'hora_number': 'Hora',
    'planet': 'Planet',
    'sign': 'Sign',
    'degree': 'Degree',
  },
  'hi': {
    'title_varsha': 'वर्षफल — वार्षिक भविष्यफल',
    'born': 'जन्म',
    'at': 'समय',
    'generated': 'तैयार',
    'section_solar_return': 'सूर्य प्रत्यागमन क्षण',
    'section_planets_sr': 'सूर्य प्रत्यागमन के समय ग्रह स्थिति',
    'section_outlook': 'वार्षिक दृष्टिकोण',
    'solar_return_at': 'सूर्य प्रत्यागमन समय',
    'ascendant': 'लग्न',
    'nakshatra': 'नक्षत्र',
    'pada': 'पाद',
    'muntha': 'मुन्था',
    'varsha_lord': 'वर्ष स्वामी',
    'house': 'भाव',
    'from_natal_lagna': 'जन्म लग्न से',
    'hora_number': 'होरा',
    'planet': 'ग्रह',
    'sign': 'राशि',
    'degree': 'अंश',
  },
  'mr': {
    'title_varsha': 'वर्षफल — वार्षिक भविष्यफल',
    'born': 'जन्म',
    'at': 'वेळ',
    'generated': 'तयार',
    'section_solar_return': 'सूर्य प्रत्यागमन क्षण',
    'section_planets_sr': 'सूर्य प्रत्यागमन वेळेस ग्रह स्थिती',
    'section_outlook': 'वार्षिक दृष्टीकोन',
    'solar_return_at': 'सूर्य प्रत्यागमन वेळ',
    'ascendant': 'लग्न',
    'nakshatra': 'नक्षत्र',
    'pada': 'चरण',
    'muntha': 'मुन्था',
    'varsha_lord': 'वर्ष अधिपती',
    'house': 'स्थान',
    'from_natal_lagna': 'जन्म लग्नापासून',
    'hora_number': 'होरा',
    'planet': 'ग्रह',
    'sign': 'राशी',
    'degree': 'अंश',
  },
  'te': {
    'title_varsha': 'వర్షఫలం: వార్షిక ఫలితాలు',
    'born': 'జననం',
    'at': 'సమయం',
    'generated': 'రూపొందించిన తేదీ',
    'section_solar_return': 'సౌర పునరాగమన క్షణం',
    'section_planets_sr': 'సౌర పునరాగమన సమయంలో గ్రహ స్థితి',
    'section_outlook': 'సంవత్సర దృక్పథం',
    'solar_return_at': 'సౌర పునరాగమన సమయం',
    'ascendant': 'లగ్నం',
    'nakshatra': 'నక్షత్రం',
    'pada': 'పాదం',
    'muntha': 'ముంథా',
    'varsha_lord': 'వర్షాధిపతి',
    'house': 'భావం',
    'from_natal_lagna': 'జన్మ లగ్నం నుండి',
    'hora_number': 'హోర',
    'planet': 'గ్రహం',
    'sign': 'రాశి',
    'degree': 'భాగలు',
  },
  'ta': {
    'title_varsha': 'வருஷ பலன்: ஆண்டுப் பலன்கள்',
    'born': 'பிறப்பு',
    'at': 'நேரம்',
    'generated': 'தயாரித்த நாள்',
    'section_solar_return': 'சூரிய மீள்வருகைத் தருணம்',
    'section_planets_sr': 'சூரிய மீள்வருகையின்போது கிரக நிலை',
    'section_outlook': 'ஆண்டுப் பார்வை',
    'solar_return_at': 'சூரிய மீள்வருகை நேரம்',
    'ascendant': 'லக்னம்',
    'nakshatra': 'நட்சத்திரம்',
    'pada': 'பாதம்',
    'muntha': 'முந்தா',
    'varsha_lord': 'வருஷ அதிபதி',
    'house': 'வீடு',
    'from_natal_lagna': 'ஜனன லக்னத்திலிருந்து',
    'hora_number': 'ஹோரை',
    'planet': 'கிரகம்',
    'sign': 'ராசி',
    'degree': 'பாகை',
  },
  'kn': {
    'title_varsha': 'ವರ್ಷಫಲ: ವಾರ್ಷಿಕ ಫಲ',
    'born': 'ಜನನ',
    'at': 'ಸಮಯ',
    'generated': 'ತಯಾರಿಸಿದ ದಿನಾಂಕ',
    'section_solar_return': 'ಸೌರ ಪುನರಾಗಮನ ಕ್ಷಣ',
    'section_planets_sr': 'ಸೌರ ಪುನರಾಗಮನದ ಸಮಯದ ಗ್ರಹ ಸ್ಥಿತಿ',
    'section_outlook': 'ವರ್ಷದ ದೃಷ್ಟಿಕೋನ',
    'solar_return_at': 'ಸೌರ ಪುನರಾಗಮನ ಸಮಯ',
    'ascendant': 'ಲಗ್ನ',
    'nakshatra': 'ನಕ್ಷತ್ರ',
    'pada': 'ಪಾದ',
    'muntha': 'ಮುಂಥಾ',
    'varsha_lord': 'ವರ್ಷಾಧಿಪತಿ',
    'house': 'ಭಾವ',
    'from_natal_lagna': 'ಜನ್ಮ ಲಗ್ನದಿಂದ',
    'hora_number': 'ಹೋರಾ',
    'planet': 'ಗ್ರಹ',
    'sign': 'ರಾಶಿ',
    'degree': 'ಅಂಶ',
  },
  'ml': {
    'title_varsha': 'വർഷഫലം: വാർഷിക ഫലങ്ങൾ',
    'born': 'ജനനം',
    'at': 'സമയം',
    'generated': 'തയ്യാറാക്കിയ തീയതി',
    'section_solar_return': 'സൗര പുനരാഗമന നിമിഷം',
    'section_planets_sr': 'സൗര പുനരാഗമന സമയത്തെ ഗ്രഹസ്ഥിതി',
    'section_outlook': 'വർഷത്തെക്കുറിച്ചുള്ള കാഴ്ചപ്പാട്',
    'solar_return_at': 'സൗര പുനരാഗമന സമയം',
    'ascendant': 'ലഗ്നം',
    'nakshatra': 'നക്ഷത്രം',
    'pada': 'പാദം',
    'muntha': 'മുന്ഥ',
    'varsha_lord': 'വർഷാധിപൻ',
    'house': 'ഭാവം',
    'from_natal_lagna': 'ജന്മലഗ്നത്തിൽ നിന്ന്',
    'hora_number': 'ഹോര',
    'planet': 'ഗ്രഹം',
    'sign': 'രാശി',
    'degree': 'ഡിഗ്രി',
  },
  'gu': {
    'title_varsha': 'વર્ષફળ: વાર્ષિક ભવિષ્યફળ',
    'born': 'જન્મ',
    'at': 'સમય',
    'generated': 'તૈયાર',
    'section_solar_return': 'સૂર્ય પ્રત્યાગમનની ક્ષણ',
    'section_planets_sr': 'સૂર્ય પ્રત્યાગમન સમયે ગ્રહ સ્થિતિ',
    'section_outlook': 'વાર્ષિક દૃષ્ટિકોણ',
    'solar_return_at': 'સૂર્ય પ્રત્યાગમન સમય',
    'ascendant': 'લગ્ન',
    'nakshatra': 'નક્ષત્ર',
    'pada': 'પાદ',
    'muntha': 'મુંથા',
    'varsha_lord': 'વર્ષ સ્વામી',
    'house': 'ભાવ',
    'from_natal_lagna': 'જન્મ લગ્નથી',
    'hora_number': 'હોરા',
    'planet': 'ગ્રહ',
    'sign': 'રાશિ',
    'degree': 'અંશ',
  },
  'bn': {
    'title_varsha': 'বর্ষফল: বার্ষিক ভবিষ্যফল',
    'born': 'জন্ম',
    'at': 'সময়',
    'generated': 'তৈরি',
    'section_solar_return': 'সৌর প্রত্যাবর্তনের মুহূর্ত',
    'section_planets_sr': 'সৌর প্রত্যাবর্তনের সময় গ্রহের অবস্থান',
    'section_outlook': 'বার্ষিক পূর্বাভাস',
    'solar_return_at': 'সৌর প্রত্যাবর্তনের সময়',
    'ascendant': 'লগ্ন',
    'nakshatra': 'নক্ষত্র',
    'pada': 'পাদ',
    'muntha': 'মুন্থা',
    'varsha_lord': 'বর্ষের অধিপতি',
    'house': 'ভাব',
    'from_natal_lagna': 'জন্মলগ্ন থেকে',
    'hora_number': 'হোরা',
    'planet': 'গ্রহ',
    'sign': 'রাশি',
    'degree': 'অংশ',
  },
  'pa': {
    'title_varsha': 'ਵਰਸ਼ਫਲ: ਸਾਲਾਨਾ ਭਵਿੱਖਫਲ',
    'born': 'ਜਨਮ',
    'at': 'ਸਮਾਂ',
    'generated': 'ਤਿਆਰ',
    'section_solar_return': 'ਸੂਰਜ ਦੀ ਵਾਪਸੀ ਦਾ ਪਲ',
    'section_planets_sr': 'ਸੂਰਜ ਦੀ ਵਾਪਸੀ ਵੇਲੇ ਗ੍ਰਹਿ ਸਥਿਤੀ',
    'section_outlook': 'ਸਾਲਾਨਾ ਨਜ਼ਰੀਆ',
    'solar_return_at': 'ਸੂਰਜ ਦੀ ਵਾਪਸੀ ਦਾ ਸਮਾਂ',
    'ascendant': 'ਲਗਨ',
    'nakshatra': 'ਨਛੱਤਰ',
    'pada': 'ਪਦ',
    'muntha': 'ਮੁੰਥਾ',
    'varsha_lord': 'ਵਰਸ਼ ਦਾ ਸੁਆਮੀ',
    'house': 'ਭਾਵ',
    'from_natal_lagna': 'ਜਨਮ ਲਗਨ ਤੋਂ',
    'hora_number': 'ਹੋਰਾ',
    'planet': 'ਗ੍ਰਹਿ',
    'sign': 'ਰਾਸ਼ੀ',
    'degree': 'ਅੰਸ਼',
  },
};

const _extraCss =
    '\n.cover .year-badge {\n  display: inline-block;\n  padding: 3mm 8mm;\n  margin: 4mm 0 8mm;\n  background: var(--brand-primary);\n  color: #fff;\n  font-size: 22pt;\n  font-weight: 700;\n  border-radius: 2mm;\n}\n.indicator-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 5mm; margin: 4mm 0; }\n.indicator-card { padding: 5mm; background: #fafafa; border-left: 3px solid var(--brand-primary); }\n.indicator-card .label {\n  font-size: 9pt; color: var(--brand-secondary);\n  text-transform: uppercase; letter-spacing: 0.5pt; margin-bottom: 1mm;\n}\n.indicator-card .value { font-size: 14pt; font-weight: 600; color: var(--brand-primary); }\n.indicator-card .detail { margin-top: 2mm; font-size: 10pt; color: #444; }\n';

/// The muntha house's quality band: 1/5/9 favorable, 6/8/12 challenging,
/// the rest mixed.
String _munthaBand(num house) {
  if (house == 1 || house == 5 || house == 9) return 'favorable';
  if (house == 6 || house == 8 || house == 12) return 'challenging';
  return 'mixed';
}

/// The Year Outlook prose for [locale] and [band], with the muntha house and
/// target year (already printed as JS would) filled in.
String _outlookText(String locale, String year, String band, String house) {
  if (locale == 'hi') {
    if (band == 'favorable') {
      return 'मुन्था का $house वें भाव में होना $year वर्ष को सामान्यतः अनुकूल बनाता है — लक्ष्य प्राप्ति, स्थायित्व, या आध्यात्मिक प्रगति की संभावनाएं बढ़ती हैं।';
    }
    if (band == 'challenging') {
      return 'मुन्था का $house वें भाव में होना $year वर्ष को चुनौतीपूर्ण बना सकता है। स्वास्थ्य, खर्च, या ऋण-सम्बन्धी मामलों में सावधानी रखिए।';
    }
    return 'मुन्था $house वें भाव में स्थित है — $year वर्ष में मिश्रित परिणाम संभव। प्रमुख निर्णयों से पूर्व अपनी कुंडली को गहराई से जाँच लीजिए।';
  }
  if (locale == 'mr') {
    if (band == 'favorable') {
      return 'मुन्था $house व्या स्थानात असल्याने $year वर्ष सामान्यतः अनुकूल राहील — उद्दिष्टपूर्ती, स्थैर्य किंवा आध्यात्मिक प्रगतीच्या शक्यता वाढतात.';
    }
    if (band == 'challenging') {
      return 'मुन्था $house व्या स्थानात असल्याने $year वर्ष आव्हानात्मक राहू शकते. आरोग्य, खर्च किंवा कर्ज-संबंधी बाबींमध्ये सावधगिरी बाळगा.';
    }
    return 'मुन्था $house व्या स्थानात आहे — $year वर्षात मिश्र परिणाम संभाव्य. महत्त्वाच्या निर्णयांपूर्वी आपली कुंडली सखोल तपासून घ्या.';
  }
  // te / ta / kn / ml / gu / bn / pa are written from the Hindi; the "consult an astrologer" line
  // of the mixed band became "study your chart first" in every locale
  // (2026-11-07: no astrologer referral anywhere).
  if (locale == 'te') {
    if (band == 'favorable') {
      return 'ముంథా $houseవ భావంలో ఉండటం వల్ల $year సంవత్సరం సాధారణంగా అనుకూలంగా ఉంటుంది; లక్ష్య సాధన, స్థిరత్వం లేదా ఆధ్యాత్మిక పురోగతికి అవకాశాలు పెరుగుతాయి.';
    }
    if (band == 'challenging') {
      return 'ముంథా $houseవ భావంలో ఉండటం వల్ల $year సంవత్సరం సవాలుగా ఉండవచ్చు. ఆరోగ్యం, ఖర్చులు లేదా అప్పులకు సంబంధించిన విషయాలలో జాగ్రత్తగా ఉండండి.';
    }
    return 'ముంథా $houseవ భావంలో ఉంది; $year సంవత్సరంలో మిశ్రమ ఫలితాలు రావచ్చు. ముఖ్యమైన నిర్ణయాలకు ముందు మీ జాతకాన్ని లోతుగా పరిశీలించుకోండి.';
  }
  if (locale == 'ta') {
    if (band == 'favorable') {
      return 'முந்தா $house-ஆம் வீட்டில் இருப்பதால் $year ஆம் ஆண்டு பொதுவாகச் சாதகமாக இருக்கும்; இலக்கை அடைதல், நிலைத்தன்மை அல்லது ஆன்மிக முன்னேற்றத்துக்கான வாய்ப்புகள் கூடும்.';
    }
    if (band == 'challenging') {
      return 'முந்தா $house-ஆம் வீட்டில் இருப்பதால் $year ஆம் ஆண்டு சவாலாக இருக்கலாம். உடல்நலம், செலவு, கடன் தொடர்பான விஷயங்களில் கவனமாக இருங்கள்.';
    }
    return 'முந்தா $house-ஆம் வீட்டில் உள்ளது; $year ஆம் ஆண்டில் கலவையான பலன்கள் வரலாம். முக்கிய முடிவுகளுக்கு முன் உங்கள் ஜாதகத்தை ஆழமாகப் பார்த்துக்கொள்ளுங்கள்.';
  }
  if (locale == 'kn') {
    if (band == 'favorable') {
      return 'ಮುಂಥಾ $houseನೇ ಭಾವದಲ್ಲಿರುವುದರಿಂದ $year ವರ್ಷ ಸಾಮಾನ್ಯವಾಗಿ ಅನುಕೂಲಕರವಾಗಿರುತ್ತದೆ; ಗುರಿ ಸಾಧನೆ, ಸ್ಥಿರತೆ ಅಥವಾ ಆಧ್ಯಾತ್ಮಿಕ ಪ್ರಗತಿಯ ಸಾಧ್ಯತೆಗಳು ಹೆಚ್ಚುತ್ತವೆ.';
    }
    if (band == 'challenging') {
      return 'ಮುಂಥಾ $houseನೇ ಭಾವದಲ್ಲಿರುವುದರಿಂದ $year ವರ್ಷ ಸವಾಲಿನದಾಗಿರಬಹುದು. ಆರೋಗ್ಯ, ಖರ್ಚು ಅಥವಾ ಸಾಲಕ್ಕೆ ಸಂಬಂಧಿಸಿದ ವಿಷಯಗಳಲ್ಲಿ ಎಚ್ಚರಿಕೆಯಿಂದಿರಿ.';
    }
    return 'ಮುಂಥಾ $houseನೇ ಭಾವದಲ್ಲಿದೆ; $year ವರ್ಷದಲ್ಲಿ ಮಿಶ್ರ ಫಲಿತಾಂಶಗಳು ಸಾಧ್ಯ. ಮುಖ್ಯ ನಿರ್ಧಾರಗಳ ಮೊದಲು ನಿಮ್ಮ ಜಾತಕವನ್ನು ಆಳವಾಗಿ ಪರಿಶೀಲಿಸಿಕೊಳ್ಳಿ.';
  }
  if (locale == 'ml') {
    if (band == 'favorable') {
      return 'മുന്ഥ $house-ാം ഭാവത്തിലായതിനാൽ $year വർഷം പൊതുവെ അനുകൂലമായിരിക്കും; ലക്ഷ്യപ്രാപ്തി, സ്ഥിരത, ആത്മീയ പുരോഗതി എന്നിവയ്ക്കുള്ള സാധ്യതകൾ വർധിക്കും.';
    }
    if (band == 'challenging') {
      return 'മുന്ഥ $house-ാം ഭാവത്തിലായതിനാൽ $year വർഷം വെല്ലുവിളി നിറഞ്ഞതാകാം. ആരോഗ്യം, ചെലവ്, കടം എന്നിവയുമായി ബന്ധപ്പെട്ട കാര്യങ്ങളിൽ ശ്രദ്ധ പുലർത്തുക.';
    }
    return 'മുന്ഥ $house-ാം ഭാവത്തിലാണ്; $year വർഷത്തിൽ സമ്മിശ്ര ഫലങ്ങൾ ഉണ്ടാകാം. പ്രധാന തീരുമാനങ്ങൾക്കു മുമ്പ് നിങ്ങളുടെ ജാതകം ആഴത്തിൽ പരിശോധിക്കുക.';
  }
  if (locale == 'gu') {
    if (band == 'favorable') {
      return 'મુંથા ભાવ $houseમાં હોવાથી વર્ષ $year સામાન્ય રીતે અનુકૂળ રહે છે; લક્ષ્યપ્રાપ્તિ, સ્થિરતા અથવા આધ્યાત્મિક પ્રગતિની સંભાવનાઓ વધે છે.';
    }
    if (band == 'challenging') {
      return 'મુંથા ભાવ $houseમાં હોવાથી વર્ષ $year પડકારરૂપ બની શકે છે. સ્વાસ્થ્ય, ખર્ચ અથવા ઋણ સંબંધિત બાબતોમાં સાવધાની રાખજો.';
    }
    return 'મુંથા ભાવ $houseમાં સ્થિત છે; વર્ષ $yearમાં મિશ્ર પરિણામ સંભવ છે. મહત્ત્વના નિર્ણયો પહેલાં આપની કુંડળીને ઊંડાણથી તપાસી લેજો.';
  }
  if (locale == 'bn') {
    if (band == 'favorable') {
      return 'মুন্থার অবস্থান ভাব $house, তাই $year সাল সাধারণত অনুকূল থাকে; লক্ষ্যপূরণ, স্থিতি বা আধ্যাত্মিক অগ্রগতির সম্ভাবনা বাড়ে।';
    }
    if (band == 'challenging') {
      return 'মুন্থার অবস্থান ভাব $house, তাই $year সাল কিছুটা কঠিন হতে পারে। স্বাস্থ্য, খরচ বা ঋণের ব্যাপারে সাবধান থাকবেন।';
    }
    return 'মুন্থার অবস্থান ভাব $house; $year সালে মিশ্র ফল দেখা দিতে পারে। বড় সিদ্ধান্তের আগে নিজের কুণ্ডলী ভালো করে দেখে নেবেন।';
  }
  if (locale == 'pa') {
    if (band == 'favorable') {
      return 'ਮੁੰਥਾ ਦਾ ਭਾਵ $house ਵਿੱਚ ਹੋਣਾ ਸਾਲ $year ਨੂੰ ਆਮ ਤੌਰ \'ਤੇ ਅਨੁਕੂਲ ਬਣਾਉਂਦਾ ਹੈ; ਟੀਚੇ ਪੂਰੇ ਹੋਣ, ਟਿਕਾਅ ਜਾਂ ਅਧਿਆਤਮਕ ਤਰੱਕੀ ਦੀ ਸੰਭਾਵਨਾ ਵਧਦੀ ਹੈ।';
    }
    if (band == 'challenging') {
      return 'ਮੁੰਥਾ ਦਾ ਭਾਵ $house ਵਿੱਚ ਹੋਣਾ ਸਾਲ $year ਨੂੰ ਕੁਝ ਚੁਣੌਤੀ ਭਰਿਆ ਬਣਾ ਸਕਦਾ ਹੈ। ਸਿਹਤ, ਖ਼ਰਚ ਜਾਂ ਕਰਜ਼ੇ ਨਾਲ ਜੁੜੇ ਮਾਮਲਿਆਂ ਵਿੱਚ ਸਾਵਧਾਨੀ ਰੱਖੋ।';
    }
    return 'ਮੁੰਥਾ ਭਾਵ $house ਵਿੱਚ ਹੈ; ਸਾਲ $year ਵਿੱਚ ਮਿਲੇ-ਜੁਲੇ ਨਤੀਜੇ ਆ ਸਕਦੇ ਹਨ। ਵੱਡੇ ਫ਼ੈਸਲਿਆਂ ਤੋਂ ਪਹਿਲਾਂ ਆਪਣੀ ਕੁੰਡਲੀ ਨੂੰ ਡੂੰਘਾਈ ਨਾਲ ਜਾਂਚ ਲਓ।';
  }
  if (band == 'favorable') {
    return 'Muntha in house $house makes $year broadly favorable — increased likelihood of goal attainment, stability, or spiritual progress.';
  }
  if (band == 'challenging') {
    return 'Muntha in house $house may make $year challenging. Exercise care around health, expenditure, or debt-related matters.';
  }
  return 'Muntha sits in house $house — $year likely brings mixed results. Study your chart closely before major decisions.';
}

/// Renders the Varshaphal report as a complete HTML document.
String renderVarshaphalHtml(Map<String, Object?> data, [Branding? branding]) {
  data = withoutNullItems(withSafeLocale(data));
  final resolved = resolveBranding(data['Branding'], branding);
  final localeRaw = data['Locale'];
  final t = makeLabeler(_labels, jsStr(jsOr(localeRaw, 'en')));
  // The outlook prose exists for the label locales only; others use English.
  final loc =
      localeRaw is String && _labels.containsKey(localeRaw) ? localeRaw : 'en';

  final subject = asMap(data['Subject']);
  final asc = asMap(data['Ascendant']);
  final muntha = asMap(data['Muntha']);
  final lord = asMap(data['VarshaLord']);
  final planets = asList(data['Planets']);
  final year = asNum(data['TargetYear']) ?? 0;

  // Cover page: title, prominent year badge, subject.
  final coverMeta =
      '${esc(t('born'))} ${esc(subject['BirthDate'])} ${esc(t('at'))} ${esc(subject['BirthTime'])}<br>${esc(subject['BirthPlace'])}';
  final cover = '''<section class="cover">
  ${coverBrandingHtml(resolved)}
  <h1>${esc(t('title_varsha'))}</h1>
  <div class="year-badge">${esc(data['TargetYear'])}</div>
  <div class="subject">${esc(subject['Name'])}</div>
  <div class="meta">$coverMeta</div>
  <div class="generated">${esc(t('generated'))} ${esc(formatGenerated(data['GeneratedAt']))}</div>
</section>''';

  // Solar-return moment and ascendant summary.
  // The birth zone's time when the report carries it, else readable UTC.
  final solarReturnTime =
      jsOr(data['SolarReturnLocal'], formatGenerated(data['SolarReturnISO']));
  final solarReturn = '''<h2>${esc(t('section_solar_return'))}</h2>
<p>
  <strong>${esc(t('solar_return_at'))}:</strong> ${esc(solarReturnTime)}<br>
  <strong>${esc(t('ascendant'))}:</strong>
  ${esc(asc['sign'])} (${esc(asc['dms_within'])}) —
  ${esc(t('nakshatra'))}: ${esc(asc['nakshatra'])},
  ${esc(t('pada'))} ${esc(asc['pada'])}
</p>''';

  // Year indicator cards: muntha placement and varsha lord.
  final indicators = '''<div class="indicator-grid">
  <div class="indicator-card">
    <div class="label">${esc(t('muntha'))}</div>
    <div class="value">${esc(muntha['sign'])}</div>
    <div class="detail">${esc(t('house'))} ${esc(muntha['house'])} ${esc(t('from_natal_lagna'))}</div>
  </div>
  <div class="indicator-card">
    <div class="label">${esc(t('varsha_lord'))}</div>
    <div class="value">${esc(lord['name'])}</div>
    <div class="detail">${esc(t('hora_number'))} ${esc(lord['hora'])}</div>
  </div>
</div>''';

  // Planetary positions at solar return.
  final planetRows = planets.map((raw) {
    final pl = asMap(raw);
    final p = asMap(pl['placement']);
    final retro = truthy(pl['retro']) ? ' (R)' : '';
    return '<tr><td>${esc(pl['name'])}$retro</td><td>${esc(p['sign'])}</td><td>${esc(p['dms_within'])}</td><td>${esc(pl['house_num'])}</td><td>${esc(p['nakshatra'])} (${esc(p['pada'])})</td></tr>';
  }).join();
  final planetsTable = '''<h2>${esc(t('section_planets_sr'))}</h2>
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

  // Year outlook prose, derived from the muntha house (as in the Go template).
  final munthaHouse = asNum(muntha['house']) ?? 0;
  final outlookProse = _outlookText(
      loc, jsNum(year), _munthaBand(munthaHouse), jsNum(munthaHouse));
  final outlook = '''<h2>${esc(t('section_outlook'))}</h2>
<p>${esc(outlookProse)}</p>''';

  final bodyHtml =
      [cover, solarReturn, indicators, planetsTable, outlook].join('\n\n');

  return layoutDocument(
    lang: localeRaw == null ? null : jsStr(localeRaw),
    title:
        '${t('title_varsha')} ${jsStr(data['TargetYear'], nullAs: '')} — ${jsStr(subject['Name'], nullAs: '')}',
    branding: resolved,
    bodyHtml: bodyHtml,
    extraCss: _extraCss,
  );
}
