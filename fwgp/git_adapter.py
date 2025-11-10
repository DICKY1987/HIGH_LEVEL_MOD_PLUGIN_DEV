from __future__ import annotations

import subprocess
from pathlib import Path
from typing import List, Optional, Tuple


class GitError(RuntimeError):
    pass


def _run_git(repo_path: str, args: List[str], timeout: float = 15.0) -> Tuple[int, str, str]:
    proc = subprocess.run(
        ["git", *args],
        cwd=repo_path,
        capture_output=True,
        text=True,
        timeout=timeout,
        shell=False,
    )
    return proc.returncode, proc.stdout.strip(), proc.stderr.strip()


def is_repo(repo_path: str) -> bool:
    return Path(repo_path, ".git").exists()


def init_repo(repo_path: str) -> None:
    code, out, err = _run_git(repo_path, ["init"])
    if code != 0:
        raise GitError(err or out)


def set_remote(repo_path: str, name: str, url: str) -> None:
    # Try set-url first, then add
    code, out, err = _run_git(repo_path, ["remote", "set-url", name, url])
    if code != 0:
        code, out, err = _run_git(repo_path, ["remote", "add", name, url])
        if code != 0 and "already exists" not in err:
            raise GitError(err or out)


def get_branch(repo_path: str) -> str:
    code, out, err = _run_git(repo_path, ["rev-parse", "--abbrev-ref", "HEAD"])
    if code != 0:
        raise GitError(err or out)
    return out


def checkout_branch(repo_path: str, branch: str, create: bool = False) -> None:
    args = ["checkout"] + (["-b", branch] if create else [branch])
    code, out, err = _run_git(repo_path, args)
    if code != 0:
        raise GitError(err or out)


def add(repo_path: str, paths: List[str]) -> None:
    if not paths:
        return
    code, out, err = _run_git(repo_path, ["add", "--", *paths])
    if code != 0:
        raise GitError(err or out)


def staged_summary(repo_path: str) -> List[str]:
    code, out, err = _run_git(repo_path, ["diff", "--cached", "--name-only"])
    if code != 0:
        raise GitError(err or out)
    return [line for line in out.splitlines() if line.strip()]


def commit(repo_path: str, message: str, sign: bool = False) -> Optional[str]:
    args = ["commit", "-m", message]
    if sign:
        args.append("-S")
    code, out, err = _run_git(repo_path, args)
    if code != 0:
        # No changes to commit is not fatal
        if "nothing to commit" in (out + err).lower():
            return None
        raise GitError(err or out)
    # Return new commit sha
    code, out, err = _run_git(repo_path, ["rev-parse", "HEAD"])
    if code != 0:
        return None
    return out


def push(repo_path: str, remote: str, branch: str, force: bool = False) -> None:
    args = ["push", remote, branch]
    if force:
        args.insert(1, "--force-with-lease")
    code, out, err = _run_git(repo_path, args, timeout=60.0)
    if code != 0:
        raise GitError(err or out)


def pull(repo_path: str, remote: str, branch: str) -> None:
    code, out, err = _run_git(repo_path, ["pull", remote, branch], timeout=120.0)
    if code != 0:
        # Not fatal for MVP; pull may fail if no tracking or conflicts
        raise GitError(err or out)


def list_conflicts(repo_path: str) -> List[str]:
    # Use diff-filter=U to list unmerged files
    code, out, err = _run_git(repo_path, ["diff", "--name-only", "--diff-filter=U"])
    if code != 0:
        return []
    return [line for line in out.splitlines() if line.strip()]
