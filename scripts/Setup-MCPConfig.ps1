# Setup MCP Configuration for Claude Code
# This script configures MCP servers for the Claude Code CLI

[CmdletBinding()]
param(
    [string]$ConfigPath = "$env:APPDATA\Claude",
    [string]$GithubToken = "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",
    [switch]$Force
)

Write-Host "=== Claude Code MCP Server Configuration ===" -ForegroundColor Cyan
Write-Host ""

# Define configuration file path
$configFile = Join-Path $ConfigPath "claude_desktop_config.json"

# Create config directory if it doesn't exist
if (-not (Test-Path $ConfigPath)) {
    Write-Host "[INFO] Creating configuration directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $ConfigPath -Force | Out-Null
    Write-Host "[SUCCESS] Created: $ConfigPath" -ForegroundColor Green
}

# Check if config already exists
if ((Test-Path $configFile) -and -not $Force) {
    Write-Host "[WARNING] Configuration file already exists!" -ForegroundColor Yellow
    Write-Host "Location: $configFile" -ForegroundColor Gray
    $response = Read-Host "Overwrite? (y/N)"
    if ($response -ne 'y' -and $response -ne 'Y') {
        Write-Host "[CANCELLED] Keeping existing configuration" -ForegroundColor Yellow
        exit 0
    }
}

# Get current project directory
$projectDir = Split-Path -Parent $PSScriptRoot

# Define MCP server configuration
$mcpConfig = @{
    mcpServers = @{
        "filesystem" = @{
            command = "npx"
            args = @(
                "-y"
                "@modelcontextprotocol/server-filesystem"
                $projectDir
            )
        }
        "github" = @{
            command = "npx"
            args = @(
                "-y"
                "@modelcontextprotocol/server-github"
            )
            env = @{
                GITHUB_PERSONAL_ACCESS_TOKEN = $GithubToken
            }
        }
        "memory" = @{
            command = "npx"
            args = @(
                "-y"
                "@modelcontextprotocol/server-memory"
            )
        }
    }
}

# Convert to JSON with proper formatting
$jsonConfig = $mcpConfig | ConvertTo-Json -Depth 10
$jsonConfig | Out-File -FilePath $configFile -Encoding utf8 -Force

Write-Host "[SUCCESS] MCP configuration created!" -ForegroundColor Green
Write-Host ""

# Display configured servers
Write-Host "Configured MCP Servers:" -ForegroundColor Cyan
Write-Host ""

Write-Host "  1. Filesystem MCP" -ForegroundColor White
Write-Host "     Command: npx @modelcontextprotocol/server-filesystem" -ForegroundColor Gray
Write-Host "     Access:  $projectDir" -ForegroundColor Gray
Write-Host ""

Write-Host "  2. GitHub MCP" -ForegroundColor White
Write-Host "     Command: npx @modelcontextprotocol/server-github" -ForegroundColor Gray
Write-Host "     Token:   Configured (${GithubToken.Substring(0,7)}...)" -ForegroundColor Gray
Write-Host ""

Write-Host "  3. Memory MCP" -ForegroundColor White
Write-Host "     Command: npx @modelcontextprotocol/server-memory" -ForegroundColor Gray
Write-Host "     Purpose: Persistent memory across sessions" -ForegroundColor Gray
Write-Host ""

# Verify configuration
Write-Host "Verification:" -ForegroundColor Cyan
if (Test-Path $configFile) {
    Write-Host "  [✓] Config file created" -ForegroundColor Green
    Write-Host "  [✓] Location: $configFile" -ForegroundColor Gray

    # Verify JSON is valid
    try {
        $testJson = Get-Content $configFile -Raw | ConvertFrom-Json
        Write-Host "  [✓] JSON structure valid" -ForegroundColor Green

        # Verify server count
        $serverCount = $testJson.mcpServers.PSObject.Properties.Name.Count
        Write-Host "  [✓] $serverCount MCP servers configured" -ForegroundColor Green
    }
    catch {
        Write-Host "  [✗] JSON validation failed: $_" -ForegroundColor Red
    }
}
else {
    Write-Host "  [✗] Config file not found!" -ForegroundColor Red
}

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Ensure Node.js and npx are installed" -ForegroundColor White
Write-Host "  2. Restart Claude Code to load the configuration" -ForegroundColor White
Write-Host "  3. MCP servers will be auto-installed on first use via npx" -ForegroundColor White
Write-Host ""

# Set environment variable for Claude Config Path
Write-Host "[INFO] Setting CLAUDE_CONFIG_PATH environment variable..." -ForegroundColor Yellow
[Environment]::SetEnvironmentVariable("CLAUDE_CONFIG_PATH", $ConfigPath, "User")
Write-Host "[SUCCESS] CLAUDE_CONFIG_PATH = $ConfigPath" -ForegroundColor Green
Write-Host ""

Write-Host "=== Configuration Complete ===" -ForegroundColor Cyan
