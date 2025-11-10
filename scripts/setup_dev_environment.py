#!/usr/bin/env python
from __future__ import annotations

import os
import platform
import shutil
import subprocess
import sys
from pathlib import Path


def sh(cmd: list[str], env=None) -> int:
    print(f"$ {' '.join(cmd)}")
    return subprocess.call(cmd, env=env)


def ensure_venv(root: Path) -> tuple[Path, dict[str, str]]:
    venv = root / ".venv"
    if not venv.exists():
        print("Creating virtual environment .venv ...")
        rc = sh([sys.executable, "-m", "venv", str(venv)])
        if rc != 0:
            sys.exit(rc)
    if platform.system() == "Windows":
        py = venv / "Scripts" / "python.exe"
        bin_dir = venv / "Scripts"
    else:
        py = venv / "bin" / "python"
        bin_dir = venv / "bin"
    env = os.environ.copy()
    env["VIRTUAL_ENV"] = str(venv)
    env["PATH"] = str(bin_dir) + os.pathsep + env.get("PATH", "")
    return Path(py), env


def install_dev_deps(py: Path, env: dict[str, str]) -> None:
    print("Upgrading pip and installing dev dependencies ...")
    sh([str(py), "-m", "pip", "install", "--upgrade", "pip"], env=env)
    sh([str(py), "-m", "pip", "install", "flake8", "jsonschema", "watchdog"], env=env)


def install_pre_commit_hook(root: Path, py: Path) -> None:
    hooks_dir = root / ".git" / "hooks"
    hooks_dir.mkdir(parents=True, exist_ok=True)
    hook_path = hooks_dir / "pre-commit"
    wrapper = f"""#!/usr/bin/env bash
set -euo pipefail
"{py}" "{root / 'scripts' / 'pre_commit_hook.py'}"
"""
    hook_path.write_text(wrapper, encoding="utf-8")
    try:
        hook_path.chmod(0o755)
    except Exception:
        pass
    print(f"Installed git hook: {hook_path}")


def run_tests(py: Path, env: dict[str, str]) -> int:
    print("Running unit tests ...")
    return sh([str(py), "-m", "unittest", "discover", "-s", "tests", "-p", "test_*.py"], env=env)


def main() -> int:
    root = Path(__file__).resolve().parent.parent
    print("Step 1/7: Check Python version (>=3.9)")
    if sys.version_info < (3, 9):
        print("Python 3.9+ required")
        return 1

    print("Step 2/7: Create .venv if missing")
    py, env = ensure_venv(root)

    print("Step 3/7: Install dev dependencies")
    install_dev_deps(py, env)

    print("Step 4/7: Ensure data/ directories exist")
    (root / "data").mkdir(exist_ok=True)

    print("Step 5/7: Install pre-commit hook")
    install_pre_commit_hook(root, py)

    print("Step 6/7: Optional lint (non-blocking)")
    sh([str(py), "-m", "flake8", "fwgp"]) or True

    print("Step 7/7: Run unit tests")
    rc = run_tests(py, env)

    print("\nSetup complete.")
    print("To activate venv:")
    if platform.system() == "Windows":
        print(r"  .venv\Scripts\activate")
    else:
        print("  source .venv/bin/activate")
    print("Then run:")
    print("  python run.py")
    return rc


if __name__ == "__main__":
    sys.exit(main())

