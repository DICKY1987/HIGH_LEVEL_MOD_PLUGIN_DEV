# scripts/validate_acceptance.ps1
# For each deliverable, verify tests exist and pass

$deliverables = @{
    "DEL-001" = @("test_task_ingestion", "test_state_transitions", "test_invalid_rejection")
    "DEL-002" = @("test_task_execution_timeout", "test_retry_backoff", "test_circuit_breaker")
    "DEL-003" = @("test_heartbeat_restart", "test_stale_recovery", "test_git_lock_repair")
    # ... all 10 deliverables
}

foreach ($del in $deliverables.Keys) {
    foreach ($test in $deliverables[$del]) {
        $result = Invoke-Pester -TestName $test -PassThru
        if ($result.FailedCount -gt 0) {
            Write-Error "Acceptance test failed: $del - $test"
            exit 1
        }
    }
}
exit 0