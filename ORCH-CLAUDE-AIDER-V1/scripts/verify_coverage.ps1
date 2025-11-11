# scripts/verify_coverage.ps1
$pester_coverage = Import-Clixml "coverage_results/pester_coverage.xml"
if ($pester_coverage.CoveragePercent -lt 90) {
    Write-Error "PowerShell coverage below 90%: $($pester_coverage.CoveragePercent)"
    exit 1
}

$pytest_coverage = Get-Content "coverage_results/pytest_coverage.txt" | Select-String "TOTAL.*(\d+)%" -AllMatches
$coverage_pct = [int]$pytest_coverage.Matches[0].Groups[1].Value
if ($coverage_pct -lt 95) {
    Write-Error "Python coverage below 95%: $coverage_pct%"
    exit 1
}

exit 0