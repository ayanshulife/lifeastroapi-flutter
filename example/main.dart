// A small tour of the SDK. Run with a key from
// https://lifeastroapi.com/dashboard/keys:
//
//   LIFEASTRO_API_KEY=dv_live_... dart run example/main.dart
import 'dart:io';

import 'package:lifeastroapi/lifeastroapi.dart';
import 'package:lifeastroapi/pdf.dart';

const arjun = BirthInput(
  date: '1990-01-15',
  time: '10:30',
  tz: 'Asia/Kolkata',
  lat: 19.076,
  lon: 72.8777,
);

Future<void> main() async {
  final client = LifeAstro(); // reads LIFEASTRO_API_KEY

  try {
    // Today's panchang for Mumbai, in Gujarati.
    final day = await client.panchang.basic(
      lat: 19.076,
      lon: 72.8777,
      tz: 'Asia/Kolkata',
      lang: Lang.gu,
    );
    print('Tithi: ${day['tithi']?['name']}');

    // Planet positions of a birth chart.
    final List<dynamic> planets =
        (await client.chart.planets(birth: arjun))['planets'] ?? [];
    for (final p in planets.take(3)) {
      print('${p['name']}: house ${p['house']}, ${p['dms_in_sign']}');
    }

    // A Detailed Kundli report in Hindi, as a branded HTML document. Open
    // it in a browser, or print it to PDF with kundliDetailedPdf(report).
    final report = await client.reports.kundliDetailed(
      birth: arjun,
      name: 'Arjun Mehta',
      place: 'Mumbai',
      lang: Lang.hi,
    );
    final html = renderKundliDetailedHtml(
      report,
      const Branding(companyName: 'Acme Astro', primaryColor: '#6b21a8'),
    );
    File('kundli.html').writeAsStringSync(html);
    print('Wrote kundli.html');
  } on PaymentRequiredException {
    print('Out of credits: https://lifeastroapi.com/dashboard/billing');
  } on LifeAstroException catch (e) {
    print('API error ${e.status} ${e.code}: ${e.message} (${e.requestId})');
  } finally {
    client.close();
  }
}
