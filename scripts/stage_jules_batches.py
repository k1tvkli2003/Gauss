#!/usr/bin/env python3
"""Push isolated visual task branches for Jules without touching the main worktree."""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import time
from pathlib import Path


def run(*args: str, cwd: Path) -> None:
    subprocess.run(args, cwd=cwd, check=True)


def push_with_retry(remote: str, branch: str, cwd: Path) -> None:
    for attempt in range(1, 4):
        result = subprocess.run(
            ["git", "push", "--force", "-u", remote, branch],
            cwd=cwd,
            check=False,
        )
        if result.returncode == 0:
            return
        if attempt == 3:
            raise subprocess.CalledProcessError(result.returncode, result.args)
        time.sleep(attempt * 5)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--tasks-root", type=Path, required=True)
    parser.add_argument("--worktree", type=Path, required=True)
    parser.add_argument("--tasks", help="Comma-separated task IDs; omit for all prepared tasks")
    parser.add_argument("--remote", default="origin")
    args = parser.parse_args()

    manifest = json.loads((args.tasks_root / "tasks.json").read_text(encoding="utf-8"))
    selected = set(args.tasks.split(",")) if args.tasks else None
    run("git", "fetch", args.remote, cwd=args.worktree)

    for task in manifest["tasks"]:
        if selected is not None and task["id"] not in selected:
            continue
        branch = task["branch"]
        run("git", "checkout", "-B", branch, f"{args.remote}/main", cwd=args.worktree)
        input_dir = args.worktree / "jules_input"
        output_dir = args.worktree / "jules_output"
        if input_dir.exists():
            shutil.rmtree(input_dir)
        if output_dir.exists():
            shutil.rmtree(output_dir)
        shutil.copytree(args.tasks_root / "tasks" / task["id"], input_dir)
        run("git", "add", "jules_input", cwd=args.worktree)
        run("git", "commit", "-m", f"Stage Nardebam visual task {task['id']}", cwd=args.worktree)
        push_with_retry(args.remote, branch, args.worktree)
        print(f"staged {task['id']} -> {branch}")


if __name__ == "__main__":
    main()
