#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";

const normalizedDir = process.argv.find((arg) => arg.startsWith("--normalized-dir="))?.slice(17)
  ?? "data/seed/review/nardebam/normalized";
const conflictsPath = process.argv.find((arg) => arg.startsWith("--conflicts="))?.slice(12)
  ?? "data/seed/review/nardebam/join_conflicts.json";
const sessionsPath = process.argv.find((arg) => arg.startsWith("--sessions="))?.slice(11)
  ?? "tmp/jules_nardebam/repair_sessions.json";

function readJson(file, fallback) {
  if (!fs.existsSync(file)) return fallback;
  return JSON.parse(fs.readFileSync(file, "utf8"));
}

function rowsOf(value) {
  if (Array.isArray(value)) return value;
  return value?.questions ?? value?.solutions ?? value?.rows ?? [];
}

function answerCount(value) {
  if (!value || typeof value !== "object") return 0;
  if (value.answers && typeof value.answers === "object") return Object.keys(value.answers).length;
  if (!Array.isArray(value)) return Object.keys(value).filter((key) => /^\d+$/.test(key)).length;
  return value.length;
}

function countRows(prefix) {
  if (!fs.existsSync(normalizedDir)) return 0;
  return fs.readdirSync(normalizedDir)
    .filter((file) => file.startsWith(prefix) && file.endsWith(".json"))
    .reduce((total, file) => total + rowsOf(readJson(path.join(normalizedDir, file), [])).length, 0);
}

function pct(count, target) {
  return Math.round((count / target) * 1000) / 10;
}

const metrics = {
  math_questions: { count: countRows("math-topic-"), target: 2042 },
  math_solutions: { count: countRows("math-solutions-"), target: 2042 },
  physics_questions: { count: countRows("physics-topic-"), target: 1630 },
  physics_solutions: { count: countRows("physics-solutions-"), target: 1630 },
  math_answer_key: { count: answerCount(readJson(path.join(normalizedDir, "math-answer-key.json"), {})), target: 2042 },
  physics_answer_key: { count: answerCount(readJson(path.join(normalizedDir, "physics-answer-key.json"), {})), target: 1630 },
};

metrics.total_transcripts = {
  count: metrics.math_questions.count + metrics.physics_questions.count,
  target: metrics.math_questions.target + metrics.physics_questions.target,
};
metrics.total_solutions = {
  count: metrics.math_solutions.count + metrics.physics_solutions.count,
  target: metrics.math_solutions.target + metrics.physics_solutions.target,
};
metrics.total_answer_keys = {
  count: metrics.math_answer_key.count + metrics.physics_answer_key.count,
  target: metrics.math_answer_key.target + metrics.physics_answer_key.target,
};

for (const value of Object.values(metrics)) value.pct = pct(value.count, value.target);

const conflicts = readJson(conflictsPath, []);
const byIssue = {};
for (const conflict of conflicts) {
  const issues = conflict.issues ?? [conflict.issue ?? "unknown"];
  const key = issues.join("+");
  byIssue[key] = (byIssue[key] ?? 0) + 1;
}

const sessions = readJson(sessionsPath, { sessions: [] }).sessions ?? [];
const jules = {};
for (const session of sessions) {
  const key = `${session.terminal ? "terminal" : session.remoteState ?? session.status ?? "new"}|${session.status ?? "none"}`;
  jules[key] = (jules[key] ?? 0) + 1;
}

console.log(JSON.stringify({
  generated_at: new Date().toISOString(),
  metrics,
  conflicts: {
    total: conflicts.length,
    by_issue: byIssue,
  },
  jules_sessions: {
    total: sessions.length,
    by_state: jules,
    latest: sessions.slice(-8).map((session) => ({
      taskId: session.taskId,
      status: session.status,
      remoteState: session.remoteState,
      url: session.url,
    })),
  },
}, null, 2));
