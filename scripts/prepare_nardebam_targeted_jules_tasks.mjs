#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

const root = "tmp/jules_nardebam_targeted";
const sourceRoot = "tmp/jules_nardebam/tasks";

const tasks = [
  {
    id: "math-solutions-06-limits-1040-1069-focused",
    branch: "codex/nardebam-targeted-limits-1040-1069",
    subject: "math",
    expected_output: "jules_output/math-solutions-06-limits-1040-1069-focused.json",
    images: [
      ["math-solutions-05", "page_0100.jpg"],
      ["math-solutions-06", "page_0101.jpg"],
      ["math-solutions-06", "page_0102.jpg"],
      ["math-solutions-06", "page_0103.jpg"],
      ["math-solutions-06", "page_0104.jpg"],
      ["math-solutions-06", "page_0105.jpg"],
    ],
    prompt: `Extract only printed explanatory solution blocks for math questions 1040 through 1069.

Create exactly jules_output/math-solutions-06-limits-1040-1069-focused.json.
Return UTF-8 JSON with task_id, subject, solutions, and review_notes.
Each solution row must include question_number, solution_page, solution_text, stated_correct_option, media_regions, and review_notes.
Do not invent missing solutions. Do not use placeholder text. If absent, omit that number and explain the inspected page files in review_notes.`,
  },
  {
    id: "math-solutions-06-derivative-1253-focused",
    branch: "codex/nardebam-targeted-derivative-1253",
    subject: "math",
    expected_output: "jules_output/math-solutions-06-derivative-1253-focused.json",
    images: [
      ["math-solutions-06", "page_0116.jpg"],
      ["math-solutions-06", "page_0117.jpg"],
      ["math-solutions-06", "page_0118.jpg"],
      ["math-solutions-06", "page_0119.jpg"],
      ["math-solutions-06", "page_0120.jpg"],
    ],
    prompt: `Extract only the printed explanatory solution block for math question 1253.

Create exactly jules_output/math-solutions-06-derivative-1253-focused.json.
Return UTF-8 JSON with task_id, subject, solutions, and review_notes.
Each solution row must include question_number, solution_page, solution_text, stated_correct_option, media_regions, and review_notes.
Do not invent missing solutions. Do not use placeholder text.`,
  },
  {
    id: "math-solutions-09-geometry-1936-1948-focused",
    branch: "codex/nardebam-targeted-geometry-1936-1948",
    subject: "math",
    expected_output: "jules_output/math-solutions-09-geometry-1936-1948-focused.json",
    images: [
      ["math-solutions-09", "page_0179.jpg"],
      ["math-solutions-09", "page_0180.jpg"],
      ["math-solutions-10", "page_0181.jpg"],
      ["math-solutions-10", "page_0182.jpg"],
    ],
    prompt: `Extract only printed explanatory solution blocks for math questions 1936 through 1948.

Create exactly jules_output/math-solutions-09-geometry-1936-1948-focused.json.
Return UTF-8 JSON with task_id, subject, solutions, and review_notes.
Each solution row must include question_number, solution_page, solution_text, stated_correct_option, media_regions, and review_notes.
Do not invent missing solutions. Do not use placeholder text.`,
  },
  {
    id: "physics-answer-key-119-129-215-220-focused",
    branch: "codex/nardebam-targeted-physics-key-119-220",
    subject: "physics",
    expected_output: "jules_output/physics-answer-key-119-129-215-220-focused.json",
    images: [
      ["physics-answer-key", "page_0342.jpg"],
      ["physics-answer-key", "page_0343.jpg"],
      ["physics-answer-key", "page_0344.jpg"],
      ["physics-answer-key", "page_0345.jpg"],
      ["physics-answer-key", "page_0346.jpg"],
    ],
    prompt: `Extract only printed physics answer-key cells for question numbers 119 through 129 and 215 through 220.

Create exactly jules_output/physics-answer-key-119-129-215-220-focused.json.
Return UTF-8 JSON with task_id, subject, answers, and review_notes.
answers must be an object with ASCII question-number keys and integer option values 1..4.
Never infer a missing or unreadable cell; omit it and explain in review_notes.`,
  },
  {
    id: "math-topic-07-functions-441-608-focused",
    branch: "codex/nardebam-targeted-functions-441-608",
    subject: "math",
    expected_output: "jules_output/math-topic-07-functions-441-608-focused.json",
    images: Array.from({ length: 28 }, (_, index) => ["math-topic-07", `page_${String(index + 1).padStart(4, "0")}.jpg`]),
    prompt: `Extract only numbered four-option math function questions 441 through 608.

Create exactly jules_output/math-topic-07-functions-441-608-focused.json.
Return UTF-8 JSON with task_id, subject, topic_key, questions, and review_notes.
topic_key must be "functions".
Each question must include question_number, question_page, question_text, options (four strings), media_regions, and review_notes.
Do not solve questions. Do not invent absent question text.`,
  },
  {
    id: "math-topic-07-functions-672-704-focused",
    branch: "codex/nardebam-targeted-functions-672-704",
    subject: "math",
    expected_output: "jules_output/math-topic-07-functions-672-704-focused.json",
    images: Array.from({ length: 10 }, (_, index) => ["math-topic-07", `page_${String(index + 35).padStart(4, "0")}.jpg`]),
    prompt: `Extract only numbered four-option math function questions 672 through 704.

Create exactly jules_output/math-topic-07-functions-672-704-focused.json.
Return UTF-8 JSON with task_id, subject, topic_key, questions, and review_notes.
topic_key must be "functions".
Each question must include question_number, question_page, question_text, options (four strings), media_regions, and review_notes.
Do not solve questions. Do not invent absent question text.`,
  },
  {
    id: "math-topic-boundary-1732-1734-focused",
    branch: "codex/nardebam-targeted-boundary-1732-1734",
    subject: "math",
    expected_output: "jules_output/math-topic-boundary-1732-1734-focused.json",
    images: [
      ["math-topic-14", "page_0017.jpg"],
      ["math-topic-14", "page_0018.jpg"],
      ["math-topic-15", "page_0001.jpg"],
      ["math-topic-15", "page_0002.jpg"],
    ],
    prompt: `Extract only numbered four-option math questions 1732, 1733, and 1734.

Create exactly jules_output/math-topic-boundary-1732-1734-focused.json.
Return UTF-8 JSON with task_id, subject, topic_key, questions, and review_notes.
Use topic_key "visual_thinking_conics" if the printed questions belong to the previous visual/conics topic, otherwise "combinatorics" if they belong to the combinatorics topic.
Each question must include question_number, question_page, question_text, options (four strings), media_regions, and review_notes.
Do not solve questions. Do not invent absent question text.`,
  },
];

fs.rmSync(root, { recursive: true, force: true });
fs.mkdirSync(path.join(root, "tasks"), { recursive: true });

for (const task of tasks) {
  const taskDir = path.join(root, "tasks", task.id);
  const imageDir = path.join(taskDir, "images");
  fs.mkdirSync(imageDir, { recursive: true });
  const pages = [];
  for (const [sourceTask, imageName] of task.images) {
    const source = path.join(sourceRoot, sourceTask, "images", imageName);
    const targetName = `${sourceTask}-${imageName}`;
    const target = path.join(imageDir, targetName);
    if (!fs.existsSync(source)) throw new Error(`Missing source image ${source}`);
    fs.copyFileSync(source, target);
    pages.push({ file: targetName, source_task: sourceTask, source_file: imageName });
  }
  const taskJson = {
    id: task.id,
    kind: task.id.includes("answer-key") ? "answer_key" : task.id.includes("topic") ? "questions" : "solutions",
    subject: task.subject,
    branch: task.branch,
    expected_output: task.expected_output,
    pages,
  };
  fs.writeFileSync(path.join(taskDir, "task.json"), `${JSON.stringify(taskJson, null, 2)}\n`, "utf8");
  fs.writeFileSync(path.join(taskDir, "TASK.md"), `${task.prompt}\n`, "utf8");
}

fs.writeFileSync(path.join(root, "tasks.json"), `${JSON.stringify({
  schema_version: 1,
  task_count: tasks.length,
  tasks: tasks.map(({ prompt, images, ...task }) => task),
}, null, 2)}\n`, "utf8");

console.log(`Prepared ${tasks.length} targeted Jules task(s) at ${root}.`);
