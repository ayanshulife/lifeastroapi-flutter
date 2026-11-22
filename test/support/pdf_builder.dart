// A tiny Chromium-like PDF (xref table, uncompressed dictionaries) for the
// outline and engine tests.
import 'dart:convert';
import 'dart:typed_data';

/// One page for each entry of [pageLinks], with a link annotation for each
/// of its URIs. [stream] is the data of a stream object written first,
/// [title] the document's /Info title (Latin-1) and [catalog] extra entries of
/// the catalog.
Uint8List buildPdf(List<List<String>> pageLinks,
    {String? stream, String? title, String catalog = ''}) {
  final objects = <String>[
    '<< /Type /Catalog /Pages 2 0 R $catalog>>',
    '', // the page tree, filled in below
  ];
  if (stream != null) {
    objects.add('<< /Length ${stream.length} >>\nstream\n$stream\nendstream');
  }
  final kids = <int>[];
  for (final links in pageLinks) {
    final annots = <int>[];
    for (final uri in links) {
      objects.add('<< /Subtype /Link /Rect [0 0 1 1] '
          '/A << /S /URI /URI ($uri) >> >>');
      annots.add(objects.length);
    }
    objects.add('<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842]'
        '${annots.isEmpty ? '' : ' /Annots [${annots.map((a) => '$a 0 R').join(' ')}]'}'
        ' >>');
    kids.add(objects.length);
  }
  objects[1] = '<< /Type /Pages /Count ${kids.length} '
      '/Kids [${kids.map((k) => '$k 0 R').join(' ')}] >>';

  var info = '';
  if (title != null) {
    objects.add('<< /Title ($title) >>');
    info = ' /Info ${objects.length} 0 R';
  }

  final out = StringBuffer('%PDF-1.4\n');
  final offsets = <int>[];
  for (var i = 0; i < objects.length; i++) {
    offsets.add(out.length);
    out.write('${i + 1} 0 obj\n${objects[i]}\nendobj\n');
  }
  final xref = out.length;
  out.write('xref\n0 ${objects.length + 1}\n0000000000 65535 f \n');
  for (final o in offsets) {
    out.write('${o.toString().padLeft(10, '0')} 00000 n \n');
  }
  out.write('trailer\n<< /Size ${objects.length + 1} /Root 1 0 R$info >>\n'
      'startxref\n$xref\n%%EOF\n');
  return latin1.encode(out.toString());
}
