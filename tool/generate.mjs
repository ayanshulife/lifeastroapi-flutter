// Code generator for the Dart SDK.
//
// Reads the endpoint manifest of the Node SDK (scripts/endpoints_part1.json +
// endpoints_part2.json, resolved by scripts/manifest.mjs: overrides, `lang`
// rules, namespace and method names) and writes:
//
//   lib/src/resources/*.dart     one class per namespace (the public methods)
//   tool/manifest.json           the resolved manifest with the Dart parameters
//   tool/src/dispatch.g.dart     "ns.method" -> call table for the live sweep and tests
//   test/fixtures/examples.json  request params of every endpoint (from the website's
//                                examples.json, when that file is found)
//
// Importing manifest.mjs, rather than copying its rules, keeps both SDKs on the
// same endpoint list, method names and `lang` rules.
//
//   node tool/generate.mjs
//
// Environment:
//   LIFEASTRO_NODE_SDK   path to the Node SDK repo (default ../lifeastroapi-node)
//   LIFEASTRO_EXAMPLES   path to the website's examples.json (default
//                        ../LifeAstroAPI/LifeAstroApiWebsite/lib/generated/examples.json)
import { existsSync, mkdirSync, readFileSync, readdirSync, rmSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { execFileSync } from "node:child_process";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const NODE_SDK = resolve(process.env.LIFEASTRO_NODE_SDK ?? join(ROOT, "..", "lifeastroapi-node"));
const EXAMPLES = resolve(
  process.env.LIFEASTRO_EXAMPLES ??
    join(ROOT, "..", "LifeAstroAPI", "LifeAstroApiWebsite", "lib", "generated", "examples.json"),
);
const OUT = join(ROOT, "lib", "src", "resources");

const manifestPath = join(NODE_SDK, "scripts", "manifest.mjs");
if (!existsSync(manifestPath)) {
  console.error(`Node SDK manifest not found at ${manifestPath}. Set LIFEASTRO_NODE_SDK.`);
  process.exit(2);
}
const { entries, camel, pascal } = await import(pathToFileURL(manifestPath).href);

// ---------------------------------------------------------------------------
// Base shapes: the Dart parameters each manifest shape contributes, and the
// wire names they map to (the same mapping as src/params.ts in the Node SDK).
// A scalar parameter has `wires: [..]`; a birth-object parameter has
// `fields: { date: [..], time: [..], ... }`.
// ---------------------------------------------------------------------------
const BIRTH_FIELDS = ["date", "time", "tz", "lat", "lon"];
const birthFields = (prefix) => Object.fromEntries(BIRTH_FIELDS.map((f) => [f, [prefix + f]]));
const p = (name, type, required, wires, more = {}) => ({ name, type, required, wires, source: "base", ...more });
const obj = (name, type, required, fields) => ({ name, type, required, fields, source: "base" });
const AYANAMSA = p("ayanamsa", "Ayanamsa", false, ["ayanamsa"]);
const HOUSE = p("houseSystem", "HouseSystem", false, ["house_system"]);

const SHAPES = {
  moment: () => [
    p("lat", "num", true, ["lat"]),
    p("lon", "num", true, ["lon"]),
    p("tz", "String", true, ["tz"]),
    p("date", "String", false, ["date"], { valueExpr: "date ?? todayIn(tz)" }),
    p("time", "String", false, ["time"]),
    AYANAMSA,
  ],
  birth: () => [obj("birth", "BirthInput", true, birthFields("")), AYANAMSA, HOUSE],
  birthPrefixed: () => [obj("birth", "BirthInput", true, birthFields("birth.")), AYANAMSA],
  boygirl: () => [
    obj("boy", "BirthInput", true, birthFields("boy.")),
    obj("girl", "BirthInput", true, birthFields("girl.")),
    AYANAMSA,
  ],
  twoPerson: () => [
    obj("personA", "BirthInput", true, birthFields("personA.")),
    obj("personB", "BirthInput", true, birthFields("personB.")),
  ],
  rashi: () => [
    p("rashi", "String", true, ["rashi"], { valueExpr: "rashi.trim().toLowerCase()" }),
    p("date", "String", false, ["date"]),
    p("lang", "Lang", false, ["lang"]),
  ],
  numerology: () => [
    p("name", "String", false, ["name"]),
    p("dob", "String", false, ["dob"]),
    p("lang", "Lang", false, ["lang"]),
  ],
  dateRange: () => [p("startDate", "String", true, ["start_date"]), p("endDate", "String", true, ["end_date"])],
  westernNatal: () => [obj("birth", "BirthInput", true, birthFields("")), HOUSE],
  westernMoment: () => [p("date", "String", true, ["date"]), p("time", "String", true, ["time"]), p("tz", "String", true, ["tz"])],
  muhurta: () => [
    p("lat", "num", true, ["lat"]),
    p("lon", "num", true, ["lon"]),
    p("tz", "String", true, ["tz"]),
    p("startDate", "String", true, ["start_date"]),
    p("endDate", "String", true, ["end_date"]),
  ],
  natalTransit: () => [
    obj("birth", "BirthInput", true, birthFields("birth.")),
    p("date", "String", true, ["date"]),
    p("time", "String", true, ["time"]),
    p("tz", "String", true, ["tz"]),
    AYANAMSA,
  ],
  // Also sends the birth place unprefixed: the handler casts the natal lagna from it.
  natalTransitPlace: () => [
    obj("birth", "BirthInput", true, {
      ...birthFields("birth."),
      lat: ["birth.lat", "lat"],
      lon: ["birth.lon", "lon"],
    }),
    p("date", "String", true, ["date"]),
    p("time", "String", true, ["time"]),
    p("tz", "String", true, ["tz"]),
    AYANAMSA,
  ],
  natalWindow: () => [
    obj("birth", "NatalWindowBirth", true, birthFields("birth.")),
    p("from", "String", false, ["from"]),
    p("tz", "String", false, ["tz"]),
    AYANAMSA,
  ],
  natalWindowOptional: () => [
    obj("birth", "NatalWindowBirth", false, birthFields("birth.")),
    p("from", "String", false, ["from"]),
    p("tz", "String", false, ["tz"]),
    AYANAMSA,
  ],
  instant: () => [
    p("date", "String", false, ["date"], { valueExpr: "date ?? todayIn(tz ?? 'UTC')" }),
    p("time", "String", false, ["time"]),
    p("tz", "String", false, ["tz"], { valueExpr: "tz ?? 'UTC'" }),
    AYANAMSA,
  ],
  none: () => [],
  custom: () => [],
};

/** Dart type of a manifest extra. Language, ayanamsa and house system get their enums. */
function dartType(x, name) {
  if (name === "lang" || name === "locale" || x.type === "locale") return "Lang";
  if (name === "ayanamsa") return "Ayanamsa";
  if (name === "houseSystem") return "HouseSystem";
  if (x.type === "number") return "num";
  if (x.type === "integer") return "int";
  if (x.type === "boolean") return "bool";
  return "String";
}

/**
 * Custom-shape endpoints that list a birth chart as separate fields
 * (date/time/tz/lat/lon, birthDate/birthTime/birthTz, boyDate/...) take a
 * BirthInput instead, like every other method that needs a chart. Each field
 * keeps its manifest wire name.
 */
const GROUPS = [
  { param: "birth", members: { date: "date", time: "time", tz: "tz", lat: "lat", lon: "lon" }, needs: ["date", "time", "tz", "lat", "lon"] },
  { param: "birth", members: { date: "birthDate", time: "birthTime", tz: "birthTz", lat: "lat", lon: "lon" }, needs: ["birthDate", "birthTime", "birthTz"] },
  { param: "boy", members: { date: "boyDate", time: "boyTime", tz: "boyTz", lat: "boyLat", lon: "boyLon" }, needs: ["boyDate", "boyTime", "boyTz"] },
  { param: "girl", members: { date: "girlDate", time: "girlTime", tz: "girlTz", lat: "girlLat", lon: "girlLon" }, needs: ["girlDate", "girlTime", "girlTz"] },
];

function applyGroups(params) {
  for (const g of GROUPS) {
    const byName = new Map(params.map((q) => [q.name, q]));
    if (!g.needs.every((n) => byName.get(n)?.source === "extra")) continue;
    if (byName.has(g.param)) continue;
    const fields = {};
    const used = new Set();
    for (const [field, member] of Object.entries(g.members)) {
      const m = byName.get(member);
      if (m && m.source === "extra") {
        fields[field] = m.wires;
        used.add(member);
      }
    }
    const required = [...used].every((n) => byName.get(n).required);
    const at = params.findIndex((q) => used.has(q.name));
    const grouped = { name: g.param, type: "BirthInput", required, fields, source: "group" };
    params = params.filter((q) => !used.has(q.name));
    params.splice(at, 0, grouped);
  }
  return params;
}

/** Resolve one manifest entry into its Dart parameter list. */
function dartParams(e) {
  const shape = SHAPES[e.shape];
  if (!shape) throw new Error(`Unknown shape "${e.shape}" for ${e.path}`);
  let params = [];
  for (const n of e.pathParams ?? []) {
    params.push({ name: n, type: n === "n" || n === "number" ? "int" : "String", required: true, source: "path" });
  }
  params.push(...shape().map((q) => ({ ...q, wires: q.wires && [...q.wires] })));
  for (const x of e.extras ?? []) {
    const name = x.name ?? camel(x.wire);
    const wires = x.wire === "lang" ? [x.wire, "locale"] : [x.wire];
    const existing = params.find((q) => q.name === name);
    if (existing) {
      // Same input field as a base parameter (e.g. `lang` on a rashi shape):
      // one Dart parameter, sent under every wire name, as in Node.
      if (!existing.wires) throw new Error(`${e.path}: extra "${name}" collides with object parameter`);
      for (const w of wires) if (!existing.wires.includes(w)) existing.wires.push(w);
      // An extra can make a base parameter required (numerology.full: `dob`).
      if (x.required) existing.required = true;
      continue;
    }
    params.push({ name, type: dartType(x, name), required: !!x.required, wires, source: "extra" });
  }
  if (e.shape === "custom") params = applyGroups(params);
  const names = new Set();
  for (const q of params) {
    if (names.has(q.name)) throw new Error(`${e.path}: duplicate Dart parameter ${q.name}`);
    names.add(q.name);
  }
  return params;
}

// ---------------------------------------------------------------------------
// Dart source helpers
// ---------------------------------------------------------------------------
const NS_DOC = {
  ashtakavarga: "Ashtakavarga: sarva, bhinna (per planet), kaksha and transit score.",
  calendar: "Hindu calendar: month, ritu, samvatsara, adhik maas, solstices.",
  chart: "Birth chart (kundli): planets, ascendant, houses, divisional charts, dignity, aspects, shadbala, KP, and the data bundles `kundliFacts`, `yogas`, `doshas`, `sensitivity`.",
  dasha: "Vimshottari (5 levels), Yogini and Chara dashas.",
  eclipses: "Solar and lunar eclipses in a date range, with local contact times and sutak.",
  festivals: "Hindu festivals and vrat dates by month, on a date, or by vrat family for a year.",
  geo: "Place search, reverse geocoding, time zone lookup.",
  horoscope: "Daily, weekly and monthly horoscope by rashi.",
  lalkitab: "Lal Kitab chart and dasha.",
  meta: "Free catalogs: endpoints with credit costs, ayanamsas, yogas, doshas, locales, version.",
  milan: "Kundli matching: Ashtakoota, doshas, navamsa and dasha compatibility, overlay, summary.",
  muhurta: "Muhurta: vivah, naamkaran, griha pravesh, vyapar, yatra, best time, chandra/tara bala.",
  narrative: "Authored Vedic readings: lagna, planets, yogas, doshas, dasha phal, transit phal, prashna, horoscopes and more.",
  numerology: "Numerology: driver, conductor, soul, personality, destiny, full, advanced, challenges, personal periods.",
  panchang: "Panchang: tithi, nakshatra, yoga, karana, vara, sunrise/sunset, muhurta windows, choghadiya, hora, monthly calendar.",
  planetMoments: "Planet moments: retrograde windows, sign ingress, combustion window, speed.",
  prashna: "Prashna (horary): answer, chart, arudha, significators.",
  remedies: "Remedies: by rule id, by graha (`forGraha`), mantra, pooja, vrat, daan, rudraksha, yantra, Lal Kitab.",
  reports: "Composed JSON reports: kundli (lite, detailed, brihad), match making, mangal dosha, sade sati, varshaphal, numerology, horoscopes.",
  tarot: "Tarot: cards, a single card, daily card, spreads, yes/no.",
  transit: "Transits: positions, sade sati, small panoti, tarabala, vedha, double transit, dated windows.",
  varshaphal: "Varshaphal (annual chart): chart, lord, muntha, mudda dasha, harsha bala, tajika yogas.",
  western: "Western (tropical) astrology. Sub-groups: `natal`, `synastry`, `transits`, `returns` and more.",
};

function escapeDoc(text) {
  return String(text)
    .replace(/\s+/g, " ")
    .trim()
    .replace(/\[/g, "\\[")
    .replace(/\]/g, "\\]")
    .replace(/(^|[^`\w])<([\w.]+)>/g, "$1`<$2>`")
    .replace(/\*_/g, "\\*_");
}

/** Word-wrap a doc paragraph into `///` lines. */
function docLines(text, indent) {
  const words = escapeDoc(text).split(" ");
  const lines = [];
  let line = "";
  const max = 80 - indent.length - 4;
  for (const w of words) {
    if (line && line.length + 1 + w.length > max) {
      lines.push(line);
      line = w;
    } else {
      line = line ? `${line} ${w}` : w;
    }
  }
  if (line) lines.push(line);
  return lines.map((l) => `${indent}/// ${l}`);
}

const dq = (s) => `'${String(s).replace(/\\/g, "\\\\").replace(/'/g, "\\'").replace(/\$/g, "\\$")}'`;

function scalarValue(q) {
  if (q.valueExpr) return q.valueExpr;
  const n = q.required ? q.name : `${q.name}?`;
  if (q.type === "Lang") return `${n}.code`;
  if (q.type === "Ayanamsa" || q.type === "HouseSystem") return `${n}.wire`;
  return q.name;
}

function buildMethod(e, params, indent = "  ") {
  const { method } = e._resolved;
  const pathParams = params.filter((q) => q.source === "path");
  const sorted = [...params].sort((a, b) => Number(b.required) - Number(a.required));
  const sig = sorted.map((q) => `${q.required ? "required " : ""}${q.type}${q.required ? "" : "?"} ${q.name},`);
  sig.push("RequestOptions? options,");

  const puts = [];
  for (const q of params) {
    if (q.source === "path") continue;
    if (q.fields) {
      const acc = q.required ? q.name : `${q.name}?`;
      for (const [field, wires] of Object.entries(q.fields)) {
        for (const w of wires) puts.push(`..put(${dq(w)}, ${acc}.${field})`);
      }
    } else {
      for (const w of q.wires) puts.push(`..put(${dq(w)}, ${scalarValue(q)})`);
    }
  }

  const pathExpr = pathParams.length
    ? `buildPath(${dq(e.path)}, {${pathParams.map((q) => `${dq(q.name)}: ${q.name}`).join(", ")}})`
    : dq(e.path);

  const doc = [...docLines(e.desc ?? e.path, indent), `${indent}///`, `${indent}/// \`GET ${e.path}\``];
  const body = puts.length
    ? [
        `${indent}  final \$q = <String, Object?>{}`,
        ...puts.map((s, i) => `${indent}    ${s}${i === puts.length - 1 ? ";" : ""}`),
        `${indent}  return _c.request<T>(${pathExpr}, \$q, options);`,
      ]
    : [`${indent}  return _c.request<T>(${pathExpr}, const {}, options);`];

  return [
    ...doc,
    `${indent}Future<T> ${method}<T>({`,
    ...sig.map((s) => `${indent}  ${s}`),
    `${indent}}) {`,
    ...body,
    `${indent}}`,
  ].join("\n");
}

function needsParams(list) {
  return list.some(({ params }) => params.length > 0);
}
function needsTypes(list) {
  const t = new Set(["Lang", "Ayanamsa", "HouseSystem", "BirthInput", "NatalWindowBirth"]);
  return list.some(({ params }) => params.some((q) => t.has(q.type)));
}

const HEADER = `// GENERATED by tool/generate.mjs from the endpoint manifest. Do not edit by hand.
// Run \`node tool/generate.mjs\` to regenerate.
`;

function imports(list) {
  const out = [];
  if (needsParams(list)) out.push("import '../params.dart';");
  out.push("import '../transport.dart';");
  if (needsTypes(list)) out.push("import '../types.dart';");
  return out.join("\n");
}

function classSrc(cls, doc, list, extraFields = "", extraInit = "") {
  const methods = list.map(({ e, params }) => buildMethod(e, params)).join("\n\n");
  const ctor = extraInit
    ? `  /// Created by [LifeAstro]; use \`client.${doc.prop}\`.\n  ${cls}(this._c)\n      : ${extraInit};`
    : `  /// Created by [LifeAstro]; use \`client.${doc.prop}\`.\n  ${cls}(this._c);`;
  return `${docLines(doc.text, "").join("\n")}
class ${cls} {
${ctor}

  final ClientCore _c;
${extraFields}
${methods}
}
`;
}

// ---------------------------------------------------------------------------
// Resolve every entry and group by namespace.
// ---------------------------------------------------------------------------
const resolved = entries.map((e) => ({ e, params: dartParams(e) }));
const byNs = new Map();
for (const r of resolved) {
  const ns = r.e._resolved.ns;
  if (!byNs.has(ns)) byNs.set(ns, []);
  byNs.get(ns).push(r);
}
for (const list of byNs.values()) list.sort((a, b) => a.e._resolved.method.localeCompare(b.e._resolved.method));

rmSync(OUT, { recursive: true, force: true });
mkdirSync(OUT, { recursive: true });

const flatNs = [...byNs.keys()].filter((ns) => !ns.startsWith("western")).sort();
const westernChildNs = [...byNs.keys()].filter((ns) => ns.startsWith("western.")).sort();
const written = [];
const fileName = (ns) => ns.replace(/[A-Z]/g, (c) => `_${c.toLowerCase()}`) + ".dart";

for (const ns of flatNs) {
  const cls = `${pascal(ns)}Api`;
  const list = byNs.get(ns);
  const src = `${HEADER}
${imports(list)}

${classSrc(cls, { text: NS_DOC[ns] ?? ns, prop: ns }, list)}`;
  writeFileSync(join(OUT, fileName(ns)), src);
  written.push({ ns, cls, file: fileName(ns), prop: ns });
}

{
  const children = westernChildNs.map((ns) => {
    const sub = ns.split(".")[1];
    return { ns, sub, cls: `Western${pascal(sub)}Api` };
  });
  const direct = byNs.get("western") ?? [];
  const all = [...direct, ...children.flatMap((c) => byNs.get(c.ns))];
  const childSrc = children
    .map((c) =>
      classSrc(c.cls, { text: `Western \`${c.sub}\` endpoints: \`client.western.${c.sub}\`.`, prop: `western.${c.sub}` }, byNs.get(c.ns)),
    )
    .join("\n");
  const fields = children.map((c) => `  /// \`client.western.${c.sub}\`.\n  final ${c.cls} ${c.sub};\n`).join("\n");
  const init = children.map((c) => `${c.sub} = ${c.cls}(_c)`).join(",\n        ");
  const src = `${HEADER}
${imports(all)}

${classSrc("WesternApi", { text: NS_DOC.western, prop: "western" }, direct, "\n" + fields, init)}
${childSrc}`;
  writeFileSync(join(OUT, "western.dart"), src);
  written.push({ ns: "western", cls: "WesternApi", file: "western.dart", prop: "western", children });
}

written.sort((a, b) => a.prop.localeCompare(b.prop));
const resourcesSrc = `${HEADER}
import '../transport.dart';
${written.map((w) => `import '${w.file}';`).join("\n")}

/// Every resource group of the API. [LifeAstro] extends this, so the groups
/// are available as \`client.panchang\`, \`client.chart\`, \`client.western.natal\`
/// and so on.
abstract class LifeAstroResources {
  /// Builds every group on top of [core].
  LifeAstroResources(ClientCore core)
      : ${written.map((w) => `${w.prop} = ${w.cls}(core)`).join(",\n        ")};

${written.map((w) => `${docLines(NS_DOC[w.prop] ?? w.prop, "  ").join("\n")}\n  final ${w.cls} ${w.prop};`).join("\n\n")}
}
`;
writeFileSync(join(OUT, "resources.dart"), resourcesSrc);

const exportsSrc = `${HEADER}
${["resources.dart", ...written.map((w) => w.file)].sort().map((f) => `export '${f}';`).join("\n")}
`;
writeFileSync(join(OUT, "all.dart"), exportsSrc);

// ---------------------------------------------------------------------------
// tool/manifest.json + tool/src/dispatch.g.dart
// ---------------------------------------------------------------------------
const manifestOut = resolved
  .map(({ e, params }) => ({
    key: `${e._resolved.ns}.${e._resolved.method}`,
    ns: e._resolved.ns,
    method: e._resolved.method,
    path: e.path,
    shape: e.shape,
    desc: e.desc ?? "",
    params: params.map((q) => ({
      name: q.name,
      type: q.type,
      required: q.required,
      source: q.source,
      ...(q.fields ? { fields: q.fields } : { wires: q.wires ?? [] }),
    })),
  }))
  .sort((a, b) => a.key.localeCompare(b.key));
writeFileSync(join(ROOT, "tool", "manifest.json"), JSON.stringify(manifestOut, null, 1) + "\n");

const COERCE = {
  num: "asNum",
  int: "asInt",
  bool: "asBool",
  String: "asStr",
  Lang: "asLang",
  Ayanamsa: "asAyanamsa",
  HouseSystem: "asHouseSystem",
  BirthInput: "asBirth",
  NatalWindowBirth: "asWindowBirth",
};
const dispatch = manifestOut
  .map((m) => {
    const access = m.ns.split(".").join(".");
    const args = m.params
      .map((q) => `${q.name}: ${COERCE[q.type]}(i[${dq(q.name)}])${q.required ? "!" : ""}`)
      .join(", ");
    return `  ${dq(m.key)}: (c, i, [o]) => c.${access}.${m.method}(${args}${args ? ", " : ""}options: o),`;
  })
  .join("\n");
writeFileSync(
  join(ROOT, "tool", "src", "dispatch.g.dart"),
  `${HEADER}
import 'package:lifeastroapi/lifeastroapi.dart';

import 'coerce.dart';

/// Calls one SDK method from a loosely typed input map.
typedef Invoker = Future<Object?> Function(
    LifeAstro c, Map<String, Object?> i, [RequestOptions? o]);

/// Every SDK method, keyed by \`ns.method\` (same keys as tool/manifest.json).
final Map<String, Invoker> invokers = {
${dispatch}
};
`,
);

// ---------------------------------------------------------------------------
// test/fixtures/examples.json: the website's verified request params.
// ---------------------------------------------------------------------------
if (existsSync(EXAMPLES)) {
  const ex = JSON.parse(readFileSync(EXAMPLES, "utf8"));
  const keep = new Set(["/v1/panchang/tithi", "/v1/chart/planets"]);
  const out = {};
  for (const [path, v] of Object.entries(ex).sort(([a], [b]) => a.localeCompare(b))) {
    out[path] = { status: v.status, required: v.required ?? [], params: v.params ?? {} };
    if (keep.has(path)) out[path].response = v.response;
  }
  mkdirSync(join(ROOT, "test", "fixtures"), { recursive: true });
  writeFileSync(join(ROOT, "test", "fixtures", "examples.json"), JSON.stringify(out, null, 1) + "\n");
} else {
  console.warn(`examples.json not found at ${EXAMPLES}; test/fixtures/examples.json left as is.`);
}

// Format what we wrote.
try {
  execFileSync("dart", ["format", "lib/src/resources", "tool/src/dispatch.g.dart"], { cwd: ROOT, stdio: "ignore" });
} catch {
  console.warn("`dart format` failed or is not installed; run it by hand.");
}

const methodCount = resolved.length;
const files = readdirSync(OUT).length;
console.log(`Generated ${files} files in lib/src/resources, ${methodCount} methods (${entries.length} endpoints).`);
console.log("Groups:", written.map((w) => w.prop).join(", "));
