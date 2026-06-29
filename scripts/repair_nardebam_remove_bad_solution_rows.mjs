#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

const rawDir = "data/seed/review/nardebam/raw";
const removals = [
  {
    file: "math-solutions-09.json",
    numbers: [1771],
    reason: "solution text belongs to a different combinatorics question",
  },
];

let removed = 0;

for (const item of removals) {
  const fullPath = path.join(rawDir, item.file);
  const json = JSON.parse(fs.readFileSync(fullPath, "utf8"));
  const rows = Array.isArray(json) ? json : (json.solutions ?? json.rows ?? []);
  const before = rows.length;
  const numberSet = new Set(item.numbers);
  const filtered = rows.filter((row) => !numberSet.has(Number(row.question_number)));
  removed += before - filtered.length;

  const output = Array.isArray(json)
    ? filtered
    : Array.isArray(json.solutions)
      ? { ...json, solutions: filtered }
      : { ...json, rows: filtered };

  fs.writeFileSync(fullPath, `${JSON.stringify(output, null, 2)}\n`, "utf8");
  console.log(`${item.file}: removed ${before - filtered.length} row(s): ${item.reason}`);
}

console.log(`Removed ${removed} bad solution row(s).`);
