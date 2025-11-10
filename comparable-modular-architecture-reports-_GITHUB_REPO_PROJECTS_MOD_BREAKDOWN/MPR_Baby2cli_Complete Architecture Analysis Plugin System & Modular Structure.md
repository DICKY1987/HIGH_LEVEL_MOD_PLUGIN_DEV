# **Baby2cli: Current System README.md**

## **Python GUI Wrapper for CLI Multi‑Rapid**

A small, extendable PyQt6 app that wraps your PowerShell‑based multi‑CLI system.

### **Features**

* Dashboard: One‑click buttons to run your existing scripts (Diagnostics, Orchestrator, Init Workspace, Sessions).  
* Streaming Logs: Non‑blocking process runner pipes stdout into the Logs panel.  
* Git-based features removed: no git operations are executed.  
* IPC Ready: ipc/stdio\_bridge.py for JSON‑over‑stdio (compatible with tool\_bridge.py and jsonrpc\_stdio\_demo.py).

### **Requirements**

* Python 3.11+  
* pip install PyQt6  
* Your existing PowerShell scripts (Diagnostics.ps1, CLI-Orchestrator.ps1, etc.) located in your working directory.

### **Run**

bash

cd gui\_wrapper  
python app.py

On Windows, PowerShell 7 (pwsh) is recommended. Update config/defaults.json if you prefer Windows PowerShell:

JSON

{ "powershell": "powershell" }

### **Wiring to Your System**

* Edit config/defaults.json to point to your scripts and set environment variables for tool paths.  
* The "Working Directory" selector in the GUI should point at a repo containing your scripts.  
* The app launches commands via PowerShell with \-ExecutionPolicy Bypass \-File when the command ends in .ps1.

### **Documentation**

Key documentation lives under docs/:

* Getting Started: docs/GettingStarted.md  
* Quick Start: docs/QuickStart.md  
* Troubleshooting & FAQ: docs/Troubleshooting.md, docs/FAQ.md  
* API Overview: docs/API.md (see docs/api/powershell/ and docs/api/python/)  
* Architecture: docs/Architecture.md  
* Configuration Reference: docs/Configuration.md  
* Upgrade Guide: docs/UpgradeGuide.md  
* Performance Tuning: docs/Performance.md  
* Keyboard Shortcuts: docs/KeyboardShortcuts.md  
* Privacy/Telemetry: docs/Privacy.md  
* Videos: docs/videos/

### **Next Steps (Extend)**

* Add a Workflows tab that parses unified\_workflow.txt to render phases and run adapters.  
* Add a Policy view to inspect .merge-policy.yaml and .gitattributes.  
* Add PR controls using gh CLI (create PR, assign reviewers).  
* Integrate a JSON‑RPC toolbar using ipc/stdio\_bridge.py to talk to tool\_bridge.py for AI tool calls.

### **Notes**

* Git operations are disabled in this build; version control is out of scope.

### **Installer (WiX) Scaffold**

* Build MSI: pwsh installer/build.ps1  
* Edit WiX source: installer/setup.wix (placeholder with product/feature stubs)  
* Uninstall helper (placeholder): pwsh installer/uninstall.ps1 \-InstallDir \<path\>  
* Installer prerequisites (scaffold): pwsh scripts/Install-Prerequisites.ps1

Notes:

* Requires WiX Toolset (candle.exe and light.exe) on PATH.  
* Current files are placeholders to enable Workstream 5 iteration.

### **Packaging & Distribution**

* Portable ZIP: pwsh scripts/Build-Portable.ps1 → dist/baby2cli-portable.zip  
* PyInstaller EXE: pwsh scripts/build\_pyinstaller.ps1 → dist/baby2cli.exe  
* Chocolatey (scaffold): pwsh scripts/Build-Chocolatey.ps1 (needs choco and MSI)  
* winget manifest (scaffold): packaging/winget/manifest.yaml  
* Build all: pwsh scripts/Build-All.ps1

### **Versioning & Updates**

* Version file: version.json  
* PowerShell: lib/VersionManager.ps1 (Read-Version, Write-Version, Bump-Version)  
* Python: lib/version\_manager.py (VersionInfo dataclass)  
* Update check (scaffold): lib/AutoUpdate.ps1, lib/auto\_update.py

### **Docker**

* Build: docker build \-t baby2cli .  
* Run (CLI tools): docker run \--rm \-it baby2cli

---

# **baby2cli: Complete Architecture Analysis (Plugin System & Modular Structure)**

# **PART A: PLUGIN SYSTEM ARCHITECTURE**

## **Section A1: PLUGIN SYSTEM OVERVIEW**

### **A1.1 Architecture Summary**

System Type: Interface-based with lightweight action dispatch (augmented by process/event execution for external scripts)

Plugin Discovery: Directory scanning of plugins/ for Python modules (e.g., example\_hello.py) plus implicit “script actions” sourced from config/defaults.json

Loading Strategy: Startup load (plugins initialized when main window builds its menu); external script actions invoked on-demand

Isolation Level: Same-process for Python plugins; external PowerShell scripts run as child processes (process-level isolation for those actions)

Communication Pattern: Direct in-process method invocation for Python plugins; stdout/stderr streaming via ipc/process\_runner.py for external scripts; potential JSON-over-stdio via ipc/stdio\_bridge.py

Core-Plugin Boundary: Core owns UI lifecycle, configuration, security (sanitization), process spawning; plugins provide additional actions surfaced in the “Plugins” menu (and future workflow panels)

### **A1.2 Plugin Lifecycle**

Lifecycle Stages:

1. Discovery \- Scan plugins/ directory for .py files; map names to actions  
2. Validation \- (⚠️ Not explicitly documented) Likely minimal: file import success; optional naming conventions  
3. Loading \- Import plugin modules; collect callable(s) into plugin\_manager.actions  
4. Registration \- Populate UI menu items dynamically from plugin\_manager.actions  
5. Activation \- User triggers action (QAction connected to \_invoke\_plugin)  
6. Deactivation \- (⚠️ Not documented) No dynamic unload; requires restart to remove a plugin  
7. Cleanup \- Python process exit handles resources; external script processes cleaned after run (handled by process runner)

Lifecycle Events/Hooks:

* load\_plugins \- Fires during app startup; discovers and registers plugin actions  
* invoke(name) \- Called when user clicks plugin menu item; plugin code executes  
* run\_command (script tab) \- Spawns external process; streams output (pseudo-extension point for scripts)  
* check\_updates \- Optional update check hook (not strictly a plugin hook but system extensibility point)  
* first\_run\_finish \- One-time initialization flow (theme/language setup) before plugin actions become interactive

---

## **Section A2: PLUGIN EXTENSION POINTS**

### **A2.1 Available Hooks/Events**

| Hook/Event Name | Trigger Condition | Plugin Receives | Plugin Returns | Can Block? | Examples |
| ----- | ----- | ----- | ----- | ----- | ----- |
| load\_plugins | App startup after UI scaffold | Access to app/plugin manager context | Registered action dict | No | Populate menu items |
| invoke:\<action\> | User clicks QAction in Plugins menu | App reference (assumed) | None / status string | Yes (during execution) | example\_hello |
| run\_command | Dashboard/script tab button pressed | Label, command string, workdir, env | Process handle / stream setup | No (async piping) | Run Diagnostics.ps1 |
| process\_output (implicit) | Child process produces stdout/stderr | Line chunks | UI log update | N/A | Live log streaming |
| stdio\_bridge | JSON message arrives over stdio | JSON object | JSON response | Yes (sync per message) | AI tool bridging |
| check\_updates | Manual/auto invocation of update check | Current version info | Update dialog / none | Briefly | Version notification |

(⚠️ Some contracts inferred; not all formally documented.)

### **A2.2 Hook Priority & Ordering**

Execution Order Control:

* Plugin actions appear sorted alphabetically when building the menu (sorted(self.plugin\_manager.actions.keys()))  
* No explicit numeric priority system observed  
* Conflict resolution: Name uniqueness – later imports probably overwrite if duplicate (⚠️ Not documented)

Examples:

Python

for name in sorted(self.plugin\_manager.actions.keys()):  
    act \= QAction(name, self)  
    act.triggered.connect(lambda checked=False, n=name: self.\_invoke\_plugin(n))  
    plugins\_menu.addAction(act)

---

## **Section A3: PLUGIN STRUCTURE & ANATOMY**

### **A3.1 Required Plugin Artifacts**

Mandatory Files:

* plugins/\<plugin\_name\>.py \- Defines callable action(s)

Optional Files:

* README.md inside plugin (⚠️ Not used here)  
* Resource/config file (plugin may read global config)

Directory Structure:

Code

plugins/  
├── example\_hello.py     \# Sample plugin providing a greeting action  
└── (future plugins)     \# Additional action modules

### **A3.2 Plugin Manifest/Descriptor**

Manifest Format: (⚠️ Not documented) – No explicit manifest; discovery is convention-based (filename & callable)

Required Fields:

JSON

{  
  "name": "Implicit from filename",  
  "action": "Callable exported (e.g., run/apply/execute)",  
  "dependencies": "Optional (inferred from imports)"  
}

Example Real Manifest:

Text

⚠️ Not documented (plugins are plain .py modules without separate manifest)

### **A3.3 Plugin Implementation Pattern**

Implementation Style: Function-based (simple callable registered in actions dict); could evolve to class-based.

Minimal Plugin Example (realistic pattern based on system):

Python

\# plugins/example\_hello.py  
def run(app):  
    app.statusBar().showMessage("Hello from example\_hello plugin\!")  
    return "ok"

Full-Featured Plugin Example (inferred pattern):

Python

\# plugins/workflow\_inspector.py (hypothetical)  
import json  
from pathlib import Path

def run(app):  
    wf \= Path(app.config.get("workflow\_file", "unified\_workflow.txt"))  
    if not wf.exists():  
        app.statusBar().showMessage("Workflow file missing")  
        return "missing"  
    phases \= \[l.strip() for l in wf.read\_text(encoding="utf-8").splitlines() if l.strip()\]  
    \# Open a dialog or tab to visualize phases  
    app.script\_tabs.open\_ephemeral("Workflow", "\\n".join(phases))  
    return {"phases": len(phases)}

(⚠️ Second example is inferred – demonstrates extensibility pattern.)

---

## **Section A4: PLUGIN CONTRACTS & INTERFACES**

### **A4.1 Core Contracts**

#### **Contract: PluginManager (in lib/plugin\_manager.py)**

Purpose: Discovers and invokes plugin actions.

Required Methods/Functions (inferred):

Python

load\_plugins() \-\> dict            \# Scans plugins directory, builds action registry  
invoke(name: str) \-\> Any          \# Executes named action if available  
actions: Dict\[str, Callable\]      \# Registry of action name \-\> callable

Input Schema (invoke):

JSON

{  
  "name": "string (registered action key)"  
}

Output Schema (invoke):

JSON

{  
  "result": "plugin-dependent (string/object/None)"  
}

Validation Rules (inferred):

* Plugin file must import without ImportError  
* Action callable must be found (e.g., run or a predefined symbol)  
* Name collisions resolved by last successful load

Example Implementation (excerpt from app usage):

Python

self.plugin\_manager \= PluginManager()  
self.plugin\_manager.load\_plugins()  
result \= self.plugin\_manager.invoke("example\_hello")

#### **Contract: run\_command (Script Tab Execution)**

Purpose: Adapter for external scripts treated as extension actions.

Python

run\_command(label: str, cmd: str, workdir: str, env: dict) \-\> None

* Spawns PowerShell process (if .ps1)  
* Streams output via non-blocking IPC

Input Schema:

JSON

{  
  "label": "UI label for tab/logging",  
  "cmd": "full command line",  
  "workdir": "absolute path",  
  "env": { "VAR": "value" }  
}

Output Schema:

JSON

{  
  "process": "spawned child process (handle not serialized)",  
  "log\_stream": "incremental lines"  
}

#### **Contract: stdio\_bridge (IPC)**

Purpose: JSON-over-stdio messaging for AI/tool integration.

Python

send(message: dict) \-\> dict   \# Round-trip JSON  
listen() \-\> Iterator\[dict\]    \# Stream incoming messages

(⚠️ Precise signatures inferred; direct code not shown.)

### **A4.2 Communication Protocols**

Plugin → Core:

* Direct Python callable using app reference  
* Access GUI (statusBar, tabs, config)  
* No explicit permission gating (⚠️ Improvement opportunity)

Core → Plugin:

* Invocation through PluginManager.invoke(name)  
* Error handling: try/except (⚠️ details not documented)  
* No formal timeout enforcement for in-process actions

Plugin → Plugin:

* Not formally supported; plugins could import others (⚠️ discouraged – risk of tight coupling)  
* Shared state mediated by app object and config

---

## **Section A5: PLUGIN CAPABILITIES & PERMISSIONS**

### **A5.1 Permission Model**

Permission Levels:

* Open (Current): Plugins run with same process privileges  
* External Process (Scripts): Constrained by OS process boundaries  
* Future Scoped (Inferred): Potential sandbox via subprocess or IPC channel

Capability Declarations:

Text

⚠️ Not documented – no explicit declaration format

Restrictions:

* ❌ No enforced resource limits in Python plugins  
* ❌ No dynamic disable/hard kill interface  
* ❌ No explicit whitelisting of accessible APIs

Sandboxing/Isolation:

* External PowerShell commands isolated as child processes  
* Python plugins share interpreter (blast radius: full process)

### **A5.2 Core Services Available to Plugins**

| Service | Purpose | Access Pattern | Permission Required |
| ----- | ----- | ----- | ----- |
| Status Bar | User feedback | app.statusBar().showMessage() | Open |
| Script Runner | Execute external tasks | app.script\_tabs.run\_command() | Open |
| Config | Read settings | app.config / loader | Open |
| Tabs API | UI surface | app.tabs.addTab(...) | Open |
| IPC Bridge | Structured messaging | ipc/stdio\_bridge.py | Open (manual import) |

---

## **Section A6: PLUGIN VALIDATION & QUALITY GATES**

### **A6.1 Pre-Load Validation**

Validation Checks (inferred):

1. Import Success \- Module loads without ImportError  
   * Pass: module imported  
   * Fail: plugin skipped; logged (⚠️ logging path not documented)  
2. Action Presence \- Required callable exists (e.g., run)  
   * Pass: callable added to registry  
   * Fail: module ignored

Validation Tool/Command:

bash

\# (Inferred) No dedicated command; restart app to re-run discovery  
python app.py

### **A6.2 Runtime Safety Mechanisms**

Error Isolation:

* External scripts isolated as processes  
* Plugin exceptions likely caught during invoke (⚠️ not fully documented)

Resource Limits:

* Memory: None enforced  
* CPU: None enforced  
* Time: No timeout for plugin actions  
* I/O: External process streaming only; no rate limiting

Circuit Breakers:

* ⚠️ Not implemented; repeated failures do not auto-disable plugins

---

## **Section A7: PLUGIN CONFIGURATION & CUSTOMIZATION**

### **A7.1 Configuration System**

Configuration Sources:

* config/defaults.json  
* Environment variables  
* Version file: version.json

Config Precedence (inferred):

1. User edits to defaults.json  
2. Environment overrides (if merged)  
3. Internal fallbacks

Hot-reload support: No (requires restart)

Configuration Schema (excerpt):

JSON

{  
  "powershell": "pwsh",  
  "scripts": {  
    "diagnostics": "pwsh \-NoLogo \-NoProfile \-File Diagnostics.ps1"  
  },  
  "theme": "light",  
  "language": "en\_US"  
}

Example Plugin Config:

JSON

{  
  "plugin\_config": {  
    "workflow\_file": "unified\_workflow.txt",  
    "enable\_metrics": true  
  }  
}

### **A7.2 Plugin-Specific Customization**

Customization Points:

* Plugins can read global config keys  
* Future: dedicated plugin config section (⚠️ not implemented)

Override Mechanisms:

* Edit defaults.json  
* Provide environment variables before launch

Extension of extensions (meta-plugins):

* ⚠️ Not documented; feasible via plugin importing another plugin

Templates/Scaffolding:

bash

\# (Hypothetical)  
cp plugins/example\_hello.py plugins/my\_plugin.py

---

# **PART B: COMPLETE MODULAR ARCHITECTURE**

## **Section B1: TIER 1: CORE MODULES (Sacred/Privileged)**

### **Module 1: Main Application (app.py)**

Purpose: Initializes GUI, loads config, orchestrates plugins, builds menus.

Deliverables:

* app.py \- Main window, lifecycle  
* Status bar integration  
* Menu construction  
* First-run setup flag file

Key Contracts:

Python

\_main() \-\> None  
\_apply\_theme(theme: str) \-\> None  
\_invoke\_plugin(name: str) \-\> None  
\_run(script\_cmd: str) \-\> None  \# via script tabs abstraction

Core Module Identification Criteria: Central orchestration; removing breaks UI and plugin system.

### **Module 2: Configuration Loader**

Purpose: Reads config/defaults.json and applies runtime settings.

Deliverables:

* Parsed config dict  
* Theme/language selection  
* Script command registry

Key Contracts:

Python

load\_config() \-\> Tuple\[dict, Optional\[str\]\]  
apply\_config(cfg: dict) \-\> None

### **Module 3: Plugin Manager (lib/plugin\_manager.py)**

Purpose: Discovers and registers plugin actions.

Deliverables:

* actions registry  
* Discovery logic

Key Contracts:

Python

load\_plugins() \-\> Dict\[str, Callable\]  
invoke(name: str) \-\> Any

### **Module 4: Process Runner (ipc/process\_runner.py)**

Purpose: Non-blocking external process execution and log streaming.

Deliverables:

* Child process spawning wrapper  
* Stdout/stderr event pumping

Key Contracts:

Python

run(cmd: str, cwd: str, env: dict, on\_line: Callable\[\[str\], None\]) \-\> ProcessHandle  
terminate(handle) \-\> None

### **Module 5: Security & Sanitization (lib/input\_sanitizer.py / InputSanitizer.ps1)**

Purpose: Validate user/workspace inputs before command execution.

Deliverables:

* Sanitization routines  
* Validation errors surfaced via dialogs

Key Contracts:

Python

sanitize\_path(path: str) \-\> str  
validate\_script\_cmd(cmd: str) \-\> bool

### **Module 6: Versioning & Updates (lib/version\_manager.py, lib/auto\_update.py)**

Purpose: Manage version info and update checks.

Deliverables:

* Version parsing  
* Update dialog integration (scaffold)

Key Contracts:

Python

read\_version() \-\> VersionInfo  
check\_remote(manifest\_url: str) \-\> Optional\[str\]

### **Module 7: Secrets Management (lib/secrets\_manager.py, SecretsManager.ps1)**

Purpose: Store/retrieve operational secrets (tokens, keys).

Deliverables:

* Secure retrieval interface  
* Optional rotation logic

Key Contracts:

Python

get(name: str) \-\> str  
set(name: str, value: str) \-\> None

### **Module 8: Metrics & Telemetry (lib/metrics.py, MetricsExporter.ps1)**

Purpose: Collect and optionally export operational metrics.

Deliverables:

* Counters/timers  
* Export routines

Key Contracts:

Python

increment(metric: str, value: int \= 1) \-\> None  
export() \-\> dict

### **Module 9: Crash & Error Reporting (lib/crash\_reporter.py, ErrorLogger.ps1)**

Purpose: Capture errors/exceptions and log them.

Deliverables:

* Exception handling hook  
* Persisted reports

Key Contracts:

Python

report(exc: Exception) \-\> str  
log(message: str, level: str) \-\> None

### **Module 10: IPC Bridge (ipc/stdio\_bridge.py)**

Purpose: Structured JSON-over-stdio communications for tooling/AI integration.

Deliverables:

* Send/receive loop  
* Message serialization

Key Contracts:

Python

send(obj: dict) \-\> None  
listen(on\_message: Callable\[\[dict\], None\]) \-\> None

---

## **Section B2: TIER 2: PLUGIN/EXTENSION MODULES (Extensible/Evolvable)**

### **Module 11: Example Hello Plugin (plugins/example\_hello.py)**

Purpose: Demonstrate plugin action pattern.

Deliverables:

* Greeting action  
* Menu item

invoke:example\_hello: User selects plugin from Plugins menu.

Input Contract:

JSON

{  
  "event": "invoke",  
  "inputs": { "name": "example\_hello" }  
}

Output Contract:

JSON

\[  
  {  
    "action": "show\_message",  
    "payload": { "text": "Hello from example\_hello plugin\!" }  
  }  
\]

Plugin/Extension Identification Criteria: Optional; system runs without it.

### **Module 12: External Diagnostics Script (Diagnostics.ps1)**

Purpose: System health inspection.

Deliverables:

* Diagnostic output log  
* Status messages

Hook/Event Name: run\_command (diagnostics)

Input Contract:

JSON

{  
  "event": "run\_command",  
  "inputs": { "cmd": "pwsh \-File Diagnostics.ps1" }  
}

Output Contract:

JSON

\[  
  { "action": "append\_log", "payload": { "line": "\<stdout\>" } }  
\]

### **Module 13: Orchestrator Pipeline (Orchestrator-Pipeline.ps1)**

Purpose: Execute multi-step operational pipeline.

Deliverables:

* Orchestrated task flow  
* Aggregated logs

Hook/Event Name: run\_command (orchestrator)

### **Module 14: Session Manager (Session-Manager.ps1)**

Purpose: Manage active tool/user sessions.

Deliverables:

* Session list  
* Start/stop interactions

Hook/Event Name: run\_command (session\_manager\_list)

### **Module 15: Workstream Viewer (Future Workflow Tab)**

Purpose: Visualize unified\_workflow.txt phases. (⚠️ Planned per README)

Deliverables:

* Parsed workflow  
* Phase navigation UI

Hook/Event Name: invoke:workflow\_inspector (inferred)

### **Module 16: Update Checker (Scaffold)**

Purpose: Compare local version against remote manifest.

Deliverables:

* Update notification dialog

Hook/Event Name: check\_updates

### **Module 17: JSON-RPC Tool Bridge (tool\_bridge.py, jsonrpc\_stdio\_demo.py)**

Purpose: Provide AI/tool invocation via standardized RPC.

Deliverables:

* RPC endpoint actions  
* Response streaming

Hook/Event Name: stdio\_bridge message

---

## **Section B3: TIER 3: SUPPORT MODULES**

### **Module 18: UI Helpers (views/\*)**

Purpose: Shared dialog/panel utilities.

Deliverables:

* ErrorDialog  
* HelpBrowser  
* Status widgets

Key Contracts:

Python

show\_error(title: str, details: str) \-\> None  
open\_help(path: str) \-\> None

### **Module 19: Theming (themes/\*.qss)**

Purpose: Provide CSS-like styling overrides.

Deliverables:

* Light/dark QSS files

Key Contracts:

Python

apply\_theme(name: str) \-\> None

### **Module 20: Packaging Scripts (scripts/\*.ps1, Dockerfile)**

Purpose: Build distributions (MSI, portable zip, PyInstaller).

Deliverables:

* dist/\* artifacts  
* Installer scaffold

### **Module 21: Documentation Assets (docs/)**

Purpose: Knowledge base and guidance.

Deliverables:

* Architecture docs  
* API references

### **Module 22: Roadmaps & Production Data (production\_roadmap.json, production\_workstreams.json)**

Purpose: Project planning, workflow metadata.

Deliverables:

* JSON data for planning features

---

## **Section B4: COMPLETE DELIVERABLES SUMMARY TABLE**

| Module | Core Files | Generated Artifacts | Config Files | Tests |
| ----- | ----- | ----- | ----- | ----- |
| Main Application | app.py | First-run flag | config/defaults.json | (⚠️ GUI tests not found) |
| Configuration Loader | app.py (load\_config section) | In-memory config dict | defaults.json | \- |
| Plugin Manager | lib/plugin\_manager.py | Actions registry | \- | \- |
| Process Runner | ipc/process\_runner.py | Live log streams | \- | \- |
| Security & Sanitization | lib/input\_sanitizer.py | Sanitized inputs | \- | \- |
| Versioning & Updates | lib/version\_manager.py, version.json | Version info | version.json | \- |
| Secrets Management | lib/secrets\_manager.py | Secret cache | (optional secure store) | \- |
| Metrics & Telemetry | lib/metrics.py | Metrics snapshot | \- | \- |
| Crash & Error Reporting | lib/crash\_reporter.py | Crash report files | \- | \- |
| IPC Bridge | ipc/stdio\_bridge.py | Message dispatch | \- | \- |
| Example Hello Plugin | plugins/example\_hello.py | Status messages | \- | \- |
| Diagnostics Script | Diagnostics.ps1 | Log output | \- | tests/powershell? |
| Orchestrator Pipeline | Orchestrator-Pipeline.ps1 | Orchestration logs | \- | \- |
| Session Manager | Session-Manager.ps1 | Session list | \- | \- |
| Workflow Viewer | (planned) | Phase view | unified\_workflow.txt | \- |
| Update Checker | auto\_update.py | Dialog state | version.json | \- |
| Tool Bridge | tool\_bridge.py | RPC responses | \- | \- |
| UI Helpers | views/\* | Widgets | \- | \- |
| Theming | themes/\*.qss | Applied styles | \- | \- |
| Packaging Scripts | scripts/\*.ps1, Dockerfile | dist/\* | packaging/winget/manifest.yaml | \- |
| Documentation Assets | docs/\* | HTML/Rendered docs (external) | \- | \- |
| Roadmaps Data | production\_roadmap.json | Planning views | \- | \- |

---

## **Section B5: MODULE DEPENDENCIES**

Code

\[Main Application\]  
├── Configuration Loader (reads defaults.json)  
├── Plugin Manager (discovers plugins)  
├── Process Runner (executes scripts)  
├── IPC Bridge (optional JSON-RPC)  
├── Versioning & Updates (version.json)  
├── Secrets Management  
├── Metrics & Telemetry  
└── UI Helpers / Theming

\[Plugin Manager\]  
└── Depends on filesystem (plugins directory)

\[Process Runner\]  
└── External PowerShell invocations  
    └── Diagnostics.ps1  
    └── Orchestrator-Pipeline.ps1  
    └── Session-Manager.ps1

\[Workflow Viewer (planned)\]  
└── unified\_workflow.txt

\[Tool Bridge\]  
└── stdio\_bridge (message transport)

\[Packaging Scripts\]  
└── Build artifacts in dist/

---

## **Section B6: INTEGRATION POINTS**

### **External Tool Integration**

Tool Integrations:

* PowerShell \- Script execution for operational tasks (Process Runner module)  
* WiX Toolset \- MSI packaging (Packaging scripts)  
* PyInstaller \- Binary distribution build  
* Chocolatey / winget \- Distribution channels (manifests/scaffold)  
* JSON-RPC (stdio) \- AI/tool bridge via tool\_bridge.py

### **Data Flows**

1. Run Diagnostics → User clicks “Run Diagnostics” → Build PowerShell command → Spawn process via Process Runner → Stream stdout lines → UI log panel updates → Status bar shows completion  
2. Invoke Plugin Action → User selects plugin in menu → PluginManager.invoke(name) → Plugin executes with app context → Plugin updates status bar → (Optional) open new tab/dialog  
3. Update Check → User triggers check → Version Manager reads local version → Fetch remote manifest (future) → Compare versions → Display update dialog or “up to date” message  
4. Workflow Visualization (planned) → User opens Workflow tab → File reader parses unified\_workflow.txt → Build phase list → Render interactive panel → User selects phase for details  
5. JSON-RPC Tool Call → External AI client sends JSON message → stdio\_bridge receives → Dispatch to handler (tool\_bridge) → Response marshalled → Returned over stdout

---

# **PART C: PLUGIN ECOSYSTEM & DEVELOPMENT**

## **Section C1: PLUGIN DEVELOPMENT WORKFLOW**

### **C1.1 Plugin Creation Process**

1. Create a new file under plugins/ (e.g., plugins/my\_task.py)  
2. Define a callable (run(app) or agreed entry point)  
3. (Optional) Read config via app.config  
4. Restart application to load and test plugin

Tools Required:

* Python 3.11  
* Text editor / IDE

Scaffolding/Generators:

bash

cp plugins/example\_hello.py plugins/my\_task.py

### **C1.2 Testing & Debugging**

Testing Framework:

* Python plugins can be unit tested with pytest (baseline tests scaffolding present in repo)  
* PowerShell scripts via Pester (Invoke-Pester \-Path tests/powershell)

Debugging Tools:

* Print/log to status bar  
* Attach debugger to Python process  
* Use stdout logging for external scripts

Test Example (inferred):

Python

def test\_example\_plugin(monkeypatch):  
    class DummyApp:  
        def statusBar(self):   
            class SB:   
                def showMessage(self, m): self.msg \= m  
            return SB()  
    from plugins import example\_hello  
    app \= DummyApp()  
    result \= example\_hello.run(app)  
    assert result \== "ok"

---

## **Section C2: PLUGIN ECOSYSTEM**

### **C2.1 Official/Built-in Plugins**

| Plugin Name | Purpose | Hooks Used | Stability |
| ----- | ----- | ----- | ----- |
| example\_hello | Greeting demo action | invoke:example\_hello | Stable |
| (Future workflow\_inspector) | Show workflow phases | invoke:workflow\_inspector | Planned |
| (Future policy\_viewer) | Inspect merge policy | invoke:policy\_viewer | Planned |

### **C2.2 Third-Party Plugin Support**

Distribution Channels:

* Manual drop-in of .py file under plugins/

Package Management:

* ⚠️ Not integrated (no pip-based plugin loading)

Installation Process:

* Copy file → restart app

Community Resources:

* Documentation under docs/  
* Architecture spec file(s)  
* Guides: readme\_guide.md

---

## **Section C3: VERSIONING & COMPATIBILITY**

### **C3.1 API Versioning**

Version Strategy:

* Core version in version.json  
* No formal plugin API version (⚠️ Opportunity for future enhancement)  
* Breaking changes would require developer notice in CHANGELOG

Compatibility Matrix:

| Core Version | Plugin API Version | Compatible With |
| ----- | ----- | ----- |
| 0.x (current) | Implicit (no tag) | All simple function plugins |

### **C3.2 Migration Guides**

Upgrade Paths:

* Replace core files; keep plugin folder  
* Check CHANGELOG for interface changes  
* Update PowerShell scripts if command signatures altered

---

# **PART D: ARCHITECTURAL ANALYSIS**

## **Section D1: PLUGIN ARCHITECTURE STRENGTHS & WEAKNESSES**

### **D1.1 Architectural Strengths**

✅ Simplicity of Plugin Pattern

* Why: Single-file, function-based approach lowers barrier.  
* Example: example\_hello.py minimal interface.

✅ Dual Extensibility (Python \+ External Scripts)

* Why: Combines fast in-process actions with isolated operational scripts.  
* Example: Diagnostics executes safely as a separate process.

✅ Clear UI Integration via Menu Generation

* Why: Automatic menu population reduces manual wiring.  
* Example: Alphabetic sorting yields predictable ordering.

### **D1.2 Architectural Limitations**

⚠️ Lack of Formal Plugin Manifest

* Why limiting: Hard to add metadata (version, capabilities).  
* Workaround: Convention-based naming and docstrings.

⚠️ No Resource/Timeout Controls

* Why limiting: Long-running plugin could freeze UI.  
* Workaround: Encourage async/threading in plugin code.

⚠️ Single Interpreter Security Exposure

* Why limiting: Malicious plugin has full access.  
* Workaround: Move sensitive operations to isolated subprocess.

### **D1.3 Design Tradeoffs**

Flexibility vs. Performance:

* Direct function calls are performant but sacrifice isolation.

Safety vs. Capability:

* External scripts safer (process boundary) but slower to start.

Simplicity vs. Power:

* Minimal interface easy for beginners; advanced lifecycle not yet available.

---

## **Section D2: COMPARATIVE METRICS**

### **D2.1 Plugin System Characteristics**

| Characteristic | Rating (1-5) | Notes |
| ----- | ----- | ----- |
| Ease of Plugin Creation | ⭐⭐⭐⭐ | One function; restart required |
| Extensibility Breadth | ⭐⭐⭐ | Actions \+ scripts; no deep hook graph |
| Safety/Isolation | ⭐⭐ | Python in-process; scripts safer |
| Performance Overhead | ⭐⭐⭐⭐ | Lightweight invocation |
| Documentation Quality | ⭐⭐⭐ | README & docs present; plugin specifics sparse |
| Developer Experience | ⭐⭐⭐ | Simple but lacks scaffolding tool |
| Plugin Ecosystem Size | ⭐ | Only example plugin currently |

### **D2.2 Complexity Analysis**

Lines of Code for "Hello World" Plugin: \~8  
Number of Required Artifacts: 1 file  
Number of Extension Points: \~6 (invoke, run\_command, process\_output, stdio\_bridge, check\_updates, first\_run)  
Learning Curve: Beginner  
Time to First Plugin: \< 0.5 hour

---

## **Section D3: MODULAR ARCHITECTURE QUALITY ASSESSMENT**

* ✅ Clear separation of concerns  
* ✅ Each module has single responsibility  
* ⚠️ Core protected from plugin failures (partial – needs better isolation)  
* ✅ Extensibility without core changes  
* ⚠️ Complete audit/observability capability (basic logging only)  
* ✅ Deterministic and testable behavior (script execution deterministic)  
* ✅ Well-defined module boundaries (directory structure)  
* ✅ Manageable dependencies (no circular deps observed)  
* ⚠️ Consistent interface contracts (plugin contract implicit)  
* ✅ Scalable architecture for growth (can add plugins & tabs)

---

## **Section D4: KEY TAKEAWAYS & PATTERNS**

### **D4.1 Core Architectural Patterns**

1. Action Registry Pattern  
   * Description: Map names to callables for dynamic UI integration.  
   * Benefits: Easy extension; decouples UI from implementation.  
   * Trade-offs: No metadata or validation layer.  
2. Process Isolation for Heavy Tasks  
   * Description: Use external scripts for operational workflows.  
   * Benefits: Stability and crash containment.  
   * Trade-offs: Startup latency & platform dependence.  
3. Convention over Configuration  
   * Description: Filenames and callable naming drive plugin discovery.  
   * Benefits: Minimal boilerplate.  
   * Trade-offs: Hard to enforce standards or versioning.

### **D4.2 Reusable Design Decisions**

Decisions Worth Borrowing:

* ✅ Hybrid extensibility (Python \+ scripts) – flexible and pragmatic.  
* ✅ Alphabetic menu construction – deterministic plugin UI ordering.  
* ✅ Single minimal entrypoint for plugins – lowers adoption barrier.

Decisions to Avoid:

* ❌ Lack of manifest – adopt structured metadata earlier.  
* ❌ No timeouts on plugin actions – introduce watchdogs.  
* ❌ In-process unrestricted execution – consider sandboxing for third-party plugins.

---

## **Section D5: CROSS-SYSTEM COMPARISON MATRIX**

| Aspect | baby2cli | System B | System C |
| ----- | ----- | ----- | ----- |
| Discovery Method | Directory scan (plugins/) | — | — |
| Loading Strategy | Startup import | — | — |
| Isolation Level | Mixed (same-process \+ external) | — | — |
| Extension Points | \~6 | — | — |
| Permission Model | Open trust model | — | — |
| Plugin Language | Python (scripts in PowerShell) | — | — |
| Validation Approach | Import success only (inferred) | — | — |
| Configuration System | JSON defaults file | — | — |
| Core Modules | 10 | — | — |
| Plugin Modules | 7 (incl. scripts & planned) | — | — |
| Developer Tools | Pester, pytest, packaging scripts | — | — |
| Ecosystem Size | Minimal | — | — |

---

# **ANALYSIS GUIDELINES (Applied Summary)**

* Traced data flow from UI actions into process runner and plugin manager.  
* Classified modules based on removability and privilege.  
* Identified implicit contracts where formal interfaces absent.  
* Marked undocumented areas with ⚠️ and provided inference \+ recommendations.

---

# **KEY CODE EXAMPLES**

### **Plugin Menu Construction (Real Excerpt)**

Python

for name in sorted(self.plugin\_manager.actions.keys()):  
    act \= QAction(name, self)  
    act.triggered.connect(lambda checked=False, n=name: self.\_invoke\_plugin(n))  
    plugins\_menu.addAction(act)

### **Script Command Construction (Excerpt)**

Python

cmd \= f'{self.pw\_exe} \-ExecutionPolicy Bypass \-NoLogo \-NoProfile \-File "{script\_path}" {rest}'  
self.script\_tabs.run\_command(label, cmd, workdir, env)

### **Minimal Plugin Example (Realistic)**

Python

def run(app):  
    app.statusBar().showMessage("Hello from example\_hello plugin\!")  
    return "ok"

---

# **RECOMMENDATIONS**

1. Introduce a plugin.json manifest with name, version, entrypoint, permissions.  
2. Add timeout/thread wrapper for plugin execution to protect UI responsiveness.  
3. Implement structured logging & observability (central metrics aggregator already scaffolded).  
4. Provide a CLI scaffolder: python \-m baby2cli scaffold-plugin \<name\>.  
5. Formalize hook contracts (document expected signature of run(app)).

---

# **COMPLETION CHECK**

Part A: All sections A1–A7 populated; lifecycle, hooks, permissions, validation included.  
Part B: Core/Plugin/Support modules enumerated; summary table; dependencies; data flows.  
Part C: Workflow, ecosystem, versioning addressed.  
Part D: Strengths, weaknesses, metrics, patterns, comparison matrix included.  
Code Examples: ≥3 real/inferred examples supplied.  
No “TBD” markers; missing info flagged with ⚠️ and analyzed.

---

# **FINAL TAKEAWAY**

baby2cli presents a deliberately minimalist, pragmatic extensibility model blending in-process Python action plugins with isolated PowerShell operational scripts. Formalization (manifests, permissions, resource controls) would elevate safety and scalability while preserving its approachable development experience.  
