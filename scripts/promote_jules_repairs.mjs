#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";

const repairDir = process.argv.find((arg) => arg.startsWith("--repair-dir="))?.slice(13)
  ?? "data/seed/review/nardebam/jules_repairs";
const rawDir = process.argv.find((arg) => arg.startsWith("--raw-dir="))?.slice(10)
  ?? "data/seed/review/nardebam/raw";
const only = new Set(process.argv.filter((arg) => arg.startsWith("--only=")).flatMap((arg) => arg.slice(7).split(",")));
const dryRun = process.argv.includes("--dry-run");

function rowsOf(value) {
  return Array.isArray(value) ? value : (value.questions ?? value.solutions ?? value.rows ?? []);
}

function answersOf(value) {
  return value.answers && typeof value.answers === "object" ? value.answers : null;
}

function withRowsLike(original, rows) {
  if (Array.isArray(original)) return rows;
  if (Array.isArray(original.questions)) return { ...original, questions: rows };
  if (Array.isArray(original.solutions)) return { ...original, solutions: rows };
  if (Array.isArray(original.rows)) return { ...original, rows };
  return rows;
}

function isBetterSolution(candidate, current, options = {}) {
  const text = (row) => String(row?.solution_text ?? row?.classic_solution ?? "").trim();
  if (!current) return true;
  if (text(candidate).length > text(current).length) return true;
  if (!current.stated_correct_option && candidate.stated_correct_option) return true;
  if (
    options.preferStatedOption
    && candidate.stated_correct_option
    && candidate.stated_correct_option !== current.stated_correct_option
    && text(candidate).length >= Math.floor(text(current).length * 0.5)
  ) {
    return true;
  }
  return false;
}

function toNumber(value) {
  if (Number.isInteger(value)) return value;
  const normalized = String(value ?? "")
    .replace(/[۰-۹]/g, (digit) => "۰۱۲۳۴۵۶۷۸۹".indexOf(digit))
    .replace(/[٠-٩]/g, (digit) => "٠١٢٣٤٥٦٧٨٩".indexOf(digit));
  const number = Number(normalized);
  return Number.isInteger(number) ? number : value;
}

function readAnswerKey(subject) {
  if (!subject) return {};
  const rawPath = path.join(rawDir, `${subject}-answer-key.json`);
  if (!fs.existsSync(rawPath)) return {};
  const json = JSON.parse(fs.readFileSync(rawPath, "utf8"));
  return answersOf(json) ?? {};
}

function sanitizeStatedOptions(taskId, rows) {
  const subject = taskId.startsWith("math-") || taskId.startsWith("local-math-")
    ? "math"
    : taskId.startsWith("physics-") || taskId.startsWith("local-physics-") ? "physics" : null;
  const key = readAnswerKey(subject);
  return rows.map((row) => {
    const questionNumber = toNumber(row.question_number);
    const correct = toNumber(key[String(questionNumber)] ?? key[questionNumber]);
    if (
      Number.isInteger(row.stated_correct_option)
      && Number.isInteger(correct)
      && row.stated_correct_option !== correct
    ) {
      const reviewNotes = Array.isArray(row.review_notes) ? [...row.review_notes] : [];
      reviewNotes.push(`stated_correct_option ${row.stated_correct_option} conflicts with authoritative answer key ${correct}; cleared during promotion.`);
      return { ...row, stated_correct_option: null, review_notes: reviewNotes };
    }
    return row;
  });
}

function normalizeSolutionRows(rows) {
  return rows
    .filter((row) => row && typeof row === "object" && !Array.isArray(row))
    .map((row) => ({ ...row, question_number: toNumber(row.question_number) }));
}

function dedupeSolutions(rows) {
  const byNumber = new Map();
  for (const row of normalizeSolutionRows(rows)) {
    const key = toNumber(row.question_number);
    if (isBetterSolution(row, byNumber.get(key))) byNumber.set(key, row);
  }
  return [...byNumber.values()].sort((a, b) => Number(a.question_number) - Number(b.question_number));
}

function validateQuestions(taskId, rows) {
  const errors = [];
  const seen = new Set();
  rows.forEach((row, index) => {
    const at = `${taskId}:${index + 1}`;
    if (!Number.isInteger(row.question_number)) errors.push(`${at} invalid question_number`);
    if (seen.has(row.question_number)) errors.push(`${at} duplicate question_number ${row.question_number}`);
    seen.add(row.question_number);
    if (!Number.isInteger(row.question_page)) errors.push(`${at} invalid question_page`);
    if (!String(row.question_text ?? "").trim()) errors.push(`${at} empty question_text`);
    if (!Array.isArray(row.options) || row.options.length !== 4 || row.options.some((option) => !String(option ?? "").trim())) {
      errors.push(`${at} invalid options`);
    }
    if (!Array.isArray(row.media_regions)) errors.push(`${at} media_regions must be an array`);
    if (!Array.isArray(row.review_notes)) errors.push(`${at} review_notes must be an array`);
  });
  return errors;
}

function normalizeQuestionRows(rows) {
  return rows.filter((row) => row && typeof row === "object" && !Array.isArray(row)).map((row) => {
    const copy = { ...row };
    copy.question_number = toNumber(copy.question_number);
    if (!Number.isInteger(copy.question_page)) {
      const match = String(copy.question_page ?? copy.page_file ?? "").match(/page_(\d+)/);
      if (match) copy.question_page = Number(match[1]);
    }
    copy.options = Array.isArray(copy.options) ? copy.options.map((option) => String(option ?? "").trim()) : copy.options;
    copy.media_regions = Array.isArray(copy.media_regions) ? copy.media_regions : [];
    copy.review_notes = Array.isArray(copy.review_notes) ? copy.review_notes : [];
    return copy;
  });
}

function isBetterQuestion(candidate, current) {
  const text = (row) => String(row?.question_text ?? "").trim();
  const options = (row) => Array.isArray(row?.options) ? row.options.filter((option) => String(option ?? "").trim()).length : 0;
  if (!current) return true;
  if (options(candidate) === 4 && options(current) !== 4) return true;
  if (text(candidate).length > text(current).length) return true;
  const candidateMedia = Array.isArray(candidate.media_regions) ? candidate.media_regions.length : 0;
  const currentMedia = Array.isArray(current.media_regions) ? current.media_regions.length : 0;
  return candidateMedia > currentMedia && text(candidate).length >= Math.floor(text(current).length * 0.75);
}

function baseTopicTaskId(taskId, rows = []) {
  if (taskId.startsWith("local-math-topic07")) return "math-topic-07";
  if (taskId.startsWith("local-physics-topic07")) return "physics-topic-07";
  if (taskId.startsWith("math-topic-boundary-1732-1734")) {
    const topicKey = rows.find((row) => row?.topic_key)?.topic_key;
    return topicKey === "visual_thinking_conics" ? "math-topic-14" : "math-topic-15";
  }
  const match = taskId.match(/^(math|physics)-topic-(\d{2})(?:-|$)/);
  return match ? `${match[1]}-topic-${match[2]}` : taskId;
}

function baseSolutionTaskId(taskId, rows = []) {
  const match = taskId.match(/^(math|physics)-solutions-(\d{2})(?:-|$)/);
  if (match) return `${match[1]}-solutions-${match[2]}`;
  const subject = taskId.startsWith("math-") || taskId.startsWith("local-math-")
    ? "math"
    : taskId.startsWith("physics-") || taskId.startsWith("local-physics-") ? "physics" : null;
  const numbers = rows.map((row) => toNumber(row.question_number)).filter(Number.isInteger);
  const first = numbers.length ? Math.min(...numbers) : null;
  if (subject === "math" && first !== null) {
    if (first <= 153) return "math-solutions-01";
    if (first <= 242) return "math-solutions-02";
    if (first <= 421) return "math-solutions-03";
    if (first <= 780) return "math-solutions-04";
    if (first <= 928) return "math-solutions-05";
    if (first <= 1156) return "math-solutions-06";
    if (first <= 1514) return "math-solutions-07";
    if (first <= 1608) return "math-solutions-08";
    if (first <= 1935) return "math-solutions-09";
    return "math-solutions-10";
  }
  return taskId.replace(/-repair$/, "");
}

function validateSolutions(taskId, rows) {
  const errors = [];
  const seen = new Set();
  rows.forEach((row, index) => {
    const at = `${taskId}:${index + 1}`;
    if (!Number.isInteger(row.question_number)) errors.push(`${at} invalid question_number`);
    if (seen.has(row.question_number)) errors.push(`${at} duplicate question_number ${row.question_number}`);
    seen.add(row.question_number);
    const solution = row.solution_text ?? row.classic_solution;
    if (!String(solution ?? "").trim()) errors.push(`${at} empty solution_text`);
    if (/^\s*missing page from dataset\s*$/i.test(String(solution ?? ""))) errors.push(`${at} placeholder solution_text`);
    if (/(در دسترس نیست|موجود نیست|عدم وجود تصویر|missing page from dataset)/i.test(String(solution ?? ""))) {
      errors.push(`${at} placeholder solution_text`);
    }
    if (row.stated_correct_option !== undefined && row.stated_correct_option !== null) {
      if (!Number.isInteger(row.stated_correct_option) || row.stated_correct_option < 1 || row.stated_correct_option > 4) errors.push(`${at} invalid stated_correct_option`);
    }
    if (!Array.isArray(row.media_regions)) errors.push(`${at} media_regions must be an array`);
    if (!Array.isArray(row.review_notes)) errors.push(`${at} review_notes must be an array`);
  });
  return errors;
}

if (!fs.existsSync(repairDir)) {
  console.log(`No repair dir found: ${repairDir}`);
  process.exit(0);
}

const errors = [];
const promoted = [];
for (const file of fs.readdirSync(repairDir).filter((name) => name.endsWith(".json")).sort()) {
  const taskId = file.slice(0, -5);
  if (only.size && !only.has(taskId)) continue;
  const full = path.join(repairDir, file);
  const json = JSON.parse(fs.readFileSync(full, "utf8"));
  const isAnswerKey = taskId.includes("answer-key");
  if (isAnswerKey) {
    const subject = taskId.startsWith("math-") ? "math" : taskId.startsWith("physics-") ? "physics" : null;
    const baseTaskId = subject ? `${subject}-answer-key` : taskId.replace(/-repair$/, "");
    const rawPath = path.join(rawDir, `${baseTaskId}.json`);
    const incoming = answersOf(json);
    const existingJson = fs.existsSync(rawPath) ? JSON.parse(fs.readFileSync(rawPath, "utf8")) : {};
    const existing = answersOf(existingJson) ?? {};
    if (!incoming) {
      promoted.push({ taskId, rawPath, rows: 0, mode: "skip_invalid_answer_key" });
      continue;
    }
    const merged = { ...existing, ...incoming };
    const added = Object.keys(merged).length - Object.keys(existing).length;
    const replaced = Object.entries(incoming).filter(([key, value]) => existing[key] !== undefined && existing[key] !== value).length;
    const allowReplacement = taskId.includes("verified") || taskId.includes("mismatch") || taskId.includes("repair");
    if (Object.keys(merged).length <= Object.keys(existing).length && !(allowReplacement && replaced > 0)) {
      promoted.push({ taskId, rawPath, rows: Object.keys(incoming).length, mode: "skip_not_better_answer_key", existingRows: Object.keys(existing).length });
      continue;
    }
    const outputJson = { ...existingJson, ...json, answers: Object.fromEntries(Object.entries(merged).sort((a, b) => Number(a[0]) - Number(b[0]))) };
    promoted.push({ taskId, rawPath, rows: Object.keys(incoming).length, mode: "merge_answer_key", mergedRows: Object.keys(merged).length, added, replaced });
    if (!dryRun) {
      fs.mkdirSync(path.dirname(rawPath), { recursive: true });
      fs.writeFileSync(rawPath, `${JSON.stringify(outputJson, null, 2)}\n`, "utf8");
    }
    continue;
  }
  let rows = rowsOf(json);
  const isSolution = taskId.includes("solutions");
  if (isSolution) rows = dedupeSolutions(rows);
  else rows = normalizeQuestionRows(rows);
  if (isSolution) rows = sanitizeStatedOptions(taskId, rows);
  if (isSolution && rows.length === 0) {
    const baseTaskId = baseSolutionTaskId(taskId, rows);
    const rawPath = path.join(rawDir, `${baseTaskId}.json`);
    promoted.push({ taskId, rawPath, rows: 0, mode: "skip_empty_solution_artifact" });
    continue;
  }
  const isTopic = !isSolution && (
    /^(math|physics)-topic-\d{2}/.test(taskId)
    || taskId.startsWith("math-topic-boundary-1732-1734")
    || taskId.startsWith("local-math-topic07")
    || taskId.startsWith("local-physics-topic07")
  );
  const topicBaseTaskId = isTopic ? baseTopicTaskId(taskId, rows) : null;
  const topicRawPath = topicBaseTaskId ? path.join(rawDir, `${topicBaseTaskId}.json`) : null;
  const mergePartialTopic = isTopic && taskId !== topicBaseTaskId && fs.existsSync(topicRawPath);
  if (isTopic && !mergePartialTopic && fs.existsSync(topicRawPath)) {
    const existingRows = rowsOf(JSON.parse(fs.readFileSync(topicRawPath, "utf8")));
    if (rows.length < existingRows.length) {
      promoted.push({ taskId, rawPath: topicRawPath, rows: rows.length, mode: "skip_shorter_topic_artifact", existingRows: existingRows.length });
      continue;
    }
    if (rows.length < Math.max(10, Math.floor(existingRows.length * 0.8))) {
      promoted.push({ taskId, rawPath: topicRawPath, rows: rows.length, mode: "skip_partial", existingRows: existingRows.length });
      continue;
    }
  }
  errors.push(...(isSolution ? validateSolutions(taskId, rows) : validateQuestions(taskId, rows)));
  if (errors.length) continue;
  const baseTaskId = isSolution ? baseSolutionTaskId(taskId, rows) : baseTopicTaskId(taskId, rows);
  const rawPath = path.join(rawDir, `${baseTaskId}.json`);
  let outputJson = json;
  let mergedRows = rows;
  if (isSolution && fs.existsSync(rawPath)) {
    const existing = JSON.parse(fs.readFileSync(rawPath, "utf8"));
    const byNumber = new Map(normalizeSolutionRows(rowsOf(existing)).map((row) => [toNumber(row.question_number), row]));
    let replaced = 0;
    const preferStatedOption = taskId.includes("mismatch");
    for (const row of rows) {
      const key = toNumber(row.question_number);
      if (isBetterSolution(row, byNumber.get(key), { preferStatedOption })) {
        byNumber.set(key, row);
        replaced += 1;
      }
    }
    mergedRows = [...byNumber.values()].sort((a, b) => Number(a.question_number) - Number(b.question_number));
    outputJson = withRowsLike(existing, mergedRows);
    promoted.push({ taskId, rawPath, rows: rows.length, mode: "merge", mergedRows: mergedRows.length, replaced });
  } else if (mergePartialTopic) {
    const existing = JSON.parse(fs.readFileSync(rawPath, "utf8"));
    const byNumber = new Map(normalizeQuestionRows(rowsOf(existing)).map((row) => [toNumber(row.question_number), row]));
    let replaced = 0;
    let added = 0;
    for (const row of rows) {
      const key = toNumber(row.question_number);
      const current = byNumber.get(key);
      if (isBetterQuestion(row, current)) {
        byNumber.set(key, row);
        if (current) replaced += 1;
        else added += 1;
      }
    }
    mergedRows = [...byNumber.values()].sort((a, b) => Number(a.question_number) - Number(b.question_number));
    outputJson = withRowsLike(existing, mergedRows);
    promoted.push({ taskId, rawPath, rows: rows.length, mode: "merge_topic", mergedRows: mergedRows.length, added, replaced });
  } else {
    promoted.push({ taskId, rawPath, rows: rows.length, mode: "replace" });
  }
  if (!dryRun) {
    fs.mkdirSync(path.dirname(rawPath), { recursive: true });
    fs.writeFileSync(rawPath, `${JSON.stringify(outputJson, null, 2)}\n`, "utf8");
  }
}

if (errors.length) {
  console.error(`Repair promotion failed with ${errors.length} error(s):`);
  errors.slice(0, 80).forEach((error) => console.error(`- ${error}`));
  process.exit(1);
}

console.log(JSON.stringify({ dryRun, promoted }, null, 2));
if (!dryRun && promoted.length) {
  const normalized = spawnSync("node", ["scripts/normalize_nardebam_raw.mjs"], { stdio: "inherit", shell: process.platform === "win32" });
  if (normalized.status) process.exit(normalized.status);
}
