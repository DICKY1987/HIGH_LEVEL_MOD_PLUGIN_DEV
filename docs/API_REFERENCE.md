# API Reference

This reference summarizes the primary public interfaces of FWGP used by plugins and by the application.

## Module: `fwgp.events`

Enums:
- `ChangeType`: `CREATED`, `MODIFIED`, `DELETED`
- `Hook`: `ON_FILE_DETECTED`, `BEFORE_STAGE`, `AFTER_STAGE`, `BEFORE_COMMIT`, `AFTER_COMMIT`, `BEFORE_PUSH`, `AFTER_PUSH`, `BEFORE_PULL`, `AFTER_PULL`, `ON_CONFLICT`

Data classes:
- `FileDetectedEvent(path: str, change_type: ChangeType, ts: float, repo: str)`
- `StageRequest(paths: list[str], repo: str, ctx: dict)`
- `StageDecision(allow: bool, reasons?: list[str], transforms?: dict)`
- `CommitRequest(staged_summary: list[str], repo: str, author?: str)`
- `CommitDecision(allow: bool, message_override?: str, sign?: bool)`
- `PushRequest(remote: str, branch: str, commits?: list[str])`
- `PushDecision(allow: bool, force?: bool)`
- `PullRequest(remote: str, branch: str)`
- `PullDecision(allow: bool, strategy?: str)`
- `ConflictInfo(files: list[str], base?: str, local?: str, remote?: str)`
- `PullResult(updated: bool, conflicts?: list[str])`

## Module: `fwgp.plugins.base`

Classes:
- `PluginManifest(name: str, version: str = "0.1.0", author?: str, description?: str)`
- `BasePlugin`: default no‑op hook implementations. Override any of:
  - `onFileDetected(evt, ctx) -> None`
  - `beforeStage(req, ctx) -> StageDecision`
  - `afterStage(req, ctx) -> None`
  - `beforeCommit(req, ctx) -> CommitDecision`
  - `afterCommit(commit_sha, ctx) -> None`
  - `beforePush(req, ctx) -> PushDecision`
  - `afterPush(req, ctx) -> None`
  - `beforePull(req, ctx) -> PullDecision`
  - `afterPull(res, ctx) -> None`
  - `onConflict(info, ctx) -> None`

## Module: `fwgp.discovery`

Functions:
- `discover_plugins(plugins_dir: str, logger) -> list[str]`
  - Scans `plugins/**/manifest.json` for manifests, validates required keys `{name, module, class, version}`, and returns `module:Class` strings.

## Module: `fwgp.dispatcher`

Classes:
- `Dispatcher(state: StateStore, logger, timeout_sec: float = 2.0)`
  - `load_plugins(plugin_specs: list[str]) -> None`
  - `on_file_detected(evt, ctx) -> None`
  - `before_stage(req, ctx) -> tuple[bool, list[str]]`
  - `after_stage(req, ctx) -> None`
  - `before_commit(req, ctx) -> tuple[bool, message_override|None, sign: bool]`
  - `after_commit(commit_sha|None, ctx) -> None`
  - `before_push(req, ctx) -> tuple[bool, force: bool]`
  - `after_push(req, ctx) -> None`
  - `before_pull(req, ctx) -> tuple[bool, strategy|None]`
  - `after_pull(res, ctx) -> None`
  - `on_conflict(info, ctx) -> None`

## Module: `fwgp.pipeline`

Classes:
- `Pipeline(repo_path: str, dispatcher: Dispatcher, logger, interval_sec: float = 2.0, watcher=None)`
  - `start() -> None` – Main loop: optional pull, detect changes, stage, commit, push.
  - `stop() -> None`

## Module: `fwgp.config`

Classes/Functions:
- `Config(base_dir: str, repo_path: str = "", remote: str = "origin", branch: str = "main", polling_interval_sec: float = 2.0, enabled_plugins: list[str] = None)`
- `load_config(base_dir: str) -> Config`
- `save_config(cfg: Config) -> None`

