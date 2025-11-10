# Plugin Development Guide

This guide explains how to build, test, and ship plugins for FWGP (File Watcher Git Pipeline). It covers discovery, manifests, hook lifecycle, local testing, and conformance expectations.

## Overview

- FWGP detects file changes in a Git repo and runs a pipeline of stages (stage → commit → push), invoking plugin hooks along the way.
- Plugins are normal Python classes that subclass `fwgp.plugins.base.BasePlugin` and implement one or more hooks.
- Plugin metadata is provided by a `manifest.json` file stored with the plugin code and used by FWGP discovery.

## Discovery & Manifest

FWGP discovers plugins by scanning `plugins/**/manifest.json` files and checking required fields.

Required fields (see `fwgp/discovery.py`):

- `name` (string) – Human‑readable name
- `module` (string) – Python import path to module, e.g. `fwgp.plugins.my_plugin`
- `class` (string) – Class name within that module, e.g. `MyPlugin`
- `version` (string) – Semantic version

Example `plugins/my_plugin/manifest.json`:

```json
{
  "name": "My Sample Plugin",
  "module": "fwgp.plugins.my_plugin",
  "class": "MyPlugin",
  "version": "0.1.0",
  "description": "Demonstrates FWGP hooks"
}
```

Place the module code at `fwgp/plugins/my_plugin.py` or a package at `fwgp/plugins/my_plugin/__init__.py` matching the `module` path.

## Base Class & Hooks

Plugins should subclass `fwgp.plugins.base.BasePlugin`. The base class provides a `manifest` and no‑op hook implementations you can override. Hook names are also enumerated in `fwgp.events.Hook`.

Available hooks (see `fwgp/plugins/base.py`, `fwgp/events.py`):

- `onFileDetected(evt, ctx)` – Called for each detected file event.
- `beforeStage(req, ctx) -> StageDecision` – Gate or transform staging.
- `afterStage(req, ctx)` – Post‑stage notification.
- `beforeCommit(req, ctx) -> CommitDecision` – Gate or override commit message/signing.
- `afterCommit(commit_sha, ctx)` – Post‑commit notification.
- `beforePush(req, ctx) -> PushDecision` – Gate or force push.
- `afterPush(req, ctx)` – Post‑push notification.
- `beforePull(req, ctx) -> PullDecision` – Gate pull (pre‑sync at start of tick).
- `afterPull(result, ctx)` – Post‑pull notification with conflicts list.
- `onConflict(info, ctx)` – Merge conflict notification.

Key data classes (see `fwgp/events.py`):

- `FileDetectedEvent(path, change_type, ts, repo)`
- `StageRequest(paths, repo, ctx)` / `StageDecision(allow, reasons?, transforms?)`
- `CommitRequest(staged_summary, repo, author?)` / `CommitDecision(allow, message_override?, sign?)`
- `PushRequest(remote, branch, commits?)` / `PushDecision(allow, force?)`
- `PullRequest(remote, branch)` / `PullDecision(allow, strategy?)`
- `ConflictInfo(files, base?, local?, remote?)`, `PullResult(updated, conflicts?)`

## Minimal Plugin Example

File: `fwgp/plugins/my_plugin.py`

```python
from fwgp.plugins.base import BasePlugin, PluginManifest
from fwgp import events


class MyPlugin(BasePlugin):
    manifest = PluginManifest(
        name="MyPlugin",
        version="0.1.0",
        author="you@example.com",
        description="Blocks staging of large files"
    )

    def beforeStage(self, req: events.StageRequest, ctx):
        too_big = [p for p in req.paths if p.endswith(".bin")]
        if too_big:
            return events.StageDecision(allow=False, reasons=["binary files not allowed"]) 
        return events.StageDecision(allow=True)
```

Manifest: `plugins/my_plugin/manifest.json`

```json
{
  "name": "My Plugin",
  "module": "fwgp.plugins.my_plugin",
  "class": "MyPlugin",
  "version": "0.1.0"
}
```

## Accessing Context

`ctx` contains execution context shared by the pipeline:

- `logger` – Python logger configured by FWGP
- `repo_path` – Path to the Git repository under watch
- `remote`, `branch` – If configured via the TUI

## Local Development Workflow

1) Create your plugin module and manifest as shown above.
2) Launch FWGP (`python run.py`) and use the menu to enable your plugin.
3) Make file changes inside the repo directory; watch hooks fire in logs.
4) Iterate and add tests under `tests/conformance/` as needed.

Run tests:

```
python -m unittest discover -s tests -p "test_*.py"
```

## Conformance Expectations

- Discovery: Manifests must include all required fields and valid import targets.
- Safety: Hooks should be side‑effect free beyond FWGP‑mediated actions.
- Timeouts: Long‑running work should be avoided or done quickly; hooks are time‑boxed by the dispatcher.
- Failures: Exceptions in hooks are captured; repeated failures may trip the circuit breaker in `fwgp.state.StateStore`.

## Versioning & Distribution

- Keep `PluginManifest.version` in sync with your release.
- If publishing externally, document dependencies and supported FWGP versions.

## Troubleshooting

- "Plugin failed to load": Check `module` and `class` in manifest and import path.
- "Hook timed out": Reduce work in the hook or precompute; see logs for the specific hook name.
- "No changes committed": Ensure `beforeStage` and `beforeCommit` allow progression, and that files are staged.

