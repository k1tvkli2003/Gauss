#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { manifest } from "./comprehensive_taxonomy.mjs";

const normalized = process.argv.find((arg) => arg.startsWith("--input="))?.slice(8) ?? "data/seed/review/nardebam/normalized";
const output = process.argv.find((arg) => arg.startsWith("--output="))?.slice(9) ?? "data/seed/comprehensive/nardebam";
const reviewFile = "data/seed/review/nardebam/join_conflicts.json";

const read = (file) => JSON.parse(fs.readFileSync(path.join(normalized, file), "utf8"));
const exists = (file) => fs.existsSync(path.join(normalized, file));
const text = (value) => [{ type: "text", text: value }];
const conflicts = [];
const buckets = new Map();

for (const [subject, book] of Object.entries(manifest.books)) {
  const solutions = new Map();
  for (const file of fs.readdirSync(normalized).filter((file) => file.startsWith(`${subject}-solutions-`) && file.endsWith(".json"))) {
    for (const solution of read(file)) {
      if (solutions.has(solution.question_number)) conflicts.push({ subject, question_number: solution.question_number, issue: "duplicate_solution", files: [solutions.get(solution.question_number)._file, file] });
      solutions.set(solution.question_number, { ...solution, _file: file });
    }
  }
  const keyFile = `${subject}-answer-key.json`;
  const key = exists(keyFile) ? read(keyFile) : {};
  const seenNumbers = new Set();

  for (const topic of book.topics) {
    const task = `${subject}-topic-${String(topic.order).padStart(2, "0")}.json`;
    if (!exists(task)) {
      conflicts.push({ subject, topic_key: topic.key, issue: "missing_question_task", task });
      continue;
    }
    const rows = [];
    for (const question of read(task)) {
      const n = question.question_number;
      if (seenNumbers.has(n)) {
        conflicts.push({ subject, topic_key: topic.key, question_number: n, issue: "duplicate_question_number" });
        continue;
      }
      seenNumbers.add(n);
      const solution = solutions.get(n);
      const correct = key[String(n)] ?? key[n];
      const issues = [];
      if (!question.question_text) issues.push("empty_question");
      if (question.options.length !== 4 || question.options.some((option) => !option)) issues.push("invalid_options");
      if (!solution?.solution_text) issues.push("missing_solution");
      if (!Number.isInteger(correct) || correct < 1 || correct > 4) issues.push("missing_key");
      if (solution?.stated_correct_option && correct && solution.stated_correct_option !== correct) issues.push("solution_key_mismatch");
      if (issues.length) {
        conflicts.push({ subject, topic_key: topic.key, question_number: n, issues, question, solution, correct });
        continue;
      }
      const id = `nardebam_${subject}_1405_${String(n).padStart(4, "0")}`;
      rows.push({
        id,
        subject,
        topic_key: topic.key,
        difficulty: "hard",
        stem: text(question.question_text),
        options: question.options.map(text),
        correct_option_index: correct,
        solution: text(solution.solution_text),
        smart_shortcut: null,
        source_bank: "nardebam",
        provenance: {
          kind: "source",
          edition: "nardebam_1405",
          question_number: n,
          question_pdf: topic.question_pdf,
          question_page: question.question_page,
          solution_page: solution.solution_page,
          solution_origin: "source",
        },
        _media_regions: { question: question.media_regions, solution: solution.media_regions },
      });
    }
    buckets.set(`${subject}/${topic.key}`, rows);
  }
  const expected = manifest.expected_question_counts[subject];
  if (seenNumbers.size !== expected) conflicts.push({ subject, issue: "question_total", expected, actual: seenNumbers.size });
}

fs.rmSync(output, { recursive: true, force: true });
for (const [key, rows] of buckets) {
  const target = path.join(output, `${key}.json`);
  fs.mkdirSync(path.dirname(target), { recursive: true });
  fs.writeFileSync(target, `${JSON.stringify(rows, null, 2)}\n`, "utf8");
}
fs.mkdirSync(path.dirname(reviewFile), { recursive: true });
fs.writeFileSync(reviewFile, `${JSON.stringify(conflicts, null, 2)}\n`, "utf8");
const total = [...buckets.values()].reduce((sum, rows) => sum + rows.length, 0);
console.log(`Joined ${total} source questions; ${conflicts.length} conflict(s) -> ${reviewFile}`);
if (conflicts.length) process.exitCode = 1;
