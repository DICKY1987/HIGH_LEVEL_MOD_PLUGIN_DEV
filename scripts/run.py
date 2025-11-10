from __future__ import annotations

import os
import sys
from pathlib import Path

from fwgp.config import Config, load_config, save_config
from fwgp.dispatcher import Dispatcher
from fwgp.git_adapter import GitError, checkout_branch, init_repo, is_repo, set_remote
from fwgp.logger import setup_logger
from fwgp.pipeline import Pipeline
from fwgp.state import StateStore
from fwgp.discovery import discover_plugins
from fwgp.watcher import get_watcher


def input_nonempty(prompt: str, default: str = "") -> str:
    val = input(f"{prompt} [{default}]: ").strip()
    return val or default


def ensure_repo(cfg: Config, logger) -> None:
    if not cfg.repo_path:
        cfg.repo_path = input_nonempty("Enter local directory to watch (Git repo)", cfg.repo_path or os.getcwd())
    Path(cfg.repo_path).mkdir(parents=True, exist_ok=True)
    if not is_repo(cfg.repo_path):
        print("Not a git repo. Initialize now? (y/N)")
        if input().strip().lower() == "y":
            try:
                init_repo(cfg.repo_path)
                logger.info("Initialized new git repo in %s", cfg.repo_path)
            except GitError as ge:
                logger.error("Failed to init repo: %s", ge)
    # Remote (optional)
    rem = input_nonempty("Remote name (blank to skip)", cfg.remote or "origin")
    url = input_nonempty("Remote URL (blank to skip)", "")
    if rem and url:
        try:
            set_remote(cfg.repo_path, rem, url)
            cfg.remote = rem
        except GitError as ge:
            logger.warning("Setting remote failed: %s", ge)
    # Branch
    br = input_nonempty("Branch name", cfg.branch or "main")
    if br:
        try:
            checkout_branch(cfg.repo_path, br)
            cfg.branch = br
        except GitError:
            # Try create branch
            try:
                checkout_branch(cfg.repo_path, br, create=True)
                cfg.branch = br
            except GitError as ge:
                logger.warning("Checkout branch failed: %s", ge)


def select_plugins(cfg: Config, available: list[str]):
    print("Available plugins:")
    all_specs = []
    # union of enabled defaults and discovered
    seen = set()
    for spec in cfg.enabled_plugins + available:
        if spec not in seen:
            all_specs.append(spec)
            seen.add(spec)
    enabled = set(cfg.enabled_plugins)
    for i, spec in enumerate(all_specs):
        mark = "[x]" if spec in enabled else "[ ]"
        print(f"  {i+1:2}. {mark} {spec}")
    print("Enter indices to toggle (comma-separated), or press Enter to keep.")
    raw = input("Selection: ").strip()
    if not raw:
        return
    try:
        idxs = {int(x)-1 for x in raw.split(",") if x.strip().isdigit() and 0 < int(x)}
        for i in idxs:
            if 0 <= i < len(all_specs):
                spec = all_specs[i]
                if spec in enabled:
                    enabled.remove(spec)
                else:
                    enabled.add(spec)
        cfg.enabled_plugins = [s for s in all_specs if s in enabled]
    except Exception:
        print("Invalid input, keeping existing selection.")


def run_pipeline(cfg: Config):
    logger = setup_logger(os.getcwd())
    state = StateStore(os.getcwd())
    disp = Dispatcher(state, logger, timeout_sec=2.0)
    disp.load_plugins(cfg.enabled_plugins)
    watcher = get_watcher(cfg.repo_path, prefer_os_events=True)
    pipe = Pipeline(cfg.repo_path, disp, logger, interval_sec=cfg.polling_interval_sec, watcher=watcher)

    # Inject remote/branch context into pipeline's ctx by wrapping _ctx
    orig_ctx = pipe._ctx
    def ctx_wrapper():
        c = orig_ctx()
        c["remote"] = cfg.remote
        c["branch"] = cfg.branch
        return c
    pipe._ctx = ctx_wrapper  # type: ignore

    print("Starting watcher. Press Ctrl+C to stop.")
    try:
        pipe.start()
    except KeyboardInterrupt:
        print("Stopped.")


def main():
    base_dir = os.getcwd()
    cfg = load_config(base_dir)

    while True:
        print("\nFile-Watcher-Git-Pipeline (FWGP)")
        print("1) Configure repo and remote")
        print("2) Configure plugins")
        print("3) Start watcher pipeline")
        print("4) Save config")
        print("5) Exit")
        choice = input("> ").strip()
        if choice == "1":
            logger = setup_logger(base_dir)
            ensure_repo(cfg, logger)
        elif choice == "2":
            logger = setup_logger(base_dir)
            discovered = discover_plugins("plugins", logger)
            select_plugins(cfg, discovered)
        elif choice == "3":
            save_config(cfg)
            run_pipeline(cfg)
        elif choice == "4":
            save_config(cfg)
            print("Config saved.")
        elif choice == "5":
            save_config(cfg)
            print("Goodbye.")
            break
        else:
            print("Unknown option.")


if __name__ == "__main__":
    sys.exit(main())
