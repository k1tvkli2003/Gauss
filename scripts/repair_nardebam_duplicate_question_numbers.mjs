#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

const rawDir =
  process.argv.find((arg) => arg.startsWith("--raw="))?.slice(6) ??
  "data/seed/review/nardebam/raw";

const readTopic = (file) => {
  const fullPath = path.join(rawDir, file);
  const data = JSON.parse(fs.readFileSync(fullPath, "utf8"));
  if (!Array.isArray(data.questions)) {
    throw new Error(`${file} does not have a questions array`);
  }
  return { fullPath, data };
};

const readSolutions = (file) => {
  const fullPath = path.join(rawDir, file);
  const data = JSON.parse(fs.readFileSync(fullPath, "utf8"));
  const rows = Array.isArray(data) ? data : data.solutions;
  if (!Array.isArray(rows)) {
    throw new Error(`${file} does not have a solutions array`);
  }
  return { fullPath, data, rows };
};

const writeTopic = (fullPath, data) => {
  fs.writeFileSync(fullPath, `${JSON.stringify(data, null, 2)}\n`, "utf8");
};

const toNumber = (value) => Number(String(value).replace(/[^0-9-]/g, ""));
const questionNumbers = (rows) => rows.map((row) => toNumber(row.question_number));
const assert = (condition, message) => {
  if (!condition) throw new Error(message);
};

const addUnique = (target, source) => {
  const output = Array.isArray(target) ? [...target] : [];
  for (const item of Array.isArray(source) ? source : []) {
    if (!output.some((existing) => JSON.stringify(existing) === JSON.stringify(item))) {
      output.push(item);
    }
  }
  return output;
};

function mergeLeadingRepeatedBlock(file, leadingCount, keptStartIndex, leadingStart, expectedStart, expectedEnd) {
  const { fullPath, data } = readTopic(file);
  const rows = data.questions;
  const nums = questionNumbers(rows);
  if (rows.length === expectedEnd - expectedStart + 1 && nums.every((n, i) => n === expectedStart + i)) {
    return `${file}: already repaired; kept ${expectedStart}..${expectedEnd}`;
  }
  assert(rows.length === expectedEnd - expectedStart + 1 + leadingCount, `${file}: unexpected row count`);
  assert(nums.slice(0, leadingCount).every((n, i) => n === leadingStart + i), `${file}: leading repeated block drifted`);
  assert(nums[keptStartIndex] === expectedStart, `${file}: kept contiguous block does not start at ${expectedStart}`);
  assert(nums.slice(keptStartIndex).every((n, i) => n === expectedStart + i), `${file}: kept contiguous block is not ${expectedStart}..${expectedEnd}`);

  for (let i = 0; i < leadingCount; i += 1) {
    const duplicate = rows[i];
    const kept = rows[keptStartIndex + (leadingStart - expectedStart) + i];
    assert(toNumber(duplicate.question_number) === toNumber(kept.question_number), `${file}: duplicate pair ${i} number mismatch`);
    kept.media_regions = addUnique(kept.media_regions, duplicate.media_regions);
    kept.review_notes = addUnique(kept.review_notes, duplicate.review_notes);
  }

  data.questions = rows.slice(keptStartIndex);
  writeTopic(fullPath, data);
  return `${file}: merged and removed leading ${leadingCount} rows; kept ${expectedStart}..${expectedEnd}`;
}

function renumberFunctionsSecond611() {
  const file = "math-topic-07.json";
  const { fullPath, data } = readTopic(file);
  const rows = data.questions;
  const nums = questionNumbers(rows);
  if (rows.length === 63 && nums.every((n, i) => n === 609 + i)) {
    return `${file}: already repaired; now 609..671`;
  }
  assert(rows.length === 63, `${file}: unexpected row count`);
  assert(nums[0] === 609 && nums[1] === 610 && nums[2] === 611 && nums[3] === 611, `${file}: expected duplicated 611 at indices 2 and 3`);
  assert(nums.slice(4).every((n, i) => n === 612 + i), `${file}: expected rows after second 611 to be 612..670`);

  for (let i = 3; i < rows.length; i += 1) {
    rows[i].question_number = String(toNumber(rows[i].question_number) + 1);
  }
  assert(questionNumbers(rows).every((n, i) => n === 609 + i), `${file}: renumber did not produce 609..671`);
  writeTopic(fullPath, data);
  return `${file}: renumbered index 3 onward by +1; now 609..671`;
}

function renumberStatisticsLeadingBlock() {
  const file = "math-topic-18.json";
  const { fullPath, data } = readTopic(file);
  const rows = data.questions;
  const nums = questionNumbers(rows);
  if (rows.length === 115 && nums.slice(0, 39).every((n, i) => n === 2059 + i)) {
    return `${file}: already repaired; leading block is 2059..2097`;
  }
  const leading = nums.slice(0, 39);
  const expectedLeading = [
    ...Array.from({ length: 30 }, (_, i) => 2001 + i),
    ...Array.from({ length: 9 }, (_, i) => 2034 + i),
  ];
  assert(rows.length === 115, `${file}: unexpected row count`);
  assert(leading.every((n, i) => n === expectedLeading[i]), `${file}: leading statistics block drifted`);
  assert(nums[39] === 1999 && nums[98] === 2058, `${file}: expected main 1999..2058 block at indices 39..98`);
  assert(nums.slice(39, 99).every((n, i) => n === 1999 + i), `${file}: main statistics block is not 1999..2058`);
  assert(nums.slice(99).every((n, i) => n === 2104 + i), `${file}: final statistics block is not 2104..2119`);

  for (let i = 0; i < 39; i += 1) {
    rows[i].question_number = String(2059 + i);
  }
  assert(questionNumbers(rows).slice(0, 39).every((n, i) => n === 2059 + i), `${file}: leading block did not become 2059..2097`);
  writeTopic(fullPath, data);
  return `${file}: renumbered leading 39 rows to 2059..2097`;
}

function repairRadicalsGapFromJules() {
  const file = "math-topic-05.json";
  const { fullPath, data } = readTopic(file);
  const rows = data.questions;
  const nums = questionNumbers(rows);
  if (rows.length === 47 && nums.every((n, i) => n === 262 + i)) {
    return `${file}: already repaired; contiguous 262..308`;
  }
  assert(rows.length === 48, `${file}: unexpected row count`);
  assert(nums.slice(0, 15).every((n) => n >= 1 && n <= 15), `${file}: expected leading local 1..15 block`);
  assert(nums[15] === 262 && nums.slice(15).every((n, i) => n === 262 + i), `${file}: expected existing global block 262..294`);

  const repairPath = path.join("data", "seed", "review", "nardebam", "jules_repairs", "math-topic-05-gap-295-308.json");
  const repair = JSON.parse(fs.readFileSync(repairPath, "utf8"));
  const repairRows = repair.questions.filter((row) => {
    const n = toNumber(row.question_number);
    return n >= 295 && n <= 308;
  });
  assert(repairRows.length === 14, `${file}: expected 14 repair rows for 295..308`);
  assert(questionNumbers(repairRows).every((n, i) => n === 295 + i), `${file}: repair rows are not 295..308`);

  data.questions = [...repairRows, ...rows.slice(15)].sort((a, b) => toNumber(a.question_number) - toNumber(b.question_number));
  assert(data.questions.length === 47, `${file}: repaired row count should be 47`);
  assert(questionNumbers(data.questions).every((n, i) => n === 262 + i), `${file}: repaired topic is not contiguous 262..308`);
  writeTopic(fullPath, data);
  return `${file}: replaced local 1..15 block with Jules 295..308; now 262..308`;
}

function repairPatternsBoundaryFromJules() {
  const file = "math-topic-02.json";
  const { fullPath, data } = readTopic(file);
  const rows = data.questions;
  const nums = questionNumbers(rows);
  if (rows.length === 50 && nums.every((n, i) => n === 51 + i)) {
    return `${file}: already repaired; now 51..100`;
  }
  assert(rows.length === 68, `${file}: unexpected row count`);
  assert(nums.every((n, i) => n === 33 + i), `${file}: expected current block 33..100`);

  const repairPath = path.join("data", "seed", "review", "nardebam", "jules_repairs", "math-topic-02-boundary-33-100.json");
  const repair = JSON.parse(fs.readFileSync(repairPath, "utf8"));
  const repairRows = repair.questions;
  assert(repairRows.length === 50, `${file}: expected 50 repair rows`);
  assert(questionNumbers(repairRows).every((n, i) => n === 51 + i), `${file}: repair rows are not 51..100`);

  data.questions = repairRows;
  writeTopic(fullPath, data);
  return `${file}: replaced overlapping 33..100 block with Jules 51..100`;
}

function renumberVisualThinkingConicsAfterJules() {
  const file = "math-topic-14.json";
  const { fullPath, data } = readTopic(file);
  const rows = data.questions;
  const nums = questionNumbers(rows);
  if (rows.length === 94 && nums.every((n, i) => n === 1638 + i)) {
    return `${file}: already repaired; now 1638..1731`;
  }
  assert(rows.length === 94, `${file}: unexpected row count`);
  assert(nums.every((n, i) => n === 1 + i), `${file}: expected local 1..94 Jules replacement`);

  for (let i = 0; i < rows.length; i += 1) {
    rows[i].question_number = String(1638 + i);
  }
  assert(questionNumbers(rows).every((n, i) => n === 1638 + i), `${file}: renumber did not produce 1638..1731`);
  writeTopic(fullPath, data);
  return `${file}: renumbered Jules local 1..94 replacement to 1638..1731`;
}

function removePhysicsMagnetismMotionBoundary() {
  const file = "physics-topic-07.json";
  const { fullPath, data } = readTopic(file);
  const rows = data.questions;
  const nums = questionNumbers(rows);
  if (!nums.includes(806) && !nums.includes(807)) {
    return `${file}: already repaired; topic ends before 806`;
  }

  const boundaryPath = path.join("data", "seed", "review", "nardebam", "jules_repairs", "physics-topic-07-08-boundary-806-807-retry.json");
  const boundary = JSON.parse(fs.readFileSync(boundaryPath, "utf8"));
  assert(String(boundary.recommendations ?? "").includes("ends exactly at question 805"), `${file}: missing Jules boundary confirmation`);
  assert(nums.slice(-2).join(",") === "806,807", `${file}: expected trailing 806,807 boundary rows`);

  data.questions = rows.filter((row) => {
    const n = toNumber(row.question_number);
    return n !== 806 && n !== 807;
  });
  assert(!questionNumbers(data.questions).includes(806), `${file}: 806 was not removed`);
  assert(!questionNumbers(data.questions).includes(807), `${file}: 807 was not removed`);
  writeTopic(fullPath, data);
  return `${file}: removed trailing 806,807; Jules confirmed topic 07 ends at 805`;
}

function removeInvalidMathStatisticsContinuation() {
  const file = "math-solutions-10.json";
  const { fullPath, data, rows } = readSolutions(file);
  if (!rows.some((row) => toNumber(row.question_number) === 0)) {
    return `${file}: already repaired; no zero-number continuation row`;
  }
  assert(toNumber(rows[0]?.question_number) === 0, `${file}: zero-number continuation row moved`);
  assert(String(rows[0]?.review_notes ?? "").includes("Continuation"), `${file}: zero-number row is not marked as continuation`);
  const repaired = rows.filter((row) => toNumber(row.question_number) !== 0);
  writeTopic(fullPath, Array.isArray(data) ? repaired : { ...data, solutions: repaired });
  return `${file}: removed invalid zero-number continuation row`;
}

function mergeDerivativeApplicationsGlobalTopic() {
  const file = "math-topic-11.json";
  const { fullPath, data } = readTopic(file);
  const rows = data.questions;
  const nums = questionNumbers(rows);
  if (nums.every((n) => n >= 1248 && n <= 1466) && nums.length === 219) {
    return `${file}: already repaired; global 1248..1466`;
  }

  const repairPath = path.join("data", "seed", "review", "nardebam", "jules_repairs", "math-topic-11-global-1248-1466-retry.json");
  const repair = JSON.parse(fs.readFileSync(repairPath, "utf8"));
  const repairRows = repair.questions ?? repair.rows ?? repair;
  assert(Array.isArray(repairRows), `${file}: global repair rows missing`);
  const repairNums = questionNumbers(repairRows);
  assert(repairRows.length === 151, `${file}: expected 151 global repair rows`);
  assert(repairNums.every((n, i) => n === 1248 + i), `${file}: global repair should be 1248..1398`);
  assert(nums.slice(0, 64).every((n, i) => n === 1 + i), `${file}: expected local duplicate block 1..64 at start`);
  assert(nums.slice(64).every((n, i) => n === 1346 + i), `${file}: expected existing global tail 1346..1466 after local block`);

  const byNumber = new Map();
  for (const row of repairRows) byNumber.set(toNumber(row.question_number), row);
  for (const row of rows.slice(64)) byNumber.set(toNumber(row.question_number), row);
  data.questions = [...byNumber.entries()]
    .sort(([a], [b]) => a - b)
    .map(([, row]) => row);
  const repairedNums = questionNumbers(data.questions);
  assert(repairedNums.length === 219, `${file}: repaired row count should be 219`);
  assert(repairedNums.every((n, i) => n === 1248 + i), `${file}: repaired topic is not contiguous 1248..1466`);
  writeTopic(fullPath, data);
  return `${file}: merged Jules 1248..1398 with existing 1346..1466; now 1248..1466`;
}

const changes = [
  repairPatternsBoundaryFromJules(),
  repairRadicalsGapFromJules(),
  mergeLeadingRepeatedBlock("math-topic-10.json", 12, 12, 1157, 1156, 1247),
  renumberFunctionsSecond611(),
  renumberVisualThinkingConicsAfterJules(),
  mergeLeadingRepeatedBlock("math-topic-16.json", 15, 15, 1854, 1823, 1935),
  renumberStatisticsLeadingBlock(),
  removePhysicsMagnetismMotionBoundary(),
  removeInvalidMathStatisticsContinuation(),
  mergeDerivativeApplicationsGlobalTopic(),
];

for (const change of changes) console.log(change);
