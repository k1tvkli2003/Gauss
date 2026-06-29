#!/usr/bin/env node

import fs from "node:fs";

const file = "data/seed/review/nardebam/raw/physics-topic-01.json";
const root = JSON.parse(fs.readFileSync(file, "utf8"));
const rows = root.questions ?? root;
const repairs = new Map([
  [48, [175, 1435, 510, 1690, "نمودار جرم بر حسب حجم اجسام A و B"]],
  [49, [150, 1700, 860, 2035, "نمودارهای جرم-حجم سه مایع و ظرف استوانه‌ای"]],
  [50, [150, 2030, 540, 2325, "نمودار حجم بر حسب جرم مایعات A و B و مخلوط C"]],
]);

for (const row of rows) {
  const number = Number(row.question_number);
  const repair = repairs.get(number);
  if (!repair) continue;
  const [left, top, right, bottom, alt] = repair;
  row.question_page = 13;
  row.media_regions = [{
    page_file: "page_0013.jpg",
    box: [left, top, right, bottom],
    box_format: "xyxy",
    placement: "stem",
    alt,
  }];
}

const found = rows.filter((row) => repairs.has(Number(row.question_number))).length;
if (found !== repairs.size) throw new Error(`Expected ${repairs.size} rows, found ${found}`);
fs.writeFileSync(file, `${JSON.stringify(root, null, 2)}\n`, "utf8");
console.log(`Repaired question media for physics 48-50 in ${file}`);
