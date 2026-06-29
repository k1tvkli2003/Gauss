#!/usr/bin/env node
// Quota-aware, resumable Jules scheduler for Nardebam visual extraction tasks.

import fs from "node:fs";
import path from "node:path";

const arg = (name, fallback) => {
  const raw = process.argv.find((item) => item.startsWith(`--${name}=`));
  return raw ? raw.slice(name.length + 3) : fallback;
};

const tasksRoot = arg("tasks-root", "tmp/jules_nardebam");
const reviewDir = arg("review-dir", "data/seed/review/nardebam/raw");
const statePath = arg("state", path.join(tasksRoot, "pipeline_state.json"));
const maxParallel = Number(arg("max-parallel", "15"));
const dailyLimit = Number(arg("daily-limit", "100"));
const pollMs = Number(arg("poll-ms", "30000"));
const selectedArg = arg("tasks", "");
const selected = selectedArg ? new Set(selectedArg.split(",")) : null;
const once = process.argv.includes("--once");
const apiKey = process.env.JULES_API_KEY;
const source = arg("source", "sources/github/yousefnedaei2003/Gauss");
const base = "https://jules.googleapis.com/v1alpha";
const headers = { "content-type": "application/json", "x-goog-api-key": apiKey };
const terminalStates = new Set(["COMPLETED", "AWAITING_USER_FEEDBACK", "FAILED", "CANCELLED"]);

if (!apiKey) throw new Error("JULES_API_KEY is required.");
const taskManifest = JSON.parse(fs.readFileSync(path.join(tasksRoot, "tasks.json"), "utf8"));
const tasks = taskManifest.tasks.filter((task) => !selected || selected.has(task.id));
let state = fs.existsSync(statePath)
  ? JSON.parse(fs.readFileSync(statePath, "utf8"))
  : { schemaVersion: 1, tasks: {} };

function saveState() {
  fs.mkdirSync(path.dirname(statePath), { recursive: true });
  fs.writeFileSync(statePath, `${JSON.stringify(state, null, 2)}\n`, "utf8");
}

async function request(url, options = {}) {
  for (let attempt = 1; attempt <= 4; attempt += 1) {
    try {
      const response = await fetch(url, { ...options, headers: { ...headers, ...(options.headers ?? {}) } });
      const text = await response.text();
      if (!response.ok) {
        const error = new Error(`${response.status} ${response.statusText}: ${text}`);
        error.status = response.status;
        if (response.status < 500 || attempt === 4) throw error;
      } else {
        return text ? JSON.parse(text) : {};
      }
    } catch (error) {
      const transient = !error.status || error.status >= 500;
      if (!transient || attempt === 4) throw error;
      await new Promise((resolve) => setTimeout(resolve, attempt * 1500));
    }
  }
}

async function recentCreatedCount() {
  const data = await request(`${base}/sessions?pageSize=100`, { method: "GET" });
  const cutoff = Date.now() - 24 * 60 * 60 * 1000;
  return (data.sessions ?? []).filter((session) => Date.parse(session.createTime ?? 0) >= cutoff).length;
}

async function createSession(task, attempt) {
  const prompt = [
    "Open and follow jules_input/TASK.md exactly.",
    "The JPEGs in jules_input/images are the only visual source for this isolated task.",
    `Create only ${task.expected_output}; do not edit app code, inputs, or unrelated files.`,
    "For question tasks, every extracted record must include an integer question_number, question_page, non-empty question_text, exactly four non-empty options, media_regions, and review_notes.",
    "Do not return an empty questions array when numbered four-option tests are visible; keep uncertain records and explain uncertainty in review_notes.",
    "Before finishing, parse the JSON yourself and report its record count.",
    attempt > 1 ? "This is a retry: be especially careful about emitting the requested output artifact." : "",
  ].filter(Boolean).join("\n");
  return request(`${base}/sessions`, {
    method: "POST",
    body: JSON.stringify({
      prompt,
      title: `Nardebam ${task.id} attempt ${attempt}`,
      sourceContext: {
        source,
        githubRepoContext: { startingBranch: task.branch },
      },
    }),
  });
}

async function sessionData(name) {
  return request(`${base}/${name}`, { method: "GET" });
}

async function activities(name) {
  return request(`${base}/${name}/activities?pageSize=100`, { method: "GET" });
}

async function nudge(name, task) {
  return request(`${base}/${name}:sendMessage`, {
    method: "POST",
    body: JSON.stringify({
      prompt: `The required ${task.expected_output} artifact is missing. Create that JSON file now, parse-check it, and make no other changes.`,
    }),
  });
}

function extractExpectedJson(patch, expected) {
  const sections = patch.split(/(?=^diff --git )/m).filter(Boolean);
  for (const section of sections) {
    const file = section.match(/^\+\+\+ b\/(.+)$/m)?.[1]?.replaceAll("\\", "/");
    if (file !== expected.replaceAll("\\", "/")) continue;
    const added = section
      .split("\n")
      .filter((line) => line.startsWith("+") && !line.startsWith("+++"))
      .map((line) => line.slice(1))
      .join("\n");
    return JSON.parse(added);
  }
  return null;
}

async function collectArtifact(task, record) {
  const [session, data] = await Promise.all([sessionData(record.session), activities(record.session)]);
  const outputPatches = (session.outputs ?? [])
    .map((output) => ({
      createTime: session.updateTime ?? session.createTime ?? new Date().toISOString(),
      patch: output.changeSet?.gitPatch?.unidiffPatch,
    }));
  const activityPatches = (data.activities ?? [])
    .flatMap((activity) => (activity.artifacts ?? []).map((artifact) => ({
      createTime: activity.createTime,
      patch: artifact.changeSet?.gitPatch?.unidiffPatch,
    })))
  const patches = [...outputPatches, ...activityPatches]
    .filter((item) => item.patch)
    .sort((a, b) => a.createTime.localeCompare(b.createTime));
  for (const item of patches.toReversed()) {
    try {
      const json = extractExpectedJson(item.patch, task.expected_output);
      if (!json) continue;
      fs.mkdirSync(reviewDir, { recursive: true });
      const output = path.join(reviewDir, `${task.id}.json`);
      fs.writeFileSync(output, `${JSON.stringify(json, null, 2)}\n`, "utf8");
      record.artifactTime = item.createTime;
      record.output = output;
      record.status = "collected";
      console.log(`collected ${task.id} -> ${output}`);
      return true;
    } catch (error) {
      record.lastError = `artifact parse: ${error.message}`;
    }
  }
  return false;
}

function taskRecord(task) {
  return state.tasks[task.id] ??= { id: task.id, attempts: 0, status: "pending" };
}

async function tick() {
  let active = 0;
  for (const task of tasks) {
    const record = taskRecord(task);
    if (!record.session || ["collected", "failed"].includes(record.status)) continue;
    let data;
    try {
      data = await sessionData(record.session);
    } catch (error) {
      record.lastError = `session poll: ${error.message}`;
      record.updatedAt = new Date().toISOString();
      if (error.status === 404 && record.attempts < 2) {
        record.session = null;
        record.status = "pending";
        record.nudged = false;
        console.warn(`missing ${task.id} session; queued for retry`);
        continue;
      }
      if (error.status === 404) {
        record.status = "failed";
        console.error(`failed ${task.id}: ${record.lastError}`);
        continue;
      }
      throw error;
    }
    record.remoteState = data.state;
    record.url = data.url;
    record.updatedAt = new Date().toISOString();
    if (!terminalStates.has(data.state)) {
      active += 1;
      continue;
    }
    try {
      if (await collectArtifact(task, record)) continue;
    } catch (error) {
      record.lastError = `artifact fetch: ${error.message}`;
      if (error.status !== 404) throw error;
    }
    if (!record.nudged && ["COMPLETED", "AWAITING_USER_FEEDBACK"].includes(data.state)) {
      try {
        await nudge(record.session, task);
      } catch (error) {
        record.lastError = `nudge: ${error.message}`;
        if (error.status !== 404) throw error;
        record.session = null;
        record.status = record.attempts < 2 ? "pending" : "failed";
        record.nudged = false;
        console.warn(`missing ${task.id} during nudge; ${record.status}`);
        continue;
      }
      record.nudged = true;
      record.status = "active";
      active += 1;
      console.log(`nudged ${task.id}`);
    } else if (record.attempts >= 2) {
      record.status = "failed";
      record.lastError ??= `terminal state ${data.state} without a usable artifact`;
      console.error(`failed ${task.id}: ${record.lastError}`);
    } else {
      record.session = null;
      record.status = "pending";
      record.nudged = false;
    }
  }

  let createdToday = await recentCreatedCount();
  for (const task of tasks) {
    if (active >= maxParallel || createdToday >= dailyLimit) break;
    const record = taskRecord(task);
    if (record.status !== "pending" || record.session) continue;
    record.attempts += 1;
    let created;
    try {
      created = await createSession(task, record.attempts);
    } catch (error) {
      record.attempts -= 1;
      if (String(error.message).includes("FAILED_PRECONDITION")) {
        console.log("Jules global concurrency limit reached; waiting for a slot.");
        break;
      }
      throw error;
    }
    record.session = created.name;
    record.url = created.url;
    record.status = "active";
    record.createdAt = created.createTime ?? new Date().toISOString();
    record.remoteState = created.state;
    active += 1;
    createdToday += 1;
    console.log(`created ${task.id}: ${created.name} ${created.url ?? ""}`);
    saveState();
  }
  saveState();

  const summary = { pending: 0, active: 0, local_active: 0, collected: 0, failed: 0 };
  for (const task of tasks) {
    const status = taskRecord(task).status;
    summary[status] = (summary[status] ?? 0) + 1;
  }
  console.log(JSON.stringify({ ...summary, createdToday, maxParallel, dailyLimit }));
  return summary;
}

while (true) {
  const summary = await tick();
  if (once || summary.pending + summary.active === 0) break;
  if (summary.active === 0 && summary.pending > 0) {
    console.log("No slots available under the daily limit; stopping cleanly for resume later.");
    break;
  }
  await new Promise((resolve) => setTimeout(resolve, pollMs));
}
