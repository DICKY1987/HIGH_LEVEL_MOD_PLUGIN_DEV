# Test Commands - Verify All Tools Are Accessible
Write-Host "=== Testing Command Accessibility ===" -ForegroundColor Cyan
Write-Host "This script tests commands in a fresh environment with updated PATH`n" -ForegroundColor White

# Refresh PATH from environment variables
$env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path', 'User')

$testResults = @()

# Test function
function Test-Command {
    param(
        [string]$CommandName,
        [string]$TestArg = "--version"
    )

    try {
        $output = & $CommandName $TestArg 2>&1 | Select-Object -First 1
        $testResults += [PSCustomObject]@{
            Command = $CommandName
            Status = "✓ PASS"
            Output = $output
        }
        Write-Host "  ✓ $CommandName" -ForegroundColor Green -NoNewline
        Write-Host " - $output" -ForegroundColor Gray
    } catch {
        $testResults += [PSCustomObject]@{
            Command = $CommandName
            Status = "✗ FAIL"
            Output = $_.Exception.Message
        }
        Write-Host "  ✗ $CommandName" -ForegroundColor Red -NoNewline
        Write-Host " - FAILED" -ForegroundColor Gray
    }
}

Write-Host "Testing npm global commands (from C:\Tools\node):" -ForegroundColor Yellow
Test-Command "claude" "--version"
Test-Command "mcp-server-github" "--version"
Test-Command "mcp-server-memory" "--version"
Test-Command "mcp-server-filesystem" "--version"

Write-Host "`nTesting core runtime:" -ForegroundColor Yellow
Test-Command "node"
Test-Command "npm"
Test-Command "python"
Test-Command "git"

Write-Host "`nTesting AI tools:" -ForegroundColor Yellow
Test-Command "aider"
Test-Command "invoke"

Write-Host "`nMCP Configuration:" -ForegroundColor Yellow
$mcpConfigPath = "$env:APPDATA\Claude\claude_desktop_config.json"
if (Test-Path $mcpConfigPath) {
    Write-Host "  ✓ MCP config exists: $mcpConfigPath" -ForegroundColor Green
    $config = Get-Content $mcpConfigPath | ConvertFrom-Json
    $serverCount = $config.mcpServers.PSObject.Properties.Count
    Write-Host "  ✓ Configured servers: $serverCount" -ForegroundColor Green
    Write-Host "    Servers: $($config.mcpServers.PSObject.Properties.Name -join ', ')" -ForegroundColor Gray
} else {
    Write-Host "  ✗ MCP config not found" -ForegroundColor Red
}

Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
$passed = ($testResults | Where-Object { $_.Status -eq "✓ PASS" }).Count
$failed = ($testResults | Where-Object { $_.Status -eq "✗ FAIL" }).Count
Write-Host "Passed: $passed / $($testResults.Count)" -ForegroundColor Green
if ($failed -gt 0) {
    Write-Host "Failed: $failed / $($testResults.Count)" -ForegroundColor Red
}
