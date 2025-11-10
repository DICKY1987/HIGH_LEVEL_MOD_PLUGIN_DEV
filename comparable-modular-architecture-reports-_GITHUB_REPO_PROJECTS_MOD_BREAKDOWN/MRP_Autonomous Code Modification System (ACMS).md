
Autonomous Code Modification System (ACMS)
ACMS is a deterministic, headless pipeline that plans, executes, validates, and merges code changes using AI-first tooling. This repository captures Phase 1 of the multi-phase implementation described in the Build Execution Contract.

🚀 Quick Start
Prerequisites
Python 3.11 or higher
Git
pip (comes with Python)
Installation
Option 1: Automated Setup (Recommended)

bash
# Linux/Mac
chmod +x setup_dev.sh
./setup_dev.sh

# Windows PowerShell
.\setup_dev.ps1
Option 2: Manual Setup

bash
# 1. Create virtual environment
python -m venv .venv

# 2. Activate virtual environment
source .venv/bin/activate  # Linux/Mac
.venv\Scripts\activate     # Windows

# 3. Upgrade pip
pip install --upgrade pip

# 4. Install package in editable mode with dev dependencies
pip install -e ".[dev]"

# 5. Verify installation
pytest -v
📁 Repository Structure
Code
.
├── core/                          # Core ACMS package
│   ├── __init__.py
│   ├── config.py
│   ├── state_machine.py          # Execution state machine
│   ├── task_scheduler.py         # DAG topological sort
│   └── orchestrator.py           # Main pipeline orchestrator
├── tests/                         # Test suite
│   ├── conftest.py               # Shared fixtures
│   ├── integration/              # Integration tests
│   └── test_worktree.py          # Worktree management tests
├── immediate CI enforcement and reproducibility/
│   ├── conftest.py               # Path configuration for tests
│   ├── test_state_machine.py    # State machine tests
│   ├── test_toposort.py          # Topological sort tests
│   └── schemas/                  # JSON schemas
├── docs/                          # Documentation
├── .github/
│   └── workflows/
│       └── ci.yml                # CI/CD pipeline
├── .env.example                   # Environment variables template
├── .gitignore
├── docker-compose.yml
├── LICENSE
├── noxfile.py                     # Task automation
├── pyproject.toml                 # Package configuration
├── README.md                      # This file
├── requirements.txt               # Production dependencies
├── setup_dev.sh                   # Linux/Mac setup script
└── setup_dev.ps1                  # Windows setup script
🧪 Running Tests
Run All Tests
bash
pytest -v
Run Specific Test Files
bash
# State machine tests
pytest "immediate CI enforcement and reproducibility/test_state_machine.py" -v

# Topological sort tests
pytest "immediate CI enforcement and reproducibility/test_toposort.py" -v

# Worktree tests
pytest tests/test_worktree.py -v

# Integration tests only
pytest tests/integration/ -v -m integration
Run with Coverage
bash
pytest --cov=core --cov-report=term --cov-report=html
Coverage report will be available in htmlcov/index.html

🔧 Development Tools
Linting
bash
# Black formatting
black .

# Ruff linting
ruff check .

# Check import sorting
isort --check-only .
Type Checking
bash
mypy core/
Run All Quality Checks
bash
# Format code
black .
isort .

# Lint
ruff check . --fix

# Type check
mypy core/

# Test
pytest -v --cov=core
🐛 Troubleshooting
Import Errors: ModuleNotFoundError: No module named 'core'
Solution: Ensure the package is installed in editable mode:

bash
pip install -e ".[dev]"
This is the recommended approach and is now properly configured in:

pyproject.toml - with proper test paths
.github/workflows/ci.yml - CI/CD installs package before testing
tests/conftest.py - adds repo root to sys.path as backup
immediate CI enforcement and reproducibility/conftest.py - same for reference tests
Tests Pass Locally But Fail in CI
Verify your local setup matches CI:

Clean install: rm -rf .venv && python -m venv .venv
Activate: source .venv/bin/activate
Install: pip install -e ".[dev]"
Test: pytest -v
IDE Not Recognizing Imports
Restart your IDE after installing in editable mode
In VSCode: Reload window (Cmd/Ctrl+Shift+P → "Developer: Reload Window")
In PyCharm: Mark project root as "Sources Root"
📚 Documentation
Executive Summary - Project overview and architecture
Build Execution Contract - Implementation phases
Test Import Fix Guide - Detailed fix documentation
Versioning Operating Contract - Governance
🔄 CI/CD Pipeline
The project uses GitHub Actions for continuous integration:

Lint and Test: Runs formatting, linting, and all tests
Type Check: Static type checking with mypy
Security Scans: Bandit and Gitleaks for security
Integration Tests: Full workflow tests
All checks must pass before merging.

🌟 Key Features
Phase 1 Deliverables (Completed)
✅ Version-controlled licensing and documentation
✅ Python package metadata via pyproject.toml
✅ Task automation entry point using Nox
✅ Core Python package with proper structure
✅ Environment and container orchestration templates
✅ CI/CD pipeline with comprehensive checks
✅ Fixed test import issues - all tests pass reliably

🚦 Getting Started Checklist
 Clone repository
 Run setup script (./setup_dev.sh or .\setup_dev.ps1)
 Copy .env.example to .env and configure
 Run tests to verify setup: pytest -v
 Review documentation in docs/
 Read the Executive Summary
📝 Contributing
Create a feature branch from develop
Make your changes
Run quality checks: black . && ruff check . && pytest -v
Commit with descriptive messages
Push and create a pull request
All PRs must:

Pass CI/CD checks
Maintain test coverage >= 80%
Follow code style (Black, Ruff)
Include tests for new features
📄 License
This project is licensed under the MIT License - see the LICENSE file for details.

🤝 Support
Issues: GitHub Issues
Documentation: See docs/ directory
Questions: Contact platform engineering team
📈 Next Steps
Subsequent phases will add:

Orchestration framework (Phase 2)
Plugin management (Phase 3)
LLM tool integration (Phase 4)
Validation gates (Phase 5)
Worktree management (Phase 6)
Observability and tracing (Phase 7)
CI/CD integration (Phase 8)
Full test coverage (Phase 9)
Documentation generation (Phase 10)
Deployment automation (Phase 11)
See ACMS_BUILD_EXECUTION_CONTRACT.yaml for the complete roadmap.

Last Updated: 2025-11-02
Version: 1.1.0
Owner: Platform.Engineering

ACMS (Autonomous Code Modification System): Complete Architecture Analysis (Plugin System & Modular Structure)
PART A: PLUGIN SYSTEM ARCHITECTURE
Section A1: PLUGIN SYSTEM OVERVIEW
A1.1 Architecture Summary
System Type: Event-driven / Hook-based with centralized orchestration

Plugin Discovery: Directory scanning with manifest registration (plugins/ directory)

Loading Strategy: Startup (plugins discovered and loaded during orchestrator initialization)

Isolation Level: Same-process with module namespacing (Python import system)

Communication Pattern: Direct calls through plugin loader interface + Event bus for workflow hooks

Core-Plugin Boundary: Core controls state machine, task scheduling, and orchestration; plugins extend planning, execution, validation, and tool integration capabilities

A1.2 Plugin Lifecycle
Lifecycle Stages:

Discovery - Plugin loader scans plugins/ directory for Python modules with plugin.yaml manifests
Validation - Manifest schema validation + dependency check via Validate-Plugin.ps1 or validate_plugin.py
Loading - Python module import + class instantiation via core/plugin_loader.py
Registration - Plugin registers its hooks/capabilities with orchestrator
Activation - Plugin becomes active when relevant workflow stage is triggered
Deactivation - Plugin releases resources at workflow completion
Cleanup - Temporary files removed, connections closed
Lifecycle Events/Hooks:

on_plugin_load - When plugin module is imported, allows initialization
on_workflow_start - Beginning of pipeline execution, setup resources
on_planning_phase - Planning stage, plugins can influence task graph
on_task_execute - Per-task execution, plugins can intercept/modify
on_validation_gate - Code gate validation, plugins add quality checks
on_workflow_complete - End of pipeline, cleanup and reporting
on_plugin_unload - Plugin teardown, resource release
Section A2: PLUGIN EXTENSION POINTS
A2.1 Available Hooks/Events
Hook/Event Name	Trigger Condition	Plugin Receives	Plugin Returns	Can Block?	Examples
on_planning_phase	After run init, before task graph execution	RunContext, PlanningInput	List[Task] (additional tasks)	No	LLM-based task generation, dependency analysis
on_worktree_create	Before git worktree creation	WorktreeConfig	WorktreeConfig (modified)	Yes	Custom branch naming, isolation policies
on_code_execute	During LLM tool execution	CodeRequest, Context	CodeResponse	No	Aider/Claude Code integration, custom tools
on_validation_gate	After code generation, before merge	ValidationInput, Artifacts	ValidationResult (pass/fail)	Yes	Linting, security scans, custom checks
on_quality_check	During code gate phase	FileDiff, Metrics	QualityScore	Yes	Coverage checks, complexity analysis
on_merge_prepare	Before PR creation	MergeRequest, Commits	MergeStrategy	Yes	Conflict resolution, commit squashing
on_observability_emit	Throughout execution	TraceEvent, Metadata	EnrichedEvent	No	Custom metrics, log enrichment
on_error_handler	When task fails	Exception, TaskContext	RetryDecision	Yes	Custom retry logic, failure routing
A2.2 Hook Priority & Ordering
Execution Order Control:

Plugins specify priority via priority field in manifest (1-100, lower = higher priority)
Default ordering: registration order (first registered = first executed)
Conflict resolution: Explicit priority > Registration order
Examples:

Python
# In plugin manifest (plugin.yaml)
name: "security-scanner"
version: "1.0.0"
hooks:
  - name: "on_validation_gate"
    priority: 10  # Runs early (security before style)
  
  - name: "on_quality_check"
    priority: 50  # Runs mid-priority
Python
# In plugin implementation
class SecurityScannerPlugin:
    def __init__(self):
        self.priority = 10
    
    def on_validation_gate(self, validation_input):
        # Executes before lower-priority plugins
        return self.run_security_scan(validation_input)
Section A3: PLUGIN STRUCTURE & ANATOMY
A3.1 Required Plugin Artifacts
Mandatory Files:

plugin.yaml - Plugin manifest (metadata, hooks, dependencies)
__init__.py - Python package marker + plugin class export
plugin.py - Main plugin implementation class
Optional Files:

config.yaml - Plugin-specific configuration
schema.json - Input/output contract schemas
README.md - Plugin documentation
tests/ - Plugin-specific tests
Directory Structure:

Code
plugins/
├── my_plugin/
│   ├── __init__.py          # Exports MyPlugin class
│   ├── plugin.py            # Main implementation
│   ├── plugin.yaml          # Manifest
│   ├── config.yaml          # Optional configuration
│   ├── schema.json          # Optional schemas
│   ├── README.md            # Documentation
│   └── tests/
│       └── test_plugin.py   # Plugin tests
A3.2 Plugin Manifest/Descriptor
Manifest Format: YAML

Required Fields:

YAML
name: "plugin-name"              # Unique identifier
version: "1.0.0"                 # SemVer
description: "What this plugin does"
author: "Platform.Engineering"
hooks:                            # Extension points
  - name: "on_validation_gate"
    priority: 50
dependencies:                     # Other plugins required
  - "context-broker>=1.0.0"
python_version: ">=3.11"         # Runtime requirement
Example Real Manifest:

YAML
---
name: "aider-integration"
version: "1.2.0"
description: "Integrates Aider CLI for code generation"
author: "Platform.Engineering"
license: "MIT"
hooks:
  - name: "on_code_execute"
    priority: 20
  - name: "on_planning_phase"
    priority: 30
dependencies:
  - "context-broker>=1.0.0"
python_version: ">=3.11"
external_tools:
  - name: "aider"
    version: ">=0.30.0"
    required: true
configuration:
  model: "gpt-4"
  max_tokens: 4000
  temperature: 0.2
A3.3 Plugin Implementation Pattern
Implementation Style: Class-based with mixin pattern

Minimal Plugin Example:

Python
# plugins/hello_world/plugin.py
from typing import Dict, Any

class HelloWorldPlugin:
    """Minimal plugin that logs workflow start"""
    
    def __init__(self):
        self.name = "hello-world"
        self.version = "1.0.0"
    
    def on_workflow_start(self, context: Dict[str, Any]) -> None:
        """Called when workflow begins"""
        print(f"Hello from {self.name}!")
        context['hello_plugin_active'] = True
Full-Featured Plugin Example:

Python
# plugins/advanced_validator/plugin.py
from typing import Dict, Any, List
from dataclasses import dataclass
import logging

@dataclass
class ValidationResult:
    passed: bool
    errors: List[str]
    warnings: List[str]
    metadata: Dict[str, Any]

class AdvancedValidatorPlugin:
    """
    Full-featured validation plugin with configuration,
    multiple hooks, and comprehensive error handling.
    """
    
    def __init__(self, config: Dict[str, Any] = None):
        self.name = "advanced-validator"
        self.version = "2.1.0"
        self.config = config or {}
        self.logger = logging.getLogger(__name__)
        self._init_validators()
    
    def _init_validators(self):
        """Initialize validation rules from config"""
        self.max_complexity = self.config.get('max_complexity', 10)
        self.coverage_threshold = self.config.get('coverage_threshold', 80)
    
    def on_plugin_load(self) -> None:
        """Lifecycle: Plugin loaded"""
        self.logger.info(f"Loaded {self.name} v{self.version}")
    
    def on_planning_phase(self, context: Dict[str, Any]) -> List[Dict]:
        """Add validation tasks to plan"""
        return [
            {
                'id': 'validate_complexity',
                'dependencies': ['code_generation'],
                'priority': 60
            },
            {
                'id': 'validate_coverage',
                'dependencies': ['test_generation'],
                'priority': 61
            }
        ]
    
    def on_validation_gate(self, validation_input: Dict[str, Any]) -> ValidationResult:
        """Primary validation hook - can block workflow"""
        errors = []
        warnings = []
        
        # Check code complexity
        complexity = self._calculate_complexity(validation_input['code'])
        if complexity > self.max_complexity:
            errors.append(f"Complexity {complexity} exceeds {self.max_complexity}")
        
        # Check test coverage
        coverage = validation_input.get('coverage', 0)
        if coverage < self.coverage_threshold:
            warnings.append(f"Coverage {coverage}% below {self.coverage_threshold}%")
        
        passed = len(errors) == 0
        
        return ValidationResult(
            passed=passed,
            errors=errors,
            warnings=warnings,
            metadata={
                'complexity': complexity,
                'coverage': coverage,
                'plugin_version': self.version
            }
        )
    
    def _calculate_complexity(self, code: str) -> int:
        """Calculate cyclomatic complexity"""
        # Simplified implementation
        return code.count('if ') + code.count('for ') + code.count('while ')
    
    def on_workflow_complete(self, context: Dict[str, Any]) -> None:
        """Cleanup hook"""
        self.logger.info(f"Validation complete: {context.get('validation_summary')}")
Section A4: PLUGIN CONTRACTS & INTERFACES
A4.1 Core Contracts
Contract: PluginInterface
Purpose: Base interface all plugins must implement

Required Methods/Functions:

Python
def __init__(self, config: Dict[str, Any] = None) -> None
    # Initialize plugin with optional configuration

def get_metadata(self) -> PluginMetadata
    # Return plugin name, version, capabilities

def on_plugin_load(self) -> None
    # Optional: Called when plugin is first loaded
Input Schema:

JSON
{
  "config": {
    "type": "object",
    "properties": {
      "enabled": {"type": "boolean", "default": true},
      "log_level": {"type": "string", "enum": ["DEBUG", "INFO", "WARN", "ERROR"]}
    }
  }
}
Output Schema:

JSON
{
  "metadata": {
    "type": "object",
    "required": ["name", "version"],
    "properties": {
      "name": {"type": "string"},
      "version": {"type": "string", "pattern": "^\\d+\\.\\d+\\.\\d+$"},
      "description": {"type": "string"},
      "hooks": {"type": "array", "items": {"type": "string"}}
    }
  }
}
Validation Rules:

Plugin name must be unique across all loaded plugins
Version must follow SemVer (major.minor.patch)
Hooks must be registered extension points
Example Implementation:

Python
from dataclasses import dataclass
from typing import Dict, Any, List

@dataclass
class PluginMetadata:
    name: str
    version: str
    description: str
    hooks: List[str]

class BasePlugin:
    def __init__(self, config: Dict[str, Any] = None):
        self.config = config or {}
        self.enabled = self.config.get('enabled', True)
    
    def get_metadata(self) -> PluginMetadata:
        return PluginMetadata(
            name=self.name,
            version=self.version,
            description=self.description,
            hooks=self.get_registered_hooks()
        )
    
    def get_registered_hooks(self) -> List[str]:
        """Return list of implemented hook methods"""
        hooks = []
        for attr in dir(self):
            if attr.startswith('on_'):
                hooks.append(attr)
        return hooks
Contract: ValidationHook
Purpose: Plugins that validate code/artifacts

Required Methods/Functions:

Python
def on_validation_gate(self, validation_input: ValidationInput) -> ValidationResult
    # Validate code, return pass/fail with details

def get_validation_rules(self) -> List[ValidationRule]
    # Return rules this plugin enforces
Input Schema:

JSON
{
  "validation_input": {
    "type": "object",
    "required": ["files", "context"],
    "properties": {
      "files": {"type": "array", "items": {"$ref": "#/definitions/FileChange"}},
      "context": {"$ref": "#/definitions/ExecutionContext"},
      "metadata": {"type": "object"}
    }
  }
}
Output Schema:

JSON
{
  "validation_result": {
    "type": "object",
    "required": ["passed", "errors"],
    "properties": {
      "passed": {"type": "boolean"},
      "errors": {"type": "array", "items": {"type": "string"}},
      "warnings": {"type": "array", "items": {"type": "string"}},
      "metadata": {"type": "object"}
    }
  }
}
Validation Rules:

Must return within 5 minutes (timeout)
Errors array must be populated if passed = false
Cannot modify input files (read-only)
Example Implementation:

Python
from typing import List
from dataclasses import dataclass

@dataclass
class ValidationInput:
    files: List[str]
    context: Dict[str, Any]
    metadata: Dict[str, Any]

@dataclass
class ValidationResult:
    passed: bool
    errors: List[str]
    warnings: List[str]
    metadata: Dict[str, Any]

class LintValidatorPlugin:
    def on_validation_gate(self, validation_input: ValidationInput) -> ValidationResult:
        errors = []
        warnings = []
        
        for file_path in validation_input.files:
            if file_path.endswith('.py'):
                lint_result = self._run_ruff(file_path)
                errors.extend(lint_result.errors)
                warnings.extend(lint_result.warnings)
        
        return ValidationResult(
            passed=len(errors) == 0,
            errors=errors,
            warnings=warnings,
            metadata={'linter': 'ruff', 'version': '0.1.0'}
        )
    
    def _run_ruff(self, file_path: str):
        # Implementation omitted
        pass
A4.2 Communication Protocols
Plugin → Core:

Plugins call core services via context object passed to hooks
Available APIs: logging, state access, file operations (via SafePatch), configuration
Permission model: Plugins cannot modify core state directly, only through approved APIs
Core → Plugin:

Core invokes plugins via registered hook methods
Error handling: Exceptions caught, logged, and workflow continues (unless validation hook blocks)
Timeout: 5 minutes per hook invocation (configurable)
Resource limits: Memory monitored, excessive usage logged
Plugin → Plugin:

No direct communication (isolation principle)
Shared state via context object (core-mediated)
Event forwarding: Core propagates events to all registered plugins
Section A5: PLUGIN CAPABILITIES & PERMISSIONS
A5.1 Permission Model
Permission Levels:

ReadOnly: Can read context, files, configuration (default for most plugins)
Validate: Can approve/reject workflows (validation plugins)
Modify: Can propose file changes (code generation plugins, via SafePatch)
System: Can access worktrees, git operations (infrastructure plugins)
Capability Declarations:

YAML
# In plugin.yaml
capabilities:
  - "read_context"
  - "validate_code"
  - "propose_changes"  # Requires approval
  - "access_worktree"  # Elevated permission
Restrictions:

❌ Plugins CANNOT directly modify files (must use SafePatch API)
❌ Plugins CANNOT bypass validation gates
❌ Plugins CANNOT access secrets directly (must request via context)
❌ Plugins CANNOT spawn arbitrary processes (must use approved tool integrations)
❌ Plugins CANNOT modify core state machine
Sandboxing/Isolation:

Process-level: Same process as core (Python import isolation)
Filesystem: Read-only access except via SafePatch
Network: Restricted to approved LLM APIs
Resource limits: Memory capped at 1GB per plugin, CPU time monitored
A5.2 Core Services Available to Plugins
Service	Purpose	Access Pattern	Permission Required
Logger	Structured logging	context.logger.info(msg)	ReadOnly
Config	Read configuration	context.config.get(key)	ReadOnly
FileSys (SafePatch)	File operations	context.fs.propose_change(file, patch)	Modify
StateQuery	Read workflow state	context.state.get_current_phase()	ReadOnly
Tracer	OpenTelemetry tracing	context.tracer.start_span(name)	ReadOnly
SecretStore	Access secrets	context.secrets.get('API_KEY')	System
WorktreeAccess	Git worktree ops	context.worktree.create(branch)	System
LLMDispatcher	Invoke LLM tools	context.llm.invoke('aider', prompt)	Modify
Section A6: PLUGIN VALIDATION & QUALITY GATES
A6.1 Pre-Load Validation
Validation Checks:

Manifest Schema - YAML structure matches required schema

Pass criteria: All required fields present, types correct
Fail action: Plugin not loaded, error logged
Dependency Resolution - Required plugins/tools available

Pass criteria: All dependencies satisfied
Fail action: Plugin skipped, warning logged
Python Syntax - Plugin code is valid Python

Pass criteria: python -m py_compile plugin.py succeeds
Fail action: Plugin not loaded, error logged
Hook Signature - Methods match expected signatures

Pass criteria: Type hints compatible with contracts
Fail action: Plugin loaded with warnings, incompatible hooks disabled
Validation Tool/Command:

bash
# PowerShell validator
pwsh core/Validate-Plugin.ps1 -PluginPath plugins/my_plugin

# Python validator
python scripts/validate_plugin.py --plugin plugins/my_plugin
A6.2 Runtime Safety Mechanisms
Error Isolation:

Plugin exceptions caught by plugin loader
System recovery: Workflow continues, plugin marked as failed
Error reporting: Logged to JSONL ledger with trace ID
Resource Limits:

Memory: 1GB per plugin (soft limit, monitored)
CPU: 80% utilization threshold triggers warning
Time: 5-minute timeout per hook invocation
I/O: Rate limited to 100 file operations per second
Circuit Breakers:

Plugins auto-disabled after 3 consecutive failures
Failure threshold: 50% error rate over 10 invocations
Recovery: Manual re-enable or automatic after cooldown (1 hour)
Section A7: PLUGIN CONFIGURATION & CUSTOMIZATION
A7.1 Configuration System
Configuration Sources:

plugins/<plugin>/config.yaml - Plugin defaults
.env - Environment variables (override)
core/config.py - Global configuration
Command-line args - Runtime overrides
Config precedence order: CLI args > Env vars > Plugin config > Global defaults

Hot-reload support: No (plugins loaded at startup only)

Configuration Schema:

YAML
# plugins/my_plugin/config.yaml
plugin:
  enabled: true
  log_level: "INFO"
  custom_settings:
    max_retries: 3
    timeout_seconds: 300
Example Plugin Config:

YAML
# plugins/aider_integration/config.yaml
plugin:
  enabled: true
  log_level: "DEBUG"
aider:
  model: "gpt-4"
  max_tokens: 4000
  temperature: 0.2
  edit_format: "diff"
  auto_commits: false
  map_tokens: 1024
A7.2 Plugin-Specific Customization
Customization Points:

Users customize via config.yaml in plugin directory
Override mechanisms: Environment variables with prefix PLUGIN_<NAME>_
Extension of extensions: Plugins can declare their own hooks (meta-plugins not currently supported)
Templates/Scaffolding:

bash
# PowerShell scaffold generator
pwsh core/Generate-PluginScaffold.ps1 -PluginName "my-custom-plugin"

# Creates:
# plugins/my_custom_plugin/
#   ├── __init__.py
#   ├── plugin.py
#   ├── plugin.yaml
#   ├── config.yaml
#   └── tests/test_plugin.py
PART B: COMPLETE MODULAR ARCHITECTURE
Section B1: TIER 1: CORE MODULES (Sacred/Privileged)
Module 1: State Machine
Purpose: Manages workflow execution states and transitions for deterministic, resumable pipelines

Deliverables:

core/state_machine.py - ExecutionState enum, TaskExecution dataclass, state transition logic
schemas/execution_state_machine.schema.json - JSON schema for state validation
tests/test_state_machine.py - State transition unit tests
Checkpoint files (.runs/<run_id>/checkpoint.json) - Resumption data
Key Contracts:

Python
class ExecutionState(Enum):
    PENDING = auto()
    RUNNING = auto()
    COMPLETED = auto()
    FAILED = auto()
    SKIPPED = auto()
    CANCELLED = auto()

@dataclass
class TaskExecution:
    task_id: str
    state: ExecutionState
    trace_id: str
    attempt: int = 0
    max_attempts: int = 3
    
    def can_transition_to(self, new_state: ExecutionState) -> bool
        # Validates allowed state transitions

def create_checkpoint(run_id: str, state: Dict) -> str
    # Persists workflow state for resumption
Core Module Identification Criteria:

Controls critical workflow state (cannot be disabled)
Enforces deterministic execution (state machine prevents invalid transitions)
Other modules depend on state queries
Handles resumption after failures
Module 2: Task Scheduler (DAG)
Purpose: Resolves task dependencies via topological sort, enabling parallel execution and preventing deadlocks

Deliverables:

core/task_scheduler.py - TaskScheduler class with topological sort
tests/test_toposort.py - Cycle detection and ordering tests
Task execution plan (in-memory DAG representation)
Key Contracts:

Python
class TaskScheduler:
    def __init__(self, task_graph: Dict) -> None
        # Initializes from task graph definition
    
    def topological_sort(self) -> List[List[str]]
        # Returns execution waves (parallel groups)
        # Raises ValueError if cycle detected
    
    def get_execution_plan(self) -> Dict
        # Returns: total_tasks, total_waves, max_parallelism, execution_order

# Task graph schema
{
  "tasks": [
    {
      "id": "task_001",
      "dependencies": [],
      "priority": 1,
      "parallel_group": "optional_group_name"
    }
  ]
}
Core Module Identification Criteria:

Controls execution order (critical for correctness)
Prevents circular dependencies (system-wide invariant)
Used by orchestrator for every workflow run
Cannot be replaced without breaking determinism
Module 3: Orchestrator
Purpose: Main pipeline controller that coordinates all phases, plugins, and validation gates

Deliverables:

core/orchestrator.py - PipelineOrchestrator class, phase execution logic
core/runner.py - CLI entry point for production runs
Execution logs (JSONL ledger entries)
Key Contracts:

Python
class PipelineOrchestrator:
    def __init__(self, config: Config, plugins: List[Plugin]) -> None
        # Initialize with configuration and loaded plugins
    
    def execute_workflow(self, run_context: RunContext) -> ExecutionResult
        # Executes full 12-step pipeline
        # Returns: status, artifacts, trace_id
    
    def execute_phase(self, phase_name: str, context: Dict) -> PhaseResult
        # Executes single phase (planning, execution, validation, etc.)
    
    def invoke_hooks(self, hook_name: str, data: Any) -> List[HookResult]
        # Triggers all plugins registered for hook_name
Core Module Identification Criteria:

Entry point for all workflows (cannot be bypassed)
Coordinates all other modules (central controller)
Enforces execution order and gates
Manages plugin invocation
Module 4: Plugin Loader
Purpose: Discovers, validates, and loads plugins dynamically from plugins/ directory

Deliverables:

core/plugin_loader.py - PluginLoader class, discovery logic
plugins/__init__.py - Plugin package marker
Loaded plugin registry (in-memory)
Key Contracts:

Python
class PluginLoader:
    def discover_plugins(self, plugin_dir: str = "plugins") -> List[PluginMetadata]
        # Scans directory for plugin.yaml manifests
    
    def load_plugin(self, plugin_path: str) -> Plugin
        # Imports Python module, instantiates class
        # Raises PluginLoadError if validation fails
    
    def validate_plugin(self, plugin: Plugin) -> ValidationResult
        # Checks manifest schema, dependencies, signatures
    
    def get_loaded_plugins(self) -> Dict[str, Plugin]
        # Returns all successfully loaded plugins
Core Module Identification Criteria:

Manages plugin lifecycle (critical for extensibility)
Enforces plugin contracts (security/safety)
Required for any plugin-based functionality
Controls what code gets executed
Module 5: Configuration Manager
Purpose: Centralized configuration loading with environment variable support and validation

Deliverables:

core/config.py - Config dataclass, loader functions
.env.example - Environment variable template
Configuration validation logic
Key Contracts:

Python
@dataclass
class Config:
    # System settings
    log_level: str = "INFO"
    dry_run: bool = False
    max_parallel_worktrees: int = 5
    
    # Paths
    plugin_dir: str = "plugins"
    runs_dir: str = ".runs"
    schema_dir: str = "schemas"
    
    # Observability
    jaeger_endpoint: str = "http://localhost:14268/api/traces"
    ledger_path: str = ".runs/ledger.jsonl"
    
    @classmethod
    def from_env(cls) -> Config
        # Loads from .env and environment variables
    
    def validate(self) -> List[str]
        # Returns list of validation errors (empty if valid)
Core Module Identification Criteria:

Every module depends on configuration
Controls system behavior globally
Validates settings (prevents misconfigurations)
Cannot be disabled
Module 6: Worktree Manager
Purpose: Manages Git worktrees for isolated, concurrent code modifications

Deliverables:

core/worktree/manager.py - WorktreeManager class
core/worktree/sync.py - Synchronization utilities
tests/test_worktree.py - Worktree isolation tests
Temporary worktree directories (.runs/<run_id>/worktrees/)
Key Contracts:

Python
class WorktreeManager:
    def create_worktree(self, branch_name: str, base_ref: str = "main") -> Worktree
        # Creates isolated git worktree
        # Returns: Worktree(path, branch, commit_sha)
    
    def sync_worktree(self, worktree: Worktree, target_ref: str) -> SyncResult
        # Syncs worktree with target branch
    
    def cleanup_worktree(self, worktree: Worktree) -> None
        # Removes worktree and temporary files
    
    def list_active_worktrees(self) -> List[Worktree]
        # Returns all worktrees for current run
Core Module Identification Criteria:

Provides isolation (critical for concurrent execution)
Directly interacts with Git (privileged operation)
Required for multi-worktree workflows
Failure impacts all dependent tasks
Module 7: Observability (Tracing)
Purpose: OpenTelemetry integration for distributed tracing and correlation

Deliverables:

core/observability/tracing.py - Tracer initialization, span management
docker/jaeger/docker-compose.yml - Jaeger deployment config
Trace data (exported to Jaeger)
Key Contracts:

Python
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider

def initialize_tracer(service_name: str = "acms") -> trace.Tracer
    # Sets up OpenTelemetry with Jaeger exporter

def create_span(tracer: trace.Tracer, name: str, attributes: Dict) -> trace.Span
    # Creates trace span with metadata

@contextmanager
def traced_operation(operation_name: str, **attrs):
    # Context manager for automatic span creation
    # Usage: with traced_operation("plan_phase"): ...
Core Module Identification Criteria:

System-wide observability (used by all modules)
Enforces correlation via trace IDs
Required for debugging and auditing
Cannot be disabled (observability principle)
Module 8: Observability (Ledger)
Purpose: Append-only JSONL audit log for all operations (immutable record)

Deliverables:

core/observability/ledger.py - LedgerWriter class
core/observability/ulid_generator.py - ULID generation for unique IDs
.runs/ledger.jsonl - Append-only log file
Key Contracts:

Python
class LedgerWriter:
    def __init__(self, ledger_path: str) -> None
        # Opens ledger file in append mode
    
    def write_event(self, event: Dict[str, Any]) -> str
        # Appends event to ledger, returns ULID
        # Event schema: {ulid, timestamp, trace_id, event_type, data}
    
    def query_events(self, filters: Dict) -> List[Dict]
        # Reads ledger with filters (read-only)

def generate_ulid() -> str
    # Returns ULID (sortable, unique ID)
Core Module Identification Criteria:

Immutable audit trail (compliance requirement)
All operations must log to ledger
Cannot be bypassed (governance principle)
Read-only after write (append-only)
Section B2: TIER 2: PLUGIN/EXTENSION MODULES (Extensible/Evolvable)
Module 1: Context Broker Plugin
Purpose: Manages context aggregation and routing for LLM tool invocations

Deliverables:

tools/context_broker.py - ContextBroker class
.context-broker.yaml - Context routing configuration
schemas/context_broker.schema.json - Contract schema
on_planning_phase: When orchestrator enters planning stage

Input Contract:

JSON
{
  "event": "on_planning_phase",
  "inputs": {
    "run_context": {
      "run_id": "01JAF...",
      "repository": "path/to/repo",
      "issue_description": "User's request"
    },
    "available_tools": ["aider", "claude-code"]
  }
}
Output Contract:

JSON
[
  {
    "action": "aggregate_context",
    "payload": {
      "file_map": ["src/main.py", "tests/test_main.py"],
      "relevant_docs": ["README.md"],
      "dependencies": ["requirements.txt"],
      "selected_tool": "aider"
    }
  }
]
Module 2: LLM Tool Dispatcher Plugin
Purpose: Integrates Aider and Claude Code CLI for AI-driven code generation

Deliverables:

core/context/dispatcher.py - LLMToolDispatcher class
Tool integration wrappers (Aider, Claude Code)
Tool invocation logs
on_code_execute: When orchestrator needs to generate/modify code

Input Contract:

JSON
{
  "event": "on_code_execute",
  "inputs": {
    "prompt": "Add error handling to process_data function",
    "files": ["src/processor.py"],
    "context": {
      "repository_path": "/worktrees/task_004",
      "model": "gpt-4"
    }
  }
}
Output Contract:

JSON
[
  {
    "action": "code_generated",
    "payload": {
      "modified_files": ["src/processor.py"],
      "diff": "--- a/src/processor.py\n+++ b/src/processor.py...",
      "tool_used": "aider",
      "model": "gpt-4",
      "tokens_used": 1250
    }
  }
]
Module 3: Linting Validator Plugin
Purpose: Runs code quality checks (Black, Ruff, mypy, pylint) as validation gate

Deliverables:

core/validation/linters.py - LinterValidator class
.ruff.toml - Ruff configuration
pyproject.toml - Black/mypy configuration sections
Linting reports (per-run artifacts)
on_validation_gate: After code generation, before merge approval

Input Contract:

JSON
{
  "event": "on_validation_gate",
  "inputs": {
    "files": ["src/processor.py", "tests/test_processor.py"],
    "worktree_path": "/worktrees/task_004"
  }
}
Output Contract:

JSON
[
  {
    "action": "validation_result",
    "payload": {
      "passed": false,
      "errors": [
        "src/processor.py:42: E501 line too long (92 > 88 characters)"
      ],
      "warnings": [
        "tests/test_processor.py:10: W0612 Unused variable 'temp'"
      ],
      "linters_run": ["black", "ruff", "mypy"],
      "can_auto_fix": true
    }
  }
]
Module 4: Security Scanner Plugin
Purpose: Scans code for security vulnerabilities (Bandit) and secrets (Gitleaks)

Deliverables:

core/validation/security_scanner.py - SecurityScanner class
Bandit/Gitleaks configuration
Security scan reports
on_validation_gate: Runs in parallel with linting validation

Input Contract:

JSON
{
  "event": "on_validation_gate",
  "inputs": {
    "files": ["src/api.py", "src/auth.py"],
    "worktree_path": "/worktrees/task_005"
  }
}
Output Contract:

JSON
[
  {
    "action": "security_scan_result",
    "payload": {
      "passed": false,
      "errors": [
        "Hardcoded password found in src/auth.py:23"
      ],
      "warnings": [
        "Use of eval() detected in src/api.py:45 (CWE-95)"
      ],
      "scanners_run": ["bandit", "gitleaks"],
      "severity_counts": {"high": 1, "medium": 1, "low": 0}
    }
  }
]
Module 5: Code Gate Router Plugin
Purpose: Routes code changes to approved/ or rejected/ directories based on validation results

Deliverables:

core/validation/code_gate.py - CodeGateRouter class
.runs/approved/ - Directory for passing changes
.runs/rejected/ - Directory for failing changes
Routing decision logs
on_quality_check: After all validation gates complete

Input Contract:

JSON
{
  "event": "on_quality_check",
  "inputs": {
    "validation_results": [
      {"plugin": "linter", "passed": true},
      {"plugin": "security", "passed": false}
    ],
    "artifacts": ["src/processor.py", "tests/test_processor.py"]
  }
}
Output Contract:

JSON
[
  {
    "action": "route_decision",
    "payload": {
      "destination": "rejected",
      "reason": "Security scan failed (1 high-severity issue)",
      "can_retry": true,
      "retry_count": 1,
      "max_retries": 3
    }
  }
]
Module 6: Plugin Scaffold Generator Plugin
Purpose: Generates plugin boilerplate from templates

Deliverables:

scripts/generate_plugin_scaffold.py - Python implementation
core/Generate-PluginScaffold.ps1 - PowerShell implementation
Plugin templates (manifest, implementation, tests)
on_plugin_load: N/A (utility plugin, not hook-based)

Input Contract:

JSON
{
  "plugin_name": "my-custom-validator",
  "hooks": ["on_validation_gate"],
  "author": "Platform.Engineering"
}
Output Contract:

JSON
[
  {
    "action": "scaffold_created",
    "payload": {
      "plugin_dir": "plugins/my_custom_validator",
      "files_created": [
        "plugins/my_custom_validator/__init__.py",
        "plugins/my_custom_validator/plugin.py",
        "plugins/my_custom_validator/plugin.yaml",
        "plugins/my_custom_validator/tests/test_plugin.py"
      ]
    }
  }
]
Section B3: TIER 3: SUPPORT MODULES
Module 1: Nox Automation
Purpose: Task automation for development workflows (lint, test, build)

Deliverables:

noxfile.py - Nox session definitions
Task automation commands (nox sessions)
Key Contracts (if applicable):

Python
@nox.session(python="3.11")
def lint(session):
    # Runs black, ruff, mypy

@nox.session(python="3.11")
def test(session):
    # Runs pytest with coverage

@nox.session(python="3.11")
def docs(session):
    # Builds MkDocs documentation
Support Module Identification Criteria:

Developer utility (not runtime-critical)
Used during development/CI, not production
Cross-cutting concern (automation)
Module 2: Test Infrastructure
Purpose: Shared pytest fixtures and test utilities

Deliverables:

tests/conftest.py - Shared fixtures (mock plugins, temp directories)
tests/integration/ - Integration test suite
Test data fixtures (sample configs, mock responses)
Key Contracts (if applicable):

Python
@pytest.fixture
def mock_plugin():
    # Returns mock plugin for testing

@pytest.fixture
def temp_worktree(tmp_path):
    # Creates temporary git worktree

@pytest.fixture
def sample_task_graph():
    # Returns sample DAG for scheduler tests
Support Module Identification Criteria:

Testing utility (not production code)
Reusable across test files
No runtime dependencies
Module 3: Documentation Generator
Purpose: Auto-generates API documentation from code

Deliverables:

scripts/generate_docs.py - Doc generator script
mkdocs.yml - MkDocs configuration
docs/ - Generated documentation site
Key Contracts (if applicable):

Python
def generate_api_docs(module_path: str) -> str
    # Extracts docstrings, generates markdown

def build_docs_site() -> None
    # Runs mkdocs build
Support Module Identification Criteria:

Documentation utility (not runtime)
Used during CI/release process
No production dependencies
Module 4: Setup Scripts
Purpose: Developer environment setup automation

Deliverables:

setup_dev.sh - Linux/Mac setup script
setup_dev.ps1 - Windows PowerShell setup script
Virtual environment configuration
Key Contracts (if applicable):

bash
# setup_dev.sh
setup_venv() {
    python -m venv .venv
    source .venv/bin/activate
    pip install -e ".[dev]"
}
Support Module Identification Criteria:

One-time setup utility
Developer experience improvement
Not part of runtime system
Section B4: COMPLETE DELIVERABLES SUMMARY TABLE
Module	Core Files	Generated Artifacts	Config Files	Tests
State Machine	state_machine.py	checkpoint.json	-	test_state_machine.py
Task Scheduler	task_scheduler.py	execution_plan.json	-	test_toposort.py
Orchestrator	orchestrator.py, runner.py	ledger.jsonl, traces	-	test_orchestrator.py
Plugin Loader	plugin_loader.py	plugin_registry.json	-	test_plugin_loader.py
Configuration	config.py	-	.env.example	test_config.py
Worktree Manager	worktree/manager.py, sync.py	worktree dirs	-	test_worktree.py
Observability (Trace)	observability/tracing.py	trace spans (Jaeger)	docker-compose.yml	-
Observability (Ledger)	observability/ledger.py, ulid_generator.py	ledger.jsonl	-	test_ledger.py
Context Broker	context_broker.py	context_map.json	.context-broker.yaml	test_context_broker.py
LLM Dispatcher	context/dispatcher.py	tool_invocations.log	-	test_dispatcher.py
Linting Validator	validation/linters.py	lint_reports/	.ruff.toml, pyproject.toml	test_linters.py
Security Scanner	validation/security_scanner.py	security_reports/	bandit.yaml	test_security.py
Code Gate Router	validation/code_gate.py	approved/, rejected/	-	test_code_gate.py
Plugin Scaffold	generate_plugin_scaffold.py, Generate-PluginScaffold.ps1	plugin templates	-	-
Nox Automation	noxfile.py	-	-	-
Test Infrastructure	tests/conftest.py	-	pytest.ini	-
Docs Generator	scripts/generate_docs.py	docs/ HTML	mkdocs.yml	-
Setup Scripts	setup_dev.sh, setup_dev.ps1	.venv/	-	-
Section B5: MODULE DEPENDENCIES
Code
Orchestrator (root controller)
├── State Machine (execution state tracking)
├── Task Scheduler (DAG ordering)
│   └── State Machine (query task states)
├── Plugin Loader (extension discovery)
│   └── Configuration (plugin paths, validation rules)
├── Worktree Manager (isolation)
│   └── Configuration (worktree settings)
├── Observability/Tracing (distributed tracing)
└── Observability/Ledger (audit logging)
    └── ULID Generator (unique IDs)

Plugin Loader
├── Configuration (plugin directory paths)
└── Validation (plugin manifest schema)

LLM Dispatcher Plugin
├── Context Broker Plugin (context aggregation)
└── Configuration (API keys, model settings)

Code Gate Router Plugin
├── Linting Validator Plugin (code quality)
├── Security Scanner Plugin (vulnerability detection)
└── State Machine (retry logic on FAILED)

Validation Plugins (Linter, Security)
└── Configuration (tool settings, thresholds)

Support Modules (no runtime dependencies)
├── Nox (dev automation)
├── Test Infrastructure (pytest fixtures)
├── Docs Generator (MkDocs)
└── Setup Scripts (environment setup)
Section B6: INTEGRATION POINTS
External Tool Integration
Tool Integrations:

Aider - CLI-based AI code editing, integrated via LLM Dispatcher Plugin
Claude Code CLI - Anthropic's code assistant, integrated via LLM Dispatcher Plugin
Jaeger - OpenTelemetry trace collection, integrated via Observability/Tracing
Bandit - Python security scanner, integrated via Security Scanner Plugin
Gitleaks - Secret detection, integrated via Security Scanner Plugin
Ruff - Python linter, integrated via Linting Validator Plugin
Black - Code formatter, integrated via Linting Validator Plugin
mypy - Type checker, integrated via Linting Validator Plugin
pytest - Test runner, integrated via Nox Automation and Test Infrastructure
Git - Version control, integrated via Worktree Manager
Data Flows
Workflow Execution (Happy Path) → Orchestrator initializes run → State Machine creates PENDING tasks → Task Scheduler computes DAG → Orchestrator executes waves → Worktree Manager creates isolation → LLM Dispatcher invokes Aider → Code generated → Validation Plugins check quality → Code Gate routes to approved/ → Orchestrator merges → Final trace/ledger write

Plugin Discovery & Loading → Plugin Loader scans plugins/ → Validates manifests → Imports Python modules → Registers hooks with Orchestrator → Plugins ready for invocation

Validation Gate (Blocking) → Code generated in worktree → Orchestrator invokes validation hooks → Linting Validator runs Ruff/Black → Security Scanner runs Bandit/Gitleaks → Code Gate aggregates results → If FAILED: route to rejected/, increment retry → If PASSED: route to approved/, continue workflow

Resumption After Failure → Task fails → State Machine writes checkpoint → Ledger records failure event → User triggers resume → Orchestrator loads checkpoint → State Machine restores task states → Scheduler recomputes remaining waves → Execution continues from last successful task

Observability Flow → Every operation creates trace span (OpenTelemetry) → Span context propagated via trace_id → Ledger writes JSONL event with trace_id → Jaeger receives spans → User queries Jaeger UI with trace_id → Correlates with ledger entries for full audit trail

PART C: PLUGIN ECOSYSTEM & DEVELOPMENT
Section C1: PLUGIN DEVELOPMENT WORKFLOW
C1.1 Plugin Creation Process
Step-by-Step:

Generate scaffold: Run pwsh core/Generate-PluginScaffold.ps1 -PluginName "my-plugin"
Implement hooks: Edit plugins/my_plugin/plugin.py, add hook methods
Configure manifest: Update plugin.yaml with hooks, dependencies, metadata
Write tests: Add unit tests in plugins/my_plugin/tests/test_plugin.py
Validate: Run python scripts/validate_plugin.py --plugin plugins/my_plugin
Test integration: Load plugin in orchestrator, verify hooks fire correctly
Document: Update plugin README.md with usage examples
Tools Required:

Python 3.11+ - Runtime environment
Git - Version control
Pytest - Testing framework
PowerShell 7+ (optional) - For PowerShell scaffold generator
Scaffolding/Generators:

bash
# PowerShell scaffold generator
pwsh core/Generate-PluginScaffold.ps1 -PluginName "custom-validator" -Hooks "on_validation_gate"

# Creates:
# plugins/custom_validator/
#   ├── __init__.py
#   ├── plugin.py (with on_validation_gate method stub)
#   ├── plugin.yaml
#   ├── config.yaml
#   └── tests/test_plugin.py
C1.2 Testing & Debugging
Testing Framework:

Plugins tested using pytest
Test runner: pytest plugins/my_plugin/tests/ -v
Mock/stub: Shared fixtures from tests/conftest.py
Debugging Tools:

Standard Python logging (context.logger)
Trace correlation via OpenTelemetry (trace_id in logs)
JSONL ledger for event replay
Test Example:

Python
# plugins/my_validator/tests/test_plugin.py
import pytest
from plugins.my_validator.plugin import MyValidatorPlugin

def test_validation_gate_passes():
    plugin = MyValidatorPlugin()
    
    validation_input = {
        'files': ['src/main.py'],
        'context': {'run_id': '01JAF'},
        'metadata': {}
    }
    
    result = plugin.on_validation_gate(validation_input)
    
    assert result.passed == True
    assert len(result.errors) == 0

def test_validation_gate_fails_on_complexity():
    plugin = MyValidatorPlugin(config={'max_complexity': 5})
    
    validation_input = {
        'files': ['src/complex.py'],  # File with high complexity
        'context': {'run_id': '01JAF'},
        'metadata': {}
    }
    
    result = plugin.on_validation_gate(validation_input)
    
    assert result.passed == False
    assert "Complexity" in result.errors[0]
Section C2: PLUGIN ECOSYSTEM
C2.1 Official/Built-in Plugins
Plugin Name	Purpose	Hooks Used	Stability
context-broker	Context aggregation for LLM tools	on_planning_phase	Stable
llm-dispatcher	Aider/Claude Code integration	on_code_execute	Stable
linting-validator	Code quality checks (Ruff/Black)	on_validation_gate	Stable
security-scanner	Security scans (Bandit/Gitleaks)	on_validation_gate	Stable
code-gate-router	Approve/reject routing	on_quality_check	Stable
plugin-scaffold	Generate plugin templates	N/A (utility)	Stable
C2.2 Third-Party Plugin Support
Distribution Channels:

Plugins distributed as Python packages (no central registry currently)
Installation: Manual copy to plugins/ directory or pip install
Package management: Standard Python packaging (setuptools, poetry)
Community Resources:

Documentation: Main repo docs/ directory
Example repositories: Reference plugins in plugins/ directory
Support: GitHub issues on main ACMS repo
Section C3: VERSIONING & COMPATIBILITY
C3.1 API Versioning
Version Strategy:

Plugin API versioned independently from ACMS core
Breaking change policy: Major version bump (SemVer)
Deprecation process: 2 minor versions notice before removal
Compatibility Matrix:

Core Version	Plugin API Version	Compatible With
1.0.0	1.0.0	Initial plugin system
1.1.0	1.1.0	Added on_error_handler hook
2.0.0	2.0.0	Breaking: Changed ValidationResult schema
C3.2 Migration Guides
Upgrade Paths:

Plugin API 1.x → 2.x: Update ValidationResult to include metadata field
Core 1.x → 2.x: Re-validate all plugins against new schema
Automated migration tools: ⚠️ Not documented / Not found in provided materials

Inference based on related patterns: Could implement via plugin validator with auto-fix mode

Recommendation: Look for schema migration scripts in future releases

PART D: ARCHITECTURAL ANALYSIS
Section D1: PLUGIN ARCHITECTURE STRENGTHS & WEAKNESSES
D1.1 Architectural Strengths
✅ Event-Driven Extensibility

Why it's good: Clean separation between core orchestration and extensions; new capabilities added without core changes
Example: Security scanning added as plugin without modifying orchestrator
✅ Deterministic Execution with State Machine

Why it's good: Workflows are resumable after failures; state transitions are explicit and validated
Example: Failed task can resume from checkpoint with known state
✅ Strong Observability Foundation

Why it's good: Every operation traced (OpenTelemetry) and logged (JSONL ledger); full audit trail
Example: Trace ID correlates plugin invocations across distributed workflow
✅ Validation-First Design

Why it's good: Plugins validated before loading; contracts enforced via schemas; quality gates prevent bad code
Example: Invalid plugin manifest fails fast with clear error
✅ Parallel Execution via DAG Scheduler

Why it's good: Independent tasks execute concurrently; topological sort prevents deadlocks
Example: Multiple worktrees process different files simultaneously
D1.2 Architectural Limitations
⚠️ **No Plugin Sandbox