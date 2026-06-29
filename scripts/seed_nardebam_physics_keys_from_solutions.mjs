#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

const rawDir = argValue("--raw-dir=") ?? "data/seed/review/nardebam/raw";
const normalizedDir = argValue("--normalized-dir=") ?? "data/seed/review/nardebam/normalized";
const reportPath = argValue("--report=") ?? "data/seed/review/nardebam/agent_reports/key_mismatch_report.json";
const artifactPath = argValue("--artifact=") ?? "data/seed/review/nardebam/local_parts/physics-answer-key-from-solutions-repair.json";
const apply = process.argv.includes("--apply");

function argValue(prefix) {
  return process.argv.find((arg) => arg.startsWith(prefix))?.slice(prefix.length);
}

function readJson(file) {
  return JSON.parse(fs.readFileSync(file, "utf8"));
}

function writeJson(file, value) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, `${JSON.stringify(value, null, 2)}\n`, "utf8");
}

function answerEntries(value) {
  return value.answers && typeof value.answers === "object" ? value.answers : {};
}

function isValidOption(value) {
  return Number.isInteger(value) && value >= 1 && value <= 4;
}

function inRanges(questionNumber, ranges) {
  return ranges.some((range) => questionNumber >= range.start && questionNumber <= range.end);
}

function reportItems(report) {
  return (report.low_risk_local_normalization_fixes ?? []).filter((item) =>
    item.subject === "physics"
    && item.issue === "missing_key"
    && item.classification === "incomplete_answer_key_solution_can_seed"
    && typeof item.source_file === "string"
    && Array.isArray(item.ranges)
  );
}

const report = readJson(reportPath);
const candidatesByFile = new Map();
for (const item of reportItems(report)) {
  if (!candidatesByFile.has(item.source_file)) candidatesByFile.set(item.source_file, []);
  candidatesByFile.get(item.source_file).push(...item.ranges);
}

const rawKeyPath = path.join(rawDir, "physics-answer-key.json");
const rawKey = fs.existsSync(rawKeyPath)
  ? readJson(rawKeyPath)
  : { task_id: "physics-answer-key", subject: "physics", answers: {}, review_notes: [] };
const existingAnswers = answerEntries(rawKey);
const repairAnswers = {};
const provenance = [];
const skippedExisting = [];
const skippedInvalid = [];
const duplicateCandidates = [];
const seenCandidates = new Map();

for (const [sourceFile, ranges] of [...candidatesByFile.entries()].sort(([a], [b]) => a.localeCompare(b))) {
  const solutionPath = path.join(normalizedDir, sourceFile);
  if (!fs.existsSync(solutionPath)) {
    skippedInvalid.push({ source_file: sourceFile, issue: "missing_solution_file" });
    continue;
  }

  for (const solution of readJson(solutionPath)) {
    const questionNumber = solution.question_number;
    const option = solution.stated_correct_option;
    if (!Number.isInteger(questionNumber) || !inRanges(questionNumber, ranges)) continue;
    if (!isValidOption(option)) {
      skippedInvalid.push({ source_file: sourceFile, question_number: questionNumber, stated_correct_option: option });
      continue;
    }
    if (existingAnswers[String(questionNumber)] !== undefined) {
      skippedExisting.push({ source_file: sourceFile, question_number: questionNumber });
      continue;
    }

    const previous = seenCandidates.get(questionNumber);
    if (previous && previous.option !== option) {
      duplicateCandidates.push({ question_number: questionNumber, candidates: [previous, { source_file: sourceFile, option }] });
      continue;
    }
    seenCandidates.set(questionNumber, { source_file: sourceFile, option });
    repairAnswers[String(questionNumber)] = option;
    provenance.push({
      question_number: questionNumber,
      correct_option_index: option,
      source_file: sourceFile,
      source_field: "stated_correct_option",
      source_quality: "low_risk_local_normalization_fix",
    });
  }
}

if (duplicateCandidates.length) {
  console.error(`Refusing to write repair: ${duplicateCandidates.length} conflicting duplicate candidate(s).`);
  console.error(JSON.stringify(duplicateCandidates.slice(0, 20), null, 2));
  process.exit(1);
}

const sortedAnswers = Object.fromEntries(Object.entries(repairAnswers).sort((a, b) => Number(a[0]) - Number(b[0])));
const sortedProvenance = provenance.sort((a, b) => a.question_number - b.question_number);
const ranges = [];
for (const questionNumber of Object.keys(sortedAnswers).map(Number)) {
  const last = ranges[ranges.length - 1];
  if (last && last.end + 1 === questionNumber) {
    last.end = questionNumber;
    last.count += 1;
  } else {
    ranges.push({ start: questionNumber, end: questionNumber, count: 1 });
  }
}

const artifact = {
  task_id: "physics-answer-key-from-solutions-repair",
  subject: "physics",
  answers: sortedAnswers,
  repair_metadata: {
    generated_by: "scripts/seed_nardebam_physics_keys_from_solutions.mjs",
    source_report: reportPath,
    normalized_solution_dir: normalizedDir,
    rule: "Fill only report-backed physics missing answer keys from normalized solution.stated_correct_option when option is 1..4 and the raw key has no existing answer.",
    applied_to_raw: apply,
    counts: {
      report_items: [...candidatesByFile.values()].reduce((sum, fileRanges) => sum + fileRanges.length, 0),
      filled: Object.keys(sortedAnswers).length,
      skipped_existing: skippedExisting.length,
      skipped_invalid: skippedInvalid.length,
    },
    ranges,
  },
  provenance: sortedProvenance,
  review_notes: [
    "Local deterministic repair artifact; candidates are seeded from normalized solution.stated_correct_option only for low-risk missing_key ranges in key_mismatch_report.json.",
    "Existing physics-answer-key entries are treated as stronger source keys and are not overwritten.",
  ],
};

writeJson(artifactPath, artifact);

let mergedRows = Object.keys(existingAnswers).length;
if (apply) {
  const mergedAnswers = Object.fromEntries(
    Object.entries({ ...existingAnswers, ...sortedAnswers }).sort((a, b) => Number(a[0]) - Number(b[0])),
  );
  mergedRows = Object.keys(mergedAnswers).length;
  const note = `Seeded ${Object.keys(sortedAnswers).length} missing physics answer-key entries from solution.stated_correct_option via ${path.basename(artifactPath)}; existing keys were not overwritten.`;
  writeJson(rawKeyPath, {
    ...rawKey,
    answers: mergedAnswers,
    review_notes: [...new Set([...(Array.isArray(rawKey.review_notes) ? rawKey.review_notes : []), note])],
  });
}

console.log(JSON.stringify({
  apply,
  artifactPath,
  rawKeyPath,
  filled: Object.keys(sortedAnswers).length,
  ranges,
  skippedExisting: skippedExisting.length,
  skippedInvalid: skippedInvalid.length,
  mergedRows,
}, null, 2));
