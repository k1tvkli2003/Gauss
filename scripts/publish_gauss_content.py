#!/usr/bin/env python3
"""Validate and publish one immutable Gauss question-content release.

The script talks to Supabase's official Management API with the caller's
SUPABASE_ACCESS_TOKEN. It never needs or prints the service-role key. A release
stays invisible as `draft` until every artifact, immutable revision, and
release link has been inserted and reconciled on the server.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
import re
import sys
import time
import urllib.error
import urllib.request
from collections import defaultdict
from pathlib import Path
from typing import Any, Iterable


PROJECT_REF = "evyjrbwibwrdkjakooor"
RELEASE_ID_RE = re.compile(r"^[a-z0-9][a-z0-9._-]{2,79}$")
CHANNEL_RE = re.compile(r"^[a-z0-9][a-z0-9._-]{2,39}$")
QUESTION_ID_RE = re.compile(r"^nardebam_(math|physics)_[0-9]{4}_[0-9]{4}$")
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
ARTIFACT_KINDS = (
    "certification_runtime",
    "five_question_plan",
    "media_manifest",
    "question_index",
)


class PublishError(RuntimeError):
    pass


def canonical_json(value: Any) -> str:
    """Match Flutter's question_certification.dart canonical JSON contract."""

    if isinstance(value, list):
        return "[" + ",".join(canonical_json(item) for item in value) + "]"
    if isinstance(value, dict):
        if not all(isinstance(key, str) for key in value):
            raise PublishError("Canonical JSON object contains a non-string key.")
        return "{" + ",".join(
            json.dumps(key, ensure_ascii=False, separators=(",", ":"))
            + ":"
            + canonical_json(value[key])
            for key in sorted(value)
        ) + "}"
    if isinstance(value, bool) or value is None or isinstance(value, str):
        return json.dumps(value, ensure_ascii=False, separators=(",", ":"))
    if isinstance(value, int):
        return str(value)
    if isinstance(value, float):
        if not math.isfinite(value):
            raise PublishError("Canonical JSON contains a non-finite number.")
        if value.is_integer():
            return str(int(value))
        return repr(value)
    raise PublishError(f"Unsupported canonical JSON value: {type(value).__name__}")


def sha256_text(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def canonical_sha256(value: Any) -> str:
    return sha256_text(canonical_json(value))


def read_json(path: Path) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise PublishError(f"Cannot read valid JSON from {path}: {error}") from error


def read_jsonl(path: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    try:
        with path.open("r", encoding="utf-8") as handle:
            for number, line in enumerate(handle, start=1):
                if not line.strip():
                    continue
                value = json.loads(line)
                if not isinstance(value, dict):
                    raise PublishError(f"{path}:{number} is not a JSON object.")
                rows.append(value)
    except (OSError, json.JSONDecodeError) as error:
        raise PublishError(f"Cannot read valid JSONL from {path}: {error}") from error
    return rows


def chunks(values: list[Any], size: int) -> Iterable[list[Any]]:
    for start in range(0, len(values), size):
        yield values[start : start + size]


def sql_text(value: str) -> str:
    return "'" + value.replace("'", "''") + "'"


def sql_json(value: Any) -> str:
    return f"{sql_text(canonical_json(value))}::jsonb"


class ManagementSql:
    def __init__(self, project_ref: str, token: str) -> None:
        self._url = f"https://api.supabase.com/v1/projects/{project_ref}/database/query"
        self._token = token

    def query(self, sql: str) -> Any:
        body = json.dumps({"query": sql}, separators=(",", ":")).encode("utf-8")
        request = urllib.request.Request(
            self._url,
            data=body,
            method="POST",
            headers={
                "Authorization": f"Bearer {self._token}",
                "Content-Type": "application/json",
                "User-Agent": "gauss-content-publisher/1",
            },
        )
        last_error: Exception | None = None
        for attempt in range(5):
            try:
                with urllib.request.urlopen(request, timeout=90) as response:
                    payload = response.read().decode("utf-8")
                    return json.loads(payload) if payload else None
            except urllib.error.HTTPError as error:
                message = error.read().decode("utf-8", errors="replace")[:1000]
                if error.code not in (429, 500, 502, 503, 504):
                    raise PublishError(
                        f"Supabase SQL request failed ({error.code}): {message}"
                    ) from error
                last_error = PublishError(
                    f"Supabase SQL request remained transiently unavailable ({error.code})."
                )
            except (urllib.error.URLError, TimeoutError) as error:
                last_error = error
            time.sleep(1.5 * (attempt + 1))
        raise PublishError(f"Supabase SQL request failed after retries: {last_error}")


def one_row(result: Any) -> dict[str, Any]:
    if isinstance(result, dict):
        return result
    if isinstance(result, list) and len(result) == 1 and isinstance(result[0], dict):
        return result[0]
    raise PublishError("Supabase returned an unexpected single-row result.")


def result_rows(result: Any) -> list[dict[str, Any]]:
    if result is None:
        return []
    if isinstance(result, list) and all(isinstance(row, dict) for row in result):
        return result
    if isinstance(result, dict):
        return [result]
    raise PublishError("Supabase returned an unexpected row result.")


def load_and_validate(repo: Path) -> tuple[
    dict[str, Any],
    dict[str, list[str]],
    list[dict[str, Any]],
    dict[str, Any],
    dict[str, Any],
    dict[str, Any],
]:
    assets = repo / "flutter_app" / "assets"
    index = read_json(assets / "question_bank" / "index.json")
    certification = read_json(
        assets / "curriculum" / "certified_question_runtime_v1.json"
    )
    plan = read_json(assets / "curriculum" / "five_question_plan_v1.json")
    media_entries = read_jsonl(repo / "data" / "certification" / "v1" / "media-manifest.jsonl")

    if not isinstance(index, dict) or index.get("schema_version") != 2:
        raise PublishError("Unsupported question index schema.")
    if index.get("total") != 3672:
        raise PublishError(f"Question index declares {index.get('total')}; expected 3672.")
    topics = index.get("topics")
    if not isinstance(topics, list) or len(topics) != 29:
        raise PublishError("Question index must contain exactly 29 topics.")

    certification_by_id = {
        row["question_id"]: row
        for row in certification.get("questions", [])
        if isinstance(row, dict) and isinstance(row.get("question_id"), str)
    }
    questions: list[dict[str, Any]] = []
    topic_question_ids: dict[str, list[str]] = {}
    seen_ids: set[str] = set()
    referenced_media: set[str] = set()

    def collect_media(value: Any) -> None:
        if isinstance(value, list):
            for item in value:
                collect_media(item)
        elif isinstance(value, dict):
            asset = value.get("asset")
            if value.get("type") == "image" and isinstance(asset, str):
                referenced_media.add(asset)
            for item in value.values():
                collect_media(item)

    for topic in topics:
        if not isinstance(topic, dict):
            raise PublishError("Question index contains a malformed topic.")
        topic_key = topic.get("topic_key")
        subject = topic.get("subject")
        relative_file = topic.get("file")
        expected_count = topic.get("count")
        if (
            not isinstance(topic_key, str)
            or subject not in ("math", "physics")
            or not isinstance(relative_file, str)
            or not isinstance(expected_count, int)
        ):
            raise PublishError("Question index contains an invalid topic descriptor.")
        rows = read_json(assets / relative_file)
        if not isinstance(rows, list) or len(rows) != expected_count:
            raise PublishError(f"{topic_key} count does not match its topic file.")
        ordered_ids: list[str] = []
        for row in rows:
            if not isinstance(row, dict):
                raise PublishError(f"{topic_key} contains a non-object question.")
            question_id = row.get("id")
            if not isinstance(question_id, str) or not QUESTION_ID_RE.fullmatch(question_id):
                raise PublishError(f"{topic_key} contains an invalid stable question id.")
            if question_id in seen_ids:
                raise PublishError(f"Duplicate stable question id: {question_id}.")
            seen_ids.add(question_id)
            ordered_ids.append(question_id)
            if row.get("subject") != subject or row.get("topic_key") != topic_key:
                raise PublishError(f"{question_id} identity disagrees with its topic shard.")
            if row.get("source_bank") != "nardebam":
                raise PublishError(f"{question_id} is outside the preserved source bank.")
            options = row.get("options")
            if not isinstance(options, list) or len(options) != 4 or any(not option for option in options):
                raise PublishError(f"{question_id} violates the four-choice contract.")
            correct = row.get("correct_option_index")
            if not isinstance(correct, int) or correct < 1 or correct > 4:
                raise PublishError(f"{question_id} has an invalid source answer index.")
            if not row.get("stem") or not row.get("solution"):
                raise PublishError(f"{question_id} lacks a stem or solution.")
            certification_row = certification_by_id.get(question_id)
            if certification_row is not None:
                expected_hash = certification_row.get("runtime_record_sha256")
                if canonical_sha256(row) != expected_hash:
                    raise PublishError(
                        f"{question_id} no longer matches its certification runtime hash."
                    )
            collect_media(row)
            questions.append(row)
        topic_question_ids[topic_key] = ordered_ids

    if len(questions) != index["total"] or len(seen_ids) != index["total"]:
        raise PublishError("Question count or stable-id reconciliation failed.")
    if certification.get("source_question_count") != len(questions):
        raise PublishError("Certification source count disagrees with the corpus.")
    if plan.get("source_question_count") != len(questions):
        raise PublishError("Five-question plan does not cover the complete corpus.")

    media_by_asset: dict[str, dict[str, Any]] = {}
    for entry in media_entries:
        asset = entry.get("asset")
        digest = entry.get("sha256")
        byte_count = entry.get("bytes")
        if (
            not isinstance(asset, str)
            or not isinstance(digest, str)
            or not SHA256_RE.fullmatch(digest)
            or not isinstance(byte_count, int)
            or byte_count < 1
            or asset in media_by_asset
        ):
            raise PublishError("Media manifest contains an invalid or duplicate row.")
        media_file = assets / asset
        if not media_file.is_file():
            raise PublishError(f"Missing Flutter media asset: {asset}.")
        payload = media_file.read_bytes()
        if len(payload) != byte_count or hashlib.sha256(payload).hexdigest() != digest:
            raise PublishError(f"Flutter media asset failed its hash binding: {asset}.")
        media_by_asset[asset] = entry
    missing_media = referenced_media - media_by_asset.keys()
    if missing_media:
        raise PublishError(f"Referenced media is absent from the manifest: {sorted(missing_media)[:3]}.")

    index_artifact = {
        "schema_version": 1,
        "index": index,
        "topic_question_ids": topic_question_ids,
    }
    media_artifact = {
        "schema_version": 1,
        "entries": [media_by_asset[key] for key in sorted(media_by_asset)],
    }
    return (
        index,
        topic_question_ids,
        questions,
        index_artifact,
        certification,
        {"plan": plan, "media": media_artifact},
    )


def corpus_sha256(
    artifact_hashes: dict[str, str],
    links: list[dict[str, Any]],
) -> str:
    lines = ["gauss-content-v1"]
    lines.extend(
        f"artifact:{kind}:{artifact_hashes[kind]}" for kind in sorted(artifact_hashes)
    )
    lines.extend(
        "question:{position}:{question_id}:{revision}:{content_sha256}".format(**link)
        for link in links
    )
    return sha256_text("\n".join(lines))


def publish(args: argparse.Namespace) -> None:
    repo = Path(__file__).resolve().parents[1]
    (
        index,
        _,
        questions,
        index_artifact,
        certification,
        supporting,
    ) = load_and_validate(repo)
    plan = supporting["plan"]
    media_artifact = supporting["media"]
    artifacts = {
        "question_index": index_artifact,
        "five_question_plan": plan,
        "certification_runtime": certification,
        "media_manifest": media_artifact,
    }
    artifact_hashes = {kind: canonical_sha256(value) for kind, value in artifacts.items()}

    token = os.environ.get("SUPABASE_ACCESS_TOKEN")
    if args.publish and not token:
        raise PublishError("SUPABASE_ACCESS_TOKEN is required for --publish.")
    sql = ManagementSql(args.project_ref, token or "unused")

    existing: dict[str, list[tuple[int, str]]] = defaultdict(list)
    if args.publish:
        rows = result_rows(
            sql.query(
                "select question_id, revision, content_sha256 "
                "from public.gauss_question_revisions "
                "order by question_id, revision"
            )
        )
        for row in rows:
            existing[str(row["question_id"])].append(
                (int(row["revision"]), str(row["content_sha256"]))
            )

    new_revisions: list[dict[str, Any]] = []
    links: list[dict[str, Any]] = []
    for position, question in enumerate(questions):
        question_id = question["id"]
        digest = canonical_sha256(question)
        history = existing.get(question_id, [])
        matching = [revision for revision, old_hash in history if old_hash == digest]
        if matching:
            revision = max(matching)
        else:
            revision = max((value for value, _ in history), default=0) + 1
            new_revisions.append(
                {
                    "question_id": question_id,
                    "revision": revision,
                    "subject": question["subject"],
                    "topic_key": question["topic_key"],
                    "difficulty": question["difficulty"],
                    "content_sha256": digest,
                    "payload": question,
                }
            )
        links.append(
            {
                "position": position,
                "question_id": question_id,
                "revision": revision,
                "content_sha256": digest,
            }
        )

    corpus_hash = corpus_sha256(artifact_hashes, links)
    print(
        json.dumps(
            {
                "release_id": args.release_id,
                "channel": args.channel,
                "question_count": len(questions),
                "topic_count": len(index["topics"]),
                "new_revision_count": len(new_revisions),
                "reused_revision_count": len(questions) - len(new_revisions),
                "artifact_count": len(artifacts),
                "corpus_sha256": corpus_hash,
            },
            ensure_ascii=False,
        )
    )
    if not args.publish:
        print("DRY_RUN_OK")
        return

    release_insert = f"""
      insert into public.gauss_content_releases (
        id, schema_version, corpus_sha256, question_count, topic_count,
        state, minimum_app_build
      ) values (
        {sql_text(args.release_id)}, 1, {sql_text(corpus_hash)},
        {len(questions)}, {len(index['topics'])}, 'draft', {args.minimum_app_build}
      ) on conflict (id) do nothing;
    """
    sql.query(release_insert)

    for kind in ARTIFACT_KINDS:
        sql.query(
            "insert into public.gauss_content_artifacts "
            "(release_id, kind, sha256, payload) values ("
            f"{sql_text(args.release_id)}, {sql_text(kind)}, "
            f"{sql_text(artifact_hashes[kind])}, {sql_json(artifacts[kind])}) "
            "on conflict (release_id, kind) do nothing;"
        )

    for batch_number, batch in enumerate(chunks(new_revisions, 80), start=1):
        values = ",".join(
            "(" + ",".join(
                (
                    sql_text(row["question_id"]),
                    str(row["revision"]),
                    sql_text(row["subject"]),
                    sql_text(row["topic_key"]),
                    sql_text(row["difficulty"]),
                    sql_text(row["content_sha256"]),
                    sql_json(row["payload"]),
                )
            ) + ")"
            for row in batch
        )
        sql.query(
            "insert into public.gauss_question_revisions "
            "(question_id, revision, subject, topic_key, difficulty, content_sha256, payload) values "
            + values
            + " on conflict (question_id, revision) do nothing;"
        )
        print(f"REVISION_BATCH_OK {batch_number}")

    for batch_number, batch in enumerate(chunks(links, 500), start=1):
        values = ",".join(
            f"({sql_text(args.release_id)}, {sql_text(row['question_id'])}, "
            f"{row['revision']}, {row['position']})"
            for row in batch
        )
        sql.query(
            "insert into public.gauss_release_questions "
            "(release_id, question_id, revision, position) values "
            + values
            + " on conflict (release_id, question_id) do nothing;"
        )
        print(f"LINK_BATCH_OK {batch_number}")

    audit_sql = f"""
      select json_build_object(
        'release_rows', (
          select count(*) from public.gauss_content_releases
          where id = {sql_text(args.release_id)}
            and schema_version = 1
            and corpus_sha256 = {sql_text(corpus_hash)}
            and question_count = {len(questions)}
            and topic_count = {len(index['topics'])}
            and state = 'draft'
            and minimum_app_build = {args.minimum_app_build}
        ),
        'artifact_rows', (
          select count(*) from public.gauss_content_artifacts
          where release_id = {sql_text(args.release_id)}
        ),
        'artifact_mismatches', (
          select count(*) from public.gauss_content_artifacts artifact
          where artifact.release_id = {sql_text(args.release_id)}
            and (artifact.kind, artifact.sha256) not in (
              {','.join(f"({sql_text(kind)}, {sql_text(artifact_hashes[kind])})" for kind in ARTIFACT_KINDS)}
            )
        ),
        'link_rows', (
          select count(*) from public.gauss_release_questions
          where release_id = {sql_text(args.release_id)}
        ),
        'link_mismatches', (
          select count(*)
          from public.gauss_release_questions link
          join public.gauss_question_revisions revision
            on revision.question_id = link.question_id
           and revision.revision = link.revision
          where link.release_id = {sql_text(args.release_id)}
            and (link.position < 0 or revision.content_sha256 !~ '^[0-9a-f]{{64}}$')
        ),
        'position_min', (
          select min(position) from public.gauss_release_questions
          where release_id = {sql_text(args.release_id)}
        ),
        'position_max', (
          select max(position) from public.gauss_release_questions
          where release_id = {sql_text(args.release_id)}
        )
      ) as audit;
    """
    audit = one_row(sql.query(audit_sql)).get("audit")
    expected_audit = {
        "release_rows": 1,
        "artifact_rows": len(ARTIFACT_KINDS),
        "artifact_mismatches": 0,
        "link_rows": len(questions),
        "link_mismatches": 0,
        "position_min": 0,
        "position_max": len(questions) - 1,
    }
    if audit != expected_audit:
        raise PublishError(f"Server reconciliation failed closed: {audit}")

    sql.query(
        "begin; "
        "update public.gauss_content_releases set state='published', published_at=now() "
        f"where id={sql_text(args.release_id)} and state='draft'; "
        "insert into public.gauss_content_channels (channel, release_id, updated_at) values ("
        f"{sql_text(args.channel)}, {sql_text(args.release_id)}, now()) "
        "on conflict (channel) do update set release_id=excluded.release_id, updated_at=excluded.updated_at; "
        "commit;"
    )

    final = one_row(
        sql.query(
            "select json_build_object("
            "'state', release.state, 'channel_release', channel.release_id, "
            "'question_count', release.question_count, 'corpus_sha256', release.corpus_sha256"
            ") as proof from public.gauss_content_releases release "
            "join public.gauss_content_channels channel on channel.release_id=release.id "
            f"where release.id={sql_text(args.release_id)} and channel.channel={sql_text(args.channel)};"
        )
    ).get("proof")
    expected_final = {
        "state": "published",
        "channel_release": args.release_id,
        "question_count": len(questions),
        "corpus_sha256": corpus_hash,
    }
    if final != expected_final:
        raise PublishError(f"Published release proof failed closed: {final}")
    print("PUBLISH_OK")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--release-id", required=True)
    parser.add_argument("--channel", default="android-stable")
    parser.add_argument("--minimum-app-build", type=int, default=90)
    parser.add_argument("--project-ref", default=PROJECT_REF)
    parser.add_argument("--publish", action="store_true")
    args = parser.parse_args()
    if not RELEASE_ID_RE.fullmatch(args.release_id):
        parser.error("--release-id violates the release id contract")
    if not CHANNEL_RE.fullmatch(args.channel):
        parser.error("--channel violates the channel contract")
    if args.minimum_app_build < 1:
        parser.error("--minimum-app-build must be positive")
    return args


if __name__ == "__main__":
    try:
        publish(parse_args())
    except PublishError as error:
        print(f"PUBLISH_FAILED: {error}", file=sys.stderr)
        raise SystemExit(1) from error
