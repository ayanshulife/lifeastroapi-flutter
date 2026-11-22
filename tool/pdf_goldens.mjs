// Golden files for the Dart port of the PDF report templates.
//
// The Dart `render*Html` functions (lib/src/pdf/) are a port of the Node SDK's
// src/pdf/. This script renders the same inputs with the Node TypeScript
// sources and writes the expected HTML, so test/pdf_golden_test.dart can check
// that the Dart output is byte-for-byte identical.
//
// Inputs:
//   1. every render*Html call made by the Node SDK's own PDF tests
//      (test/pdf.test.ts, test/pdf-south-locales.test.ts), recorded while the
//      tests run against a stubbed `vitest`;
//   2. the real report responses in the website's examples.json, rendered in
//      all 10 locales, with and without a branding override;
//   3. hand-written inputs for fixed defects, which the inputs above do not reach.
//
//   node tool/pdf_goldens.mjs
//
// Environment: LIFEASTRO_NODE_SDK, LIFEASTRO_EXAMPLES (as tool/generate.mjs).
import { createRequire } from "node:module";
import { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const NODE_SDK = resolve(process.env.LIFEASTRO_NODE_SDK ?? join(ROOT, "..", "lifeastroapi-node"));
const EXAMPLES = resolve(
  process.env.LIFEASTRO_EXAMPLES ??
    join(ROOT, "..", "LifeAstroAPI", "LifeAstroApiWebsite", "lib", "generated", "examples.json"),
);
const OUT = join(ROOT, "test", "fixtures", "pdf");
const TMP = join(ROOT, ".dart_tool", "pdf_goldens");

const require = createRequire(join(NODE_SDK, "package.json"));
const esbuild = require("esbuild");
const PDF_INDEX = join(NODE_SDK, "src", "pdf", "index.ts");

const RENDERERS = [
  "renderKundliLiteHtml",
  "renderKundliDetailedHtml",
  "renderKundliBrihadHtml",
  "renderMatchMakingHtml",
  "renderDashaAnalysisHtml",
  "renderNumerologyHtml",
  "renderSadeSatiHtml",
  "renderVarshaphalHtml",
  "renderHoroscopeHtml",
  "renderMangalDoshaHtml",
];

// A bundle that exposes the real templates plus a recorder around them.
const recorderSrc = `
import * as real from ${JSON.stringify(PDF_INDEX)};
export * from ${JSON.stringify(PDF_INDEX)};
globalThis.__pdfCalls = globalThis.__pdfCalls ?? [];
const rec = (name, fn) => (...args) => {
  globalThis.__pdfCalls.push({ fn: name, args: JSON.parse(JSON.stringify(args.map((a) => a ?? null))) });
  return fn(...args);
};
${RENDERERS.map((n) => `export const ${n} = rec(${JSON.stringify(n)}, real.${n});`).join("\n")}
`;

const stubVitest = `
const chain = new Proxy(function () {}, { get: () => chain, apply: () => chain });
const run = (fn) => { try { const r = fn?.(); if (r && typeof r.catch === "function") r.catch(() => {}); } catch {} };
export const describe = (_n, fn) => run(fn);
export const it = (_n, fn) => run(fn);
it.each = () => (_n, fn) => {};
export const test = it;
export const expect = () => chain;
export const vi = chain;
export const beforeAll = () => {}, afterAll = () => {}, beforeEach = () => {}, afterEach = () => {};
`;

const plugin = {
  name: "pdf-goldens",
  setup(build) {
    build.onResolve({ filter: /^vitest$/ }, () => ({ path: "vitest", namespace: "stub" }));
    build.onLoad({ filter: /.*/, namespace: "stub" }, () => ({ contents: stubVitest, loader: "js" }));
    build.onResolve({ filter: /src\/pdf\/index\.js$/ }, () => ({ path: "recorder", namespace: "rec" }));
    build.onLoad({ filter: /.*/, namespace: "rec" }, () => ({
      contents: recorderSrc,
      loader: "js",
      resolveDir: join(NODE_SDK, "src", "pdf"),
    }));
  },
};

rmSync(TMP, { recursive: true, force: true });
mkdirSync(TMP, { recursive: true });
// The Node tests' htmlToPdf cases reject without Puppeteer; only the render
// calls matter here.
process.on("unhandledRejection", () => {});

// The table of CSS names, which colors.ts does not export.
async function namedColours() {
  const file = join(NODE_SDK, "src", "pdf", "colors.ts");
  const outfile = join(TMP, "named.mjs");
  await esbuild.build({
    stdin: { contents: readFileSync(file, "utf8") + "\nexport { NAMED_COLORS };\n", resolveDir: dirname(file), loader: "ts" },
    bundle: true,
    format: "esm",
    platform: "node",
    outfile,
    logLevel: "error",
  });
  return (await import(pathToFileURL(outfile).href)).NAMED_COLORS;
}

async function bundle(entry, outfile) {
  await esbuild.build({
    entryPoints: [entry],
    bundle: true,
    format: "esm",
    platform: "node",
    outfile,
    plugins: [plugin],
    logLevel: "error",
  });
  return import(pathToFileURL(outfile).href + `?t=${Date.now()}`);
}

// 1. Record the Node tests' calls.
for (const t of ["pdf.test.ts", "pdf-south-locales.test.ts"]) {
  await bundle(join(NODE_SDK, "test", t), join(TMP, t.replace(/\.ts$/, ".mjs")));
}
await new Promise((r) => setTimeout(r, 50)); // let async test bodies settle
const recorded = globalThis.__pdfCalls ?? [];

// The real templates (and the Brihad TOC helpers), bundled from the TS source.
const helpersEntry = join(TMP, "helpers.ts");
writeFileSync(
  helpersEntry,
  `export * from ${JSON.stringify(PDF_INDEX)};
export { brihadHeaderTemplate, brihadFooterTemplate, brihadPalette, buildBrihadToc, tagBrihadSectionsForToc } from ${JSON.stringify(
    join(NODE_SDK, "src", "pdf", "templates", "kundliBrihadSections.ts"),
  )};
export { TOC_HEADING } from ${JSON.stringify(join(NODE_SDK, "src", "pdf", "locales.ts"))};
export * as colorMath from ${JSON.stringify(join(NODE_SDK, "src", "pdf", "colors.ts"))};
export { printOptionsCss } from ${JSON.stringify(join(NODE_SDK, "src", "pdf", "render.ts"))};
export { northIndianChartSvg, planetLabelsFor, PLANET_COLORS } from ${JSON.stringify(
    join(NODE_SDK, "src", "pdf", "templates", "northIndianChart.ts"),
  )};
`,
);
const pdf = await bundle(helpersEntry, join(TMP, "helpers.mjs"));

// 2. Real report responses in every locale.
const LOCALES = ["en", "hi", "mr", "te", "ta", "kn", "ml", "gu", "bn", "pa"];
const BRANDING = {
  companyName: "Acme Astro",
  logoUrl: "https://cdn.example/acme/logo.png",
  primaryColor: "#6b21a8",
  secondaryColor: "#9333ea",
  footerText: "Acme Astro · confidential",
  watermarkText: "SAMPLE",
};
const REPORTS = {
  "/v1/reports/kundli/lite": "renderKundliLiteHtml",
  "/v1/reports/kundli/detailed": "renderKundliDetailedHtml",
  "/v1/reports/kundli/brihad": "renderKundliBrihadHtml",
  "/v1/reports/match-making": "renderMatchMakingHtml",
  "/v1/reports/dasha-analysis": "renderDashaAnalysisHtml",
  "/v1/reports/numerology": "renderNumerologyHtml",
  "/v1/reports/sade-sati": "renderSadeSatiHtml",
  "/v1/reports/varshaphal": "renderVarshaphalHtml",
  "/v1/reports/mangal-dosha": "renderMangalDoshaHtml",
};
const cases = [];
const seen = new Set();
function addCase(fn, args) {
  const key = fn + JSON.stringify(args);
  if (seen.has(key)) return;
  seen.add(key);
  cases.push({ fn, args });
}
for (const c of recorded) addCase(c.fn, c.args.length === 1 ? [c.args[0], null] : c.args);
// Horoscope reports have no example response (the examples run without a
// live corpus); render the Node test inputs in every locale instead.
for (const c of recorded.filter((r) => r.fn === "renderHoroscopeHtml")) {
  for (const loc of LOCALES) {
    addCase(c.fn, [{ ...c.args[0], language: loc }, c.args[1] ?? null]);
  }
}
if (existsSync(EXAMPLES)) {
  const ex = JSON.parse(readFileSync(EXAMPLES, "utf8"));
  for (const [path, fn] of Object.entries(REPORTS)) {
    const resp = ex[path]?.response;
    if (!resp || typeof resp !== "object") continue;
    for (const loc of LOCALES) addCase(fn, [{ ...resp, Locale: loc }, null]);
    addCase(fn, [resp, BRANDING]);
    addCase(fn, [{ ...resp, Locale: "hi" }, BRANDING]);
  }
} else {
  console.warn(`examples.json not found at ${EXAMPLES}; only the Node test inputs are used.`);
}

// 3. Fixed defects (each one is also asserted in test/pdf_regressions_test.dart).
const TAG = "<img src=x>";
addCase("renderNumerologyHtml", [{ name: "Arjun Mehta", dob: "1990-01-15", driver: 6, Locale: "pa" }, null]);
addCase("renderNumerologyHtml", [{ Subject: { Name: "" }, name: "Arjun Mehta", driver: 6 }, null]);
addCase("renderVarshaphalHtml", [
  { SolarReturnISO: "2027-01-15T16:39:17Z", SolarReturnLocal: "2027-01-15 22:09 IST" },
  null,
]);
addCase("renderVarshaphalHtml", [{ SolarReturnISO: "2027-01-15T16:39:17Z", SolarReturnLocal: "" }, null]);
addCase("renderKundliBrihadHtml", [
  {
    rajyoga_power: { percent: 5, planets: [TAG, "Sun"] },
    kp: { cusps: [{ house: 1, sign: "Aries" }], planet_significators: [{ key: "Sun", values: [TAG, 4] }] },
  },
  null,
]);
// Crowded chart cells: a centre diamond, a side triangle and the two edges.
const crowd = { 1: ["Sun", "Moon", "Mars", "Mercury"], 3: ["Jupiter", "Venus", "Saturn"], 11: ["Rahu"], 12: ["Ketu"] };
addCase("renderKundliBrihadHtml", [
  {
    Locale: "pa",
    Ascendant: { sign: "ਮੀਨ" },
    Planets: Object.entries(crowd).flatMap(([h, names]) =>
      names.map((n) => ({ name: n, house_num: Number(h), placement: { sign: "Pisces" } })),
    ),
  },
  null,
]);
addCase("renderVarshaphalHtml", [{ SolarReturnISO: "2027-01-15T16:39:17" }, null]);
addCase("renderVarshaphalHtml", [{ SolarReturnISO: "2027-01-15 16:39" }, null]);
addCase("renderVarshaphalHtml", [{ SolarReturnISO: "2027-01-15t16:39:17.5" }, null]);
// Marathi spells five planets differently from Hindi: chart and glyph lookups.
const MR_PLANETS = ["सूर्य", "चंद्र", "मंगळ", "बुध", "बृहस्पती", "शुक्र", "शनी", "राहू", "केतू"];
addCase("renderKundliBrihadHtml", [
  {
    Locale: "mr",
    Ascendant: { sign: "मेष" },
    Planets: MR_PLANETS.map((name, i) => ({ name, house_num: i + 1, placement: { sign: "मेष" } })),
    DivisionalCharts: [{ varga: "D9", lagna_sign: "मेष", planets: MR_PLANETS.map((name, i) => ({ name, house: i + 1 })) }],
  },
  null,
]);
addCase("renderKundliLiteHtml", [{ Locale: "toString", GeneratedAt: "2026-01-01T09:30" }, null]);
addCase("renderHoroscopeHtml", [{ language: "constructor" }, null]);
addCase("renderKundliLiteHtml", [
  { Locale: "gu" },
  {
    logoUrl: "https://cdn.example/a,,b->c.png?x=1&y=2",
    secondaryColor: "rgb(1 2 3 / 50%)",
    watermarkText: "A/*B*/C",
  },
]);

// Branding and layout (test/pdf_branding_test.dart asserts each one as well).
const API_DEFAULTS = {
  CompanyName: "", LogoURL: "", PrimaryColor: "#1a1a1a", SecondaryColor: "#666666",
  FooterText: "Generated using LifeAstroAPI", WatermarkText: "",
};
const LAYOUT = {
  Branding: API_DEFAULTS,
  Ascendant: { sign: "Aries" },
  Planets: [{ name: "Sun", house_num: 1, placement: { sign: "Aries" } }],
  DivisionalCharts: [{ varga: "D9", lagna_sign: "Leo", planets: [{ name: "Moon", house: 4 }] }],
  Remedies: [
    { Title: "A", Category: "graha_shanti", Description: "D" },
    { Title: "B", Category: "charity", Description: "D" },
  ],
  maitri: {
    order: ["Sun", "Moon"],
    tatkalik: [{ planet: "Sun", relations: { Sun: "TempFriend", Moon: "TempEnemy" } }],
  },
  rajyoga_power: { percent: 50, swarnim_kaal: [{ lord: "Moon" }] },
  ishta_devata: { deity: "Vishnu" },
  gems: { stones: [{ stone: "Pearl" }] },
};
for (const branding of [
  null,
  { primaryColor: "#0b5cad", secondaryColor: "#0b6b36", watermarkText: "DRAFT FOR REVIEW ONLY" },
  { primaryColor: "#ffe14d", companyName: "Acme — Astro", footerText: "© Acme — <private>" },
  { secondaryColor: "seagreen", logoUrl: "//cdn.example/l.png" },
  { primaryColor: "#1a1a1a", secondaryColor: "#666666", watermarkText: "CONFIDENTIAL" },
]) {
  addCase("renderKundliBrihadHtml", [LAYOUT, branding]);
}
// A field that should be a list and is not (Node's listOf / listText).
for (const value of ["1, 5", { a: 1 }, 7, true]) {
  addCase("renderKundliBrihadHtml", [
    {
      ...LAYOUT,
      narrative_chapters: value,
      DivisionalCharts: [{ varga: "D9", lagna_sign: "Leo", planets: value }],
      gems: { stones: value },
      kp: { cusps: [{ house: 1 }], planet_significators: [{ key: "Sun", values: value }] },
      rajyoga_power: { percent: 50, planets: value, swarnim_kaal: value },
    },
    null,
  ]);
  addCase("renderSadeSatiHtml", [
    { Current: { SignsTraversed: value }, Future: [{ StartDate: "2030", SignsTraversed: value }] },
    null,
  ]);
}
// A null inside a list (Node's withoutNullItems).
for (const list of [[null], ["x", null], [7, null, true], [{}, null], [[null]]]) {
  addCase("renderKundliBrihadHtml", [
    {
      ...LAYOUT,
      Planets: list,
      narrative_chapters: [{ key: "outlook" }, null],
      kp: { cusps: [{ house: 1 }], planet_significators: [{ key: "Sun", values: list }, null] },
      rajyoga_power: { percent: 50, planets: list, swarnim_kaal: list },
    },
    null,
  ]);
  addCase("renderKundliDetailedHtml", [{ Planets: list }, null]);
  addCase("renderDashaAnalysisHtml", [{ AllMahadashas: list }, null]);
  addCase("renderHoroscopeHtml", [{ slow_movers: list }, null]);
  addCase("renderSadeSatiHtml", [{ Current: { SignsTraversed: list }, Future: [null, { SignsTraversed: list }] }, null]);
  addCase("renderMatchMakingHtml", [{ MangalDoshaBoy: { Computed: true, HasDosha: true, HousesOccupied: list } }, null]);
}
addCase("renderKundliBrihadHtml", [{ ...LAYOUT, Branding: { ...API_DEFAULTS, PrimaryColor: "hsl(210, 100%, 50%)" } }, null]);
for (const [Locale, HousesOccupied] of [["en", []], ["pa", null], ["hi", [-4]]]) {
  addCase("renderMangalDoshaHtml", [{ Locale, HasDosha: !!HousesOccupied?.length, HousesOccupied }, null]);
}
addCase("renderKundliLiteHtml", [
  {},
  { primaryColor: "rgba(250, 240, 120, 0.8)", secondaryColor: "notacolour", watermarkText: " 😀😀 CONFIDENTIAL\u00a0COPY " },
]);

// Render.
rmSync(OUT, { recursive: true, force: true });
mkdirSync(join(OUT, "golden"), { recursive: true });
const counters = {};
const index = [];
for (const c of cases) {
  const short = c.fn.replace(/^render/, "").replace(/Html$/, "");
  const name = short[0].toLowerCase() + short.slice(1);
  counters[name] = (counters[name] ?? 0) + 1;
  const id = `${name}-${String(counters[name]).padStart(3, "0")}`;
  const args = JSON.parse(JSON.stringify(c.args));
  const html = pdf[c.fn](args[0], args[1] ?? undefined);
  writeFileSync(join(OUT, "golden", `${id}.html`), html);
  index.push({ id, fn: c.fn, data: c.args[0], branding: c.args[1] });
}
writeFileSync(join(OUT, "cases.json"), JSON.stringify(index, null, 1) + "\n");

// Text helpers: every string in the inputs, through humanize / cleanNarrative / esc.
const strings = new Set();
const walk = (v) => {
  if (typeof v === "string") strings.add(v);
  else if (Array.isArray(v)) v.forEach(walk);
  else if (v && typeof v === "object") Object.values(v).forEach(walk);
};
for (const c of cases) walk(c.args);
for (const s of [
  "A — B", "x – y", "a -> b => c", "—", " – ", "word —", "— word", "a , , b", "(, x ,)",
  "In Vedic astrology the chart is read on three levels: birth, dasha and transit. It is about guidance.",
  "the native's career; The native is calm; native's luck; native",
  "जातक की कुंडली में जातक को लाभ। जातक",
  "जातकाच्या जीवनात जातकाला यश जातक",
  "ਲਗਨ — ਤੁਹਾਡਾ ਸੁਭਾਅ, the native's career", "\u0085 NEL stays \u0085", "\u00a0\ufeff trimmed \u2028",
  "पहले। वैदिक ज्योतिष में तीन  स्तरों पर विचार होता है, यह दिशा देने वाला शास्त्र है। बाद",
  "जन्म, दशा और गोचर, इन तीन स्तरों पर देखा जाता है। बाद",
]) strings.add(s);
const text = [];
for (const s of [...strings].sort()) {
  const row = { s, humanize: pdf.humanize(s), esc: pdf.esc(s), clean: {} };
  for (const loc of ["en", "hi", "mr", "te", "gu", "pa"]) row.clean[loc] = pdf.cleanNarrative(s, loc);
  text.push(row);
}
writeFileSync(join(OUT, "text.json"), JSON.stringify(text, null, 1) + "\n");

// Colour math: every CSS name, every accepted form and the traps (rounding, Unicode spaces, length).
const names = Object.keys(await namedColours());
const values = [
  ...names, "RebeccaPurple", "SEAGREEN", "\u0130NDIGO", "\u212ahaki", "", " ", "inherit", "transparent", "constructor", "toString",
  "#05a", "#05af", "#0000", "#0b5cadff", "#0B5CAD", "#12345", "#0b5cad00", "#ffffff01", "#aBcDeF80",
  "rgb(11, 92, 173)", "rgb(11 92 173)", "rgb(1 2 3 / 50%)", "rgba(0,0,0,0.5)", "rgba(250, 240, 120, 0.8)", "rgb(100%, 0%, 0%)",
  "rgb(50%,12.5%,.5%)", "rgb(0.5,1.5,2.5)", "rgb(0.49999999999999994, 2, 3)", "rgb(300, 1, 1)", "rgb(1,2)", "rgb(1.2.3, 4, 5)", "rgb(1., 2, 3)",
  "rgb(\u0661, 2, 3)", "rgb(1,\u00a02,3)", "rgb(1\u20002\u20003)", "rgb(1\u00852\u00853)", "RGB(1,2,3)", "hsl(1,2,3)", "hsl(10%, 20%, 30%)",
  "\u00a0#0b5cad\ufeff", "\u0085#0b5cad", "#0b5cad\n", " red ", "#fff", "#1a1a1a", "#666666",
];
for (const alpha of ["0", "0.0", "1", "100%", ".5", "0.001", "2", "33%"]) values.push(`rgba(11, 92, 173, ${alpha})`);
for (let i = 0; i < 64; i++) values.push(`rgba(${i * 4},${255 - i * 3},${(i * 37) % 256},${(i + 1) / 64})`);
for (let hue = 0; hue <= 750; hue += 12.5) {
  for (const [s, l] of [[100, 50], [50, 25], [33.3, 72.5], [12.5, 90]]) values.push(`hsl(${hue}, ${s}%, ${l}%)`);
}
for (let width = 60; width <= 66; width++) values.push(`rgb(1,2,3${" ".repeat(width - 10)})`);
const colors = values.map((value) => {
  const m = pdf.colorMath;
  const rgb = m.parseColor(value);
  return {
    value,
    rgb: rgb ?? null,
    printable: m.printableColor(value, "#1a1a1a"),
    ...(rgb && {
      hex: m.toHex(rgb),
      brihad: m.toHex(m.darkenToContrast(rgb, 5.2)),
      tint: [3, 5, 25].map((p) => m.toHex(m.tintOnWhite(rgb, p))),
      seeThrough: m.seeThrough(rgb),
    }),
  };
});
writeFileSync(join(OUT, "colors.json"), JSON.stringify(colors) + "\n");

// Print options to CSS.
const options = [];
for (const format of ["A3", "A4", "A5", "Letter", "Legal", "Tabloid"]) {
  for (const landscape of [false, true]) {
    for (const preferCSSPageSize of [undefined, true, false]) options.push({ format, landscape, preferCSSPageSize });
  }
}
for (const margin of [
  {}, { top: "40mm", left: "0" }, { top: "12" }, { right: ".5in", bottom: "2CM" }, { top: "\u00a010px\ufeff" },
  { top: "1mm}body{display:none", bottom: " " }, { top: "-5mm", left: "5 mm", right: "1em", bottom: "1." },
  { top: "\u008510px", left: "\u0661\u0660mm" }, { top: "26mm", bottom: "16mm", left: "0mm", right: "0mm" },
]) {
  options.push({ margin }, { margin, format: "A5", printBackground: false, displayHeaderFooter: true, footerTemplate: "<b>x</b>" });
}
options.push(
  {}, { printBackground: false }, { printBackground: true }, { footerTemplate: "<b>x</b>" }, { displayHeaderFooter: true },
  { displayHeaderFooter: true, footerTemplate: "" }, { displayHeaderFooter: false, footerTemplate: "<b>x</b>" },
);
writeFileSync(
  join(OUT, "options.json"),
  JSON.stringify(options.map((o) => ({ options: o, css: pdf.printOptionsCss(o) }))) + "\n",
);

// North Indian chart: one chart for each number of bodies (0 to 12) in every cell.
const BODIES = ["Sun", "Moon", "Mars", "Mercury", "Jupiter", "Venus", "Saturn", "Rahu", "Ketu", "Uranus", "Neptune", "Pluto"];
const chartLabels = pdf.planetLabelsFor("ml");
const charts = [];
for (let count = 0; count <= BODIES.length; count++) {
  const planets = [];
  for (let house = 1; house <= 12; house++) {
    for (const name of BODIES.slice(0, count)) {
      planets.push({ label: chartLabels[name], house, color: pdf.PLANET_COLORS[name] });
    }
  }
  const input = { lagnaSignIndex: count % 12, planets };
  charts.push({ ...input, svg: pdf.northIndianChartSvg(input) });
}
writeFileSync(join(OUT, "charts.json"), JSON.stringify(charts) + "\n");

// Brihad running header/footer, TOC, and section tagging.
const brihad = {
  bands: [
    [null, null],
    [API_DEFAULTS, null],
    [null, BRANDING],
    [API_DEFAULTS, BRANDING],
    [API_DEFAULTS, { primaryColor: "#1a1a1a" }],
    [API_DEFAULTS, { primaryColor: "#1A1A1A", secondaryColor: " #666666 " }],
    [API_DEFAULTS, { secondaryColor: "seagreen" }],
    [{ CompanyName: "Json Co", PrimaryColor: "#0b5cad", FooterText: "Json footer" }, null],
    [{ CompanyName: "Json Co", PrimaryColor: "#0b5cad" }, { companyName: " ", primaryColor: "\u00a0", secondaryColor: "\ufeff" }],
    [null, { primaryColor: "#ffe14d", companyName: "Acme — Astro", footerText: "© Acme — <private>" }],
  ].map(([report, branding]) => ({
    report,
    branding,
    palette: pdf.brihadPalette(report ?? undefined, branding ?? undefined) ?? null,
    header: pdf.brihadHeaderTemplate(report ?? undefined, branding ?? undefined),
    footer: pdf.brihadFooterTemplate(report ?? undefined, branding ?? undefined),
  })),
  toc: LOCALES.filter((l) => pdf.TOC_HEADING[l]).map((l) => ({
    heading: pdf.TOC_HEADING[l],
    entries: [
      { title: "Part 1: Birth Details", page: 3 },
      { title: "Planets & <Houses>", page: 7 },
      { title: "भाग 2: दशा", page: 12 },
      { title: "ਭਾਗ 3: ਉਪਾਅ", page: 108 },
    ],
    html: pdf.buildBrihadToc(
      [
        { title: "Part 1: Birth Details", page: 3 },
        { title: "Planets & <Houses>", page: 7 },
        { title: "भाग 2: दशा", page: 12 },
        { title: "ਭਾਗ 3: ਉਪਾਅ", page: 108 },
      ],
      pdf.TOC_HEADING[l],
    ),
  })),
  tagged: index
    .filter((c) => c.fn === "renderKundliBrihadHtml")
    .map((c) => {
      const { html, titles } = pdf.tagBrihadSectionsForToc(readFileSync(join(OUT, "golden", `${c.id}.html`), "utf8"));
      return { id: c.id, titles, html };
    }),
};
writeFileSync(join(OUT, "brihad.json"), JSON.stringify(brihad, null, 1) + "\n");

const byFn = {};
for (const c of index) byFn[c.fn] = (byFn[c.fn] ?? 0) + 1;
console.log(`${index.length} golden HTML files (${recorded.length} calls recorded from the Node tests).`);
console.log(byFn);
console.log(`${text.length} text-helper rows.`);
