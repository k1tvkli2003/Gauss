#!/usr/bin/env node
// Poll a Jules dataset-expansion session without storing API keys in the repo.
// Usage:
//   JULES_API_KEY=... node scripts/jules_dataset_status.mjs sessions/123
//   JULES_API_KEY=... node scripts/jules_dataset_status.mjs 123 --activities=50

const rawSession = process.argv[2];
const activityArg = process.argv.find((arg) => arg.startsWith("--activities="));
const pageSize = Number(activityArg?.split("=")[1] ?? 20);
const key = process.env.JULES_API_KEY;

if (!key) {
  console.error("Missing JULES_API_KEY in the local environment.");
  process.exit(1);
}
if (!rawSession) {
  console.error("Usage: node scripts/jules_dataset_status.mjs <session-id-or-name> [--activities=20]");
  process.exit(1);
}

const session = rawSession.startsWith("sessions/") ? rawSession : `sessions/${rawSession}`;
const base = "https://jules.googleapis.com/v1alpha";
const headers = { "x-goog-api-key": key };

async function getJson(url) {
  const res = await fetch(url, { headers });
  const text = await res.text();
  if (!res.ok) {
    throw new Error(`${res.status} ${res.statusText}: ${text}`);
  }
  return text ? JSON.parse(text) : {};
}

const sessionData = await getJson(`${base}/${session}`);
const activityData = await getJson(`${base}/${session}/activities?pageSize=${pageSize}`);

console.log(JSON.stringify({
  session: {
    name: sessionData.name,
    id: sessionData.id,
    title: sessionData.title,
    state: sessionData.state,
    url: sessionData.url,
    createTime: sessionData.createTime,
    updateTime: sessionData.updateTime,
    outputs: sessionData.outputs ?? [],
  },
  activities: (activityData.activities ?? []).map((activity) => ({
    name: activity.name,
    id: activity.id,
    originator: activity.originator,
    description: activity.description,
    createTime: activity.createTime,
    hasArtifacts: Boolean(activity.artifacts?.length),
    artifacts: activity.artifacts ?? undefined,
  })),
}, null, 2));
