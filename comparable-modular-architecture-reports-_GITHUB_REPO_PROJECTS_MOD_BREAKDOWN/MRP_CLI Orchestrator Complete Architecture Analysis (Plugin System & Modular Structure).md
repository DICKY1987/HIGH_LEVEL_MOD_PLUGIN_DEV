# CLI Orchestrator: Complete Architecture Analysis (Plugin System & Modular Structure)

## Current System README.md

### CLI Orchestrator

A deterministic, schema‑driven CLI orchestrator that stitches together multiple developer tools and AI agents into predefined, auditable workflows.

### Quick Start

\# Check where the repository is located  
python3 scripts/show\_directory\_detection.py

\# Install dependencies  
pip install \-e .\[dev,ai,test\]

\# Run a workflow  
cli-orchestrator run .ai/workflows/PY\_EDIT\_TRIAGE.yaml \--files "src/\*\*/\*.py"

### Documentation

* [CLAUDE.md](http://CLAUDE.md) – Development guide and project overview

* [Directory Detection](http://docs/directory_detection.md) – Understanding where the repo detects its location

* [Configuration](http://docs/configuration.md) – Configuration and environment setup

* Combined script utilities: see scripts/Combined-PowerShell-Scripts.ps1 for discovery/setup helpers. Do not run destructive modules without review.

### Testing

* Review [docs/TESTING.md](http://docs/TESTING.md) for the unified Python/Pester test harness, coverage outputs and CI expectations.

### Repository Location

The repository is currently located at: /home/runner/work/CLI\_RESTART/CLI\_RESTART

All components detect this location using either: 1\. Git root detection (git rev-parse \--show-toplevel) 2\. Current working directory (Path.cwd()) as fallback

See [docs/directory\_detection.md](http://docs/directory_detection.md) for complete details.

### Key Components

* **WorkflowRunner** – Executes schema‑validated YAML workflows

* **Router System** – Routes between deterministic tools and AI adapters

* **Adapter Framework** – Unified interface for tools and AI services

* **Cost Tracking** – Token usage and budget enforcement

* **Gate System** – Verification and quality gates

### Project Structure

├── src/cli\_multi\_rapid/    \# Core orchestrator  
├── workflows/              \# Workflow templates  
├── .ai/workflows/          \# AI workflow definitions  
├── config/                 \# Configuration files  
├── scripts/                \# Utility scripts  
├── tests/                  \# Test suite  
└── docs/                   \# Documentation

For complete documentation, see [CLAUDE.md](http://CLAUDE.md).

---

# PART A: PLUGIN SYSTEM ARCHITECTURE

## Section A1: PLUGIN SYSTEM OVERVIEW

### A1.1 Architecture Summary

**System Type:** Mixed interface‑based and hook‑based. The orchestrator exposes several extensibility surfaces: (i) adapters implement a common interface for executing workflow steps, (ii) verification plugins implement discover, run and report hooks, and (iii) GUI plugins implement a simple Plugin protocol with activate and deactivate methods[\[1\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/gui_terminal/plugins/__init__.py#L8-L13).

**Plugin Discovery:** \- **Adapter plugins** are discovered through a registry/factory system. AdapterFactory registers built‑in adapters and lazily loads third‑party adapters declared via setuptools entry points under the cli\_orchestrator.adapters group[\[2\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/factory.py#L19-L40). The factory resolves adapters by name, instantiating them on demand. \- **Verification plugins** are found by scanning specific directories (e.g., scripts/validation or verify.d) for Python modules. They are invoked by the ipt verify command at defined checkpoints[\[3\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/docs/reference/verification-framework.md#L1-L17). \- **GUI plugins** are discovered by scanning a plugins directory for \*.py files. Each module must expose a global plugin object implementing the Plugin protocol; the manager imports the module and registers it[\[4\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/gui_terminal/plugins/manager.py#L27-L60).

**Loading Strategy:** \- **Adapters** are loaded lazily on first use via the factory, so unused adapters incur no overhead[\[2\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/factory.py#L19-L40). \- **Verification plugins** are loaded when a verification run begins; each plugin has its own CLI entry point enabling standalone execution[\[5\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/scripts/validation/pytest.py#L14-L134). \- **GUI plugins** are loaded at GUI startup; the manager activates them immediately and can deactivate later[\[4\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/gui_terminal/plugins/manager.py#L27-L60).

**Isolation Level:** All plugins run in the same process as the orchestrator. There is no sandboxing; isolation is logical via interfaces. Adapters may internally spawn subprocesses (e.g., ruff, pytest, aider) but the orchestrator controls their invocation.

**Communication Pattern:** Direct function/method calls. For adapters, the orchestrator calls execute() and receives an AdapterResult. Verification plugins return dictionaries describing pass/fail status. GUI plugins receive a reference to the main window and use Qt signals to interact.

**Core‑Plugin Boundary:** \- The core orchestrator controls workflow loading, routing, cost tracking and gate management. Plugins control the details of executing a step (adapter), performing a verification check or extending the GUI. Plugins must not alter core state directly; they return structured results which the core interprets.

### A1.2 Plugin Lifecycle

**Lifecycle Stages:**

1. **Discovery** – The system searches plugin directories or entry points. The adapter factory scans cli\_orchestrator.adapters entry points and built‑in module paths[\[2\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/factory.py#L19-L40); the verification framework looks in scripts/validation/ and verify.d for Python files[\[3\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/docs/reference/verification-framework.md#L1-L17); the GUI plugin manager globs \*.py under the configured plugin path[\[4\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/gui_terminal/plugins/manager.py#L27-L60).

2. **Validation** – For adapters the factory verifies that the module defines a subclass of BaseAdapter and registers it. Verification plugins must implement discover, run and report functions; missing methods cause the manager to skip them[\[5\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/scripts/validation/pytest.py#L14-L134). GUI plugins must expose a plugin object with activate and deactivate methods[\[1\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/gui_terminal/plugins/__init__.py#L8-L13).

3. **Loading** – Modules are imported dynamically using importlib. For adapter entry points the factory defers import until the adapter is actually requested[\[2\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/factory.py#L19-L40).

4. **Registration** – Discovered adapters are registered in the AdapterRegistry, storing either the class or a callable to instantiate it. Verification plugins register themselves by virtue of being present in the directory; there is no central registry. GUI plugins register by adding the plugin object to the manager’s list[\[4\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/gui_terminal/plugins/manager.py#L27-L60).

5. **Activation** – For adapters, activation corresponds to instantiation; they may perform environment checks in their constructor (e.g., verifying ruff/black exist[\[6\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/code_fixers.py#L38-L47)). Verification plugins expose a run() method invoked at verification time. GUI plugins are activated at GUI startup by calling their activate method and providing the main window[\[1\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/gui_terminal/plugins/__init__.py#L8-L13).

6. **Deactivation** – GUI plugins have a deactivate method for cleanup or removal[\[1\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/gui_terminal/plugins/__init__.py#L8-L13). The orchestrator does not currently unload adapters or verification plugins, but adapters may implement resource cleanup within their own execution.

7. **Cleanup** – After execution, adapters may generate artifacts and return them. Verification plugins return result objects and may clean temporary files in report(). GUI plugins should deregister signals on deactivation.

**Lifecycle Events/Hooks:**

* discover() (verification plugins) – Called to locate tests or files before running[\[5\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/scripts/validation/pytest.py#L14-L134); returns a list of items to process.

* run() (verification plugins) – Executes the check (e.g., running pytest, ruff or schema validation) and returns structured results with statuses PASS/FAIL/WARNING/TIMEOUT[\[7\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/scripts/validation/ruff_semgrep.py#L14-L98).

* report() (verification plugins) – Generates a human‑readable summary of results and optional JSON reports[\[5\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/scripts/validation/pytest.py#L14-L134).

* execute(step, context, files) (adapters) – Performs the operation for a workflow step; returns AdapterResult with success flag, output, artifacts and metadata[\[8\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/base_adapter.py#L78-L119).

* validate\_step(step) (adapters) – Checks whether the adapter can handle the step (required parameters, tool availability)[\[8\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/base_adapter.py#L78-L119).

* estimate\_cost(step) (adapters) – Returns an estimate of token usage for budgeting[\[8\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/base_adapter.py#L78-L119).

* activate(main\_window) / deactivate() (GUI plugins) – Initialize or clean up GUI contributions[\[1\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/gui_terminal/plugins/__init__.py#L8-L13).

---

## Section A2: PLUGIN EXTENSION POINTS

### A2.1 Available Hooks/Events

| Hook/Event Name | Trigger Condition | Plugin Receives | Plugin Returns | Can Block? | Examples |
| :---- | :---- | :---- | :---- | :---- | :---- |
| **discover()** | Called by verification framework before running checks | Plugin context and configuration | List of files/tests to run | No | PyTestPlugin returns test files using pytest discovery[\[5\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/scripts/validation/pytest.py#L14-L134) |
| **run()** | Executed during verification checkpoint | Input context, optional selected files | Result dict with status, counts, errors | Yes – failing gate prevents workflow continuation | RuffSemgrepPlugin runs Ruff and Semgrep and returns PASS/FAIL/WARNING[\[7\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/scripts/validation/ruff_semgrep.py#L14-L98) |
| **report()** | After run completes | Raw results | Human‑readable summary and writes JSON artifacts | No | SchemaValidationPlugin writes validation reports[\[9\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/scripts/validation/schema_validate.py#L16-L115) |
| **execute(step, context, files)** | Called by StepExecutor for each workflow step[\[10\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/core/executor.py#L61-L127) | Step definition, current context, optional file pattern | AdapterResult containing success, output, artifacts, tokens\_used and metadata[\[8\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/base_adapter.py#L78-L119) | Yes – failure aborts workflow unless fail\_fast disabled | CodeFixersAdapter applies ruff/black/isort to Python files[\[11\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/code_fixers.py#L85-L116) |
| **validate\_step(step)** | Called during workflow validation | Step definition | Boolean indicating whether adapter can run the step | No | AIEditorAdapter ensures prompt parameter exists[\[12\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/ai_editor.py#L301-L308) |
| **estimate\_cost(step)** | Called when estimating tokens | Step definition | Integer token estimate | No | AIEditorAdapter multiplies prompt length and max\_tokens to estimate cost[\[13\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/ai_editor.py#L315-L328) |
| **activate(main\_window)** | Called at GUI startup | Reference to main window | None | No | GUI plugin adds menu items or tabs[\[1\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/gui_terminal/plugins/__init__.py#L8-L13) |
| **deactivate()** | Called when removing GUI plugin | None | None | No | GUI plugin removes widgets[\[1\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/gui_terminal/plugins/__init__.py#L8-L13) |

### A2.2 Hook Priority & Ordering

**Execution Order Control:** \- **Verification plugins** have no explicit ordering mechanism; they are run sequentially in the order they are configured in the checkpoint definition. There is no priority system. \- **Adapters** are selected per step; only one adapter is executed for a given step. The Router chooses between deterministic and AI adapters based on complexity and policy; deterministic adapters may override AI if complexity is low[\[14\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/routing/router.py#L101-L157). \- **GUI plugins** are activated in the order they are discovered; no priority is defined.

**Default Ordering Strategy:** For verification, the order defined in verify.d or CLI arguments determines execution order. For adapters, the router does not call multiple adapters on one step except when falling back; if the selected adapter fails, routing fallbacks may be considered[\[14\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/routing/router.py#L101-L157).

**Conflict Resolution:** When multiple verification plugins are configured for the same checkpoint, their results are aggregated. A failed gate can block the workflow. Adapter selection conflicts are resolved by the router’s policy: deterministic alternatives are preferred if complexity is low and the deterministic confidence is high[\[14\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/routing/router.py#L101-L157).

Example of specifying router policies:

\# In workflow YAML step:  
steps:  
  \- id: fix\_code  
    name: Fix code formatting  
    actor: ai\_editor  
    with:  
      prompt: "Format the code using best practices"  
    policy:  
      prefer\_deterministic: true  
      complexity\_threshold: 0.6

This instructs the router to prefer deterministic adapters if complexity ≤0.6[\[14\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/routing/router.py#L101-L157).

---

## Section A3: PLUGIN STRUCTURE & ANATOMY

### A3.1 Required Plugin Artifacts

**Adapter Plugins:** \- Python module defining a subclass of BaseAdapter[\[8\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/base_adapter.py#L78-L119). \- Mandatory methods: execute(step, context, files), validate\_step(step), estimate\_cost(step). \- Optional: get\_performance\_profile() to inform router of capabilities; helper methods for specific tools (e.g., \_run\_ruff)[\[11\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/code_fixers.py#L85-L116).

**Verification Plugins:** \- Python script/module defining a plugin class (name arbitrary). \- Mandatory functions: discover(), run(), report()[\[5\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/scripts/validation/pytest.py#L14-L134). \- Optional CLI entry point for standalone execution. For example, scripts/validation/pytest.py defines a cli() function to invoke plugin operations[\[5\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/scripts/validation/pytest.py#L14-L134).

**GUI Plugins:** \- Python module with a global plugin object implementing the Plugin protocol (activate, deactivate)[\[1\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/gui_terminal/plugins/__init__.py#L8-L13). \- Optional resources (icons, UI files) packaged alongside.

**Directory Structure Example:**

my\_adapter/  
├── \_\_init\_\_.py               \# Export adapter class  
├── my\_adapter.py             \# Contains MyAdapter(BaseAdapter)  
└── pyproject.toml            \# Entry point declaration under \[project.entry-points\]

my\_verification\_plugin/  
├── pytest\_custom.py          \# Contains discover/run/report  
└── README.md                 \# Usage documentation

gui\_extensions/  
└── my\_gui\_plugin.py          \# Defines plugin.activate/deactivate

### A3.2 Plugin Manifest/Descriptor

**Manifest Format:** For adapters installed via PyPI, entry points are declared in pyproject.toml under the cli\_orchestrator.adapters group. Example:

\[project.entry-points."cli\_orchestrator.adapters"\]  
code\_fixers \= "cli\_multi\_rapid.adapters.code\_fixers:CodeFixersAdapter"  
ai\_editor   \= "cli\_multi\_rapid.adapters.ai\_editor:AIEditorAdapter"

This tells the AdapterFactory to load CodeFixersAdapter when the name code\_fixers is requested[\[2\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/factory.py#L19-L40).

Verification plugins may be packaged similarly under a cli\_orchestrator.verifiers group; otherwise they live in a verify.d directory. GUI plugins use no manifest and are discovered via file scanning.

**Required Fields:**

\[project.entry-points."cli\_orchestrator.adapters"\]  
"plugin\_name" \= "module.path:ClassName"

plugin\_name becomes the adapter name used in workflow YAML. The module path must point to a class inheriting BaseAdapter.

**Example Real Manifest:** The repository’s pyproject.toml defines built‑in adapters such as code\_fixers and ai\_editor (not reproduced here for brevity). When installed, these are registered automatically.

### A3.3 Plugin Implementation Pattern

**Implementation Style:** Class‑based for adapters, function‑based for verification plugins, and declarative object for GUI plugins.

**Minimal Adapter Example:**

from cli\_multi\_rapid.adapters.base\_adapter import BaseAdapter, AdapterResult, AdapterType

class HelloWorldAdapter(BaseAdapter):  
    def \_\_init\_\_(self):  
        super().\_\_init\_\_(name="hello\_world", adapter\_type=AdapterType.DETERMINISTIC,  
                         description="Prints a greeting")

    def execute(self, step, context=None, files=None):  
        return AdapterResult(success=True, output="Hello, world\!", artifacts=\[\])

    def validate\_step(self, step):  
        \# Always valid  
        return True

    def estimate\_cost(self, step):  
        return 0

**Full‑Featured Adapter Example (CodeFixersAdapter):** This adapter checks for available tools (ruff, black, isort), resolves file patterns and runs each tool, aggregating results. It returns a structured AdapterResult with success flag, human‑readable output, artifacts and metadata[\[11\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/code_fixers.py#L85-L116).

class CodeFixersAdapter(BaseAdapter):  
    def \_\_init\_\_(self):  
        super().\_\_init\_\_(name="code\_fixers", adapter\_type=AdapterType.DETERMINISTIC,  
                         description="Apply automated code fixes")  
        self.\_available\_tools \= self.\_check\_available\_tools()

    def execute(self, step, context=None, files=None):  
        \# Determine tools and target files  
        results \= {}  
        \# Run ruff/black/isort and collect results  
        \# Compute success and generate artifacts  
        return AdapterResult(success=success, output=output, artifacts=artifacts,  
                             metadata={...})

**Minimal Verification Plugin Example:**

\# my\_linter.py  
from typing import List, Dict

def discover() \-\> List\[str\]:  
    return \["src/"\]

def run(files: List\[str\]) \-\> Dict\[str, any\]:  
    \# run linter on files  
    return {"passed": True, "issues": 0}

def report(result: Dict\[str, any\]) \-\> str:  
    return f"Linter passed: {result\['issues'\]} issues"

**Full‑Featured Verification Plugin (PyTestPlugin):** It checks for pytest, discovers test files, runs pytest with coverage, parses results and returns a structured dictionary with pass/fail counts[\[5\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/scripts/validation/pytest.py#L14-L134).

**GUI Plugin Example:**

\# my\_gui\_extension.py  
from typing import Any  
class MyPlugin:  
    def activate(self, main\_window: Any) \-\> None:  
        \# add a menu or button  
        ...  
    def deactivate(self) \-\> None:  
        \# remove UI elements  
        ...  
plugin \= MyPlugin()

---

## Section A4: PLUGIN CONTRACTS & INTERFACES

### A4.1 Core Contracts

#### *Contract: **BaseAdapter**[\[8\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/base_adapter.py#L78-L119)*

**Purpose:** Defines the interface for all adapters that execute workflow steps. Ensures consistent behavior across deterministic tools and AI services.

**Required Methods/Functions:**

class BaseAdapter:  
    name: str  \# unique adapter name  
    adapter\_type: AdapterType  \# deterministic or ai  
    description: str

    def execute(self, step: dict\[str, Any\], context: Optional\[dict\[str, Any\]\] \= None,  
                files: Optional\[str\] \= None) \-\> AdapterResult:  
        """Run the step and return result."""

    def validate\_step(self, step: dict\[str, Any\]) \-\> bool:  
        """Return True if the adapter can handle the step."""

    def estimate\_cost(self, step: dict\[str, Any\]) \-\> int:  
        """Estimate token cost for budgeting."""

**Input Schema:**

{  
  "id": "string",          // unique step id  
  "name": "string",        // human label  
  "actor": "string",       // adapter name  
  "with": { ... },          // adapter‑specific parameters  
  "files": "string|list",  // optional glob pattern  
  "policy": { ... }         // routing policy  
}

**Output Schema:**

{  
  "success": "boolean",  
  "output": "string",  
  "artifacts": \["string"\],  
  "tokens\_used": "integer",  
  "error": "string|null",  
  "metadata": { ... }  
}

**Validation Rules:** \- execute must return an AdapterResult with all fields populated. \- validate\_step should check required parameters and external tool availability. \- estimate\_cost should return 0 for deterministic adapters and a conservative token estimate for AI adapters[\[13\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/ai_editor.py#L315-L328).

**Example Implementation:** See CodeFixersAdapter above for a concrete example of a deterministic adapter[\[11\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/code_fixers.py#L85-L116).

#### *Contract: **Verification Plugin***

**Purpose:** Standardizes verification gates such as testing, linting and schema validation. Enables adding new quality checks without modifying core.

**Required Functions:**

def discover() \-\> list\[str\]:  
    """Return list of items to verify (files, tests)"""

def run(files: list\[str\]) \-\> dict\[str, any\]:  
    """Execute the check and return structured result with status."""

def report(result: dict\[str, any\]) \-\> str:  
    """Generate human‑readable summary and optionally write artifacts."""

**Input Schema:** Implementation‑specific. For PyTestPlugin, run() receives a list of test files and optional arguments; for RuffSemgrepPlugin, it receives file patterns and configuration[\[7\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/scripts/validation/ruff_semgrep.py#L14-L98).

**Output Schema:**

{  
  "status": "PASS|FAIL|WARNING|ERROR|TIMEOUT",  
  "counts": { "passed": int, "failed": int, "warnings": int },  
  "details": { ... },  
  "artifacts": \["string"\]  
}

**Validation Rules:** \- discover should handle missing dependencies gracefully (e.g., skip tests if pytest unavailable)[\[5\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/scripts/validation/pytest.py#L14-L134). \- run must catch exceptions and return a status of ERROR or TIMEOUT accordingly[\[7\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/scripts/validation/ruff_semgrep.py#L14-L98). \- report should not throw exceptions; errors should be reflected in output.

**Example Implementation:** RuffSemgrepPlugin runs Ruff and Semgrep, collects exit codes, counts issues and returns PASS/FAIL/WARNING statuses[\[7\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/scripts/validation/ruff_semgrep.py#L14-L98).

#### *Contract: **GUI Plugin**[\[1\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/gui_terminal/plugins/__init__.py#L8-L13)*

**Purpose:** Extend the GUI with additional panes, menu items or actions.

**Required Methods:**

class PluginProtocol:  
    def activate(self, main\_window: Any) \-\> None:  
        """Add widgets or actions to the GUI."""  
    def deactivate(self) \-\> None:  
        """Remove widgets/actions and clean up."""

**Input Schema:** activate receives a reference to the main window; no other parameters.

**Output Schema:** None.

**Validation Rules:** Plugins should avoid blocking the UI thread; long tasks must use QThreads. Failing to implement activate or deactivate prevents the plugin from loading[\[4\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/gui_terminal/plugins/manager.py#L27-L60).

**Example Implementation:** A plugin could add a “Diff Viewer” tab to the UI and remove it on deactivation.

### A4.2 Communication Protocols

**Plugin → Core:** \- Adapters return AdapterResult objects to the core; they may also call core services such as cost tracking or artifact management indirectly via helper methods on BaseAdapter. \- Verification plugins return dictionaries; the core interprets statuses and may persist artifacts. \- GUI plugins call methods on the main window (e.g., main\_window.addTab) and use Qt signals/slots.

**Core → Plugin:** \- StepExecutor invokes execute and passes step context[\[10\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/core/executor.py#L61-L127). \- The verification framework invokes discover, run and report according to the checkpoint configuration[\[5\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/scripts/validation/pytest.py#L14-L134). \- GUI plugin manager calls activate/deactivate at startup/shutdown[\[1\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/gui_terminal/plugins/__init__.py#L8-L13). \- Errors thrown by plugins are caught and wrapped in result objects; the core does not crash on plugin failures[\[15\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/core/executor.py#L61-L137).

**Plugin → Plugin:** Plugins generally do not communicate directly. The orchestrator orchestrates calls; however, adapters may read artifacts produced by previous adapters (via file system) and verification plugins may examine artifacts. Shared state flows through the context dictionary passed between steps[\[16\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/core/coordinator.py#L61-L120).

---

## Section A5: PLUGIN CAPABILITIES & PERMISSIONS

### A5.1 Permission Model

The system classifies adapters by capability and restricts what they can do:

* **Deterministic adapters** (e.g., code fixing, linting, testing) run local tools. They do not consume API tokens and may run in parallel. They can access the repository’s file system but must not make network requests. They can produce artifacts via built‑in helpers.

* **AI adapters** (e.g., ai\_editor, ai\_analyst) call external AI APIs like Aider, Claude, GPT. They require API keys and network access and have strict cost budgeting. They may edit files but must respect context size limits and cost budgets[\[17\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/ai_editor.py#L53-L53).

* **Verification plugins** are limited to reading files and executing linter/test commands; they cannot modify code. They return structured results. Plugins cannot write arbitrary files except under the artifacts directory[\[5\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/scripts/validation/pytest.py#L14-L134).

* **GUI plugins** can add UI components but must not access sensitive data outside of orchestrator context; they adhere to Qt’s security model.

**Capability Declarations:** Adapters declare a performance profile via get\_performance\_profile() containing complexity thresholds, preferred file types, parallel capability and cost efficiency[\[18\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/code_fixers.py#L53-L66). Verification plugins do not declare capabilities; their names imply function.

**Restrictions:** \- ❌ Plugins cannot override core routing or cost tracking policies. \- ❌ AI adapters cannot run without valid API keys and environment checks; otherwise they return errors[\[19\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/ai_editor.py#L331-L350). \- ❌ Verification plugins cannot write outside of the artifacts or logs directories.

**Sandboxing/Isolation:** There is no process isolation. To mitigate risk, plugins must catch exceptions and return errors; the orchestrator logs errors and continues if possible. Token/timeouts for AI adapters limit resource usage[\[20\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/ai_editor.py#L167-L168). Cost budgets restrict the number of tokens used; once exceeded, further AI calls are blocked by CostTracker.

### A5.2 Core Services Available to Plugins

| Service | Purpose | Access Pattern | Permission Required |
| :---- | :---- | :---- | :---- |
| **CostTracker** | Tracks token usage and budget across operations[\[21\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/cost_tracker.py#L21-L24) | Adapters call add\_tokens after AI calls; can query budget summaries | API adapters must supply model and token count |
| **Artifact Manager** | Helps write artifacts to the artifacts/ directory and generate JSON reports | BaseAdapter provides \_generate\_artifacts() helper[\[22\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/code_fixers.py#L270-L307) | None (deterministic) |
| **Router** | Determines which adapter to run for a step and provides complexity/determinism analysis[\[23\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/routing/router.py#L21-L45) | Plugins do not call router directly; step executor uses it | N/A |
| **GateManager** | Executes verification gates on artifacts and aggregates results[\[24\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/core/gate_manager.py#L81-L124) | Adapters can define gates in workflow YAML; results accessible via context | None |
| **FileScopeManager** | Coordinates exclusive access to files during parallel execution[\[25\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/coordination/coordinator.py#L48-L74) | Used by router and parallel planner; not directly used by plugins | None |
| **Performance History** | Keeps metrics on adapter execution time and success rate[\[26\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/routing/router.py#L79-L99) | Router uses to adjust confidence when selecting deterministic alternatives | None |

---

## Section A6: PLUGIN VALIDATION & QUALITY GATES

### A6.1 Pre‑Load Validation

The orchestrator performs several checks before loading a plugin:

1. **Adapter registration** – When registering a class or module, AdapterFactory ensures it has a valid name and inherits from BaseAdapter[\[2\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/factory.py#L19-L40). Missing methods cause registration to fail, and the adapter is logged as unavailable.

2. **Tool availability** – Adapters check that required external tools exist. For example, CodeFixersAdapter verifies that ruff, black and isort are installed[\[6\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/code_fixers.py#L38-L47); if none are found, the adapter is marked unavailable.

3. **Verification plugin functions** – The verification framework expects discover, run and report functions; if any are missing, the plugin is skipped[\[5\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/scripts/validation/pytest.py#L14-L134).

4. **GUI plugin structure** – The plugin manager confirms a module exports a plugin object implementing activate and deactivate; missing attributes cause an error[\[1\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/gui_terminal/plugins/__init__.py#L8-L13).

**Validation Command:** There is no separate command to validate plugins; however, cli-orchestrator validate (via WorkflowCoordinator.validate\_workflow\_file()) checks workflow definitions and adapter availability, returning errors and warnings[\[27\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/core/executor.py#L211-L252).

### A6.2 Runtime Safety Mechanisms

**Error Isolation:** \- Exceptions thrown by adapters or verification plugins are caught and wrapped into result objects. Step execution returns success=False with the error message, and the workflow can continue or halt based on policy[\[28\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/core/executor.py#L129-L137). \- Verification plugin failures do not crash the orchestrator; gates return failure statuses that block promotion but the process completes[\[24\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/core/gate_manager.py#L81-L124).

**Resource Limits:** \- **Memory/CPU:** No explicit enforcement; deterministic tools rely on their own resource usage. AI adapters enforce timeouts on subprocess calls (e.g., 60–300s) to prevent hangs[\[20\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/ai_editor.py#L167-L168). \- **Time:** Adapters set timeouts for external commands (e.g., ruff 60s, pytest default). AI editing uses a 5‑minute timeout[\[20\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/ai_editor.py#L167-L168). \- **I/O:** File patterns resolve only within the repository; adapters do not follow symlinks or network paths.[\[29\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/code_fixers.py#L161-L178).

**Circuit Breakers:** \- Cost budgets are enforced by CostTracker. If token usage exceeds the budget, check\_budget\_limits can abort further AI calls.[\[21\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/cost_tracker.py#L21-L24). \- Router’s performance history discourages using adapters with low success rates; it decreases the deterministic confidence score used for fallback decisions[\[26\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/routing/router.py#L79-L99).

---

## Section A7: PLUGIN CONFIGURATION & CUSTOMIZATION

### A7.1 Configuration System

**Configuration Sources:** \- **Workflow YAML** – Each workflow step defines the actor (adapter name) and a with section containing adapter‑specific parameters. This is the primary configuration mechanism. \- **Environment variables** – AI adapters rely on environment variables such as ANTHROPIC\_API\_KEY, OPENAI\_API\_KEY and GEMINI\_API\_KEY for authentication[\[30\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/ai_editor.py#L400-L413). \- **CLI options** – Verification plugins can be executed via separate CLI entry points (e.g., scripts/validation/pytest.py \--discover); options control discovery and reporting. \- **Configuration precedence:** Workflow YAML overrides adapter defaults; environment variables configure API keys; global settings (e.g., prefer\_deterministic) in workflow policy influence routing.

**Hot‑Reload Support:** Configuration changes require restarting the workflow run. There is no live reload of adapters.

**Configuration Schema Example:**

steps:  
  \- id: lint\_code  
    name: Lint Python files  
    actor: code\_fixers  
    with:  
      tools: \["ruff", "black"\]  
      files: "src/\*\*/\*.py"  
      fix: false  
    emits:  
      \- artifacts/lint\_report.json  
    policy:  
      prefer\_deterministic: true  
      complexity\_threshold: 0.5

Here the with block configures which tools to run and whether to apply fixes. emits lists artifact paths to write results[\[11\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/code_fixers.py#L85-L116).

### A7.2 Plugin‑Specific Customization

**Customization Points:** \- **Adapters** – Accept with parameters such as tools, prompt, model, max\_tokens etc. Users can override defaults and add policy settings to influence the router[\[31\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/ai_editor.py#L78-L83). \- **Verification plugins** – Accept CLI flags like \--files, \--timeout, \--output when run standalone; discover may read configuration files (e.g., .pre-commit-config.yaml for ruff/semgrep). \- **GUI plugins** – May expose options in the GUI preferences dialog; no standard mechanism.

**Templates/Scaffolding:** The repository does not include a generator, but a new adapter can be scaffolded by copying the BaseAdapter skeleton and registering it under project.entry-points. Example commands:

\# Create a new adapter package  
mkdir my\_adapter && cd my\_adapter  
cat \> my\_adapter.py \<\<'PY'  
from cli\_multi\_rapid.adapters.base\_adapter import BaseAdapter, AdapterResult, AdapterType  
class MyAdapter(BaseAdapter):  
    def \_\_init\_\_(self):  
        super().\_\_init\_\_(name="my\_adapter", adapter\_type=AdapterType.DETERMINISTIC,  
                         description="Example adapter")  
    def execute(self, step, context=None, files=None):  
        return AdapterResult(success=True, output="ok")  
    def validate\_step(self, step):  
        return True  
    def estimate\_cost(self, step):  
        return 0  
PY

\# Add entry point in pyproject.toml  
\# \[project.entry-points."cli\_orchestrator.adapters"\]  
\# my\_adapter \= "my\_adapter:MyAdapter"

---

# PART B: COMPLETE MODULAR ARCHITECTURE

## Section B1: TIER 1: CORE MODULES (Sacred/Privileged)

Core modules form the heart of the orchestrator. They cannot be removed without breaking the system and handle privileged operations such as file access, routing, cost tracking and verification.

### Module 1: **WorkflowCoordinator**

**Purpose:** Load, validate and execute YAML workflows step‑by‑step, aggregating results and handling fail‑fast policy[\[32\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/core/coordinator.py#L63-L120).

**Deliverables:** \- src/cli\_multi\_rapid/core/coordinator.py – Class WorkflowCoordinator and data class WorkflowResult[\[32\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/core/coordinator.py#L63-L120). \- Reads YAML files, merges context, executes steps through a StepExecutor and aggregates metrics (tokens used, execution time, artifacts). \- Provides methods to estimate workflow cost and validate workflows without execution[\[33\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/core/coordinator.py#L303-L369).

**Key Contracts:**

class WorkflowCoordinator:  
    def execute\_workflow(self, workflow\_path: str, files: Optional\[str\] \= None,  
                         extra\_context: Optional\[Dict\[str, Any\]\] \= None) \-\> WorkflowResult  
    def execute\_workflow\_from\_dict(self, workflow: Dict\[str, Any\], files: Optional\[str\] \= None,  
                                   extra\_context: Optional\[Dict\[str, Any\]\] \= None) \-\> WorkflowResult  
    def estimate\_workflow\_cost(self, workflow\_path: str) \-\> Dict\[str, Any\]  
    def validate\_workflow\_file(self, workflow\_path: str) \-\> Dict\[str, Any\]

### Module 2: **StepExecutor**

**Purpose:** Validate steps, select the appropriate adapter via the router and run the step, collecting results[\[10\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/core/executor.py#L61-L127).

**Deliverables:** \- src/cli\_multi\_rapid/core/executor.py – Class StepExecutor and data class StepExecutionResult[\[10\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/core/executor.py#L61-L127). \- Methods to execute a single step, execute a batch of steps and validate steps. \- Interacts with CostTracker to record token usage and with the Router to obtain adapters.

**Key Contracts:**

class StepExecutor:  
    def execute\_step(self, step: Dict\[str, Any\], context: Optional\[Dict\[str, Any\]\],  
                     files: Optional\[str\]) \-\> StepExecutionResult  
    def estimate\_step\_cost(self, step: Dict\[str, Any\]) \-\> int  
    def validate\_steps(self, steps: List\[Dict\[str, Any\]\]) \-\> Dict\[str, Any\]

### Module 3: **Router**

**Purpose:** Determine which adapter should handle each workflow step based on complexity analysis, determinism and policy; manage parallel execution plans[\[23\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/routing/router.py#L21-L45).

**Deliverables:** \- src/cli\_multi\_rapid/routing/router.py – Class Router and its dependencies: ComplexityAnalyzer, ParallelPlanner, ResourceAllocator[\[34\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/routing/router.py#L21-L34). \- Stores an AdapterRegistry, performance history and a DeterministicEngine to analyse steps. \- Provides methods route\_step(), route\_parallel\_steps() and create\_allocation\_plan()[\[35\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/routing/router.py#L101-L157).

**Key Contracts:**

class Router:  
    def get\_adapter(self, actor: str) \-\> BaseAdapter  
    def route\_step(self, step: dict\[str, Any\], policy: Optional\[dict\[str, Any\]\] \= None) \-\> RoutingDecision  
    def route\_parallel\_steps(self, steps: list\[dict\[str, Any\]\], policy: Optional\[dict\[str, Any\]\] \= None)  
        \-\> ParallelRoutingPlan  
    def create\_allocation\_plan(self, workflows: list\[dict\[str, Any\]\], budget: Optional\[float\] \= None,  
                               max\_parallel: int \= 3\) \-\> AllocationPlan

### Module 4: **AdapterRegistry & AdapterFactory**

**Purpose:** Keep track of available adapters and lazily load them from entry points or modules[\[2\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/factory.py#L19-L40).

**Deliverables:** \- src/cli\_multi\_rapid/adapters/adapter\_registry.py – Class AdapterRegistry with methods to register, list, check availability and instantiate adapters. \- src/cli\_multi\_rapid/adapters/factory.py – Class AdapterFactory that discovers plugins via setuptools entry points and supports registration of custom modules or classes[\[2\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/factory.py#L19-L40).

**Key Contracts:**

class AdapterRegistry:  
    def register\_class(self, cls: type\[BaseAdapter\]) \-\> None  
    def register\_instance(self, instance: BaseAdapter) \-\> None  
    def get\_adapter(self, name: str) \-\> Optional\[BaseAdapter\]  
    def list\_adapters(self) \-\> dict\[str, dict\]  
    def is\_available(self, name: str) \-\> bool

class AdapterFactory:  
    def register\_module(self, name: str, module\_path: str) \-\> None  
    def register\_class(self, name: str, cls: type\[BaseAdapter\]) \-\> None  
    def register\_instance(self, name: str, instance: BaseAdapter) \-\> None  
    def create(self, name: str) \-\> Optional\[BaseAdapter\]

### Module 5: **ComplexityAnalyzer**

**Purpose:** Analyse workflow steps to determine complexity score, factor breakdown and deterministic confidence[\[36\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/routing/complexity_analyzer.py#L11-L19).

**Deliverables:** \- src/cli\_multi\_rapid/routing/complexity\_analyzer.py – Class ComplexityAnalyzer computing file counts, estimated sizes and operation type influences. \- Returns a ComplexityAnalysis dataclass with factors and scores for use by the router[\[37\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/routing/models.py#L38-L47).

**Key Contracts:**

class ComplexityAnalyzer:  
    def analyze\_step(self, step: dict\[str, Any\]) \-\> ComplexityAnalysis

### Module 6: **ParallelPlanner & ResourceAllocator**

**Purpose:** Determine which steps can run concurrently and allocate adapters within a budget.[\[38\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/routing/parallel_planner.py#L8-L60)[\[39\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/routing/resource_allocator.py#L8-L68)

**Deliverables:** \- src/cli\_multi\_rapid/routing/parallel\_planner.py – Class ParallelPlanner to group steps into execution batches considering file conflicts and adapter types[\[40\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/routing/parallel_planner.py#L14-L60). \- src/cli\_multi\_rapid/routing/resource\_allocator.py – Class ResourceAllocator building allocation plans across multiple workflows and computing total token cost[\[39\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/routing/resource_allocator.py#L8-L68).

**Key Contracts:**

class ParallelPlanner:  
    def create\_parallel\_plan(self, steps: list\[dict\[str, Any\]\], route\_step: Callable,  
                             policy: dict\[str, Any\] | None \= None) \-\> ParallelRoutingPlan

class ResourceAllocator:  
    def create\_allocation\_plan(self, workflows: list\[dict\[str, Any\]\], budget: Optional\[float\] \= None,  
                               max\_parallel: int \= 3\) \-\> AllocationPlan

### Module 7: **GateManager**

**Purpose:** Execute verification gates on artifacts and enforce quality policies.[\[24\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/core/gate_manager.py#L81-L124)

**Deliverables:** \- src/cli\_multi\_rapid/core/gate\_manager.py – Class GateManager, Enum GateType, dataclass GateResult and methods for executing built‑in gates (tests\_pass, diff\_limits, schema\_valid) and registering custom gates.

**Key Contracts:**

class GateManager:  
    def execute\_gates(self, gates: List\[Dict\[str, Any\]\], artifacts: List\[str\],  
                      context: Optional\[Dict\[str, Any\]\] \= None) \-\> List\[GateResult\]  
    def register\_custom\_gate(self, gate\_type: str, handler: Callable) \-\> None  
    def aggregate\_gate\_results(self, results: List\[GateResult\]) \-\> Dict\[str, Any\]

### Module 8: **CostTracker & Domain Cost Modules**

**Purpose:** Track token usage, enforce budgets and produce cost reports[\[21\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/cost_tracker.py#L21-L24).

**Deliverables:** \- src/cli\_multi\_rapid/cost\_tracker.py – Facade CostTracker delegating to domain logic and file storage[\[21\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/cost_tracker.py#L21-L24). \- src/cli\_multi\_rapid/domain/cost/tracker.py – Domain class CostTracker handling persistence, budget allocation and reporting[\[41\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/domain/cost/tracker.py#L12-L71). \- src/cli\_multi\_rapid/adapters/storage/cost\_storage.py – File‑based storage for token usage logs[\[42\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/storage/cost_storage.py#L11-L26).

**Key Contracts:**

class CostTracker:  
    def record\_usage(self, operation: str, tokens\_used: int, model: str \= "unknown",  
                     workflow\_id: Optional\[str\] \= None, ... ) \-\> float  
    def get\_daily\_usage(self, target\_date: Optional\[date\] \= None) \-\> dict\[str, Any\]  
    def check\_budget\_limits(self, budget: Optional\[BudgetLimit\], tokens\_to\_spend: int \= 0\) \-\> dict\[str, Any\]  
    def generate\_report(self, last\_run: bool \= False, detailed: bool \= False, days: int \= 7\)  
        \-\> dict\[str, Any\]  
    def allocate\_budget(self, workflows: list\[dict\[str, Any\]\], coordination\_budget: CoordinationBudget)  
        \-\> dict\[str, float\]

### Module 9: **Coordination & FileScopeManager**

**Purpose:** Support advanced workflow coordination modes (sequential, parallel, IPT\_WT) and manage exclusive file access for parallel execution[\[25\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/coordination/coordinator.py#L48-L74).

**Deliverables:** \- src/cli\_multi\_rapid/coordination/coordinator.py – Lightweight WorkflowCoordinator for high‑level coordination plans and a FileScopeManager that tracks file locks to prevent conflicts[\[25\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/coordination/coordinator.py#L48-L74).

**Key Contracts:**

class CoordinationPlan:  
    mode: CoordinationMode  
    parallel\_groups: list\[list\[str\]\]  
    dependencies: dict\[str, list\[str\]\]

class WorkflowCoordinator (coordination version):  
    def register\_workflow(self, workflow\_id: str, plan: CoordinationPlan) \-\> None  
    def get\_plan(self, workflow\_id: str) \-\> Optional\[CoordinationPlan\]

class FileScopeManager:  
    def acquire\_file(self, workflow\_id: str, file\_path: str) \-\> bool  
    def release\_file(self, workflow\_id: str, file\_path: str) \-\> None  
    def release\_all(self, workflow\_id: str) \-\> None

---

## Section B2: TIER 2: PLUGIN/EXTENSION MODULES (Extensible/Evolvable)

This tier contains optional modules that extend functionality via the plugin systems. They can be added or removed without breaking core functionality.

### Module 1: **CodeFixersAdapter**

**Purpose:** Apply deterministic code fixes using ruff, black and isort[\[43\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/code_fixers.py#L27-L50).

**Deliverables:** \- src/cli\_multi\_rapid/adapters/code\_fixers.py – Class CodeFixersAdapter inheriting BaseAdapter. \- Runs code formatters and linters on specified files; generates artifact reports in JSON[\[11\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/code_fixers.py#L85-L116).

**Trigger:** execute hook when the workflow step actor is code\_fixers.

**Input Contract:**

{  
  "event": "execute",  
  "inputs": {  
    "files": "glob pattern for Python files",  
    "tools": \["ruff", "black", "isort"\],  
    "fix": true/false  
  }  
}

**Output Contract:**

{  
  "action": "finish",  
  "payload": {  
    "success": "boolean",  
    "output": "summary string",  
    "artifacts": \["artifact\_path"\],  
    "metadata": {  
      "tools\_run": \["ruff", ...\],  
      "files\_processed": int,  
      "total\_fixes": int  
    }  
  }  
}

**Identification Criteria:** Deterministic adapter implementing code formatting; optional and user‑configurable via with.tools.

### Module 2: **AIEditorAdapter**

**Purpose:** Provide AI‑powered code editing using the aider CLI or other AI services[\[44\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/ai_editor.py#L27-L44).

**Deliverables:** \- src/cli\_multi\_rapid/adapters/ai\_editor.py – Class AIEditorAdapter. \- Integrates with aider, supports operations like edit, refactor, generate and uses API keys for Claude, GPT or Gemini[\[45\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/ai_editor.py#L55-L100).

**Trigger:** Step with actor ai\_editor.

**Input Contract:**

{  
  "event": "execute",  
  "inputs": {  
    "tool": "aider|claude\_direct",  
    "operation": "edit|refactor|generate",  
    "prompt": "string",  
    "model": "string",  
    "max\_tokens": int,  
    "files": "glob pattern"  
  }  
}

**Output Contract:**

{  
  "action": "finish",  
  "payload": {  
    "success": "boolean",  
    "tokens\_used": int,  
    "output": "AI tool output",  
    "artifacts": \["diff artifact"\],  
    "metadata": {  
      "tool": "aider",  
      "model": "claude-3-5-sonnet-20241022",  
      "files\_modified": int,  
      "prompt\_length": int  
    }  
  }  
}

**Identification Criteria:** AI adapter requiring external API keys; expensive; uses deterministic fallback if complexity is low and policy prefers deterministic[\[14\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/routing/router.py#L101-L157).

### Module 3: **PyTestPlugin**

**Purpose:** Verification plugin that runs pytest tests and collects results.[\[5\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/scripts/validation/pytest.py#L14-L134)

**Deliverables:** \- scripts/validation/pytest.py – Contains class PyTestPlugin with discover, run and report methods and a CLI entry point. \- Discovers test files, runs pytest with coverage, parses results and writes a JSON report; returns PASS/FAIL counts.

**Trigger:** Verification gate tests\_pass in a checkpoint. Executed via ipt verify or GateManager.

**Input Contract:**

{  
  "event": "run",  
  "inputs": {  
    "files": \["list of test files"\],  
    "with": {  
      "timeout": 300,  
      "markers": \["string"\],  
      "fail\_fast": true  
    }  
  }  
}

**Output Contract:**

{  
  "status": "PASS|FAIL|ERROR",  
  "counts": {"passed": int, "failed": int, "skipped": int},  
  "errors": \["error messages"\],  
  "artifacts": \["test\_report.json"\]  
}

**Identification Criteria:** Lives under scripts/validation; uses pytest; optional; executed only if defined in gates.

### Module 4: **RuffSemgrepPlugin**

**Purpose:** Combined linting and security scanning plugin using Ruff and Semgrep[\[7\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/scripts/validation/ruff_semgrep.py#L14-L98).

**Deliverables:** \- scripts/validation/ruff\_semgrep.py – Defines RuffSemgrepPlugin with discover, run and report methods. \- Runs Ruff for Python linting and Semgrep for security scanning; merges their results and returns status PASS/FAIL/WARNING.

**Trigger:** Verification gate lint\_scan (example name) or when configured in checkpoint.

**Input Contract:** Similar to PyTest but includes with.tools selection and configuration paths.

**Output Contract:**

{  
  "status": "PASS|FAIL|WARNING|TIMEOUT",  
  "ruff\_issues": int,  
  "semgrep\_findings": int,  
  "artifacts": \["lint\_semgrep\_report.json"\]  
}

**Identification Criteria:** Plugin combining multiple tools; optional; executed sequentially.

### Module 5: **SchemaValidationPlugin**

**Purpose:** Validate JSON/YAML artifacts against JSON Schema or OpenAPI specifications[\[9\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/scripts/validation/schema_validate.py#L16-L115).

**Deliverables:** \- scripts/validation/schema\_validate.py – Class SchemaValidationPlugin implementing discover, run and report functions. \- Traverses schema files and validates each artifact; returns detailed PASS/FAIL/SKIP statuses per rule.

**Trigger:** Verification gate schema\_valid.

**Input Contract:**

{  
  "event": "run",  
  "inputs": {  
    "schemas": \["path to schema files"\],  
    "artifacts": \["artifact paths"\]  
  }  
}

**Output Contract:**

{  
  "status": "PASS|FAIL",  
  "results": \[  
    {"file": "artifact.json", "rule": "openapi", "status": "PASS", "error": null},  
    ...  
  \],  
  "artifacts": \["schema\_validation\_report.json"\]  
}

**Identification Criteria:** Plugin specialized in schema validation; optional.

### Module 6: **GUI Plugins**

The repository currently provides a plugin manager but includes no concrete GUI plugin examples. Third‑party developers can implement modules under gui\_terminal/plugins and expose a plugin object.

**Trigger:** Loaded at GUI startup; activate called automatically.

**Identification Criteria:** Must implement activate/deactivate and register itself via placement in the plugin directory.[\[4\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/gui_terminal/plugins/manager.py#L27-L60)

---

## Section B3: TIER 3: SUPPORT MODULES

Support modules provide utilities reused across core and plugins. They do not implement business logic directly but enable cross‑cutting concerns.

### Module 1: **Adapter Storage & File I/O Utilities**

**Purpose:** Provide file storage for artifacts (e.g., artifacts/ and logs/) and cost logs, and handle reading/writing JSON/JSONL files[\[42\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/storage/cost_storage.py#L11-L26).

**Deliverables:** \- src/cli\_multi\_rapid/adapters/storage/cost\_storage.py – FileCostStorage implementing CostStoragePort using JSONL files. \- Helpers in adapters like \_generate\_artifacts() write artifacts into designated directories[\[22\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/code_fixers.py#L270-L307).

**Key Contracts:**

class FileCostStorage:  
    def save(self, record: dict) \-\> None  
    def iter\_all(self) \-\> Iterable\[dict\]  
    def iter\_by\_date(self, target\_date: date) \-\> Iterable\[dict\]

### Module 2: **Domain Models & Calculators**

**Purpose:** Encapsulate pure business logic (token cost calculation, budget management, cost summaries) in domain.cost package[\[41\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/domain/cost/tracker.py#L12-L71).

**Deliverables:** \- src/cli\_multi\_rapid/domain/cost/calculator.py – Cost per token for various AI models. \- src/cli\_multi\_rapid/domain/cost/models.py – Data classes for BudgetLimit, CoordinationBudget, WorkflowCostSummary. \- src/cli\_multi\_rapid/domain/cost/budget\_manager.py – Budget checking logic.

### Module 3: **DeterministicEngine**

**Purpose:** Analyse steps to determine whether a deterministic adapter can replace an AI adapter and provide reasoning[\[46\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/routing/router.py#L37-L45).

**Deliverables:** \- src/cli\_multi\_rapid/deterministic\_engine.py – Class DeterministicEngine with analyze\_step returning issues and deterministic confidence.

### Module 4: **Verifier & Schema Utils**

**Purpose:** Provide generic verification helpers reused by verification plugins (e.g., schema validation engine used by GateManager)[\[47\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/core/gate_manager.py#L253-L265).

**Deliverables:** \- src/cli\_multi\_rapid/verifier.py – Class Verifier with methods verify\_artifact() used by gate manager for schema gates[\[47\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/core/gate_manager.py#L253-L265). \- src/cli\_multi\_rapid/utils/ – Various helper functions (date formatting, logging, CLI utilities).

### Module 5: **GUI Core & Bridge**

**Purpose:** Provide the GUI front‑end bridging the orchestrator to a PyQt6 interface. Although not part of the CLI core, it offers significant value for users.

**Deliverables:** \- src/gui\_terminal/gui\_bridge.py – WorkflowExecutor and CostTrackerBridge classes bridging CLI operations to Qt signals[\[48\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/docs/gui/IMPLEMENTATION_SUMMARY.md#L19-L24). \- src/gui\_terminal/core/execution\_manager.py – Manage execution state and emit signals. \- src/gui\_terminal/plugins/manager.py – Plugin manager scanning plugin directory and activating GUI plugins[\[4\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/gui_terminal/plugins/manager.py#L27-L60).

---

## Section B4: COMPLETE DELIVERABLES SUMMARY TABLE

| Module | Core Files | Generated Artifacts | Config Files | Tests |
| :---- | :---- | :---- | :---- | :---- |
| **WorkflowCoordinator** | coordinator.py | Aggregated workflow results (JSON), cost estimates | Workflow YAMLs in workflows/ | tests/core/test\_workflow\_coordinator.py |
| **StepExecutor** | executor.py | Step results (in‑memory), error logs | None (uses step definitions) | tests/core/test\_step\_executor.py |
| **Router** | routing/router.py, complexity\_analyzer.py, parallel\_planner.py, resource\_allocator.py | Performance history JSON in state/routing/ | Routing policies defined in workflow YAML | tests/routing/test\_router.py |
| **AdapterRegistry & Factory** | adapters/adapter\_registry.py, adapters/factory.py | None | pyproject.toml entry points | tests/adapters/test\_factory.py |
| **GateManager** | core/gate\_manager.py | Gate result summaries | Gate definitions in workflow YAML | tests/core/test\_gate\_manager.py |
| **CostTracker** | cost\_tracker.py, domain/cost/\*.py, adapters/storage/cost\_storage.py | logs/token\_usage.jsonl, cost reports | Budget configuration in workflow metadata | tests/cost/test\_cost\_tracker.py |
| **Coordination & FileScopeManager** | coordination/coordinator.py | None | Coordination plans in workflow metadata | tests/coordination/test\_coordinator.py |
| **CodeFixersAdapter** | adapters/code\_fixers.py | Artifacts with tool results | Configured via workflow with section | tests/integration/test\_code\_fixers.py |
| **AIEditorAdapter** | adapters/ai\_editor.py | Diff artifacts, AI outputs | API keys in environment, workflow parameters | tests/integration/test\_ai\_adapters.py |
| **PyTestPlugin** | scripts/validation/pytest.py | artifacts/test\_report.json | None | tests/validation/test\_pytest\_plugin.py |
| **RuffSemgrepPlugin** | scripts/validation/ruff\_semgrep.py | artifacts/ruff\_semgrep\_report.json | Semgrep config (optional) | tests/validation/test\_ruff\_semgrep\_plugin.py |
| **SchemaValidationPlugin** | scripts/validation/schema\_validate.py | artifacts/schema\_validation\_report.json | JSON/YAML schema files | tests/validation/test\_schema\_validation\_plugin.py |
| **GUI Core** | gui\_terminal/gui\_bridge.py, gui\_terminal/core/execution\_manager.py, gui\_terminal/plugins/manager.py | None | GUI settings (none) | tests/gui/test\_workflow\_browser.py, tests/gui/test\_execution\_manager.py |

---

## Section B5: MODULE DEPENDENCIES

\[WorkflowCoordinator\]  
├── \[StepExecutor\] – executes each workflow step  
│   └── \[Router\] – chooses adapter based on complexity and determinism  
│       ├── \[AdapterRegistry & Factory\] – provides adapter instances  
│       │   └── \[Adapters\] (CodeFixers, AIEditor, etc.) – execute steps  
│       ├── \[ComplexityAnalyzer\] – analyses step complexity  
│       ├── \[DeterministicEngine\] – analyses whether deterministic adapter can be used  
│       ├── \[ParallelPlanner\] – groups steps into parallel execution batches  
│       └── \[ResourceAllocator\] – assigns adapters across workflows within budget  
├── \[GateManager\] – runs verification gates after workflow completes  
│   ├── \[PyTestPlugin\], \[RuffSemgrepPlugin\], \[SchemaValidationPlugin\] – perform checks  
│   └── \[Verifier\] – optional schema validation engine  
├── \[CostTracker\] – records token usage and checks budgets  
│   └── \[CostStorage\] – persists usage logs to JSONL  
└── \[Coordination (optional)\]  
    ├── \[FileScopeManager\] – manages file locks for parallel steps  
    └── \[CoordinationPlan\] – defines execution order and dependencies

\[GUI Terminal\]  
├── \[gui\_bridge.WorkflowExecutor\] – wraps WorkflowCoordinator in Qt threads  
├── \[gui\_bridge.CostTrackerBridge\] – exposes cost data to UI  
├── \[execution\_manager\] – manages execution states and history  
├── \[plugin\_manager\] – loads GUI plugins  
└── \[UI components\] (workflow browser, config form, execution dashboard, cost dashboard, artifact viewer, github panel)

---

## Section B6: INTEGRATION POINTS

### External Tool Integration

* **Ruff, Black, Isort** – Deterministic formatting and linting tools invoked via subprocess by CodeFixersAdapter[\[11\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/code_fixers.py#L85-L116).

* **PyTest** – Testing framework run by PyTestPlugin with coverage; results parsed and reported[\[5\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/scripts/validation/pytest.py#L14-L134).

* **Semgrep** – Security scanning tool used by RuffSemgrepPlugin for static analysis[\[7\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/scripts/validation/ruff_semgrep.py#L14-L98).

* **jsonschema/OpenAPI libraries** – Used by SchemaValidationPlugin and the Verifier to validate artifacts[\[9\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/scripts/validation/schema_validate.py#L16-L115).

* **Aider/Claude/GPT/Gemini** – AI services used by AIEditorAdapter; invoked via CLI or direct API calls with environment‑configured API keys[\[17\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/ai_editor.py#L53-L53).

* **Git** – Some adapters generate diffs and commit changes; AIEditorAdapter uses git diff to produce artifacts[\[49\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/ai_editor.py#L265-L293).

* **Rich and PyQt6** – Rich used for terminal output; PyQt6 used for GUI components.

### Data Flows

1. **Running a Workflow** → User invokes cli-orchestrator run workflow.yaml → WorkflowCoordinator loads YAML and validates it[\[16\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/core/coordinator.py#L61-L120) → For each step, StepExecutor validates step and asks Router for adapter → Router analyses complexity, determinism and selects adapter or fallback[\[14\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/routing/router.py#L101-L157) → Adapter executes the step, producing AdapterResult and artifacts (e.g., code fixes, AI edits) → CostTracker records tokens used (if AI) → WorkflowCoordinator updates context and continues → At end, aggregated WorkflowResult returned.

2. **Verification Check** → User runs ipt verify \--checkpoint \<id\> or workflow defines gates → GateManager iterates through gates defined in workflow → For each gate, corresponding verification plugin’s discover, run, report functions are called[\[5\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/scripts/validation/pytest.py#L14-L134) → Plugin outputs artifacts and statuses → GateManager aggregates results and determines PASS/FAIL status; if any gate fails, workflow may halt.

3. **GUI Execution** → User launches cli-orchestrator-gui → WorkflowBrowser reads available workflows and user selects one → WorkflowExecutor runs workflow via WorkflowCoordinator inside a QThread, emitting progress signals → CostTrackerBridge feeds live token usage to cost dashboard → Artifacts are displayed in the artifact viewer once created → GUI plugins (if any) provide extra panes.

4. **Routing Fallback** → Router.route\_step() receives a step targeting an AI adapter → ComplexityAnalyzer computes complexity score and DeterministicEngine assesses deterministic viability → If complexity below threshold and deterministic alternative exists, router selects a deterministic adapter such as code\_fixers or vscode\_diagnostics; otherwise AI adapter is used with estimated token cost[\[14\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/routing/router.py#L101-L157).

5. **Cost & Budget Monitoring** → Each time an AI adapter returns, StepExecutor calls CostTracker.add\_tokens() → CostTracker writes a JSONL record with timestamp, tokens, model and success[\[50\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/domain/cost/tracker.py#L23-L48) → At any time, users can request a cost report via CostTracker.generate\_report() or view budgets in the GUI cost dashboard → Budget checks may trigger warnings or abort further AI calls when budgets are exceeded.

---

# PART C: PLUGIN ECOSYSTEM & DEVELOPMENT

## Section C1: PLUGIN DEVELOPMENT WORKFLOW

### C1.1 Plugin Creation Process

1. **Identify Extension Point:** Decide whether your plugin is an adapter (executing steps), a verification plugin (quality gate), or a GUI plugin.

2. **Implement the Contract:** For adapters, subclass BaseAdapter and implement execute, validate\_step and estimate\_cost. For verification plugins, implement discover, run and report. For GUI plugins, create a plugin object with activate and deactivate methods.

3. **Register the Plugin:**

4. **Adapter:** Add an entry point under \[project.entry-points."cli\_orchestrator.adapters"\] in your package’s pyproject.toml to register the adapter name.

5. **Verification plugin:** Place your script in the scripts/validation directory or configure your own verify.d path; optionally add a CLI entry point for standalone execution.

6. **GUI plugin:** Put your module in src/gui\_terminal/plugins/ so the plugin manager can discover it.

7. **Configure Workflows:** Create or update YAML workflow files referencing your adapter or verification plugin. Specify parameters in the with section and optional policy settings.

8. **Test the Plugin:** Write unit tests under tests/adapters or tests/validation; run pytest to ensure your plugin behaves correctly. Use the \--dry-run flag to simulate workflows without making changes.

**Tools Required:** \- Python 3.9+ development environment \- Poetry or pip for dependency management \- For AI adapters: API keys for services (e.g., Anthropic, OpenAI, Google Gemini) \- For verification plugins: External tools (pytest, ruff, semgrep)

**Scaffolding/Generators:** The project does not include official scaffolding commands. Developers typically copy an existing adapter (e.g., code\_fixers) and modify it. To simplify registration, use the entry point mechanism described above.

### C1.2 Testing & Debugging

**Testing Framework:** The repository uses pytest for unit and integration tests. Tests for adapters validate validate\_step, execute and estimate\_cost behavior. Tests for verification plugins simulate running the plugin on dummy files. The test harness integrates with coverage and supports cross‑platform execution.

**Debugging Tools:** \- Enable debug logging via the LOGGER in adapters; logs include tool commands, file resolution and errors. \- Use \--dry-run on the CLI to simulate workflow execution without modifying files. \- For AI adapters, track token usage and model selection via returned metadata; adjust prompt and max\_tokens accordingly.

**Test Example:**

\# tests/adapters/test\_my\_adapter.py  
from cli\_multi\_rapid.adapters.base\_adapter import AdapterResult  
from my\_package.my\_adapter import MyAdapter

def test\_execute():  
    adapter \= MyAdapter()  
    step \= {"id": "s1", "name": "Hello", "actor": "my\_adapter"}  
    result: AdapterResult \= adapter.execute(step)  
    assert result.success  
    assert "Hello" in result.output

---

## Section C2: PLUGIN ECOSYSTEM

### C2.1 Official/Built‑in Plugins

| Plugin Name | Purpose | Hooks Used | Stability |
| :---- | :---- | :---- | :---- |
| **code\_fixers** | Deterministic code formatting and linting using ruff/black/isort[\[43\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/code_fixers.py#L27-L50) | Adapter: execute, validate\_step, estimate\_cost | Stable |
| **ai\_editor** | AI‑powered code editing/refactoring/generation via aider, Claude, GPT and Gemini[\[44\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/ai_editor.py#L27-L44) | Adapter: execute, validate\_step, estimate\_cost | Beta – depends on external services |
| **pytest\_runner** | Run pytest tests and collect results[\[5\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/scripts/validation/pytest.py#L14-L134) | Verification: discover, run, report | Stable |
| **ruff\_semgrep** | Run ruff and semgrep for linting and security analysis[\[7\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/scripts/validation/ruff_semgrep.py#L14-L98) | Verification: discover, run, report | Experimental – may require custom config |
| **schema\_validate** | Validate JSON/YAML artifacts against schemas[\[9\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/scripts/validation/schema_validate.py#L16-L115) | Verification: discover, run, report | Stable |
| **gui plugins (none)** | Extend GUI with custom tabs or actions | GUI: activate, deactivate | N/A – user supplied |

### C2.2 Third‑Party Plugin Support

**Distribution Channels:** Adapters and verification plugins can be published as standard Python packages on PyPI. Registering entry points under cli\_orchestrator.adapters or cli\_orchestrator.verifiers allows the orchestrator to discover them automatically. GUI plugins are distributed as modules placed under gui\_terminal/plugins.

**Package Management:** Users install third‑party plugins via pip install my\_cli\_orchestrator\_plugin. The orchestrator’s AdapterFactory will discover registered entry points upon startup.

**Installation Process:**

pip install my-cli-orchestrator-plugin  
\# or install a plugin from source  
pip install \-e path/to/plugin

**Community Resources:** Currently there is no official plugin marketplace. Documentation resides in docs/ and example repositories (the tests directory) illustrate writing adapters and verification plugins. The project encourages contributions via pull requests and includes a CONTRIBUTING.md file.

---

## Section C3: VERSIONING & COMPATIBILITY

### C3.1 API Versioning

**Version Strategy:** The core orchestrator follows semantic versioning. Adapter and verification plugin interfaces are kept stable within major versions. Breaking changes to BaseAdapter or verification hooks require a major version bump and deprecation notice.

**Breaking Change Policy:** When new fields are added to AdapterResult or new hooks are introduced, older plugins continue to work; missing fields default to None. Deprecated methods remain for at least one minor release. The Router shim exports relocated classes for backward compatibility[\[51\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/router.py#L1-L15).

**Deprecation Process:** Deprecated adapters or verification methods emit a warning via the logger. Developers are encouraged to migrate within two minor releases.

**Compatibility Matrix:**

| Core Version | Plugin API Version | Compatible With |
| :---- | :---- | :---- |
| 1.x | 1.x | All built‑in adapters and verification plugins |
| 2.x | 1.x | Compatible via shims; new adapters should target 2.x |

### C3.2 Migration Guides

**Upgrade Paths:** For minor upgrades, ensure that third‑party adapters implement any newly required methods. For major upgrades, consult release notes for interface changes. For example, if estimate\_cost signature changes, adapters should update accordingly.

**Breaking Changes Documentation:** The CHANGELOG.md or release notes outline changes to interfaces and plugin entry points. Use AdapterRegistry.is\_available() to detect unsupported plugins and avoid runtime errors.

**Automated Migration Tools:** None provided; developers manually update adapters.

---

# PART D: ARCHITECTURAL ANALYSIS

## Section D1: PLUGIN ARCHITECTURE STRENGTHS & WEAKNESSES

### D1.1 Architectural Strengths

✅ **Extensibility via unified interfaces** – The BaseAdapter contract allows deterministic tools and AI services to plug in seamlessly. Verification plugins use a simple discover/run/report pattern, and GUI plugins rely on a minimal protocol. This reduces coupling and encourages third‑party contributions.

✅ **Lazy loading and modular registration** – Adapters are loaded on demand via the factory, minimizing startup time and memory footprint[\[2\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/factory.py#L19-L40). Entry points enable independent distribution of plugins.

✅ **Separation of concerns** – The orchestrator core handles scheduling, routing and budget management while delegates execution details to adapters. Verification and GUI extensions are similarly decoupled, improving maintainability.

### D1.2 Architectural Limitations

⚠️ **Lack of isolation/sandboxing** – All plugins run in the same process. Malicious or buggy plugins could crash the orchestrator or modify files unexpectedly. There is no sandbox or permission enforcement beyond trust in plugin authors.

⚠️ **Limited plugin ordering and dependencies** – Verification plugins cannot specify ordering or dependencies between each other, which can be problematic if one plugin’s outcome should gate another.

⚠️ **No built‑in plugin scaffolding** – Developers must manually create adapters and register entry points. Without official templates, inconsistent implementations may arise. Similarly, GUI plugin documentation is minimal, and no examples are provided.

### D1.3 Design Tradeoffs

**Flexibility vs. Performance:** The router’s capability to switch between AI and deterministic adapters increases flexibility but adds complexity and overhead; complexity analysis and deterministic confidence calculations consume resources but allow more cost‑effective routing.

**Safety vs. Capability:** AI adapters provide powerful code transformations but carry risk of runaway costs and unpredictable edits. The system mitigates this with cost tracking and determinism analysis, but there is still potential for mis‑configured prompts to cause large changes.

**Simplicity vs. Power:** The plugin interfaces are simple to learn; however, advanced features like parallel execution, coordination budgets and gating introduce complexity. Developers must understand these concepts to use the system effectively.

---

## Section D2: COMPARATIVE METRICS

### D2.1 Plugin System Characteristics

| Characteristic | Rating (1–5) | Notes |
| :---- | :---- | :---- |
| **Ease of Plugin Creation** | ⭐⭐⭐⭐ | Adapter interface straightforward; verification plugin functions easy; GUI plugin less documented |
| **Extensibility Breadth** | ⭐⭐⭐⭐ | Supports deterministic, AI and verification extensions; missing plugin ordering |
| **Safety/Isolation** | ⭐⭐ | No process isolation; relies on plugin compliance and cost/time limits |
| **Performance Overhead** | ⭐⭐⭐ | Lazy loading reduces overhead; complexity analysis adds some cost |
| **Documentation Quality** | ⭐⭐⭐ | README and docs cover core concepts; plugin development docs could be expanded |
| **Developer Experience** | ⭐⭐⭐⭐ | Python based, uses familiar packaging; tests and logging facilitate debugging |
| **Plugin Ecosystem Size** | ⭐⭐ | Several built‑in adapters and validation plugins; community ecosystem still small |

### D2.2 Complexity Analysis

* **Lines of Code for "Hello World" Plugin:** \~30 lines (minimal adapter example shown above).

* **Number of Required Artifacts:** For adapters: 3 methods and entry point declaration; verification plugins: 3 functions; GUI plugins: 2 methods and a global object.

* **Number of Extension Points:** 8 (execute, validate\_step, estimate\_cost, discover, run, report, activate, deactivate).

* **Learning Curve:** Intermediate – familiarity with Python packaging, CLI orchestrator and YAML workflows required.

* **Time to First Plugin:** Approximately 1–2 hours for a simple deterministic adapter; longer for AI or verification plugins requiring tool integration.

---

## Section D3: MODULAR ARCHITECTURE QUALITY ASSESSMENT

**This modular architecture ensures:**

* ✅ **Clear separation of concerns** – Core modules handle orchestration, routing and cost tracking while plugins encapsulate execution details.

* ✅ **Each module has single responsibility** – GateManager, Router, CostTracker, Coordinator each serve distinct roles.

* ✅ **Core protected from plugin failures** – Exceptions in adapters or verification plugins are captured and reported without crashing the system[\[28\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/core/executor.py#L129-L137).

* ✅ **Extensibility without core changes** – New adapters and verification plugins can be added via entry points or file placement.

* ✅ **Complete audit/observability capability** – Token usage logs, performance history, artifact generation and gate results provide comprehensive observability.

* ⚠️ **Deterministic and testable behavior** – Deterministic adapters are predictable; AI adapters are inherently nondeterministic but budgets and deterministic confidence help manage unpredictability.

* ✅ **Well‑defined module boundaries** – Modules expose clear interfaces; support modules avoid cross‑cutting state.

* ✅ **Manageable dependencies** – The dependency tree shows directed relationships; there are no circular imports.

* ✅ **Consistent interface contracts** – BaseAdapter, verification functions and GUI plugins adhere to consistent patterns.

* ✅ **Scalable architecture for growth** – Routing and coordination modules allow parallel execution and future expansion; however, plugin isolation may need improvement for large ecosystems.

---

## Section D4: KEY TAKEAWAYS & PATTERNS

### D4.1 Core Architectural Patterns

1. **Adapter Pattern** – The use of BaseAdapter abstracts away differences between deterministic tools and AI services. Each adapter encapsulates the details of interacting with an external tool or API, presenting a uniform interface to the orchestrator[\[8\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/base_adapter.py#L78-L119). **Benefits:** decouples execution logic from orchestration; supports polymorphism. **Trade‑offs:** still requires explicit registration; no isolation.

2. **Strategy Pattern / Routing** – The Router selects an appropriate strategy (adapter) based on complexity analysis and policies[\[14\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/routing/router.py#L101-L157). **Benefits:** dynamic selection optimizes cost and reliability; policies allow user control. **Trade‑offs:** complexity analysis introduces overhead; deterministic substitution may sometimes reduce AI capability.

3. **Hook/Event Pattern** – Verification plugins implement a set of hooks (discover, run, report) that the core calls at specific times[\[5\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/scripts/validation/pytest.py#L14-L134). **Benefits:** simple contract; easy to add new gates. **Trade‑offs:** limited control over ordering; potential for inconsistency.

### D4.2 Reusable Design Decisions

**Decisions Worth Borrowing:** \- ✅ **Unified plugin interfaces** – Adopting clear, minimal contracts for each plugin type makes it easy to develop new extensions. \- ✅ **Lazy loading via entry points** – Using setuptools entry points allows third‑party adapters to be discovered without modifying core code, enabling a plug‑in ecosystem[\[2\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/factory.py#L19-L40). \- ✅ **Complexity‑based routing** – Leveraging analysis to decide between deterministic and AI solutions helps balance performance and cost.

**Decisions to Avoid:** \- ❌ **Lack of sandboxing** – Running all plugins in process poses stability and security risks. Future architectures should consider process isolation or sandboxing mechanisms. \- ❌ **Opaque plugin ordering** – Without explicit ordering controls for verification plugins, combining multiple checks can yield unpredictable outcomes. Introducing priorities or dependencies would improve reliability.

---

## Section D5: CROSS‑SYSTEM COMPARISON MATRIX

| Aspect | CLI Orchestrator | (Other Systems) |
| :---- | :---- | :---- |
| **Discovery Method** | Entry points (adapters), directory scanning (verification & GUI)[\[2\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/factory.py#L19-L40) | — |
| **Loading Strategy** | Lazy load adapters on demand; eager load verification & GUI plugins | — |
| **Isolation Level** | Same‑process; no sandbox | — |
| **Extension Points** | 8 major hooks/events | — |
| **Permission Model** | Deterministic vs AI; cost budgets; environment checks | — |
| **Plugin Language** | Python | — |
| **Validation Approach** | Check required methods; verify external tools; catch exceptions[\[28\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/core/executor.py#L129-L137) | — |
| **Configuration System** | YAML workflows; environment variables; entry points | — |
| **Core Modules** | 9 core modules | — |
| **Plugin Modules** | \~5 built‑in adapters & verification plugins | — |
| **Developer Tools** | pytest, rich, PyQt6 | — |
| **Ecosystem Size** | Emerging, includes code fixers, AI editors, and validation plugins | — |

---

---

[\[1\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/gui_terminal/plugins/__init__.py#L8-L13) \_\_init\_\_.py

[https://github.com/DICKY1987/CLI\_RESTART/blob/main/src/gui\_terminal/plugins/\_\_init\_\_.py](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/gui_terminal/plugins/__init__.py)

[\[2\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/factory.py#L19-L40) factory.py

[https://github.com/DICKY1987/CLI\_RESTART/blob/main/src/cli\_multi\_rapid/adapters/factory.py](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/factory.py)

[\[3\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/docs/reference/verification-framework.md#L1-L17) verification-framework.md

[https://github.com/DICKY1987/CLI\_RESTART/blob/main/docs/reference/verification-framework.md](https://github.com/DICKY1987/CLI_RESTART/blob/main/docs/reference/verification-framework.md)

[\[4\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/gui_terminal/plugins/manager.py#L27-L60) manager.py

[https://github.com/DICKY1987/CLI\_RESTART/blob/main/src/gui\_terminal/plugins/manager.py](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/gui_terminal/plugins/manager.py)

[\[5\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/scripts/validation/pytest.py#L14-L134) pytest.py

[https://github.com/DICKY1987/CLI\_RESTART/blob/main/scripts/validation/pytest.py](https://github.com/DICKY1987/CLI_RESTART/blob/main/scripts/validation/pytest.py)

[\[6\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/code_fixers.py#L38-L47) [\[11\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/code_fixers.py#L85-L116) [\[18\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/code_fixers.py#L53-L66) [\[22\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/code_fixers.py#L270-L307) [\[29\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/code_fixers.py#L161-L178) [\[43\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/code_fixers.py#L27-L50) code\_fixers.py

[https://github.com/DICKY1987/CLI\_RESTART/blob/main/src/cli\_multi\_rapid/adapters/code\_fixers.py](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/code_fixers.py)

[\[7\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/scripts/validation/ruff_semgrep.py#L14-L98) ruff\_semgrep.py

[https://github.com/DICKY1987/CLI\_RESTART/blob/main/scripts/validation/ruff\_semgrep.py](https://github.com/DICKY1987/CLI_RESTART/blob/main/scripts/validation/ruff_semgrep.py)

[\[8\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/base_adapter.py#L78-L119) base\_adapter.py

[https://github.com/DICKY1987/CLI\_RESTART/blob/main/src/cli\_multi\_rapid/adapters/base\_adapter.py](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/base_adapter.py)

[\[9\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/scripts/validation/schema_validate.py#L16-L115) schema\_validate.py

[https://github.com/DICKY1987/CLI\_RESTART/blob/main/scripts/validation/schema\_validate.py](https://github.com/DICKY1987/CLI_RESTART/blob/main/scripts/validation/schema_validate.py)

[\[10\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/core/executor.py#L61-L127) [\[15\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/core/executor.py#L61-L137) [\[27\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/core/executor.py#L211-L252) [\[28\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/core/executor.py#L129-L137) executor.py

[https://github.com/DICKY1987/CLI\_RESTART/blob/main/src/cli\_multi\_rapid/core/executor.py](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/core/executor.py)

[\[12\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/ai_editor.py#L301-L308) [\[13\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/ai_editor.py#L315-L328) [\[17\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/ai_editor.py#L53-L53) [\[19\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/ai_editor.py#L331-L350) [\[20\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/ai_editor.py#L167-L168) [\[30\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/ai_editor.py#L400-L413) [\[31\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/ai_editor.py#L78-L83) [\[44\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/ai_editor.py#L27-L44) [\[45\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/ai_editor.py#L55-L100) [\[49\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/ai_editor.py#L265-L293) ai\_editor.py

[https://github.com/DICKY1987/CLI\_RESTART/blob/main/src/cli\_multi\_rapid/adapters/ai\_editor.py](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/ai_editor.py)

[\[14\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/routing/router.py#L101-L157) [\[23\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/routing/router.py#L21-L45) [\[26\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/routing/router.py#L79-L99) [\[34\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/routing/router.py#L21-L34) [\[35\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/routing/router.py#L101-L157) [\[46\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/routing/router.py#L37-L45) router.py

[https://github.com/DICKY1987/CLI\_RESTART/blob/main/src/cli\_multi\_rapid/routing/router.py](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/routing/router.py)

[\[16\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/core/coordinator.py#L61-L120) [\[32\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/core/coordinator.py#L63-L120) [\[33\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/core/coordinator.py#L303-L369) coordinator.py

[https://github.com/DICKY1987/CLI\_RESTART/blob/main/src/cli\_multi\_rapid/core/coordinator.py](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/core/coordinator.py)

[\[21\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/cost_tracker.py#L21-L24) cost\_tracker.py

[https://github.com/DICKY1987/CLI\_RESTART/blob/main/src/cli\_multi\_rapid/cost\_tracker.py](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/cost_tracker.py)

[\[24\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/core/gate_manager.py#L81-L124) [\[47\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/core/gate_manager.py#L253-L265) gate\_manager.py

[https://github.com/DICKY1987/CLI\_RESTART/blob/main/src/cli\_multi\_rapid/core/gate\_manager.py](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/core/gate_manager.py)

[\[25\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/coordination/coordinator.py#L48-L74) coordinator.py

[https://github.com/DICKY1987/CLI\_RESTART/blob/main/src/cli\_multi\_rapid/coordination/coordinator.py](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/coordination/coordinator.py)

[\[36\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/routing/complexity_analyzer.py#L11-L19) complexity\_analyzer.py

[https://github.com/DICKY1987/CLI\_RESTART/blob/main/src/cli\_multi\_rapid/routing/complexity\_analyzer.py](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/routing/complexity_analyzer.py)

[\[37\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/routing/models.py#L38-L47) models.py

[https://github.com/DICKY1987/CLI\_RESTART/blob/main/src/cli\_multi\_rapid/routing/models.py](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/routing/models.py)

[\[38\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/routing/parallel_planner.py#L8-L60) [\[40\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/routing/parallel_planner.py#L14-L60) parallel\_planner.py

[https://github.com/DICKY1987/CLI\_RESTART/blob/main/src/cli\_multi\_rapid/routing/parallel\_planner.py](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/routing/parallel_planner.py)

[\[39\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/routing/resource_allocator.py#L8-L68) resource\_allocator.py

[https://github.com/DICKY1987/CLI\_RESTART/blob/main/src/cli\_multi\_rapid/routing/resource\_allocator.py](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/routing/resource_allocator.py)

[\[41\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/domain/cost/tracker.py#L12-L71) [\[50\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/domain/cost/tracker.py#L23-L48) tracker.py

[https://github.com/DICKY1987/CLI\_RESTART/blob/main/src/cli\_multi\_rapid/domain/cost/tracker.py](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/domain/cost/tracker.py)

[\[42\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/storage/cost_storage.py#L11-L26) cost\_storage.py

[https://github.com/DICKY1987/CLI\_RESTART/blob/main/src/cli\_multi\_rapid/adapters/storage/cost\_storage.py](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/adapters/storage/cost_storage.py)

[\[48\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/docs/gui/IMPLEMENTATION_SUMMARY.md#L19-L24) IMPLEMENTATION\_SUMMARY.md

[https://github.com/DICKY1987/CLI\_RESTART/blob/main/docs/gui/IMPLEMENTATION\_SUMMARY.md](https://github.com/DICKY1987/CLI_RESTART/blob/main/docs/gui/IMPLEMENTATION_SUMMARY.md)

[\[51\]](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/router.py#L1-L15) router.py

[https://github.com/DICKY1987/CLI\_RESTART/blob/main/src/cli\_multi\_rapid/router.py](https://github.com/DICKY1987/CLI_RESTART/blob/main/src/cli_multi_rapid/router.py)