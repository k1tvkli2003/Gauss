#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";

const rawDir = process.argv.find((arg) => arg.startsWith("--raw-dir="))?.slice(10)
  ?? "data/seed/review/nardebam/raw";
const subject = process.argv.find((arg) => arg.startsWith("--subject="))?.slice(10) ?? "math";
const output = process.argv.find((arg) => arg.startsWith("--output="))?.slice(9)
  ?? `data/seed/review/nardebam/jules_repairs/${subject}-answer-key-from-solutions-missing.json`;

function rowsOf(json) {
  return Array.isArray(json) ? json : (json.solutions ?? json.rows ?? []);
}

function toNumber(value) {
  const parsed = Number(String(value ?? "").replace(/[^0-9-]/g, ""));
  return Number.isInteger(parsed) ? parsed : null;
}

const answerKeyPath = path.join(rawDir, `${subject}-answer-key.json`);
const existing = JSON.parse(fs.readFileSync(answerKeyPath, "utf8")).answers ?? {};
const answers = {};
const provenance = [];

for (const file of fs.readdirSync(rawDir).filter((name) => name.startsWith(`${subject}-solutions`) && name.endsWith(".json"))) {
  const json = JSON.parse(fs.readFileSync(path.join(rawDir, file), "utf8"));
  for (const row of rowsOf(json)) {
    const questionNumber = toNumber(row?.question_number);
    const option = toNumber(row?.stated_correct_option ?? row?.correct_option);
    if (!questionNumber || existing[String(questionNumber)] !== undefined) continue;
    if (!(option >= 1 && option <= 4)) continue;
    answers[String(questionNumber)] = option;
    provenance.push({
      question_number: questionNumber,
      answer: option,
      source_solution_file: file,
      basis: "stated_correct_option",
    });
  }
}

const artifact = {
  answers: Object.fromEntries(Object.entries(answers).sort((a, b) => Number(a[0]) - Number(b[0]))),
  review_notes: [
    "Generated locally from existing solution stated_correct_option only for answer-key gaps.",
  ],
  provenance,
};

fs.mkdirSync(path.dirname(output), { recursive: true });
fs.writeFileSync(output, `${JSON.stringify(artifact, null, 2)}\n`, "utf8");
console.log(JSON.stringify({ output, answers: Object.keys(answers).length }, null, 2));
