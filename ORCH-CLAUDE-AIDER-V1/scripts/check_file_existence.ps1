# scripts/check_file_existence.ps1
$required_files = @(
    # Core executables
    "scripts/QueueWorker.ps1",
    "scripts/Supervisor.ps1",
    "scripts/RecoverProcessing.ps1",
    "scripts/run_quality.ps1",
    
    # Modules
    "scripts/ToolAdapters.psm1",
    "scripts/ErrorHandler.psm1",
    "scripts/WorktreeManager.psm1",
    "scripts/LogRotation.ps1",
    
    # Schemas
    "schemas/task_v1.schema.json",
    "schemas/ledger_entry_v1.schema.json",
    "schemas/heartbeat_v1.schema.json",
    "schemas/quality_report_v1.schema.json",
    "schemas/config_policies_v1.schema.json",
    
    # Configuration
    "Config/HeadlessPolicies.psd1",
    
    # CI
    ".github/workflows/quality.yml",
    ".github/workflows/integration.yml",
    
    # Directories
    ".tasks/inbox/",
    ".tasks/processing/",
    ".tasks/done/",
    ".tasks/failed/",
    ".tasks/quarantine/",
    ".state/",
    "logs/",
    
    # Documentation
    "docs/technical_specification.md",
    "docs/operations/runbook.md",
    "docs/api/task_jsonl_v1.md",
    "docs/api/ledger_entry_v1.md"
)

$missing = $required_files | Where-Object { -not (Test-Path $_) }
if ($missing) {
    Write-Error "Missing files: $($missing -join ', ')"
    exit 1
}
exit 0