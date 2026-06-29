#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

const rawDir = "data/seed/review/nardebam/raw";

function answersOf(value) {
  return value.answers && typeof value.answers === "object" ? value.answers : {};
}

function toNumber(value) {
  if (Number.isInteger(value)) return value;
  const normalized = String(value ?? "")
    .replace(/[۰-۹]/g, (digit) => "۰۱۲۳۴۵۶۷۸۹".indexOf(digit))
    .replace(/[٠-٩]/g, (digit) => "٠١٢٣٤٥٦٧٨٩".indexOf(digit));
  const parsed = Number(normalized);
  return Number.isInteger(parsed) ? parsed : null;
}

function rowsOf(value) {
  if (Array.isArray(value)) return value;
  return value.solutions ?? value.rows ?? [];
}

function withRowsLike(original, rows) {
  if (Array.isArray(original)) return rows;
  if (Array.isArray(original.solutions)) return { ...original, solutions: rows };
  if (Array.isArray(original.rows)) return { ...original, rows };
  return rows;
}

let changed = 0;
for (const subject of ["math", "physics"]) {
  const keyPath = path.join(rawDir, `${subject}-answer-key.json`);
  if (!fs.existsSync(keyPath)) continue;
  const key = answersOf(JSON.parse(fs.readFileSync(keyPath, "utf8")));
  for (const file of fs.readdirSync(rawDir).filter((name) => name.startsWith(`${subject}-solutions-`) && name.endsWith(".json"))) {
    const fullPath = path.join(rawDir, file);
    const json = JSON.parse(fs.readFileSync(fullPath, "utf8"));
    let fileChanged = false;
    const rows = rowsOf(json).map((row) => {
      const questionNumber = toNumber(row.question_number);
      const correct = toNumber(key[String(questionNumber)] ?? key[questionNumber]);
      if (
        Number.isInteger(row.stated_correct_option)
        && Number.isInteger(correct)
        && row.stated_correct_option !== correct
      ) {
        const reviewNotes = Array.isArray(row.review_notes) ? [...row.review_notes] : [];
        reviewNotes.push(`stated_correct_option ${row.stated_correct_option} conflicts with authoritative answer key ${correct}; cleared by repair_nardebam_solution_key_mismatches.`);
        changed += 1;
        fileChanged = true;
        return { ...row, stated_correct_option: null, review_notes: reviewNotes };
      }
      return row;
    });
    if (fileChanged) {
      fs.writeFileSync(fullPath, `${JSON.stringify(withRowsLike(json, rows), null, 2)}\n`, "utf8");
    }
  }
}

console.log(`Cleared ${changed} conflicting stated_correct_option value(s).`);
