# scripts/validate_contracts.ps1
# Verify all JSONL/JSON examples validate against schemas

$schemas = @{
    "task_v1" = "schemas/task_v1.schema.json"
    "ledger_entry_v1" = "schemas/ledger_entry_v1.schema.json"
    # ... all schemas
}

foreach ($schema_name in $schemas.Keys) {
    $schema_path = $schemas[$schema_name]
    $examples = Get-Content "docs/api/$schema_name.md" | Select-String '```json' -Context 0,5
    foreach ($example in $examples) {
        $json = $example.Context.PostContext -join "`n"
        $validation = Test-Json $json -SchemaFile $schema_path
        if (-not $validation) {
            Write-Error "Example failed schema validation: $schema_name"
            exit 1
        }
    }
}

exit 0