# Examples

## Dart

```bash
LIFEASTRO_API_KEY=dv_live_... dart run example/main.dart
```

[`main.dart`](main.dart) prints today's panchang in Gujarati and a few planet positions, and
writes a branded Detailed Kundli report in Hindi to `kundli.html`, and to `kundli.pdf` when a
Chrome, Chromium or Edge is installed.

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

A report as a PDF in the app, printed by the platform's web view through the `printing` and
`pdf` packages (add both to your app). The report JSON comes from your backend:

```dart
import 'package:lifeastroapi/pdf.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

Future<void> shareKundli(Map<String, dynamic> report) async {
  final html = renderKundliLiteHtml(report);
  // printing marks convertHtml as deprecated; check that the platform has it.
  if (!(await Printing.info()).canConvertHtml) return;
  final m = a4PrintOptions.margins;
  // ignore: deprecated_member_use
  final bytes = await Printing.convertHtml(
    html: html,
    format: PdfPageFormat(a4PrintOptions.width, a4PrintOptions.height,
        marginTop: m.top, marginRight: m.right,
        marginBottom: m.bottom, marginLeft: m.left),
  );
  await Printing.sharePdf(bytes: bytes, filename: 'kundli.pdf');
}
```
