#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";

const apiKey = process.env.JULES_API_KEY;
if (!apiKey) throw new Error("JULES_API_KEY is required.");

const statePath = process.argv.find((arg) => arg.startsWith("--state="))?.slice(8)
  ?? process.argv.find((arg) => !arg.startsWith("--") && arg !== process.argv[0] && arg !== process.argv[1])
  ?? "tmp/jules_nardebam/repair_sessions.json";
const outDir = process.argv.find((arg) => arg.startsWith("--out-dir="))?.slice(10)
  ?? "data/seed/review/nardebam/jules_repairs";
const only = new Set(process.argv.filter((arg) => arg.startsWith("--only=")).flatMap((arg) => arg.slice(7).split(",")));
const base = "https://jules.googleapis.com/v1alpha";
const headers = { "x-goog-api-key": apiKey };
const terminalStates = new Set(["COMPLETED", "AWAITING_USER_FEEDBACK", "FAILED", "CANCELLED"]);

function readJson(file) {
  return JSON.parse(fs.readFileSync(file, "utf8"));
}

async function request(pathname) {
  const response = await fetch(`${base}/${pathname}`, { headers });
  const text = await response.text();
  if (!response.ok) throw new Error(`${response.status} ${response.statusText}: ${text}`);
  return text ? JSON.parse(text) : {};
}

function extractExpectedJson(patch, expected) {
  const normalizedExpected = expected.replaceAll("\\", "/");
  const sections = patch.split(/(?=^diff --git )/m).filter(Boolean);
  for (const section of sections) {
    const file = section.match(/^\+\+\+ b\/(.+)$/m)?.[1]?.replaceAll("\\", "/");
    if (file !== normalizedExpected) continue;
    const added = section
      .split("\n")
      .filter((line) => line.startsWith("+") && !line.startsWith("+++"))
      .map((line) => line.slice(1))
      .join("\n");
    return JSON.parse(added);
  }
  return null;
}

function rowCountOf(json) {
  const rows = Array.isArray(json) ? json : (json.questions ?? json.solutions ?? json.rows ?? []);
  if (rows.length) return rows.length;
  const answers = json.answers && typeof json.answers === "object" ? Object.keys(json.answers).length : 0;
  return answers;
}

async function collect(sessionRecord) {
  const [session, activityData] = await Promise.all([
    request(sessionRecord.session),
    request(`${sessionRecord.session}/activities?pageSize=100`).catch((error) => {
      sessionRecord.activityError = error.message;
      return {};
    }),
  ]);
  sessionRecord.remoteState = session.state;
  sessionRecord.updatedAt = new Date().toISOString();
  sessionRecord.url = session.url ?? sessionRecord.url;

  const outputPatches = (session.outputs ?? [])
    .map((output) => ({
      createTime: session.updateTime ?? session.createTime ?? "",
      patch: output.changeSet?.gitPatch?.unidiffPatch,
    }));
  const activityPatches = (activityData.activities ?? [])
    .flatMap((activity) => (activity.artifacts ?? []).map((artifact) => ({
      createTime: activity.createTime ?? "",
      patch: artifact.changeSet?.gitPatch?.unidiffPatch,
    })));
  const patches = [...outputPatches, ...activityPatches]
    .filter((item) => item.patch)
    .sort((a, b) => String(a.createTime).localeCompare(String(b.createTime)));
  for (const patch of patches.toReversed()) {
    const json = extractExpectedJson(patch.patch, sessionRecord.expected_output);
    if (!json) continue;
    fs.mkdirSync(outDir, { recursive: true });
    const outputPath = path.join(outDir, `${sessionRecord.taskId}.json`);
    const rows = rowCountOf(json);
    if (fs.existsSync(outputPath) && sessionRecord.rowCount && rows < sessionRecord.rowCount) {
      sessionRecord.lastSkippedArtifact = {
        reason: "shorter_than_existing",
        existingRows: sessionRecord.rowCount,
        candidateRows: rows,
        createTime: patch.createTime,
      };
      continue;
    }
    fs.writeFileSync(outputPath, `${JSON.stringify(json, null, 2)}\n`, "utf8");
    sessionRecord.status = "collected";
    sessionRecord.output = outputPath;
    sessionRecord.artifactTime = patch.createTime;
    sessionRecord.terminal = terminalStates.has(session.state);
    sessionRecord.rowCount = rows;
    return true;
  }

  if (!terminalStates.has(session.state)) return false;

  if (session.state === "FAILED" || session.state === "CANCELLED") {
    sessionRecord.status = "failed";
  } else {
    sessionRecord.status = "terminal_without_artifact";
  }
  return false;
}

const state = readJson(statePath);
let collected = 0;
for (const record of state.sessions ?? []) {
  if (only.size && !only.has(record.taskId)) continue;
  if (record.status === "collected" && record.terminal) continue;
  try {
    if (await collect(record)) collected += 1;
  } catch (error) {
    record.lastError = error.message;
    record.updatedAt = new Date().toISOString();
  }
}

fs.writeFileSync(statePath, `${JSON.stringify(state, null, 2)}\n`, "utf8");
const counts = {};
for (const record of state.sessions ?? []) {
  const key = record.status ?? record.remoteState ?? "created";
  counts[key] = (counts[key] ?? 0) + 1;
}
console.log(JSON.stringify({ collectedNow: collected, counts }, null, 2));
