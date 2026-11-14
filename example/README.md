# Examples

## Dart

```bash
LIFEASTRO_API_KEY=dv_live_... dart run example/main.dart
```

[`main.dart`](main.dart) prints today's panchang in Gujarati and a few planet positions, and
writes a branded Detailed Kundli report in Hindi to `kundli.html`.

## Flutter

Keep your `dv_live_...` key on your server. The app talks to your backend, which forwards
`/v1/...` requests to LifeAstroAPI with the key (see "Authentication" in the package README).

```dart
import 'package:flutter/material.dart';
import 'package:lifeastroapi/lifeastroapi.dart';

final client = LifeAstro(
  apiKey: userSessionToken, // your app's own session token
  baseUrl: 'https://api.your-app.example/astro',
);

class TodayPanchang extends StatelessWidget {
  const TodayPanchang({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: client.panchang.basic(
        lat: 19.076, lon: 72.8777, tz: 'Asia/Kolkata', lang: Lang.hi,
      ),
      builder: (context, snap) {
        if (snap.hasError) return Text('${snap.error}');
        if (!snap.hasData) return const CircularProgressIndicator();
        final day = snap.data!;
        return ListTile(
          title: Text('${day['tithi']?['name']}'),
          subtitle: Text('${day['nakshatra']?['name']}'),
        );
      },
    );
  }
}
```

A report as a PDF in the app, with the `printing` package:

```dart
import 'package:lifeastroapi/pdf.dart';
import 'package:printing/printing.dart';

Future<void> shareKundli(Map<String, dynamic> report) async {
  final html = renderKundliLiteHtml(report);
  await Printing.layoutPdf(
    onLayout: (format) => Printing.convertHtml(format: format, html: html),
  );
}
```
