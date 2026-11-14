/// Zero-dependency PDF post-processing for Chromium-rendered PDFs:
///
/// - [addPdfOutline] appends a bookmark outline (port of the Node SDK's
///   src/pdf/outline.ts) as an incremental update: the original bytes are not
///   rewritten; new objects, a new xref section and a new trailer are appended.
/// - [linkTargetPages] lists the page each link annotation sits on, which the
///   Brihad table of contents uses to find the exact page of every section.
///
/// Both assume a cross-reference-table PDF with uncompressed object
/// dictionaries, which is what Chromium writes.
library;

import 'dart:convert';
import 'dart:typed_data';

/// One bookmark. [level] is 1-based (1 = top level).
typedef OutlineItem = ({String title, int page, int level});

class _ParsedPdf {
  _ParsedPdf(this.text, this.maxObj, this.rootObj, this.pageObjs,
      this.prevStartXref, this.bodies);
  final String text;
  final int maxObj;
  final int rootObj;
  final List<int> pageObjs;
  final int prevStartXref;
  final Map<int, String> bodies;
}

final _defRe = RegExp(r'(\d+)\s+0\s+obj([\s\S]*?)endobj');

_ParsedPdf _parsePdf(Uint8List pdf) {
  final text = latin1.decode(pdf);

  var maxObj = 0;
  for (final m in RegExp(r'(\d+)\s+0\s+obj\b').allMatches(text)) {
    final n = int.parse(m[1]!);
    if (n > maxObj) maxObj = n;
  }

  final rootM = RegExp(r'/Root\s+(\d+)\s+0\s+R').firstMatch(text);
  if (rootM == null) {
    throw const FormatException('pdf outline: /Root not found in trailer');
  }
  final rootObj = int.parse(rootM[1]!);

  // Page objects in the order they appear (Chromium writes them in page order).
  final pageObjs = <int>[];
  final bodies = <int, String>{};
  for (final m in _defRe.allMatches(text)) {
    final obj = int.parse(m[1]!);
    final body = m[2] ?? '';
    bodies[obj] = body;
    if (RegExp(r'/Type\s*/Page\b').hasMatch(body) &&
        !RegExp(r'/Type\s*/Pages\b').hasMatch(body)) {
      pageObjs.add(obj);
    }
  }

  var prevStartXref = 0;
  for (final m in RegExp(r'startxref\s+(\d+)').allMatches(text)) {
    prevStartXref = int.parse(m[1]!);
  }

  if (pageObjs.isEmpty) {
    throw const FormatException('pdf outline: no /Type /Page objects found');
  }
  return _ParsedPdf(text, maxObj, rootObj, pageObjs, prevStartXref, bodies);
}

/// The number of pages of a Chromium-rendered PDF.
int pdfPageCount(Uint8List pdf) => _parsePdf(pdf).pageObjs.length;

/// For every URI link annotation, the 1-based page it is on (first page wins
/// when a URI appears more than once).
Map<String, int> linkTargetPages(Uint8List pdf) {
  final p = _parsePdf(pdf);
  final out = <String, int>{};
  for (var i = 0; i < p.pageObjs.length; i++) {
    final page = p.bodies[p.pageObjs[i]] ?? '';
    final annots = <String>[];
    final inline = RegExp(r'/Annots\s*\[([^\]]*)\]').firstMatch(page);
    var refs = inline?[1];
    if (refs == null) {
      final indirect = RegExp(r'/Annots\s+(\d+)\s+0\s+R').firstMatch(page);
      if (indirect != null) {
        final arr = p.bodies[int.parse(indirect[1]!)] ?? '';
        refs = RegExp(r'\[([^\]]*)\]').firstMatch(arr)?[1];
      }
    }
    if (refs != null) {
      for (final r in RegExp(r'(\d+)\s+0\s+R').allMatches(refs)) {
        annots.add(p.bodies[int.parse(r[1]!)] ?? '');
      }
      // Annotation dictionaries written inline in the array.
      if (RegExp(r'<<').hasMatch(refs)) annots.add(refs);
    }
    for (final a in annots) {
      for (final m in RegExp(r'/URI\s*\(((?:\\.|[^\\)])*)\)').allMatches(a)) {
        final uri = m[1]!.replaceAllMapped(RegExp(r'\\(.)'), (x) => x[1]!);
        out.putIfAbsent(uri, () => i + 1);
      }
    }
  }
  return out;
}

/// A PDF text string: UTF-16BE with a BOM, as a literal `( ... )` whose
/// characters are the bytes (latin1).
String _pdfText(String s) {
  final bytes = <int>[0xfe, 0xff];
  for (final rune in s.runes) {
    if (rune > 0xffff) {
      final v = rune - 0x10000;
      final hi = 0xd800 + (v >> 10);
      final lo = 0xdc00 + (v & 0x3ff);
      bytes.addAll([hi >> 8, hi & 0xff, lo >> 8, lo & 0xff]);
    } else {
      bytes.addAll([rune >> 8, rune & 0xff]);
    }
  }
  final out = StringBuffer('(');
  for (final b in bytes) {
    if (b == 0x28 || b == 0x29 || b == 0x5c) out.write('\\');
    out.writeCharCode(b);
  }
  out.write(')');
  return out.toString();
}

/// Appends a bookmark outline to [pdf] and returns the new bytes. [items]
/// are in order; `page` is 1-based, `level` is the 1-based depth.
Uint8List addPdfOutline(Uint8List pdf, List<OutlineItem> items) {
  if (items.isEmpty) return pdf;
  final parsed = _parsePdf(pdf);
  final pageObjs = parsed.pageObjs;

  final valid = [
    for (final it in items)
      if (it.title.trim().isNotEmpty)
        (
          title: it.title,
          page: it.page.clamp(1, pageObjs.length),
          level: it.level < 1 ? 1 : it.level,
        ),
  ];
  if (valid.isEmpty) return pdf;

  final outlineRootObj = parsed.maxObj + 1;
  int itemObj(int i) => outlineRootObj + 1 + i;

  final n = valid.length;
  final parent = List<int>.filled(n, -1);
  final children = List.generate(n, (_) => <int>[]);
  final rootChildren = <int>[];
  final stack = <int>[];
  for (var i = 0; i < n; i++) {
    final lvl = valid[i].level;
    while (stack.isNotEmpty && valid[stack.last].level >= lvl) {
      stack.removeLast();
    }
    if (stack.isEmpty) {
      rootChildren.add(i);
    } else {
      parent[i] = stack.last;
      children[stack.last].add(i);
    }
    stack.add(i);
  }

  String ref(int obj) => '$obj 0 R';
  int countOpen(int i) {
    var c = children[i].length;
    for (final ch in children[i]) {
      c += countOpen(ch);
    }
    return c;
  }

  final objBodies = <({int obj, String body})>[];
  {
    var total = rootChildren.length;
    for (final r in rootChildren) {
      total += countOpen(r);
    }
    final first = ' /First ${ref(itemObj(rootChildren.first))}';
    final last = ' /Last ${ref(itemObj(rootChildren.last))}';
    objBodies.add((
      obj: outlineRootObj,
      body: '<< /Type /Outlines$first$last /Count $total >>'
    ));
  }

  for (var i = 0; i < n; i++) {
    final it = valid[i];
    final par = parent[i];
    final sibs = par == -1 ? rootChildren : children[par];
    final kids = children[i];
    final pos = sibs.indexOf(i);
    final parentRef = par == -1 ? ref(outlineRootObj) : ref(itemObj(par));
    final b =
        StringBuffer('<< /Title ${_pdfText(it.title)} /Parent $parentRef');
    if (pos > 0) b.write(' /Prev ${ref(itemObj(sibs[pos - 1]))}');
    if (pos < sibs.length - 1) b.write(' /Next ${ref(itemObj(sibs[pos + 1]))}');
    if (kids.isNotEmpty) {
      b.write(' /First ${ref(itemObj(kids.first))}');
      b.write(' /Last ${ref(itemObj(kids.last))}');
      var count = kids.length;
      for (final k in kids) {
        count += countOpen(k);
      }
      b.write(' /Count $count');
    }
    b.write(' /Dest [${ref(pageObjs[it.page - 1])} /Fit] >>');
    objBodies.add((obj: itemObj(i), body: b.toString()));
  }

  // The Catalog again, with /Outlines and /PageMode /UseOutlines added.
  final rootBody = RegExp('\\b${parsed.rootObj}\\s+0\\s+obj([\\s\\S]*?)endobj')
      .firstMatch(parsed.text);
  if (rootBody == null) {
    throw const FormatException('pdf outline: could not read /Root object');
  }
  var rootInner = rootBody[1]!
      .trim()
      .replaceAll(RegExp(r'/Outlines\s+\d+\s+0\s+R'), '')
      .replaceAll(RegExp(r'/PageMode\s*/\w+'), '');
  final close = rootInner.lastIndexOf('>>');
  rootInner =
      '${rootInner.substring(0, close)} /Outlines ${ref(outlineRootObj)} /PageMode /UseOutlines ${rootInner.substring(close)}';
  objBodies.add((obj: parsed.rootObj, body: rootInner));

  final out = BytesBuilder(copy: false)..add(pdf);
  var offset = pdf.length;
  void add(String s) {
    final bytes = latin1.encode(s);
    out.add(bytes);
    offset += bytes.length;
  }

  add('\n');
  objBodies.sort((a, b) => a.obj.compareTo(b.obj));
  final xrefEntries = <({int obj, int offset})>[];
  for (final ob in objBodies) {
    xrefEntries.add((obj: ob.obj, offset: offset));
    add('${ob.obj} 0 obj\n${ob.body}\nendobj\n');
  }

  final xrefStart = offset;
  final xref = StringBuffer('xref\n');
  var i = 0;
  while (i < xrefEntries.length) {
    var j = i;
    while (j + 1 < xrefEntries.length &&
        xrefEntries[j + 1].obj == xrefEntries[j].obj + 1) {
      j++;
    }
    xref.write('${xrefEntries[i].obj} ${j - i + 1}\n');
    for (var k = i; k <= j; k++) {
      xref.write(
          '${xrefEntries[k].offset.toString().padLeft(10, '0')} 00000 n \n');
    }
    i = j + 1;
  }
  final maxNewObj = xrefEntries.last.obj;
  xref.write('trailer\n<< /Size ${maxNewObj + 1} /Root ${ref(parsed.rootObj)} '
      '/Prev ${parsed.prevStartXref} >>\nstartxref\n$xrefStart\n%%EOF\n');
  add(xref.toString());
  return out.takeBytes();
}
