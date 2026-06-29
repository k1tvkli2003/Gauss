#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

const topicId = process.argv[2];
if (!topicId) {
  console.error("Usage: node scripts/merge_local_nardebam_parts.mjs <topic-id>");
  process.exit(1);
}

const inputDir = "data/seed/review/nardebam/local_parts";
const outputDir = "data/seed/review/nardebam/raw";
const tasksPath = "tmp/jules_nardebam/tasks.json";
const files = fs.existsSync(inputDir)
  ? fs.readdirSync(inputDir).filter((file) => file.startsWith(`${topicId}-`) && file.endsWith(".json")).sort()
  : [];
const manifest = fs.existsSync(tasksPath) ? JSON.parse(fs.readFileSync(tasksPath, "utf8")) : { tasks: [] };
const task = manifest.tasks?.find((item) => item.id === topicId) ?? {};

const questions = [];
for (const file of files) {
  const data = JSON.parse(fs.readFileSync(path.join(inputDir, file), "utf8"));
  const rows = Array.isArray(data.questions) ? data.questions : Array.isArray(data) ? data : [];
  for (const row of rows) questions.push(row);
}

const byNumberAndPage = new Map();
const score = (row) =>
  String(row.question_text ?? "").length +
  (Array.isArray(row.options) ? row.options.join("").length : 0) +
  (Array.isArray(row.media_regions) ? row.media_regions.length * 40 : 0);
for (const row of questions.sort((a, b) => (a.question_number ?? 0) - (b.question_number ?? 0))) {
  const key = `${row.question_number}|${row.question_page}`;
  const previous = byNumberAndPage.get(key);
  if (!previous || score(row) > score(previous)) byNumberAndPage.set(key, row);
}
const deduped = [...byNumberAndPage.values()];

const output = {
  task_id: topicId,
  subject: task.subject ?? deduped[0]?.subject ?? "physics",
  topic_key: task.topic_key ?? deduped[0]?.topic_key ?? topicId.replace(/^[a-z]+-topic-\d+-?/, ""),
  questions: deduped,
};

fs.mkdirSync(outputDir, { recursive: true });
fs.writeFileSync(path.join(outputDir, `${topicId}.json`), `${JSON.stringify(output, null, 2)}\n`, "utf8");
console.log(`Merged ${deduped.length} question(s) from ${files.length} local part(s) -> ${path.join(outputDir, `${topicId}.json`)}`);
