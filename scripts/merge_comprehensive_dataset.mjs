#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { topicRows } from "./comprehensive_taxonomy.mjs";

const INPUT = "data/seed/comprehensive";
const OUTPUT = "app/src/main/assets/question_bank";

function walk(dir) {
  if (!fs.existsSync(dir)) return [];
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    const target = path.join(dir, entry.name);
    return entry.isDirectory() ? walk(target) : entry.name.endsWith(".json") ? [target] : [];
  });
}

const buckets = new Map(topicRows.map((topic) => [`${topic.subject}|${topic.key}`, []]));
const ids = new Set();
for (const file of walk(INPUT).filter((file) => !file.endsWith("aliases.json"))) {
  const rows = JSON.parse(fs.readFileSync(file, "utf8"));
  if (!Array.isArray(rows)) continue;
  for (const row of rows) {
    if (ids.has(row.id)) throw new Error(`Duplicate id ${row.id} in ${file}`);
    ids.add(row.id);
    const key = `${row.subject}|${row.topic_key}`;
    if (!buckets.has(key)) throw new Error(`Invalid topic ${key} in ${file}`);
    buckets.get(key).push(row);
  }
}

fs.rmSync(OUTPUT, { recursive: true, force: true });
fs.mkdirSync(path.join(OUTPUT, "topics"), { recursive: true });
const topics = [];
for (const topic of topicRows) {
  const rows = buckets.get(`${topic.subject}|${topic.key}`).sort((a, b) => a.id.localeCompare(b.id));
  const relative = `question_bank/topics/${topic.subject}_${topic.key}.json`;
  fs.writeFileSync(path.join("app/src/main/assets", relative), JSON.stringify(rows), "utf8");
  topics.push({ subject: topic.subject, topic_key: topic.key, label: topic.label, order: topic.order, file: relative, count: rows.length });
}
const aliasFile = path.join(INPUT, "aliases.json");
const aliases = fs.existsSync(aliasFile) ? JSON.parse(fs.readFileSync(aliasFile, "utf8")) : {};
fs.writeFileSync(path.join(OUTPUT, "index.json"), JSON.stringify({ schema_version: 2, total: ids.size, topics, aliases }), "utf8");
console.log(`Wrote ${ids.size} questions across ${topics.length} topic shards -> ${OUTPUT}`);
