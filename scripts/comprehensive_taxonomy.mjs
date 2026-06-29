import fs from "node:fs";

const manifest = JSON.parse(fs.readFileSync("data/nardebam/topic_manifest.json", "utf8"));

export const topicRows = Object.entries(manifest.books).flatMap(([subject, book]) =>
  book.topics.map((topic) => ({ subject, ...topic })),
);

export const topicsBySubject = new Map(
  Object.entries(manifest.books).map(([subject, book]) => [subject, book.topics]),
);

const valid = new Set(topicRows.map((topic) => `${topic.subject}|${topic.key}`));

export function isValidTopic(subject, topicKey) {
  return valid.has(`${subject}|${topicKey}`);
}

export function topicLabel(subject, topicKey) {
  return topicRows.find((topic) => topic.subject === subject && topic.key === topicKey)?.label ?? topicKey;
}

export { manifest };
