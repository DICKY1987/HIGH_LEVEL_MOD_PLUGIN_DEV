#!/usr/bin/env python
from __future__ import annotations

import glob
import json
import os
import subprocess
import sys


def run(cmd: list[str]) -> int:
    print(f"$ {' '.join(cmd)}")
    try:
        return subprocess.call(cmd)
    except FileNotFoundError:
        print(f"Command not found: {cmd[0]}")
        return 127


def validate_manifests() -> int:
    required = {"name", "module", "class", "version"}
    manifests = glob.glob(os.path.join("plugins", "**", "manifest.json"), recursive=True)
    if not manifests:
        print("[manifest] No manifests found; skipping")
        return 0
    errors = 0
    for m in manifests:
        try:
            with open(m, "r", encoding="utf-8") as fh:
                data = json.load(fh)
            missing = required - set(data.keys())
            if missing:
                print(f"[manifest] {m}: missing fields: {', '.join(sorted(missing))}")
                errors += 1
        except Exception as e:
            print(f"[manifest] {m}: invalid JSON or unreadable: {e}")
            errors += 1
    if errors:
        print(f"[manifest] validation failed with {errors} error(s)")
        return 2
    print("[manifest] all manifests valid")
    return 0


def main() -> int:
    rc = 0

    # Lint (non-blocking)
    try:
        _ = subprocess.check_output([sys.executable, "-m", "pip", "show", "flake8"])  # noqa: F841
        print("Running flake8 (non-blocking)...")
        _ = run(["flake8", "fwgp"])  # ignore status
    except subprocess.CalledProcessError:
        pass
    except FileNotFoundError:
        pass

    # Validate manifests (blocking)
    rc = validate_manifests()
    if rc != 0:
        return rc

    # Unit tests (blocking)
    print("Running unit tests...")
    rc = run([sys.executable, "-m", "unittest", "discover", "-s", "tests", "-p", "test_*.py"])
    if rc != 0:
        print("Tests failed; aborting commit")
        return rc

    print("Pre-commit checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())

