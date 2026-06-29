#!/usr/bin/env node
// Validate official seed files or the merged app asset against the canonical
// experimental-sciences curriculum.

import fs from "node:fs";
import path from "node:path";
import { isValidTopic, officialTopicRows, validSubjects } from "./curriculum.mjs";

const mode = process.argv.includes("--asset")
  ? "asset"
  : process.argv.includes("--review")
    ? "review"
    : "official";
const strictCoverage = process.argv.includes("--strict-coverage");
const root = mode === "asset"
  ? "app/src/main/assets/questions.json"
  : mode === "review"
    ? "data/seed/review/jules_v2"
    : "data/seed/official";
const validDifficulties = new Set(["above_average", "hard", "very_hard", "olympiad"]);
const placeholderSolutionMarkers = [
  "راه‌حل منبع برای این سؤال ناقص بود",
  "پاسخ درست از کلید اولیه بازسازی شد",
];

function walk(dir) {
  let out = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, entry.name);
    if (entry.isDirectory()) out = out.concat(walk(p));
    else if (entry.name.endsWith(".json")) out.push(p);
  }
  return out;
}

function readRows() {
  if (mode === "asset") {
    return JSON.parse(fs.readFileSync(root, "utf8")).map((q, index) => ({ file: root, index, q }));
  }
  if (!fs.existsSync(root)) throw new Error(`${root} does not exist. Run node scripts/reclassify_dataset.mjs first.`);
  return walk(root).flatMap((file) =>
    JSON.parse(fs.readFileSync(file, "utf8")).map((q, index) => ({ file, index, q })),
  );
}

const rows = readRows();
const errors = [];
const seen = new Set();
const coverage = new Map(officialTopicRows().map((row) => [`${row.subject}|${row.course}|${row.chapter}`, 0]));

for (const { file, index, q } of rows) {
  const where = `${file}:${index + 1}`;
  const id = q.id || `${q.subject}|${q.question_text}`;
  if (!q.id || !/^[a-z0-9_-]+$/.test(q.id)) errors.push(`${where} id must contain ASCII lowercase letters, digits, _ or - only`);
  if (seen.has(id)) errors.push(`${where} duplicate id ${id}`);
  seen.add(id);

  if (!validSubjects.has(q.subject)) errors.push(`${where} invalid subject ${q.subject}`);
  if (!isValidTopic(q.subject, q.category, q.sub_category)) {
    errors.push(`${where} invalid course/chapter ${q.subject}/${q.category}/${q.sub_category}`);
  } else {
    const key = `${q.subject}|${q.category}|${q.sub_category}`;
    coverage.set(key, (coverage.get(key) ?? 0) + 1);
  }

  for (const field of ["difficulty", "question_text", "option_1", "option_2", "option_3", "option_4", "classic_solution"]) {
    if (q[field] === undefined || q[field] === null || String(q[field]).trim() === "") {
      errors.push(`${where} missing ${field}`);
    }
  }
  if (mode === "review") {
    for (const field of ["smart_shortcut", "source"]) {
      if (q[field] === undefined || q[field] === null || String(q[field]).trim() === "") {
        errors.push(`${where} missing ${field}`);
      }
    }
  }
  if (q.difficulty && !validDifficulties.has(q.difficulty)) {
    errors.push(`${where} invalid difficulty ${q.difficulty}`);
  }
  if (placeholderSolutionMarkers.some((marker) => String(q.classic_solution ?? "").includes(marker))) {
    errors.push(`${where} placeholder classic_solution`);
  }
  const searchableText = [
    q.question_text,
    q.option_1,
    q.option_2,
    q.option_3,
    q.option_4,
    q.classic_solution,
    q.smart_shortcut,
  ].join("\n");
  if (/[ØÙ]/.test(searchableText)) errors.push(`${where} probable UTF-8 mojibake`);
  if (/[\u0400-\u04ff]/.test(searchableText)) errors.push(`${where} unexpected Cyrillic text`);
  if (mode === "review" && String(q.classic_solution ?? "").includes("\\n")) {
    errors.push(`${where} literal escaped newline in classic_solution`);
  }
  const optionValues = [q.option_1, q.option_2, q.option_3, q.option_4].map((option) => String(option ?? "").trim());
  if (new Set(optionValues).size !== optionValues.length) {
    errors.push(`${where} duplicate options`);
  }
  const correct = Number(q.correct_option_index);
  if (!Number.isInteger(correct) || correct < 1 || correct > 4) {
    errors.push(`${where} invalid correct_option_index ${q.correct_option_index}`);
  } else if (!optionValues[correct - 1]) {
    errors.push(`${where} correct option is empty`);
  }
  if (mode === "review") {
    const persianDigits = "۰۱۲۳۴۵۶۷۸۹";
    for (const option of optionValues) {
      if (option.includes("\\") && !option.includes("$")) errors.push(`${where} unwrapped LaTeX option`);
    }
    for (const match of String(q.classic_solution ?? "").matchAll(/گزینه\s*([1-4۱-۴])/g)) {
      const referenced = /[1-4]/.test(match[1]) ? Number(match[1]) : persianDigits.indexOf(match[1]);
      if (referenced !== correct) errors.push(`${where} stale option reference ${match[1]}`);
    }
  }
}

const modeLabel = mode === "asset" ? "asset" : mode === "review" ? "Jules review" : "official seed";
console.log(`Validated ${rows.length} ${modeLabel} questions.`);
console.log("Coverage by official chapter:");
const coverageWarnings = [];
for (const row of officialTopicRows()) {
  const count = coverage.get(`${row.subject}|${row.course}|${row.chapter}`) ?? 0;
  const status = count >= 120 ? "target" : count >= 60 ? "release" : count > 0 ? "low" : "empty";
  if (count < 60) coverageWarnings.push(`${row.course}/${row.chapter}: ${count}`);
  console.log(`${String(count).padStart(4, " ")}  ${status.padEnd(7)}  ${row.course} / ${row.chapter}  ${row.chapterLabel}`);
}

if (coverageWarnings.length && mode !== "review") {
  console.warn(`Coverage below release minimum (60) in ${coverageWarnings.length} chapters.`);
  if (strictCoverage) errors.push(...coverageWarnings.map((w) => `coverage ${w}`));
}

if (errors.length) {
  console.error(`Dataset validation failed with ${errors.length} error(s):`);
  errors.slice(0, 80).forEach((err) => console.error(`- ${err}`));
  if (errors.length > 80) console.error(`... ${errors.length - 80} more`);
  process.exit(1);
}

console.log("Dataset validation passed.");
