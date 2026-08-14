#!/usr/bin/env python3
"""Apply one reviewed Gauss migration through Supabase Management SQL.

The personal Management API token is read only from SUPABASE_ACCESS_TOKEN and
is never accepted as an argument or printed. A private checksum ledger makes
replays idempotent and rejects edited history.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
from pathlib import Path

from publish_gauss_content import ManagementSql, PROJECT_REF, PublishError, result_rows, sql_text


MIGRATION_RE = re.compile(r"^(?P<version>[0-9]{12,14})_(?P<name>[a-z0-9_]+)\.sql$")


def load_migration(path: Path) -> tuple[str, str, str, str]:
    match = MIGRATION_RE.fullmatch(path.name)
    if match is None:
        raise PublishError("Migration filename must be a timestamp and safe snake_case name.")
    sql = path.read_text(encoding="utf-8").strip()
    if not sql:
        raise PublishError("Migration SQL is empty.")
    if re.search(r"(?im)^\s*(begin|commit|rollback)\s*;", sql):
        raise PublishError("Migration files must not manage their own transaction.")
    digest = hashlib.sha256(sql.encode("utf-8")).hexdigest()
    return match.group("version"), match.group("name"), digest, sql


def existing_receipt(client: ManagementSql, version: str) -> dict[str, object] | None:
    exists = result_rows(
        client.query(
            "select to_regclass('gauss_internal.schema_migrations')::text as ledger"
        )
    )
    if not exists or exists[0].get("ledger") is None:
        return None
    rows = result_rows(
        client.query(
            "select version, name, sha256, applied_at "
            "from gauss_internal.schema_migrations "
            f"where version = {sql_text(version)}"
        )
    )
    return rows[0] if rows else None


def apply(path: Path, *, execute: bool, project_ref: str) -> None:
    version, name, digest, sql = load_migration(path)
    receipt: dict[str, object] = {
        "version": version,
        "name": name,
        "sha256": digest,
        "mode": "validate" if not execute else "apply",
    }
    if not execute:
        print(json.dumps(receipt, indent=2))
        return

    token = os.environ.get("SUPABASE_ACCESS_TOKEN")
    if not token:
        raise PublishError("SUPABASE_ACCESS_TOKEN is required for --apply.")
    client = ManagementSql(project_ref, token)
    existing = existing_receipt(client, version)
    if existing is not None:
        if existing.get("sha256") != digest or existing.get("name") != name:
            raise PublishError(
                f"Remote migration {version} exists with different reviewed content."
            )
        receipt["mode"] = "already-applied"
        receipt["applied_at"] = existing.get("applied_at")
        print(json.dumps(receipt, indent=2))
        return

    transaction = f"""
begin;
create schema if not exists gauss_internal;
revoke all on schema gauss_internal from public, anon, authenticated;
create table if not exists gauss_internal.schema_migrations (
  version text primary key,
  name text not null,
  sha256 text not null check (sha256 ~ '^[0-9a-f]{{64}}$'),
  applied_at timestamptz not null default now()
);
revoke all on table gauss_internal.schema_migrations from public, anon, authenticated;

{sql}

insert into gauss_internal.schema_migrations (version, name, sha256)
values ({sql_text(version)}, {sql_text(name)}, {sql_text(digest)});
commit;
"""
    client.query(transaction)
    verified = existing_receipt(client, version)
    if verified is None or verified.get("sha256") != digest:
        raise PublishError("Remote migration receipt did not verify after commit.")
    receipt["applied_at"] = verified.get("applied_at")
    print(json.dumps(receipt, indent=2))


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("migration", type=Path)
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--project-ref", default=PROJECT_REF)
    return parser.parse_args()


if __name__ == "__main__":
    try:
        args = parse_args()
        apply(args.migration, execute=args.apply, project_ref=args.project_ref)
    except (OSError, PublishError) as error:
        raise SystemExit(f"Migration failed: {error}") from error
