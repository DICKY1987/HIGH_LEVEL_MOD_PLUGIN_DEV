# scripts/validate_rtm.ps1
# Verify every deliverable has tests, every test has evidence

$rtm = Import-PowerShellDataFile "rtm.psd1"

foreach ($entry in $rtm) {
    if (-not $entry.tests -or $entry.tests.Count -eq 0) {
        Write-Error "RTM entry missing tests: $($entry.requirement)"
        exit 1
    }
    if (-not $entry.evidence -or $entry.evidence.Count -eq 0) {
        Write-Error "RTM entry missing evidence: $($entry.requirement)"
        exit 1
    }
}

# Verify no orphaned files
$mapped_files = $rtm.files | Select-Object -Unique
$actual_files = Get-ChildItem -Recurse -File | Where-Object { $_.Extension -in @('.ps1', '.psm1', '.json') }
$orphans = $actual_files | Where-Object { $_.FullName -notin $mapped_files }
if ($orphans) {
    Write-Error "Orphaned files (not in RTM): $($orphans.FullName -join ', ')"
    exit 1
}

exit 0