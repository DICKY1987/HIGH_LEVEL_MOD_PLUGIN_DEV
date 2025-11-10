[CmdletBinding()]
param(
    [string]$PluginsRoot = (Join-Path $PSScriptRoot '..\INSTALL\plugins'),
    [string]$SchemaPath = (Join-Path $PSScriptRoot '..\plugin-manifest-schema.json')
)
$ErrorActionPreference = 'Stop'
Write-Host "Validating plugin manifests..." -ForegroundColor Cyan

if (-not (Test-Path $PluginsRoot)) {
    Write-Host "Plugins root not found: $PluginsRoot" -ForegroundColor Yellow
    exit 0
}

$manifests = Get-ChildItem -Path $PluginsRoot -Directory |
    ForEach-Object { Join-Path $_.FullName 'plugin.manifest.json' } |
    Where-Object { Test-Path $_ }

if (-not $manifests) {
    Write-Host "No plugin manifests found." -ForegroundColor Yellow
    exit 0
}

$failed = 0
foreach ($m in $manifests) {
    try {
        if ((Get-Content $m -Raw) | Test-Json -SchemaFile $SchemaPath) {
            Write-Host "✓ $m" -ForegroundColor Green
        } else {
            Write-Host "✗ $m" -ForegroundColor Red
            $failed++
        }
    } catch {
        Write-Host "✗ $m - $_" -ForegroundColor Red
        $failed++
    }
}

if ($failed -gt 0) { exit 1 }
exit 0
