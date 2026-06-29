#!/usr/bin/env node
// Promote validated Jules review files into official seeds without duplicating IDs.

import fs from "node:fs";
import path from "node:path";

const reviewDir = "data/seed/review/jules_v2";
const officialDir = "data/seed/official";

if (!fs.existsSync(reviewDir)) throw new Error(`${reviewDir} does not exist.`);
fs.mkdirSync(officialDir, { recursive: true });

let addedTotal = 0;
for (const name of fs.readdirSync(reviewDir).filter((entry) => entry.endsWith(".json")).sort()) {
  const reviewPath = path.join(reviewDir, name);
  const officialPath = path.join(officialDir, name);
  const reviewRows = JSON.parse(fs.readFileSync(reviewPath, "utf8"));
  const officialRows = fs.existsSync(officialPath)
    ? JSON.parse(fs.readFileSync(officialPath, "utf8"))
    : [];

  const seen = new Set(officialRows.map((row) => row.id));
  const additions = reviewRows.filter((row) => !seen.has(row.id));
  if (additions.length) {
    fs.writeFileSync(officialPath, `${JSON.stringify([...officialRows, ...additions], null, 2)}\n`, "utf8");
  }
  addedTotal += additions.length;
  console.log(`${name}: ${officialRows.length} + ${additions.length} = ${officialRows.length + additions.length}`);
}

console.log(`Promoted ${addedTotal} new Jules questions.`);
