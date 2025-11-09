Core Runtimes & Language Platforms

Python 3.11+ (3.12 recommended) - Core runtime for ACMS and most services
Node.js LTS (v20) - JavaScript/TypeScript runtime for CLI tools
PowerShell 7 (7.4+) - Cross-platform automation shell
Git - Version control system
Git LFS - Git extension for large binary files

AI Coding Assistants & Automation

Aider - Terminal pair-programmer for direct repo editing
Claude Code CLI - Anthropic's repo-aware code assistant
GitHub Copilot CLI - Terminal helper for code suggestions
Continue - Open-source coding assistant with CLI/headless modes
Jules Tools - Command-line companion for Google's Jules agent
Open Interpreter - Runs code from natural-language commands
SWE-agent - Research-grade CLI agent for software engineering
AutoCodeRover - CLI agent for minimal code changes
GPT-Engineer - Generates/upgrades codebases from specs
OpenHands (formerly OpenDevin) - Dev agent with headless execution

Multi-Agent Frameworks

LangGraph - Graph-based runtime for stateful LLM workflows (CRITICAL - identified as core orchestrator)
AutoGen - Python framework for cooperating LLM agents
CrewAI - Role-specialized agent crews with Python API
SuperAGI - OSS agent platform with headless automation
Dify - Open platform for LLM apps with workflows
CAMEL - Multi-agent simulations framework
ChatDev - Simulates software company of agents
BabyAGI - Minimalist autonomous agent loop
GPTScript - Agentic workflows as scripts
AgentScope - Multi-agent runtime with Docker/K8s
Lagent - Lightweight agent framework
OpenAI Swarm - Minimal multi-agent coordination library
Langroid - Multi-agent toolkit for tool use
MetaGPT - Multi-agent "virtual company" framework

Memory & RAG Systems

MemGPT / Letta - Long-term memory agents with CLI
LlamaIndex - RAG pipeline framework
Ragna - RAG orchestrator with CLI
Cognee - AI memory layer for knowledge pipelines

Python Package Management & Tools

pip - Python package installer
pipx - Install Python CLI apps in isolated environments
Poetry - Python dependency management (optional)
setuptools - Python packaging tools

Python Linters, Formatters & Type Checkers

Ruff - Ultra-fast Python linter/formatter (Rust-based)
Black - Opinionated Python code formatter
isort - Python import sorter
Pylint - Comprehensive static analysis
mypy - Optional static type checker
pyright - Fast, scalable type checker

Python Testing Frameworks

pytest - Extensible testing framework
unittest - Built-in xUnit-style testing
Nox - Automates testing across Python versions
Bandit - Python security scanner

PowerShell Testing & Quality Tools

Pester - PowerShell testing framework
PSScriptAnalyzer - PowerShell linter
Invoke-Build - PowerShell build automation engine
Build-Checkpoint.ps1 - Persistent build management
Build-Parallel.ps1 - Concurrent task execution

Security & Secret Scanning

Gitleaks - Secrets scanner for repos
Semgrep - Multi-language static analysis
Conftest - Policy testing tool
OPA (Open Policy Agent) - Policy engine

Code Transformation & AST Tools

Comby - Structural code search/rewrite
JSCodeshift - JavaScript codemod tool
Morph - Code transformation utilities
AST manipulation libraries (language-specific)

CLI Utilities & Text Processing

jq - Command-line JSON processor
yq - Command-line YAML processor
ripgrep (rg) - Fast recursive search tool
GitHub CLI (gh) - GitHub operations from terminal

Linters for Other Languages

yamllint - YAML linter
markdownlint-cli - Markdown style enforcer
mdformat - CommonMark Markdown formatter
codespell - Spell checker for source/docs
ESLint - JavaScript/TypeScript linter
tsc - TypeScript compiler (for type checking)

MCP (Model Context Protocol) Servers

Ruff MCP - Python lint/format/fix operations
Analyzer (Ruff+Vulture) - Combined linting/dead-code checking
Python LFT - Lint/format/test MCP
Pylint MCP - Pylint wrapper
Pytest MCP - Test execution MCP
PyPI Package Intel MCP - Package metadata queries
GitMCP - GitHub repos as MCP knowledge hub
Sourcegraph Codesearch MCP - Cross-repo code search
Git Operations MCP - Git utilities (commits, branches, diffs)
PowerShell Exec MCP - Execute PS commands/scripts
PowerShell MCP (general) - PS discovery and script runs
PSScriptAnalyzer MCP - PS linter via MCP
Microsoft AI Shell - PowerShell-first AI workflows
PowerShell Universal - Dashboards/APIs/automation hosting

Model Interfaces & Local Runners

LLM (Simon Willison) - Universal CLI for multiple models
Ollama - Local LLM runtime

Web Framework & API

FastAPI - High-performance Python web framework

Observability & Tracing

Jaeger - OpenTelemetry trace collection
OpenTelemetry SDK - Distributed tracing library
Docker - For running Jaeger and other services
docker-compose - Multi-container orchestration

CI/CD & Automation

GitHub Actions - CI/CD workflows
Renovate - Dependency update automation
pre-commit - Git hook management

Documentation Generation

MkDocs - Static site generator for documentation
Sphinx (optional alternative)

IDE & Development Tools

VSCode (recommended) - Code editor with extensions
PyCharm (alternative) - Python IDE

Spec & Governance Tools

OpenSpec - Spec-driven dev toolkit
Specify - Design-token engine

Desktop Agents

Bytebot - Self-hosted desktop agent (optional)

Planned/Optional Tools

Python GUI Terminal (planned) - PyQt/PySide terminal with PTY controls
Linear - Project management (integration planned)
Plane - Project management (integration planned)
Lemon AI - Docker-based agent platform (optional)

System Dependencies

sudo (Linux) - For network namespace isolation
unshare (Linux) - Network namespace creation
Windows Firewall (Windows) - For sandbox isolation
Visual Studio Code tasks.json support - For IDE integration

Development Environment Setup Tools

Virtual environment tools (venv, virtualenv)
.env file - Environment variable management
editable package installation (pip install -e)


Installation Priority Order:

Critical Runtime (required first):

Python 3.12, PowerShell 7, Node.js 20, Git


Core Quality Tools (needed for development):

Ruff, Black, pytest, PSScriptAnalyzer, Semgrep, Gitleaks


AI Assistants (for autonomous operations):

Aider, Claude Code CLI, LangGraph


MCP Infrastructure (for tool integration):

MCP servers as needed per domain


Optional Enhancements (add as needed):

Additional multi-agent frameworks, desktop agents, specialized tools