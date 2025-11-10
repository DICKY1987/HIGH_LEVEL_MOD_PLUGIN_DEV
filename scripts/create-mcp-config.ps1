# Create MCP Configuration for Claude Desktop
Write-Host "=== Creating MCP Configuration ===" -ForegroundColor Cyan

# Define configuration directory
$configDir = "$env:APPDATA\Claude"
$configFile = "$configDir\claude_desktop_config.json"

# Create directory if it doesn't exist
if (-not (Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    Write-Host "[SUCCESS] Created directory: $configDir" -ForegroundColor Green
} else {
    Write-Host "[OK] Directory already exists: $configDir" -ForegroundColor Green
}

# Define MCP configuration
$mcpConfig = @{
    mcpServers = @{
        "github" = @{
            command = "C:\Tools\node\mcp-server-github.cmd"
            args = @()
            env = @{
                GITHUB_TOKEN = "`${GITHUB_TOKEN}"
            }
        }
        "memory" = @{
            command = "C:\Tools\node\mcp-server-memory.cmd"
            args = @()
        }
        "filesystem" = @{
            command = "C:\Tools\node\mcp-server-filesystem.cmd"
            args = @(
                "C:\Users\richg\HIGH_LEVEL_MOD_PLUGIN_DEV"
                "C:\Users\richg\Downloads\INSTALL"
            )
        }
        "powershell" = @{
            command = "pwsh"
            args = @(
                "-NoLogo"
                "-NoProfile"
                "-Command"
                "Import-Module PowerShell.MCP; Start-MCPServer"
            )
        }
    }
}

# Convert to JSON and save
$jsonConfig = $mcpConfig | ConvertTo-Json -Depth 10
$jsonConfig | Out-File -FilePath $configFile -Encoding utf8 -Force

Write-Host "[SUCCESS] Created MCP configuration file: $configFile" -ForegroundColor Green

# Display configuration
Write-Host "`nMCP Servers Configured:" -ForegroundColor Cyan
Write-Host "  1. GitHub MCP Server" -ForegroundColor White
Write-Host "     - Command: C:\Tools\node\mcp-server-github.cmd" -ForegroundColor Gray
Write-Host "     - Requires: GITHUB_TOKEN environment variable" -ForegroundColor Yellow
Write-Host ""
Write-Host "  2. Memory MCP Server" -ForegroundColor White
Write-Host "     - Command: C:\Tools\node\mcp-server-memory.cmd" -ForegroundColor Gray
Write-Host "     - Provides: Persistent memory across sessions" -ForegroundColor Gray
Write-Host ""
Write-Host "  3. Filesystem MCP Server" -ForegroundColor White
Write-Host "     - Command: C:\Tools\node\mcp-server-filesystem.cmd" -ForegroundColor Gray
Write-Host "     - Allowed Directories:" -ForegroundColor Gray
Write-Host "       * C:\Users\richg\HIGH_LEVEL_MOD_PLUGIN_DEV" -ForegroundColor Gray
Write-Host "       * C:\Users\richg\Downloads\INSTALL" -ForegroundColor Gray
Write-Host ""
Write-Host "  4. PowerShell MCP Server" -ForegroundColor White
Write-Host "     - Command: pwsh with PowerShell.MCP module" -ForegroundColor Gray
Write-Host "     - Provides: Native PowerShell cmdlet execution" -ForegroundColor Gray
Write-Host ""

Write-Host "`n[IMPORTANT] Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Set GITHUB_TOKEN environment variable for GitHub MCP" -ForegroundColor White
Write-Host "     `$env:GITHUB_TOKEN = 'your-github-token-here'" -ForegroundColor Gray
Write-Host "  2. Restart Claude Desktop to load the new configuration" -ForegroundColor White
Write-Host "  3. Verify MCP servers appear in Claude Desktop" -ForegroundColor White

# Verify file was created
if (Test-Path $configFile) {
    Write-Host "`n[VERIFIED] Configuration file exists" -ForegroundColor Green
    $fileSize = (Get-Item $configFile).Length
    Write-Host "File size: $fileSize bytes" -ForegroundColor Gray
} else {
    Write-Host "`n[ERROR] Configuration file was not created!" -ForegroundColor Red
}
