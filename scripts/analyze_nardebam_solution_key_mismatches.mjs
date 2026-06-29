#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

const conflictsFile = process.argv.find((arg) => arg.startsWith("--conflicts="))?.slice(12) ?? "data/seed/review/nardebam/join_conflicts.json";
const normalizedDir = process.argv.find((arg) => arg.startsWith("--normalized="))?.slice(13) ?? "data/seed/review/nardebam/normalized";
const outputFile = process.argv.find((arg) => arg.startsWith("--output="))?.slice(9) ?? "data/seed/review/nardebam/agent_reports/current_solution_key_mismatch_report.json";

const readJson = (file) => JSON.parse(fs.readFileSync(file, "utf8"));
const exists = (file) => fs.existsSync(file);

const stop = new Set([
  "اگر",
  "باشد",
  "کدام",
  "گزینه",
  "است",
  "را",
  "در",
  "به",
  "از",
  "و",
  "با",
  "برای",
  "حل",
  "چند",
  "عدد",
  "صورت",
  "می",
  "شود",
  "شده",
  "خواهیم",
  "داریم",
  "نتیجه",
  "بنابراین",
]);

function normalizeText(value) {
  return String(value ?? "")
    .replace(/[۰-۹]/g, (d) => "۰۱۲۳۴۵۶۷۸۹".indexOf(d))
    .replace(/[٠-٩]/g, (d) => "٠١٢٣٤٥٦٧٨٩".indexOf(d))
    .replace(/\\[a-zA-Z]+/g, " ")
    .replace(/[{}()[\]_$^=+\-*/.,;:؟?!<>|،؛]/g, " ")
    .replace(/\s+/g, " ")
    .trim()
    .toLowerCase();
}

function tokens(value) {
  return normalizeText(value)
    .split(" ")
    .filter((token) => token.length > 1 && !stop.has(token));
}

function overlap(question, solution) {
  const qTokens = new Set(tokens(question).slice(0, 120));
  const sTokens = new Set(tokens(solution).slice(0, 220));
  if (!qTokens.size || !sTokens.size) return 0;
  let hits = 0;
  for (const token of qTokens) if (sTokens.has(token)) hits += 1;
  return Number((hits / qTokens.size).toFixed(3));
}

function contiguousRanges(numbers) {
  const sorted = [...new Set(numbers)].sort((a, b) => a - b);
  const ranges = [];
  for (const n of sorted) {
    const last = ranges.at(-1);
    if (last && n === last.end + 1) {
      last.end = n;
      last.count += 1;
    } else {
      ranges.push({ start: n, end: n, count: 1 });
    }
  }
  return ranges;
}

function sampleText(value, max = 180) {
  const oneLine = String(value ?? "").replace(/\s+/g, " ").trim();
  return oneLine.length > max ? `${oneLine.slice(0, max - 1)}...` : oneLine;
}

function qualityBand(value) {
  if (value >= 0.45) return "high_text_overlap";
  if (value >= 0.2) return "medium_text_overlap";
  if (value > 0) return "low_text_overlap";
  return "zero_text_overlap";
}

function julesPrompt(group) {
  const rangeText = group.ranges.map((range) => range.start === range.end ? `${range.start}` : `${range.start}-${range.end}`).join(", ");
  const band = qualityBand(group.avg_overlap);
  const sourceHint = band === "high_text_overlap"
    ? "These look like answer-label/key disagreements; verify against the printed answer badge and do not rewrite matching solution text unless the badge was OCRed incorrectly."
    : "These likely include wrong or shifted solution attachments; inspect the question pages and solution pages together before changing any stated_correct_option.";
  return [
    `Repair Nardebam ${group.subject} ${group.topic_key} solution_key_mismatch rows ${rangeText} in ${group.source_file}.`,
    sourceHint,
    `For each row, confirm the printed correct option, ensure solution_text actually solves the same question, then return a narrow Jules repair JSON for only these question_numbers. Preserve media_regions when still valid and add review_notes for any source ambiguity.`,
  ].join(" ");
}

function rowScore(row) {
  return String(row.solution_text ?? "").trim().length +
    (Array.isArray(row.media_regions) ? row.media_regions.length * 40 : 0) +
    (Number.isInteger(row.stated_correct_option) && row.stated_correct_option >= 1 ? 20 : 0);
}

function collectSolutionsBySubject() {
  const bySubject = new Map();
  if (!exists(normalizedDir)) return bySubject;
  for (const file of fs.readdirSync(normalizedDir).filter((item) => /-solutions-.*\.json$/.test(item))) {
    const subject = file.split("-")[0];
    const rows = readJson(path.join(normalizedDir, file));
    for (const row of rows) {
      if (!Number.isInteger(row.question_number)) continue;
      const subjectMap = bySubject.get(subject) ?? new Map();
      const list = subjectMap.get(row.question_number) ?? [];
      list.push({ ...row, _file: file, _score: rowScore(row) });
      subjectMap.set(row.question_number, list);
      bySubject.set(subject, subjectMap);
    }
  }
  return bySubject;
}

function detectLocalFixCandidates(conflicts, solutionsBySubject) {
  const duplicateSolutions = conflicts
    .filter((conflict) => conflict.issue === "duplicate_solution")
    .map((conflict) => {
      const rows = solutionsBySubject.get(conflict.subject)?.get(conflict.question_number) ?? [];
      const sorted = [...rows].sort((a, b) => b._score - a._score);
      const weaker = sorted.slice(1);
      const hasEmptyDuplicate = weaker.some((row) => !String(row.solution_text ?? "").trim());
      return {
        subject: conflict.subject,
        question_number: conflict.question_number,
        files: conflict.files,
        row_count: rows.length,
        preferred_row: sorted[0] ? {
          file: sorted[0]._file,
          stated_correct_option: sorted[0].stated_correct_option,
          solution_text_preview: sampleText(sorted[0].solution_text),
          score: sorted[0]._score,
        } : null,
        weaker_rows: weaker.map((row) => ({
          file: row._file,
          stated_correct_option: row.stated_correct_option,
          has_solution_text: Boolean(String(row.solution_text ?? "").trim()),
          media_region_count: row.media_regions?.length ?? 0,
          review_notes: row.review_notes ?? [],
          score: row._score,
        })),
        recommendation: hasEmptyDuplicate
          ? "Low-risk cleanup candidate: remove or merge the empty continuation duplicate in its local/raw source only after confirming the source part that created it. This does not repair a solution_key_mismatch by itself."
          : "Needs source review before deletion because duplicate rows both carry solution content.",
      };
    });

  return { duplicate_solutions: duplicateSolutions };
}

const conflicts = readJson(conflictsFile);
const mismatchRows = conflicts.filter((conflict) => (conflict.issues ?? []).includes("solution_key_mismatch"));
const solutionsBySubject = collectSolutionsBySubject();

const enriched = mismatchRows.map((conflict) => {
  const textOverlap = overlap(conflict.question?.question_text, conflict.solution?.solution_text);
  return {
    subject: conflict.subject,
    topic_key: conflict.topic_key,
    question_number: conflict.question_number,
    source_file: conflict.solution?._file ?? null,
    key_correct: conflict.correct ?? null,
    solution_stated_correct_option: conflict.solution?.stated_correct_option ?? null,
    overlap: textOverlap,
    overlap_band: qualityBand(textOverlap),
    question_page: conflict.question?.question_page ?? null,
    solution_page: conflict.solution?.solution_page ?? null,
    question_text_preview: sampleText(conflict.question?.question_text),
    solution_text_preview: sampleText(conflict.solution?.solution_text),
  };
});

const groupedMap = new Map();
for (const row of enriched) {
  const key = `${row.subject}|${row.topic_key}|${row.source_file}`;
  const group = groupedMap.get(key) ?? {
    subject: row.subject,
    topic_key: row.topic_key,
    source_file: row.source_file,
    count: 0,
    question_numbers: [],
    overlaps: [],
    overlap_bands: {},
    samples: [],
  };
  group.count += 1;
  group.question_numbers.push(row.question_number);
  group.overlaps.push(row.overlap);
  group.overlap_bands[row.overlap_band] = (group.overlap_bands[row.overlap_band] ?? 0) + 1;
  if (group.samples.length < 4) group.samples.push(row);
  groupedMap.set(key, group);
}

const grouped_mismatches = [...groupedMap.values()]
  .map((group) => {
    const avg = group.overlaps.reduce((sum, item) => sum + item, 0) / group.overlaps.length;
    const result = {
      subject: group.subject,
      topic_key: group.topic_key,
      source_file: group.source_file,
      count: group.count,
      ranges: contiguousRanges(group.question_numbers),
      avg_overlap: Number(avg.toFixed(3)),
      overlap_bands: group.overlap_bands,
      sample_question_numbers: group.question_numbers.slice(0, 10),
      samples: group.samples,
    };
    result.jules_prompt = julesPrompt(result);
    return result;
  })
  .sort((a, b) => b.count - a.count || a.subject.localeCompare(b.subject) || a.topic_key.localeCompare(b.topic_key));

const top_jules_repair_tasks = grouped_mismatches.slice(0, 8).map((group, index) => ({
  priority: index + 1,
  subject: group.subject,
  topic_key: group.topic_key,
  source_file: group.source_file,
  count: group.count,
  ranges: group.ranges,
  avg_overlap: group.avg_overlap,
  prompt: group.jules_prompt,
}));

const issueCounts = {};
for (const conflict of conflicts) {
  for (const issue of conflict.issues ?? [conflict.issue]) issueCounts[issue] = (issueCounts[issue] ?? 0) + 1;
}

const report = {
  generated_at: new Date().toISOString(),
  scope: {
    conflicts_file: conflictsFile,
    normalized_dir: normalizedDir,
    output_file: outputFile,
    raw_or_normalized_files_edited: false,
  },
  summary: {
    total_join_conflicts: conflicts.length,
    issue_counts: issueCounts,
    solution_key_mismatch_count: mismatchRows.length,
    grouped_solution_key_mismatch_count: grouped_mismatches.length,
    top_group_share: grouped_mismatches.slice(0, 8).reduce((sum, group) => sum + group.count, 0),
  },
  grouped_mismatches,
  low_risk_local_fix_candidates: detectLocalFixCandidates(conflicts, solutionsBySubject),
  top_jules_repair_tasks,
  intentionally_not_changed: [
    "Did not overwrite answer keys from solution.stated_correct_option globally; low-overlap ranges show wrong or shifted solution attachments.",
    "Did not edit raw or normalized source rows from this analysis script.",
    "Did not touch app UI or generated app assets.",
  ],
};

fs.mkdirSync(path.dirname(outputFile), { recursive: true });
fs.writeFileSync(outputFile, `${JSON.stringify(report, null, 2)}\n`, "utf8");

console.log(`Analyzed ${mismatchRows.length} solution_key_mismatch conflict(s) in ${grouped_mismatches.length} group(s).`);
console.log(`Top 8 groups cover ${report.summary.top_group_share} mismatch conflict(s).`);
console.log(`Wrote ${outputFile}`);
