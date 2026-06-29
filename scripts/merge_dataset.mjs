#!/usr/bin/env node
// Merge official, curriculum-classified seed questions into the bundled
// offline asset. Legacy topic-based seeds are intentionally ignored; run
// `node scripts/reclassify_dataset.mjs` to regenerate data/seed/official.

import fs from "node:fs";
import crypto from "node:crypto";
import path from "node:path";
import { officialTopicRows } from "./curriculum.mjs";

const SEED_DIR = "data/seed/official";
const OUT = "app/src/main/assets/questions.json";

function walk(dir) {
  if (!fs.existsSync(dir)) {
    throw new Error(`${dir} does not exist. Run node scripts/reclassify_dataset.mjs first.`);
  }
  let out = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, entry.name);
    if (entry.isDirectory()) out = out.concat(walk(p));
    else if (entry.name.endsWith(".json")) out.push(p);
  }
  return out;
}

function stableId(q) {
  if (q.id) return q.id;
  const basis = [
    q.subject, q.category, q.sub_category ?? "", q.question_text,
    q.option_1, q.option_2, q.option_3, q.option_4,
  ].join("");
  return crypto.createHash("sha1").update(basis).digest("hex").slice(0, 24);
}

const files = walk(SEED_DIR).sort();
const seen = new Set();
const merged = [];

for (const file of files) {
  const arr = JSON.parse(fs.readFileSync(file, "utf8"));
  for (const q of arr) {
    const id = stableId(q);
    if (seen.has(id)) continue;
    seen.add(id);
    merged.push({
      id,
      subject: q.subject,
      category: q.category,
      sub_category: q.sub_category ?? null,
      difficulty: q.difficulty,
      question_text: q.question_text,
      image_url: q.image_url ?? null,
      option_1: q.option_1,
      option_2: q.option_2,
      option_3: q.option_3,
      option_4: q.option_4,
      correct_option_index: q.correct_option_index,
      classic_solution: q.classic_solution,
      smart_shortcut: q.smart_shortcut ?? null,
      source: q.source ?? "official_reclassified",
    });
  }
}

fs.mkdirSync(path.dirname(OUT), { recursive: true });
fs.writeFileSync(OUT, JSON.stringify(merged));

const counts = new Map(officialTopicRows().map((row) => [`${row.subject}|${row.course}|${row.chapter}`, 0]));
for (const q of merged) {
  const key = `${q.subject}|${q.category}|${q.sub_category}`;
  counts.set(key, (counts.get(key) ?? 0) + 1);
}

console.log(`Merged ${merged.length} official questions from ${files.length} files -> ${OUT}`);
console.log("Coverage by official chapter:");
for (const row of officialTopicRows()) {
  const count = counts.get(`${row.subject}|${row.course}|${row.chapter}`) ?? 0;
  const status = count >= 120 ? "target" : count >= 60 ? "release" : count > 0 ? "low" : "empty";
  console.log(`${String(count).padStart(4, " ")}  ${status.padEnd(7)}  ${row.course} / ${row.chapter}  ${row.chapterLabel}`);
}
