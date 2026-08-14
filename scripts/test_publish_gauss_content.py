from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import publish_gauss_content as publisher


class GaussContentPublisherTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.repo = Path(__file__).resolve().parents[1]

    def test_canonical_json_is_ordered_unicode_safe_and_numeric_stable(self) -> None:
        first = {"z": 2.0, "a": [True, None, "فارسی", 1.25]}
        second = {"a": [True, None, "فارسی", 1.25], "z": 2}

        self.assertEqual(publisher.canonical_json(first), publisher.canonical_json(second))
        self.assertIn("فارسی", publisher.canonical_json(first))
        self.assertNotIn("2.0", publisher.canonical_json(first))

    def test_published_receipt_matches_every_local_question_and_artifact(self) -> None:
        (
            index,
            _,
            questions,
            index_artifact,
            certification,
            supporting,
        ) = publisher.load_and_validate(self.repo)
        artifacts = {
            "question_index": index_artifact,
            "five_question_plan": supporting["plan"],
            "certification_runtime": certification,
            "media_manifest": supporting["media"],
        }
        artifact_hashes = {
            kind: publisher.canonical_sha256(payload)
            for kind, payload in artifacts.items()
        }
        links = [
            {
                "position": position,
                "question_id": question["id"],
                "revision": 1,
                "content_sha256": publisher.canonical_sha256(question),
            }
            for position, question in enumerate(questions)
        ]
        receipt = json.loads(
            (
                self.repo
                / "data"
                / "content-releases"
                / "gauss-2026.08.14.1.json"
            ).read_text(encoding="utf-8")
        )

        self.assertEqual(receipt["question_count"], len(questions))
        self.assertEqual(receipt["topic_count"], len(index["topics"]))
        self.assertEqual(receipt["new_revision_count"], len(questions))
        self.assertEqual(receipt["reused_revision_count"], 0)
        self.assertEqual(receipt["artifact_sha256"], artifact_hashes)
        self.assertEqual(
            receipt["corpus_sha256"],
            publisher.corpus_sha256(artifact_hashes, links),
        )


if __name__ == "__main__":
    unittest.main()
