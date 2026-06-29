#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

const sourcePath = "data/seed/review/nardebam/jules_repairs/math-topic-18.json";
const targetPath = "data/seed/review/nardebam/raw/math-topic-18.json";

const readJson = (file) => JSON.parse(fs.readFileSync(file, "utf8"));
const source = readJson(sourcePath);

if (source.subject !== "math" || source.topic_key !== "statistics") {
  throw new Error(`${sourcePath} is not the canonical math/statistics artifact`);
}

const rows = Array.isArray(source.questions) ? source.questions : [];
const numbers = rows.map((row) => Number(row.question_number));
const expected = Array.from({ length: 44 }, (_, index) => 1999 + index);

const sameRange = expected.length === numbers.length && expected.every((value, index) => value === numbers[index]);
if (!sameRange) {
  throw new Error(`Expected math statistics question numbers 1999..2042, got ${numbers.join(", ")}`);
}

const invalid = rows.filter((row) => {
  const text = String(row.question_text ?? "").trim();
  const options = Array.isArray(row.options) ? row.options.map((option) => String(option ?? "").trim()) : [];
  return !text || options.length !== 4 || options.some((option) => !option);
});

if (invalid.length) {
  throw new Error(`Canonical math statistics artifact has ${invalid.length} invalid question row(s)`);
}

const repaired = {
  task_id: "math-topic-18",
  subject: "math",
  topic_key: "statistics",
  questions: rows.map((row) => ({
    ...row,
    question_number: Number(row.question_number),
    review_notes: Array.isArray(row.review_notes) ? row.review_notes : [],
    media_regions: Array.isArray(row.media_regions) ? row.media_regions : [],
  })),
};

fs.mkdirSync(path.dirname(targetPath), { recursive: true });
fs.writeFileSync(targetPath, `${JSON.stringify(repaired, null, 2)}\n`, "utf8");
console.log(`Repaired ${targetPath}: ${repaired.questions.length} canonical statistics question(s), 1999..2042.`);
