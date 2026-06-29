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

const required = ["task-id", "branch", "expected-output"];
for (const name of required) {
  if (!args[name]) throw new Error(`Missing --${name}`);
}
if (!args["prompt-file"] && !args.prompt) throw new Error("Missing --prompt-file or --prompt");

const statePath = args.state ?? "tmp/jules_nardebam/repair_sessions.json";
const source = args.source ?? "sources/github/yousefnedaei2003/Gauss";
const base = "https://jules.googleapis.com/v1alpha";
const headers = { "content-type": "application/json", "x-goog-api-key": apiKey };
const state = fs.existsSync(statePath)
  ? JSON.parse(fs.readFileSync(statePath, "utf8"))
  : { sessions: [] };

if (state.sessions?.some((session) => session.taskId === args["task-id"])) {
  console.log(JSON.stringify({ skipped: true, reason: "task_exists", taskId: args["task-id"] }, null, 2));
  process.exit(0);
}

const prompt = args.prompt ?? fs.readFileSync(args["prompt-file"], "utf8");
async function createWithRetry() {
  let lastError;
  for (let attempt = 1; attempt <= 4; attempt += 1) {
    try {
      const response = await fetch(`${base}/sessions`, {
        method: "POST",
        headers,
        body: JSON.stringify({
          prompt,
          title: args.title ?? `Nardebam repair ${args["task-id"]}`,
          sourceContext: {
            source,
            githubRepoContext: { startingBranch: args.branch },
          },
        }),
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

const created = await createWithRetry();

state.sessions ??= [];
state.sessions.push({
  taskId: args["task-id"],
  branch: args.branch,
  session: created.name,
  url: created.url,
  createdAt: created.createTime ?? new Date().toISOString(),
  status: "created",
  expected_output: args["expected-output"],
  ranges: args.ranges ?? "",
  remoteState: created.state,
});

fs.writeFileSync(statePath, `${JSON.stringify(state, null, 2)}\n`, "utf8");
console.log(JSON.stringify({
  created: true,
  taskId: args["task-id"],
  session: created.name,
  url: created.url,
  state: created.state,
}, null, 2));
