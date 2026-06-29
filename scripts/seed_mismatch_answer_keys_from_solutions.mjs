#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";

const conflictsPath = process.argv.find((arg) => arg.startsWith("--conflicts="))?.slice(12)
  ?? "data/seed/review/nardebam/join_conflicts.json";
const outDir = process.argv.find((arg) => arg.startsWith("--out-dir="))?.slice(10)
  ?? "data/seed/review/nardebam/jules_repairs";

function toOption(value) {
  const option = Number(String(value ?? "").replace(/[^0-9]/g, ""));
  return Number.isInteger(option) && option >= 1 && option <= 4 ? option : null;
}

function usableSolution(row) {
  const text = String(row?.solution?.solution_text ?? row?.solution?.classic_solution ?? "").trim();
  if (text.length < 20) return false;
  if (/^missing page from dataset$/i.test(text)) return false;
  return true;
}

const conflicts = JSON.parse(fs.readFileSync(conflictsPath, "utf8"));
const bySubject = new Map([
  ["math", {}],
  ["physics", {}],
]);
const provenance = [];

for (const row of conflicts) {
  const issues = row.issues ?? [row.issue];
  if (!issues.includes("solution_key_mismatch")) continue;
  if (!bySubject.has(row.subject)) continue;
  if (!usableSolution(row)) continue;
  const option = toOption(row.solution?.stated_correct_option ?? row.solution?.correct_option);
  if (!option) continue;
  bySubject.get(row.subject)[String(row.question_number)] = option;
  provenance.push({
    subject: row.subject,
    question_number: row.question_number,
    topic_key: row.topic_key ?? null,
    old_option: row.correct ?? row.answer ?? null,
    replacement_option: option,
    source: "current_solution_stated_correct_option",
  });
}

fs.mkdirSync(outDir, { recursive: true });
const written = [];
for (const [subject, answers] of bySubject.entries()) {
  const entries = Object.entries(answers).sort((a, b) => Number(a[0]) - Number(b[0]));
  if (!entries.length) continue;
  const output = path.join(outDir, `${subject}-answer-key-from-current-solutions-mismatch.json`);
  fs.writeFileSync(output, `${JSON.stringify({
    answers: Object.fromEntries(entries),
    review_notes: [
      "Generated locally from join_conflicts solution_key_mismatch rows.",
      "Less-strict repair: when an existing non-placeholder solution states a valid option, the answer key is aligned to that solution so the app remains internally consistent.",
    ],
    provenance: provenance.filter((item) => item.subject === subject),
  }, null, 2)}\n`, "utf8");
  written.push({ subject, output, count: entries.length });
}

console.log(JSON.stringify({ written }, null, 2));
