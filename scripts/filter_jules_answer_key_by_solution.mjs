#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";

const input = process.argv.find((arg) => arg.startsWith("--input="))?.slice(8)
  ?? "data/seed/review/nardebam/jules_repairs/math-answer-key-verified-mismatch-ranges.json";
const rawDir = process.argv.find((arg) => arg.startsWith("--raw-dir="))?.slice(10)
  ?? "data/seed/review/nardebam/raw";
const output = process.argv.find((arg) => arg.startsWith("--output="))?.slice(9)
  ?? "data/seed/review/nardebam/jules_repairs/math-answer-key-verified-mismatch-ranges-solution-agree.json";

function rowsOf(json) {
  return Array.isArray(json) ? json : (json.solutions ?? json.rows ?? []);
}

function toNumber(value) {
  const parsed = Number(String(value ?? "").replace(/[^0-9-]/g, ""));
  return Number.isInteger(parsed) ? parsed : null;
}

const incoming = JSON.parse(fs.readFileSync(input, "utf8")).answers ?? {};
const existing = JSON.parse(fs.readFileSync(path.join(rawDir, "math-answer-key.json"), "utf8")).answers ?? {};

const solutionOptionByQuestion = new Map();
for (const file of fs.readdirSync(rawDir).filter((name) => /^math-solutions.*\.json$/.test(name))) {
  const json = JSON.parse(fs.readFileSync(path.join(rawDir, file), "utf8"));
  for (const row of rowsOf(json)) {
    const questionNumber = toNumber(row?.question_number);
    const option = toNumber(row?.stated_correct_option ?? row?.correct_option);
    if (questionNumber && option >= 1 && option <= 4) {
      solutionOptionByQuestion.set(questionNumber, option);
    }
  }
}

const answers = {};
const rejected = [];
for (const [rawQuestionNumber, rawOption] of Object.entries(incoming)) {
  const questionNumber = toNumber(rawQuestionNumber);
  const option = toNumber(rawOption);
  const oldOption = existing[String(questionNumber)];
  const solutionOption = solutionOptionByQuestion.get(questionNumber);
  if (oldOption === undefined || oldOption === option) continue;
  if (solutionOption === option) {
    answers[String(questionNumber)] = option;
  } else {
    rejected.push({
      question_number: questionNumber,
      existing_option: oldOption,
      incoming_option: option,
      solution_option: solutionOption ?? null,
      reason: solutionOption ? "incoming_disagrees_with_solution" : "missing_solution_option",
    });
  }
}

const out = {
  answers: Object.fromEntries(Object.entries(answers).sort((a, b) => Number(a[0]) - Number(b[0]))),
  review_notes: [
    `Filtered from ${path.basename(input)}; kept only replacements matching stated_correct_option in current solutions.`,
  ],
  rejected,
};

fs.mkdirSync(path.dirname(output), { recursive: true });
fs.writeFileSync(output, `${JSON.stringify(out, null, 2)}\n`, "utf8");
console.log(JSON.stringify({ output, kept: Object.keys(answers).length, rejected: rejected.length }, null, 2));
