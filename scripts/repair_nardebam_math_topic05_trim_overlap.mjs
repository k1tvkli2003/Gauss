#!/usr/bin/env node

import fs from "node:fs";

const targetPath = "data/seed/review/nardebam/raw/math-topic-05.json";
const data = JSON.parse(fs.readFileSync(targetPath, "utf8"));

if (data.subject !== "math" || data.topic_key !== "radicals_algebraic_expressions" || !Array.isArray(data.questions)) {
  throw new Error(`${targetPath} is not math topic 05`);
}

const before = data.questions.length;
data.questions = data.questions.filter((row) => Number(row.question_number) <= 308);
const removed = before - data.questions.length;

fs.writeFileSync(targetPath, `${JSON.stringify(data, null, 2)}\n`, "utf8");
console.log(`Trimmed ${removed} overlapping question(s) from ${targetPath}; kept ${data.questions.length}.`);
