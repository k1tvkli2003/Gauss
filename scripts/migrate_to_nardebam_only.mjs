#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

const apply = process.argv.slice(2).join(" ") === "--apply";
const requiredSourceBank = "nardebam";
const expectedRetainedQuestions = 3672;
const expectedTopicCount = 29;

const shippedBanks = [
  "flutter_app/assets/question_bank",
  "app/src/main/assets/question_bank",
];

// These are all question-bearing datasets that the provenance audit identified
// as Gauss, generated, or legacy-unmapped. The Nardebam source and review
// directories are deliberately absent from this list.
const nonNardebamDataTargets = [
  "sample_question_scratch.json",
  "app/src/main/assets/questions.json",
  "data/seed/comprehensive/gauss",
  "data/seed/gen",
  "data/seed/official",
  "data/seed/quarantine",
  "data/seed/review/jules_v2",
  "data/seed/review/comprehensive_classification.json",
];

function fail(message) {
  throw new Error(message);
}

function readJson(file) {
  return JSON.parse(fs.readFileSync(file, "utf8"));
}

function imageAssets(question) {
  const assets = new Set();
  const collect = (blocks) => {
    for (const block of blocks ?? []) {
      if (block?.type === "image" && typeof block.asset === "string") {
        assets.add(block.asset);
      }
    }
  };
  collect(question.stem);
  collect(question.solution);
  collect(question.smart_shortcut);
  for (const option of question.options ?? []) collect(option);
  return assets;
}

function walkFiles(directory) {
  if (!fs.existsSync(directory)) return [];
  return fs.readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
    const target = path.join(directory, entry.name);
    return entry.isDirectory() ? walkFiles(target) : [target];
  });
}

function removeEmptyDirectories(directory) {
  if (!fs.existsSync(directory)) return;
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    if (entry.isDirectory()) removeEmptyDirectories(path.join(directory, entry.name));
  }
  if (fs.readdirSync(directory).length === 0) fs.rmdirSync(directory);
}

function planQuestionBank(root) {
  const indexFile = path.join(root, "index.json");
  const index = readJson(indexFile);
  if (!Array.isArray(index.topics) || index.topics.length !== expectedTopicCount) {
    fail(`${root} must contain exactly ${expectedTopicCount} topic descriptors.`);
  }

  let rawTotal = 0;
  let retainedTotal = 0;
  let removedTotal = 0;
  const sourceCounts = new Map();
  const retainedMedia = new Set();
  const shardWrites = [];
  const topics = index.topics.map((topic) => {
    const shardFile = path.join(root, "topics", path.basename(topic.file));
    const rows = readJson(shardFile);
    if (!Array.isArray(rows)) fail(`${shardFile} is not a question array.`);
    rawTotal += rows.length;
    const retained = rows.filter((row) => row?.source_bank === requiredSourceBank);
    for (const row of rows) {
      const bank = typeof row?.source_bank === "string" ? row.source_bank : "<missing>";
      sourceCounts.set(bank, (sourceCounts.get(bank) ?? 0) + 1);
    }
    for (const row of retained) {
      for (const asset of imageAssets(row)) retainedMedia.add(asset);
    }
    retainedTotal += retained.length;
    removedTotal += rows.length - retained.length;
    if (retained.length !== rows.length) {
      shardWrites.push({ file: shardFile, content: JSON.stringify(retained) });
    }
    return { ...topic, count: retained.length };
  });

  if (retainedTotal !== expectedRetainedQuestions) {
    fail(`${root} would retain ${retainedTotal} Nardebam rows, expected ${expectedRetainedQuestions}.`);
  }

  const migratedIndex = { ...index, total: retainedTotal, topics };
  const indexContent = JSON.stringify(migratedIndex);
  const indexChanged = fs.readFileSync(indexFile, "utf8") !== indexContent;
  return {
    root,
    rawTotal,
    retainedTotal,
    removedTotal,
    sourceCounts,
    retainedMedia,
    shardWrites,
    indexFile,
    indexContent,
    indexChanged,
  };
}

function applyQuestionBank(plan) {
  for (const write of plan.shardWrites) fs.writeFileSync(write.file, write.content, "utf8");
  if (plan.indexChanged) fs.writeFileSync(plan.indexFile, plan.indexContent, "utf8");
}

function planUnreferencedFlutterMedia(retainedMedia) {
  const root = "flutter_app/assets/question_media";
  return walkFiles(root).filter((file) => {
    const asset = path.relative("flutter_app/assets", file).split(path.sep).join("/");
    return !retainedMedia.has(asset);
  });
}

function applyMediaRemoval(orphanedMedia) {
  for (const file of orphanedMedia) fs.rmSync(file);
  removeEmptyDirectories("flutter_app/assets/question_media");
}

function planTargetRemovals() {
  return nonNardebamDataTargets.filter((target) => fs.existsSync(target));
}

function applyTargetRemovals(targets) {
  for (const target of targets) fs.rmSync(target, { recursive: true, force: true });
}

const migrations = shippedBanks.map(planQuestionBank);
const [flutterMigration, legacyMigration] = migrations;
if (legacyMigration.retainedTotal !== flutterMigration.retainedTotal) {
  fail("Flutter and legacy banks diverged after the migration plan.");
}
const expectedMedia = flutterMigration.retainedMedia;

for (const migration of migrations) {
  const sources = [...migration.sourceCounts.entries()]
    .sort(([left], [right]) => left.localeCompare(right))
    .map(([source, count]) => `${source}:${count}`)
    .join(", ");
  console.log(
    `${migration.root}: ${migration.rawTotal} -> ${migration.retainedTotal} rows ` +
      `(${migration.removedTotal} removed; pre-migration sources ${sources}).`,
  );
}
console.log(`Retained Flutter media references: ${expectedMedia.size}.`);
const orphanedMedia = planUnreferencedFlutterMedia(expectedMedia);
const removedTargets = planTargetRemovals();
console.log(`Unreferenced Flutter media files: ${orphanedMedia.length}.`);
console.log(`Non-Nardebam dataset targets ${apply ? "removed" : "to remove"}: ${removedTargets.length}.`);
for (const target of removedTargets) console.log(`  ${target}`);

if (apply) {
  for (const migration of migrations) applyQuestionBank(migration);
  // These two operations are intentionally after every source-bank plan has
  // passed its count checks; no destructive deletion begins before then.
  applyMediaRemoval(orphanedMedia);
  applyTargetRemovals(removedTargets);
  console.log("Nardebam-only migration applied.");
} else {
  console.log("Dry run only. Re-run with --apply to mutate files.");
}
