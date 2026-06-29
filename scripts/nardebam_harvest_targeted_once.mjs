#!/usr/bin/env node

import { spawnSync } from "node:child_process";
import fs from "node:fs";

const activeTaskIds = [
  "math-solutions-06-limits-1040-1069-focused",
  "math-solutions-06-derivative-1253-focused",
  "math-solutions-09-geometry-1936-1948-focused",
  "physics-answer-key-119-129-215-220-focused",
  "math-topic-07-functions-441-608-focused",
  "math-topic-07-functions-672-704-focused",
  "math-topic-boundary-1732-1734-focused",
];

const statePath = "tmp/jules_nardebam/repair_sessions.json";
const node = process.execPath;

function run(args, options = {}) {
  const result = spawnSync(node, args, {
    encoding: "utf8",
    ...options,
  });
  return result;
}

function printCommandFailure(label, result) {
  console.error(`${label} failed with exit ${result.status}`);
  if (result.stdout?.trim()) console.error(result.stdout.trim());
  if (result.stderr?.trim()) console.error(result.stderr.trim());
}

const only = activeTaskIds.join(",");
const harvest = run(["scripts/harvest_jules_repairs.mjs", `--only=${only}`], { stdio: "pipe" });
if (harvest.status !== 0) {
  printCommandFailure("harvest", harvest);
  process.exit(harvest.status ?? 1);
}

const state = JSON.parse(fs.readFileSync(statePath, "utf8"));
const active = (state.sessions ?? []).filter((record) => activeTaskIds.includes(record.taskId));
const collected = active.filter((record) => record.status === "collected");
const candidates = [];
const skipped = [];

for (const record of collected) {
  const dryRun = run(["scripts/promote_jules_repairs.mjs", "--dry-run", `--only=${record.taskId}`], { stdio: "pipe" });
  if (dryRun.status !== 0) {
    skipped.push({
      taskId: record.taskId,
      reason: "dry_run_failed",
      detail: `${dryRun.stdout ?? ""}${dryRun.stderr ?? ""}`.trim().split("\n").slice(0, 6),
    });
    continue;
  }
  let parsed;
  try {
    parsed = JSON.parse(dryRun.stdout);
  } catch (error) {
    skipped.push({ taskId: record.taskId, reason: "dry_run_unparseable", detail: error.message });
    continue;
  }
  const useful = (parsed.promoted ?? []).some((item) => {
    if (String(item.mode ?? "").startsWith("skip")) return false;
    if (item.mode === "merge" || item.mode === "merge_topic") return (item.added ?? 0) > 0 || (item.replaced ?? 0) > 0;
    if (item.mode === "merge_answer_key") return (item.added ?? 0) > 0 || (item.replaced ?? 0) > 0;
    return item.rows > 0;
  });
  if (useful) candidates.push(record.taskId);
  else skipped.push({ taskId: record.taskId, reason: "dry_run_no_useful_change", dryRun: parsed.promoted ?? [] });
}

let promoted = null;
if (candidates.length) {
  const promote = run(["scripts/promote_jules_repairs.mjs", `--only=${candidates.join(",")}`], { stdio: "pipe" });
  if (promote.status !== 0) {
    printCommandFailure("promote", promote);
    process.exit(promote.status ?? 1);
  }
  promoted = JSON.parse(promote.stdout.split(/\r?\n(?=Normalized )/)[0]);
  const repairMismatches = run(["scripts/repair_nardebam_solution_key_mismatches.mjs"], { stdio: "pipe" });
  if (repairMismatches.status !== 0) {
    printCommandFailure("repair_mismatches", repairMismatches);
    process.exit(repairMismatches.status ?? 1);
  }
  const normalized = run(["scripts/normalize_nardebam_raw.mjs"], { stdio: "pipe" });
  if (normalized.status !== 0) {
    printCommandFailure("normalize", normalized);
    process.exit(normalized.status ?? 1);
  }
  const joined = spawnSync(node, ["scripts/join_nardebam_source.mjs"], {
    encoding: "utf8",
    stdio: "pipe",
  });
  if (joined.status !== 0 && joined.status !== 1) {
    printCommandFailure("join", joined);
    process.exit(joined.status ?? 1);
  }
}

const progress = run(["scripts/nardebam_progress.mjs"], { stdio: "pipe" });
const progressJson = progress.status === 0 ? JSON.parse(progress.stdout) : null;

console.log(JSON.stringify({
  harvested: JSON.parse(harvest.stdout),
  active: active.map((record) => ({
    taskId: record.taskId,
    status: record.status,
    remoteState: record.remoteState,
    rowCount: record.rowCount,
    terminal: record.terminal,
  })),
  candidates,
  skipped,
  promoted,
  progress: progressJson?.metrics ?? null,
  conflicts: progressJson?.conflicts ?? null,
}, null, 2));
