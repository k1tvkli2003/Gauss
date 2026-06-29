#!/usr/bin/env node
// Audit the latest JSON patch from a Jules session without writing it locally.

import fs from "node:fs";
import path from "node:path";

const rawSession = process.argv[2];
const key = process.env.JULES_API_KEY;
const writeReview = process.argv.includes("--write-review");
const patchTime = process.argv.find((arg) => arg.startsWith("--patch-time="))?.slice("--patch-time=".length);

if (!key || !rawSession) {
  console.error("Usage: JULES_API_KEY=... node scripts/audit_jules_session.mjs <session-id>");
  process.exit(1);
}

const session = rawSession.startsWith("sessions/") ? rawSession : `sessions/${rawSession}`;
const headers = { "x-goog-api-key": key };
const [response, sessionResponse] = await Promise.all([
  fetch(`https://jules.googleapis.com/v1alpha/${session}/activities?pageSize=100`, { headers }),
  fetch(`https://jules.googleapis.com/v1alpha/${session}`, { headers }),
]);
if (!response.ok) throw new Error(`${response.status} ${await response.text()}`);
if (!sessionResponse.ok) throw new Error(`${sessionResponse.status} ${await sessionResponse.text()}`);

const { activities = [] } = await response.json();
const sessionData = await sessionResponse.json();
const patches = activities
  .flatMap((activity) =>
    (activity.artifacts ?? [])
      .map((artifact) => ({
        createTime: activity.createTime,
        patch: artifact.changeSet?.gitPatch?.unidiffPatch,
      }))
      .filter((item) => item.patch),
  )
  .sort((a, b) => a.createTime.localeCompare(b.createTime));

if (!patches.length) {
  console.log(`${session}: no JSON patch is available yet.`);
  process.exit(0);
}

const latest = patchTime ? patches.find((item) => item.createTime === patchTime) : patches.at(-1);
if (!latest) throw new Error(`No Jules patch found at ${patchTime}.`);
const sections = latest.patch.split(/(?=^diff --git )/m).filter(Boolean);
let totalErrors = 0;
const reviewedFiles = [];

console.log(`${session}: ${sessionData.state}, auditing patch from ${latest.createTime}`);
for (const section of sections) {
  const file = section.match(/^\+\+\+ b\/(.+)$/m)?.[1];
  if (!file?.endsWith(".json")) continue;

  const json = section
    .split("\n")
    .filter((line) => line.startsWith("+") && !line.startsWith("+++"))
    .map((line) => line.slice(1))
    .join("\n");

  let rows;
  try {
    rows = JSON.parse(json);
  } catch (error) {
    console.log(`${file}: invalid JSON: ${error.message}`);
    totalErrors += 1;
    continue;
  }

  const errors = [];
  const ids = new Set();
  const archetypes = new Map();
  for (const [index, row] of rows.entries()) {
    const at = `${file}:${index + 1}`;
    if (!/^[a-z0-9_-]+$/.test(row.id ?? "")) errors.push(`${at} non-ASCII or invalid id`);
    if (ids.has(row.id)) errors.push(`${at} duplicate id ${row.id}`);
    ids.add(row.id);

    const options = [row.option_1, row.option_2, row.option_3, row.option_4].map((value) =>
      String(value ?? "").trim(),
    );
    if (new Set(options).size !== 4) errors.push(`${at} duplicate options`);
    if (!Number.isInteger(row.correct_option_index) || row.correct_option_index < 1 || row.correct_option_index > 4) {
      errors.push(`${at} invalid correct_option_index`);
    }
    for (const option of options) {
      if (option.includes("\\") && !option.includes("$")) errors.push(`${at} unwrapped LaTeX option`);
    }

    const text = [row.question_text, ...options, row.classic_solution, row.smart_shortcut].join("\n");
    if (/[ØÙ]/.test(text)) errors.push(`${at} probable mojibake`);
    if (/[\u0400-\u04ff]/.test(text)) errors.push(`${at} unexpected Cyrillic text`);
    if (String(row.classic_solution ?? "").includes("\\n")) errors.push(`${at} literal escaped newline`);
    const persianDigits = "۰۱۲۳۴۵۶۷۸۹";
    for (const match of String(row.classic_solution ?? "").matchAll(/گزینه\s*([1-4۱-۴])/g)) {
      const referenced = /[1-4]/.test(match[1]) ? Number(match[1]) : persianDigits.indexOf(match[1]);
      if (referenced !== row.correct_option_index) errors.push(`${at} stale option reference ${match[1]}`);
    }

    const normalized = String(row.question_text ?? "")
      .replace(/[0-9۰-۹]+/g, "#")
      .replace(/\s+/g, " ")
      .trim();
    archetypes.set(normalized, (archetypes.get(normalized) ?? 0) + 1);
  }

  const repeated = [...archetypes.entries()]
    .filter(([, count]) => count > 4)
    .sort((a, b) => b[1] - a[1]);
  for (const [stem, count] of repeated) errors.push(`${file} repeated archetype x${count}: ${stem}`);

  totalErrors += errors.length;
  reviewedFiles.push({ file, rows });
  console.log(`${file}: ${rows.length} rows, ${errors.length} structural error(s)`);
  errors.slice(0, 20).forEach((error) => console.log(`- ${error}`));
  if (errors.length > 20) console.log(`- ... ${errors.length - 20} more`);
}

if (totalErrors) {
  process.exitCode = 1;
} else if (writeReview) {
  const terminalStates = new Set(["COMPLETED", "AWAITING_USER_FEEDBACK"]);
  if (!terminalStates.has(sessionData.state)) {
    throw new Error(`Refusing to write an active session in state ${sessionData.state}.`);
  }
  for (const { file, rows } of reviewedFiles) {
    const normalized = file.replaceAll("\\", "/");
    if (!normalized.startsWith("data/seed/review/jules_v2/") || path.extname(normalized) !== ".json") {
      throw new Error(`Refusing unexpected review path: ${file}`);
    }
    fs.mkdirSync(path.dirname(normalized), { recursive: true });
    fs.writeFileSync(normalized, `${JSON.stringify(rows, null, 2)}\n`, "utf8");
    console.log(`Wrote ${normalized}`);
  }
}
