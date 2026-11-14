// Port helper: prints top-level constant tables of a Node SDK TypeScript file
// as Dart `const` declarations, with the data evaluated by Node (so every
// string, number and key is copied exactly).
//
//   node tool/ts_tables.mjs <file under lifeastroapi-node/src/pdf> NAME[:DartName] ...
//
// Example:
//   node tool/ts_tables.mjs templates/kundliLite.ts LABELS:_labels
//
// Objects become Map literals (numeric-looking keys become int keys only when
// every key of that object is numeric), arrays become List literals, strings
// are single-quoted with `$`, `\` and `'` escaped.
import { createRequire } from "node:module";
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const NODE_SDK = resolve(process.env.LIFEASTRO_NODE_SDK ?? join(ROOT, "..", "lifeastroapi-node"));
const require = createRequire(join(NODE_SDK, "package.json"));
const esbuild = require("esbuild");

const [file, ...names] = process.argv.slice(2);
if (!file || names.length === 0) {
  console.error("usage: node tool/ts_tables.mjs <file> NAME[:DartName] ...");
  process.exit(2);
}
const src = join(NODE_SDK, "src", "pdf", file);
const pairs = names.map((n) => {
  const [ts, dart] = n.split(":");
  return { ts, dart: dart ?? ts };
});

const tmpDir = join(ROOT, ".dart_tool", "ts_tables");
mkdirSync(tmpDir, { recursive: true });
const entry = join(dirname(src), `.__tables_${process.pid}.ts`);
writeFileSync(
  entry,
  readFileSync(src, "utf8") + `\nexport const __tables = { ${pairs.map((p) => p.ts).join(", ")} };\n`,
);
const out = join(tmpDir, `t${process.pid}.mjs`);
try {
  await esbuild.build({ entryPoints: [entry], bundle: true, format: "esm", platform: "node", outfile: out, logLevel: "error" });
} finally {
  (await import("node:fs")).rmSync(entry, { force: true });
}
const mod = await import(pathToFileURL(out).href);

function str(s) {
  return "'" + s.replace(/\\/g, "\\\\").replace(/'/g, "\\'").replace(/\$/g, "\\$").replace(/\n/g, "\\n").replace(/\r/g, "\\r").replace(/\t/g, "\\t") + "'";
}
function lit(v, indent = "") {
  const next = indent + "  ";
  if (v === null || v === undefined) return "null";
  if (typeof v === "string") return str(v);
  if (typeof v === "number" || typeof v === "boolean") return String(v);
  if (Array.isArray(v)) {
    if (v.length === 0) return "[]";
    return "[\n" + v.map((x) => next + lit(x, next) + ",").join("\n") + "\n" + indent + "]";
  }
  if (v instanceof RegExp) return `RegExp(${str(v.source)}${v.flags.includes("i") ? ", caseSensitive: false" : ""})`;
  const keys = Object.keys(v);
  if (keys.length === 0) return "{}";
  const numeric = keys.every((k) => /^(0|[1-9]\d*)$/.test(k));
  return (
    "{\n" +
    keys.map((k) => `${next}${numeric ? k : str(k)}: ${lit(v[k], next)},`).join("\n") +
    "\n" +
    indent +
    "}"
  );
}
for (const p of pairs) {
  const v = mod.__tables[p.ts];
  const isRe = v instanceof RegExp;
  console.log(`${isRe ? "final" : "const"} ${p.dart} = ${lit(v)};\n`);
}
