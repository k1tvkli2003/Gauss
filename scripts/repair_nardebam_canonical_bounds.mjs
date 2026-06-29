#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

const RAW = "data/seed/review/nardebam/raw";
const LIMITS = { math: 2042, physics: 1630 };
const removed = [];

function write(file, value) {
  fs.writeFileSync(file, `${JSON.stringify(value, null, 2)}\n`, "utf8");
}

for (const [subject, limit] of Object.entries(LIMITS)) {
  for (const name of fs.readdirSync(RAW).filter((name) =>
    (name.startsWith(`${subject}-topic-`) || name.startsWith(`${subject}-solutions-`)) && name.endsWith(".json")
  )) {
    const file = path.join(RAW, name);
    const root = JSON.parse(fs.readFileSync(file, "utf8"));
    const field = Array.isArray(root) ? "__array" : Array.isArray(root.questions) ? "questions" : Array.isArray(root.solutions) ? "solutions" : null;
    if (!field) continue;
    const before = field === "__array" ? root : root[field];
    const next = before.filter((row) => {
      const number = Number(row.question_number);
      const inBounds = Number.isInteger(number) && number >= 1 && number <= limit;
      const wrongBoundaryTopic = name === "math-topic-15.json" && number >= 1732 && number <= 1734;
      if (!inBounds || wrongBoundaryTopic) removed.push({ file: name, question_number: number });
      return inBounds && !wrongBoundaryTopic;
    });
    if (next.length !== before.length) {
      if (field === "__array") write(file, next);
      else {
        root[field] = next;
        write(file, root);
      }
    }
  }

  const keyFile = path.join(RAW, `${subject}-answer-key.json`);
  const keyRoot = JSON.parse(fs.readFileSync(keyFile, "utf8"));
  for (const key of Object.keys(keyRoot.answers)) {
    const number = Number(key);
    if (!Number.isInteger(number) || number < 1 || number > limit) {
      removed.push({ file: path.basename(keyFile), question_number: key });
      delete keyRoot.answers[key];
    }
  }
  write(keyFile, keyRoot);
}

console.log(JSON.stringify({ removed: removed.length, rows: removed }, null, 2));
