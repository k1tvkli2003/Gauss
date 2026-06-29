#!/usr/bin/env node
import fs from "node:fs";

const apiKey = process.env.JULES_API_KEY;
if (!apiKey) throw new Error("JULES_API_KEY is required.");

const args = Object.fromEntries(
  process.argv
    .slice(2)
    .filter((arg) => arg.startsWith("--") && arg.includes("="))
    .map((arg) => {
      const index = arg.indexOf("=");
      return [arg.slice(2, index), arg.slice(index + 1)];
    }),
);

const statePath = args.state ?? "tmp/jules_nardebam/repair_sessions.json";
const taskId = args["task-id"];
const sessionArg = args.session;
const prompt = args.prompt ?? (args["prompt-file"] ? fs.readFileSync(args["prompt-file"], "utf8") : null);
if (!prompt) throw new Error("Missing --prompt or --prompt-file");

const state = fs.existsSync(statePath)
  ? JSON.parse(fs.readFileSync(statePath, "utf8"))
  : { sessions: [] };
const record = sessionArg
  ? null
  : (state.sessions ?? []).find((item) => item.taskId === taskId);
const session = sessionArg ?? record?.session;
if (!session) throw new Error("Missing --session or valid --task-id");

async function sendWithRetry() {
  let lastError;
  for (let attempt = 1; attempt <= 4; attempt += 1) {
    try {
      const response = await fetch(`https://jules.googleapis.com/v1alpha/${session}:sendMessage`, {
        method: "POST",
        headers: { "content-type": "application/json", "x-goog-api-key": apiKey },
        body: JSON.stringify({ prompt }),
      });
      const text = await response.text();
      if (!response.ok) throw new Error(`${response.status} ${response.statusText}: ${text}`);
      return text ? JSON.parse(text) : {};
    } catch (error) {
      lastError = error;
      await new Promise((resolve) => setTimeout(resolve, attempt * 1500));
    }
  }
  throw lastError;
}

const result = await sendWithRetry();
if (record) {
  record.followups ??= [];
  record.followups.push({ at: new Date().toISOString(), prompt: prompt.slice(0, 500) });
  record.status = "created";
  record.remoteState = "IN_PROGRESS";
  record.updatedAt = new Date().toISOString();
  fs.writeFileSync(statePath, `${JSON.stringify(state, null, 2)}\n`, "utf8");
}

console.log(JSON.stringify({ sent: true, taskId: taskId ?? null, session, result }, null, 2));
