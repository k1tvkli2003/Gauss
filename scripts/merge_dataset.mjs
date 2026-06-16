#!/usr/bin/env node
// Merge every question JSON under data/seed/** into the bundled offline asset
// app/src/main/assets/questions.json, assigning each question a stable
// content-hash id so on-device history / spaced-repetition keys survive
// rebuilds. The dataset itself is never modified — this only repackages it.
//
//   node scripts/merge_dataset.mjs

import fs from "node:fs";
import crypto from "node:crypto";
import path from "node:path";

const SEED_DIR = "data/seed";
const OUT = "app/src/main/assets/questions.json";

function walk(dir) {
  let out = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, entry.name);
    if (entry.isDirectory()) out = out.concat(walk(p));
    else if (entry.name.endsWith(".json")) out.push(p);
  }
  return out;
}

const files = walk(SEED_DIR).sort();
const seen = new Set();
const merged = [];

for (const file of files) {
  const arr = JSON.parse(fs.readFileSync(file, "utf8"));
  for (const q of arr) {
    const basis = [
      q.subject, q.category, q.sub_category ?? "", q.question_text,
      q.option_1, q.option_2, q.option_3, q.option_4,
    ].join("");
    const id = crypto.createHash("sha1").update(basis).digest("hex").slice(0, 24);
    if (seen.has(id)) continue; // drop exact duplicates
    seen.add(id);
    merged.push({
      id,
      subject: q.subject,
      category: q.category,
      sub_category: q.sub_category ?? null,
      difficulty: q.difficulty,
      question_text: q.question_text,
      image_url: q.image_url ?? null,
      option_1: q.option_1, option_2: q.option_2, option_3: q.option_3, option_4: q.option_4,
      correct_option_index: q.correct_option_index,
      classic_solution: q.classic_solution,
      smart_shortcut: q.smart_shortcut ?? null,
      source: q.source ?? "seed",
    });
  }
}

fs.mkdirSync(path.dirname(OUT), { recursive: true });
fs.writeFileSync(OUT, JSON.stringify(merged));
console.log(`Merged ${merged.length} questions from ${files.length} files → ${OUT}`);
