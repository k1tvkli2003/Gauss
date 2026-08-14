#!/usr/bin/env python3
"""Disposable live proof for Auth, content, feedback RLS, and Storage RLS.

Two random confirmed accounts are created through the same public Gauss signup
function used by Android. Credentials remain process-local, proof artifacts are
removed through authenticated APIs, and both temporary users are deleted in a
finally block through the protected Management SQL lane.
"""

from __future__ import annotations

import base64
import hashlib
import json
import os
import re
import secrets
import urllib.error
import urllib.parse
import urllib.request
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from publish_gauss_content import ManagementSql, PROJECT_REF, PublishError, sql_text


ROOT = Path(__file__).resolve().parents[1]
BACKEND_SOURCE = ROOT / "flutter_app" / "lib" / "backend" / "gauss_supabase.dart"
PNG = base64.b64decode(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII="
)


class ProofError(RuntimeError):
    pass


def public_config() -> tuple[str, str]:
    source = BACKEND_SOURCE.read_text(encoding="utf-8")
    key_match = re.search(r"static const publishableKey\s*=\s*'([^']+)'", source)
    if key_match is None:
        raise ProofError("Cannot read the Android publishable-key contract.")
    return f"https://{PROJECT_REF}.supabase.co", key_match.group(1)


def request(
    url: str,
    *,
    method: str,
    headers: dict[str, str],
    body: bytes | None = None,
    expected: set[int] = {200},
) -> tuple[int, bytes]:
    call = urllib.request.Request(url, data=body, method=method, headers=headers)
    try:
        with urllib.request.urlopen(call, timeout=45) as response:
            payload = response.read()
            if response.status not in expected:
                raise ProofError(f"Unexpected HTTP status {response.status}.")
            return response.status, payload
    except urllib.error.HTTPError as error:
        payload = error.read()
        if error.code in expected:
            return error.code, payload
        raise ProofError(f"Live proof request failed with HTTP {error.code}.") from error
    except (urllib.error.URLError, TimeoutError) as error:
        raise ProofError("Live proof could not reach Supabase.") from error


def json_request(
    url: str,
    *,
    method: str,
    headers: dict[str, str],
    value: Any,
    expected: set[int] = {200},
) -> tuple[int, Any]:
    status, payload = request(
        url,
        method=method,
        headers={"Content-Type": "application/json", **headers},
        body=json.dumps(value, separators=(",", ":")).encode("utf-8"),
        expected=expected,
    )
    return status, json.loads(payload) if payload else None


def auth_headers(key: str, token: str) -> dict[str, str]:
    return {"apikey": key, "Authorization": f"Bearer {token}"}


def create_account(url: str, key: str) -> tuple[str, str, str]:
    marker = uuid.uuid4().hex
    email = f"gauss-proof-{marker}@example.com"
    password = f"Gx!{secrets.token_urlsafe(24)}"
    json_request(
        f"{url}/functions/v1/gauss-signup",
        method="POST",
        headers=auth_headers(key, key),
        value={"email": email, "password": password, "website": ""},
        expected={201},
    )
    _, signed_in = json_request(
        f"{url}/auth/v1/token?grant_type=password",
        method="POST",
        headers={"apikey": key},
        value={"email": email, "password": password},
    )
    try:
        user_id = str(uuid.UUID(signed_in["user"]["id"]))
        token = signed_in["access_token"]
    except (KeyError, TypeError, ValueError) as error:
        raise ProofError("Supabase returned a malformed Auth session.") from error
    return user_id, token, email


def cleanup_users(client: ManagementSql, user_ids: list[str]) -> None:
    safe = [str(uuid.UUID(value)) for value in user_ids]
    if not safe:
        return
    values = ",".join(f"{sql_text(value)}::uuid" for value in safe)
    client.query(f"delete from auth.users where id in ({values})")


def run() -> dict[str, object]:
    management_token = os.environ.get("SUPABASE_ACCESS_TOKEN")
    if not management_token:
        raise PublishError("SUPABASE_ACCESS_TOKEN is required for live cleanup.")
    management = ManagementSql(PROJECT_REF, management_token)
    url, key = public_config()
    accounts: list[tuple[str, str, str]] = []
    uploaded_path: str | None = None
    try:
        accounts.append(create_account(url, key))
        accounts.append(create_account(url, key))
        owner_id, owner_token, _ = accounts[0]
        other_id, other_token, _ = accounts[1]
        owner_headers = auth_headers(key, owner_token)
        other_headers = auth_headers(key, other_token)

        for headers in (owner_headers, other_headers):
            json_request(
                f"{url}/rest/v1/rpc/gauss_ensure_profile",
                method="POST",
                headers=headers,
                value={},
            )

        _, channels = request(
            f"{url}/rest/v1/gauss_content_channels"
            "?select=release_id&channel=eq.android-stable",
            method="GET",
            headers=owner_headers,
        )
        channel_rows = json.loads(channels)
        if not isinstance(channel_rows, list) or len(channel_rows) != 1:
            raise ProofError("Authenticated content channel did not resolve.")
        release_id = channel_rows[0]["release_id"]
        _, manifest_rows = json_request(
            f"{url}/rest/v1/rpc/gauss_release_manifest",
            method="POST",
            headers=owner_headers,
            value={
                "p_release_id": release_id,
                "p_offset": 0,
                "p_limit": 2,
            },
        )
        if (
            not isinstance(manifest_rows, list)
            or len(manifest_rows) != 2
            or any("payload" in row for row in manifest_rows)
            or [row.get("ordinal") for row in manifest_rows] != [0, 1]
        ):
            raise ProofError("Authenticated content manifest did not page exactly.")
        requested_ids = [row.get("question_id") for row in manifest_rows]
        requested_revisions = [row.get("revision") for row in manifest_rows]
        if not all(isinstance(value, str) for value in requested_ids) or not all(
            isinstance(value, int) for value in requested_revisions
        ):
            raise ProofError("Content manifest returned malformed identities.")
        _, payload_rows = json_request(
            f"{url}/rest/v1/rpc/gauss_release_payload_batch",
            method="POST",
            headers=owner_headers,
            value={
                "p_release_id": release_id,
                "p_question_ids": requested_ids,
                "p_revisions": requested_revisions,
            },
        )
        if (
            not isinstance(payload_rows, list)
            or len(payload_rows) != 2
            or [row.get("question_id") for row in payload_rows] != requested_ids
            or [row.get("revision") for row in payload_rows] != requested_revisions
            or any(not isinstance(row.get("payload"), dict) for row in payload_rows)
        ):
            raise ProofError("Authenticated delta payload did not bind exactly.")

        _, artifact_manifest_raw = request(
            f"{url}/rest/v1/gauss_content_artifacts"
            f"?select=kind,sha256&release_id=eq.{urllib.parse.quote(release_id)}"
            "&order=kind.asc",
            method="GET",
            headers=owner_headers,
        )
        artifact_manifest = json.loads(artifact_manifest_raw)
        if (
            not isinstance(artifact_manifest, list)
            or len(artifact_manifest) != 4
            or any("payload" in row for row in artifact_manifest)
        ):
            raise ProofError("Authenticated artifact manifest did not reconcile.")
        requested_kind = artifact_manifest[0].get("kind")
        requested_artifact_hash = artifact_manifest[0].get("sha256")
        _, artifact_payloads = json_request(
            f"{url}/rest/v1/rpc/gauss_release_artifact_payloads",
            method="POST",
            headers=owner_headers,
            value={"p_release_id": release_id, "p_kinds": [requested_kind]},
        )
        if (
            not isinstance(artifact_payloads, list)
            or len(artifact_payloads) != 1
            or artifact_payloads[0].get("kind") != requested_kind
            or artifact_payloads[0].get("sha256") != requested_artifact_hash
            or not isinstance(artifact_payloads[0].get("payload"), dict)
        ):
            raise ProofError("Authenticated artifact delta did not bind exactly.")

        anonymous_delta_status, _ = json_request(
            f"{url}/rest/v1/rpc/gauss_release_manifest",
            method="POST",
            headers=auth_headers(key, key),
            value={
                "p_release_id": release_id,
                "p_offset": 0,
                "p_limit": 1,
            },
            expected={401, 403, 404},
        )

        report_id = f"fb_{datetime.now(timezone.utc).timestamp():.6f}".replace(".", "_")
        uploaded_path = f"{owner_id}/{report_id}.png"
        request(
            f"{url}/storage/v1/object/gauss-feedback-private/"
            f"{urllib.parse.quote(uploaded_path, safe='/')}",
            method="POST",
            headers={
                **owner_headers,
                "Content-Type": "image/png",
                "x-upsert": "true",
            },
            body=PNG,
        )
        report = {
            "user_id": owner_id,
            "id": report_id,
            "kind": "questionIssue",
            "route": "/mission/sets",
            "note": "Disposable live RLS proof.",
            "question_id": "nardebam_math_1405_0001",
            "question_revision": 1,
            "topic_key": "sets",
            "issue_kind": "question_text",
            "session_id": "live-proof",
            "mission_index": 0,
            "selected_choice_index": None,
            "content_release_id": release_id,
            "screenshot_path": uploaded_path,
            "screenshot_sha256": hashlib.sha256(PNG).hexdigest(),
            "client_created_at": datetime.now(timezone.utc).isoformat(),
        }
        _, inserted = json_request(
            f"{url}/rest/v1/gauss_feedback_reports?on_conflict=user_id,id",
            method="POST",
            headers={
                **owner_headers,
                "Prefer": "resolution=merge-duplicates,return=representation",
            },
            value=report,
            expected={200, 201},
        )
        if not isinstance(inserted, list) or len(inserted) != 1:
            raise ProofError("Owner feedback upsert did not reconcile.")

        query = (
            f"?select=id,question_id,question_revision,screenshot_path"
            f"&user_id=eq.{owner_id}&id=eq.{report_id}"
        )
        _, owner_rows_raw = request(
            f"{url}/rest/v1/gauss_feedback_reports{query}",
            method="GET",
            headers=owner_headers,
        )
        _, other_rows_raw = request(
            f"{url}/rest/v1/gauss_feedback_reports{query}",
            method="GET",
            headers=other_headers,
        )
        owner_rows = json.loads(owner_rows_raw)
        other_rows = json.loads(other_rows_raw)
        if len(owner_rows) != 1 or other_rows != []:
            raise ProofError("Feedback row-level isolation failed.")

        cross_report = {**report, "id": f"{report_id}_cross", "screenshot_path": None, "screenshot_sha256": None}
        cross_status, _ = json_request(
            f"{url}/rest/v1/gauss_feedback_reports",
            method="POST",
            headers=other_headers,
            value=cross_report,
            expected={401, 403},
        )
        if cross_status not in (401, 403):
            raise ProofError("Cross-account feedback insert was not rejected.")

        _, downloaded = request(
            f"{url}/storage/v1/object/authenticated/gauss-feedback-private/"
            f"{urllib.parse.quote(uploaded_path, safe='/')}",
            method="GET",
            headers=owner_headers,
        )
        if downloaded != PNG:
            raise ProofError("Owner feedback screenshot did not round-trip.")
        other_download_status, _ = request(
            f"{url}/storage/v1/object/authenticated/gauss-feedback-private/"
            f"{urllib.parse.quote(uploaded_path, safe='/')}",
            method="GET",
            headers=other_headers,
            expected={400, 401, 403, 404},
        )

        json_request(
            f"{url}/storage/v1/object/gauss-feedback-private",
            method="DELETE",
            headers=owner_headers,
            value={"prefixes": [uploaded_path]},
            expected={200},
        )
        uploaded_path = None
        return {
            "temporary_accounts": 2,
            "content_release": release_id,
            "content_manifest_rows": len(manifest_rows),
            "content_delta_payload_rows": len(payload_rows),
            "artifact_manifest_rows": len(artifact_manifest),
            "artifact_delta_payload_rows": len(artifact_payloads),
            "anonymous_delta_status": anonymous_delta_status,
            "owner_feedback_rows": len(owner_rows),
            "cross_account_feedback_rows": len(other_rows),
            "cross_account_insert_rejected": True,
            "owner_screenshot_round_trip": True,
            "cross_account_screenshot_status": other_download_status,
            "temporary_artifacts_removed": True,
        }
    finally:
        if uploaded_path is not None and accounts:
            try:
                json_request(
                    f"{url}/storage/v1/object/gauss-feedback-private",
                    method="DELETE",
                    headers=auth_headers(key, accounts[0][1]),
                    value={"prefixes": [uploaded_path]},
                    expected={200},
                )
            except Exception:
                pass
        cleanup_users(management, [account[0] for account in accounts])


if __name__ == "__main__":
    try:
        print(json.dumps(run(), indent=2))
    except (OSError, ProofError, PublishError) as error:
        raise SystemExit(f"Live proof failed: {error}") from error
