#!/usr/bin/env python3
"""Derive flutter_app/assets/curriculum/subtopic_index_v1.json.

Links every shipped source question to its screened registry subtopic
("unit") using the frozen taxonomy and the certification manifest. The app
uses it to show Part > Chapter > Unit without re-cutting the five-question
lessons, so saved progress and lesson keys are untouched.

    python3 scripts/build_subtopic_index.py          # write the asset
    python3 scripts/build_subtopic_index.py --check  # fail if it is stale
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TAXONOMY = ROOT / "data/certification/v1/taxonomy.json"
MANIFEST = ROOT / "data/certification/v1/manifest.jsonl"
INDEX = ROOT / "flutter_app/assets/question_bank/index.json"
OUT = ROOT / "flutter_app/assets/curriculum/subtopic_index_v1.json"


def build() -> str:
    taxonomy = json.loads(TAXONOMY.read_text(encoding="utf-8"))
    topic_order = [t["topic_key"] for t in json.loads(INDEX.read_text())["topics"]]
    by_question = {}
    for line in MANIFEST.read_text(encoding="utf-8").splitlines():
        if line.strip():
            row = json.loads(line)
            by_question[row["question_id"]] = row["taxonomy"]
    # Screened questions without a registry subtopic are not guessed into one;
    # they sit in an explicit per-chapter "Mixed problems" unit.
    def unit_key(tax):
        return tax.get("subtopic_key") or f"{tax['topic_key']}__mixed"

    counts = {}
    for tax in by_question.values():
        counts[unit_key(tax)] = counts.get(unit_key(tax), 0) + 1
    units = [
        {
            "key": s["key"],
            "topic_key": s["topic_key"],
            "label": s["label_en"],
            "order": s["order"],
        }
        for s in sorted(
            taxonomy["subtopics"],
            key=lambda s: (topic_order.index(s["topic_key"]), s["order"]),
        )
        if counts.get(s["key"])
    ]
    for topic_key in topic_order:
        if counts.get(f"{topic_key}__mixed"):
            units.append(
                {
                    "key": f"{topic_key}__mixed",
                    "topic_key": topic_key,
                    "label": "Mixed problems",
                    "order": 1000,
                }
            )
    units.sort(key=lambda u: (topic_order.index(u["topic_key"]), u["order"]))
    index_of = {u["key"]: i for i, u in enumerate(units)}
    payload = {
        "schema_version": 1,
        "taxonomy_version": taxonomy["version"],
        "units": units,
        # question id -> index into `units`
        "question_unit": {
            qid: index_of[unit_key(tax)]
            for qid, tax in sorted(by_question.items())
        },
    }
    return json.dumps(payload, ensure_ascii=False, separators=(",", ":")) + "\n"


if __name__ == "__main__":
    text = build()
    if "--check" in sys.argv:
        if not OUT.exists() or OUT.read_text(encoding="utf-8") != text:
            sys.exit("subtopic_index_v1.json is stale; run scripts/build_subtopic_index.py")
        print("subtopic index is current")
    else:
        OUT.write_text(text, encoding="utf-8")
        print(f"wrote {OUT.relative_to(ROOT)} ({len(text) // 1024} KB)")
