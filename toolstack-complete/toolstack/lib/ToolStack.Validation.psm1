# toolstack-complete/toolstack/lib/ToolStack.Validation.psm1
# Validation functions for ToolStack configuration and plugin manifests

function Test-JsonSchema {
    <#
    .SYNOPSIS
    Validates JSON content against a schema
    #>
    param(
        [Parameter(Mandatory)] [string]$JsonContent,
        [Parameter(Mandatory)] [string]$SchemaPath
    )
    if (-not (Test-Path $SchemaPath)) { throw "Schema not found: $SchemaPath" }
    return ($JsonContent | Test-Json -SchemaFile $SchemaPath)
}

function Test-ToolStackConfig {
    <#
    .SYNOPSIS
    Validates a ToolStack configuration file
    #>
    param(
        [Parameter(Mandatory)] [string]$ConfigPath,
        [string]$SchemaPath = "$PSScriptRoot\..\config\schemas\config-schema.json"
    )
    if (-not (Test-Path $ConfigPath)) { throw "Config not found: $ConfigPath" }
    if (-not (Test-Path $SchemaPath)) { throw "Schema not found: $SchemaPath" }
    $content = Get-Content $ConfigPath -Raw
    return Test-JsonSchema -JsonContent $content -SchemaPath $SchemaPath
}

function Test-PluginManifest {
    <#
    .SYNOPSIS
    Validates a single plugin manifest against the schema
    #>
    param(
        [Parameter(Mandatory)] [string]$ManifestPath,
        [string]$SchemaPath = "$PSScriptRoot\..\config\schemas\plugin-manifest-schema.json"
    )
    if (-not (Test-Path $ManifestPath)) { throw "Manifest not found: $ManifestPath" }
    if (-not (Test-Path $SchemaPath)) { throw "Schema not found: $SchemaPath" }
    return (Get-Content $ManifestPath -Raw | Test-Json -SchemaFile $SchemaPath)
}

function Test-PluginManifests {
    <#
    .SYNOPSIS
    Validates all plugin manifests under INSTALL\plugins
    #>
    param(
        [string]$PluginsRoot = "$PSScriptRoot\..\..\..\INSTALL\plugins",
        [string]$SchemaPath = "$PSScriptRoot\..\config\schemas\plugin-manifest-schema.json"
    )
    if (-not (Test-Path $PluginsRoot)) {
        Write-Host "Plugins root not found: $PluginsRoot" -ForegroundColor Yellow
        return $true
    }
    $manifests = Get-ChildItem -Path $PluginsRoot -Directory |
        ForEach-Object { Join-Path $_.FullName 'plugin.manifest.json' } |
        Where-Object { Test-Path $_ }
    if (-not $manifests) {
        Write-Host "No plugin manifests found." -ForegroundColor Yellow
        return $true
    }
    $failed = 0
    foreach ($m in $manifests) {
        if (Test-PluginManifest -ManifestPath $m -SchemaPath $SchemaPath) {
            Write-Host "✓ $m" -ForegroundColor Green
        } else { Write-Host "✗ $m" -ForegroundColor Red; $failed++ }
    }
    return ($failed -eq 0)
}

Export-ModuleMember -Function Test-JsonSchema, Test-ToolStackConfig, Test-PluginManifest, Test-PluginManifests
