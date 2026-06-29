#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

const input = process.argv.find((arg) => arg.startsWith("--input="))?.slice(8) ?? "data/seed/review/nardebam/raw";
const output = process.argv.find((arg) => arg.startsWith("--output="))?.slice(9) ?? "data/seed/review/nardebam/normalized";

const fa = "۰۱۲۳۴۵۶۷۸۹";
const ar = "٠١٢٣٤٥٦٧٨٩";
const asciiDigits = (value) => String(value ?? "").replace(/[۰-۹]/g, (d) => fa.indexOf(d)).replace(/[٠-٩]/g, (d) => ar.indexOf(d));
const number = (value) => {
  const parsed = Number(asciiDigits(value).replace(/[^0-9-]/g, ""));
  return Number.isInteger(parsed) ? parsed : null;
};

function rowsOf(data, kind) {
  if (Array.isArray(data)) return data;
  if (kind === "questions") return data.questions ?? data.items ?? [];
  if (kind === "solutions") return data.solutions ?? data.items ?? [];
  return data.answers ?? data.key ?? {};
}

function normalizeRegion(raw, fallbackPlacement) {
  if (!raw) return null;
  const box = raw.box ?? raw.bbox ?? raw.box_2d ?? raw.region ?? raw.coordinates;
  if (!Array.isArray(box) || box.length !== 4 || box.some((value) => !Number.isFinite(Number(value)))) return null;
  return {
    page_file: raw.page_file ?? raw.file ?? raw.filename ?? null,
    box: box.map(Number),
    box_format: raw.box_2d && !raw.box && !raw.bbox ? "yxyx" : "xyxy",
    placement: raw.placement ?? fallbackPlacement,
    alt: raw.alt ?? raw.alt_text ?? raw.description ?? "شکل سؤال",
  };
}

function normalizeQuestion(row) {
  const media = row.media_regions ?? row.media ?? [];
  const regions = (Array.isArray(media) ? media : [media]).map((item) => normalizeRegion(item, "stem")).filter(Boolean);
  if (row.image) {
    const image = normalizeRegion(row.image, "stem");
    if (image) regions.push(image);
  }
  return {
    question_number: number(row.question_number ?? row.number ?? row.id),
    question_page: number(row.question_page ?? row.page ?? row.pdf_page),
    question_text: String(row.question_text ?? row.text ?? row.stem ?? "").trim(),
    options: Array.from(row.options ?? row.choices ?? []).map((option) => typeof option === "string" ? option.trim() : String(option?.text ?? "").trim()),
    media_regions: regions,
    review_notes: Array.from(row.review_notes ?? row.notes ?? []),
  };
}

function normalizeSolution(row) {
  const media = row.media_regions ?? row.media ?? [];
  return {
    question_number: number(row.question_number ?? row.number ?? row.id),
    solution_page: number(row.solution_page ?? row.page ?? row.pdf_page),
    solution_text: String(row.solution_text ?? row.classic_solution ?? row.solution ?? row.text ?? row.question_text ?? "").trim(),
    stated_correct_option: number(row.stated_correct_option ?? row.correct_option ?? row.answer),
    media_regions: (Array.isArray(media) ? media : [media]).map((item) => normalizeRegion(item, "solution")).filter(Boolean),
    review_notes: Array.from(row.review_notes ?? row.notes ?? []),
  };
}

fs.mkdirSync(output, { recursive: true });
const files = fs.existsSync(input) ? fs.readdirSync(input).filter((file) => file.endsWith(".json")) : [];
const report = [];
for (const file of files) {
  const taskId = path.basename(file, ".json");
  const kind = taskId.includes("answer-key") ? "answer_key" : taskId.includes("solutions") ? "solutions" : "questions";
  const data = JSON.parse(fs.readFileSync(path.join(input, file), "utf8"));
  let normalized;
  if (kind === "questions") normalized = rowsOf(data, kind).map(normalizeQuestion);
  else if (kind === "solutions") normalized = rowsOf(data, kind).map(normalizeSolution);
  else {
    const raw = rowsOf(data, kind);
    normalized = Object.fromEntries(
      (Array.isArray(raw) ? raw.map((row) => [row.question_number ?? row.number, row.correct_option_index ?? row.option ?? row.answer]) : Object.entries(raw))
        .map(([key, value]) => [number(key), number(value)])
        .filter(([key, value]) => Number.isInteger(key) && value >= 1 && value <= 4),
    );
  }
  fs.writeFileSync(path.join(output, file), `${JSON.stringify(normalized, null, 2)}\n`, "utf8");
  const rows = Array.isArray(normalized) ? normalized.length : Object.keys(normalized).length;
  const invalid = Array.isArray(normalized)
    ? normalized.filter((row) => !row.question_number || (kind === "questions" && (!row.question_text || row.options.length !== 4))).length
    : 0;
  report.push({ task_id: taskId, kind, rows, invalid });
}
fs.writeFileSync(path.join(output, "_report.json"), `${JSON.stringify(report, null, 2)}\n`, "utf8");
console.log(`Normalized ${files.length} Jules artifact(s).`);
report.forEach((row) => console.log(`${row.task_id}: ${row.rows} rows, ${row.invalid} invalid`));
