#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { isValidTopic, topicRows } from "./comprehensive_taxonomy.mjs";

const root = process.argv.find((arg) => arg.startsWith("--root="))?.slice(7) ?? "data/seed/comprehensive";
const strictSource = process.argv.includes("--strict-source-counts");
const validateAsset = process.argv.includes("--asset");
const assetRoot = "app/src/main/assets";
const requiredSourceBank = "nardebam";
const expectedQuestionCount = 3672;

function walk(dir) {
  if (!fs.existsSync(dir)) return [];
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    const target = path.join(dir, entry.name);
    return entry.isDirectory() ? walk(target) : entry.name.endsWith(".json") ? [target] : [];
  });
}

const errors = [];
const ids = new Set();
const sourceNumbers = { math: new Set(), physics: new Set() };
const counts = new Map(topicRows.map((topic) => [`${topic.subject}|${topic.key}`, 0]));
let total = 0;
let mediaBlocks = 0;

for (const file of walk(root)) {
  const rows = JSON.parse(fs.readFileSync(file, "utf8"));
  if (!Array.isArray(rows)) continue;
  rows.forEach((q, index) => {
    total += 1;
    const at = `${file}:${index + 1}`;
    if (!/^[a-z0-9_-]+$/.test(q.id ?? "")) errors.push(`${at} invalid id`);
    if (ids.has(q.id)) errors.push(`${at} duplicate id ${q.id}`);
    ids.add(q.id);
    if (!isValidTopic(q.subject, q.topic_key)) errors.push(`${at} invalid topic ${q.subject}/${q.topic_key}`);
    else counts.set(`${q.subject}|${q.topic_key}`, (counts.get(`${q.subject}|${q.topic_key}`) ?? 0) + 1);
    if (!Array.isArray(q.stem) || !q.stem.length) errors.push(`${at} empty stem`);
    if (!Array.isArray(q.options) || q.options.length !== 4 || q.options.some((option) => !Array.isArray(option) || !option.length)) errors.push(`${at} options must have four non-empty content arrays`);
    if (!Number.isInteger(q.correct_option_index) || q.correct_option_index < 1 || q.correct_option_index > 4) errors.push(`${at} invalid key`);
    if (!Array.isArray(q.solution) || !q.solution.length) errors.push(`${at} empty solution`);
    if (!q.provenance?.kind || !q.provenance?.edition) errors.push(`${at} incomplete provenance`);
    if (q.source_bank !== requiredSourceBank) errors.push(`${at} is not a Nardebam source item`);
    const content = [
      ...(Array.isArray(q.stem) ? q.stem : []),
      ...(Array.isArray(q.options) ? q.options.flat() : []),
      ...(Array.isArray(q.solution) ? q.solution : []),
      ...(Array.isArray(q.smart_shortcut) ? q.smart_shortcut : []),
    ];
    for (const block of content) {
      if (block?.type !== "image") continue;
      mediaBlocks += 1;
      if (!block.asset) errors.push(`${at} image block missing asset`);
      else if (validateAsset && !fs.existsSync(path.join(assetRoot, block.asset))) errors.push(`${at} missing media asset ${block.asset}`);
    }
    if (q.source_bank === "nardebam") {
      const number = q.provenance?.question_number;
      if (!Number.isInteger(number)) errors.push(`${at} missing source question number`);
      else if (sourceNumbers[q.subject].has(number)) errors.push(`${at} duplicate source number ${number}`);
      else sourceNumbers[q.subject].add(number);
    }
  });
}

console.log(`Validated ${total} Nardebam comprehensive questions.`);
for (const topic of topicRows) console.log(`${String(counts.get(`${topic.subject}|${topic.key}`) ?? 0).padStart(5)}  ${topic.subject}/${topic.key}  ${topic.label}`);
console.log(`Nardebam source counts: math=${sourceNumbers.math.size}, physics=${sourceNumbers.physics.size}`);
console.log(`Media blocks: ${mediaBlocks}`);
if (strictSource && (sourceNumbers.math.size !== 2042 || sourceNumbers.physics.size !== 1630)) errors.push("source totals must be math=2042 and physics=1630");
if (total !== expectedQuestionCount) errors.push(`total rows must be ${expectedQuestionCount}, got ${total}`);
if (validateAsset) {
  const indexFile = path.join(assetRoot, "question_bank/index.json");
  if (!fs.existsSync(indexFile)) {
    errors.push(`missing asset index ${indexFile}`);
  } else {
    const index = JSON.parse(fs.readFileSync(indexFile, "utf8"));
    const assetIds = new Set();
    let assetTotal = 0;
    for (const topic of index.topics ?? []) {
      const shardFile = path.join(assetRoot, topic.file);
      if (!fs.existsSync(shardFile)) {
        errors.push(`missing asset shard ${topic.file}`);
        continue;
      }
      const rows = JSON.parse(fs.readFileSync(shardFile, "utf8"));
      if (!Array.isArray(rows)) {
        errors.push(`asset shard is not an array ${topic.file}`);
        continue;
      }
      if (rows.length !== topic.count) errors.push(`asset shard count mismatch ${topic.file}: index=${topic.count} actual=${rows.length}`);
      assetTotal += rows.length;
      for (const row of rows) {
        if (assetIds.has(row.id)) errors.push(`duplicate asset id ${row.id}`);
        assetIds.add(row.id);
        if (row.source_bank !== requiredSourceBank) errors.push(`asset row ${row.id} is not a Nardebam source item`);
      }
    }
    if (index.total !== assetTotal) errors.push(`asset index total mismatch: index=${index.total} actual=${assetTotal}`);
    if (assetTotal !== total) errors.push(`asset/source total mismatch: asset=${assetTotal} source=${total}`);
    for (const id of ids) if (!assetIds.has(id)) errors.push(`asset missing source id ${id}`);
    for (const id of assetIds) if (!ids.has(id)) errors.push(`asset has unknown id ${id}`);
  }
}
if (errors.length) {
  console.error(`Validation failed with ${errors.length} error(s).`);
  errors.slice(0, 100).forEach((error) => console.error(`- ${error}`));
  process.exit(1);
}
console.log("Comprehensive dataset validation passed.");
