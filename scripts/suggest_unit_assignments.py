#!/usr/bin/env python3
"""Suggest registry units for screened questions that have none (review aid).

Nothing here changes the corpus or the plan. For each unclassified question it
finds the most similar already-reviewed questions of the same chapter (shared
proposed-tag vocabulary) and reports a suggested unit with its similarity and
vote share. Leave-one-out on reviewed questions measured the rule at about 96%
precision for similarity >= 0.4 and vote share >= 0.8 (20% coverage), which is
not good enough to apply automatically; a reviewer must confirm each one.

    python3 -I scripts/suggest_unit_assignments.py
"""
import collections
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MANIFEST = ROOT / "data/certification/v1/manifest.jsonl"
OUT = ROOT / "docs/anti-slop/unit-suggestions.json"
MIN_SIM, MIN_SHARE, K = 0.4, 0.8, 5


def feat(t):
    f = {"c:" + x for x in t.get("proposed_concept_tags") or []}
    f |= {"s:" + x for x in t.get("proposed_secondary_concepts") or []}
    f |= {"p:" + x for x in t.get("proposed_prerequisites") or []}
    key = (t.get("proposed_subtopic") or {}).get("key")
    if key:
        f.add("k:" + key)
    return f


rows = [json.loads(l) for l in MANIFEST.read_text(encoding="utf-8").splitlines() if l.strip()]
reviewed = collections.defaultdict(list)
for r in rows:
    t = r["taxonomy"]
    if t.get("subtopic_key"):
        reviewed[t["topic_key"]].append((t["subtopic_key"], feat(t)))

suggestions, none = [], 0
for r in rows:
    t = r["taxonomy"]
    if t.get("subtopic_key"):
        continue
    f = feat(t)
    sims = sorted(
        ((len(f & g) / len(f | g), u) for u, g in reviewed[t["topic_key"]] if f & g),
        reverse=True,
    )[:K]
    if not sims:
        none += 1
        continue
    votes = collections.Counter()
    for s, u in sims:
        votes[u] += s
    unit, v = votes.most_common(1)[0]
    share = v / sum(votes.values())
    if sims[0][0] >= MIN_SIM and share >= MIN_SHARE:
        suggestions.append(
            {
                "question_id": r["question_id"],
                "topic_key": t["topic_key"],
                "suggested_unit": unit,
                "similarity": round(sims[0][0], 2),
                "vote_share": round(share, 2),
            }
        )
total = sum(1 for r in rows if not r["taxonomy"].get("subtopic_key"))
OUT.write_text(
    json.dumps(
        {
            "note": "Review aid only. Not applied to the corpus or the plan.",
            "unclassified": total,
            "suggested": len(suggestions),
            "no_similar_reviewed_question": none,
            "suggestions": suggestions,
        },
        indent=1,
    )
    + "\n",
    encoding="utf-8",
)
print(f"{total} unclassified; {len(suggestions)} confident suggestions to review; {none} have no similar reviewed question")
