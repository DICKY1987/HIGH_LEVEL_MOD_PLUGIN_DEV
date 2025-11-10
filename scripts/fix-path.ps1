# Fix PATH - Add C:\Tools\node to User PATH
Write-Host "=== Fixing PATH Configuration ===" -ForegroundColor Cyan

# Get current User PATH
$currentPath = [System.Environment]::GetEnvironmentVariable('Path', 'User')

# Check if C:\Tools\node is already in PATH
if ($currentPath -like '*C:\Tools\node*') {
    Write-Host "[OK] C:\Tools\node is already in User PATH" -ForegroundColor Green
} else {
    # Add C:\Tools\node to PATH
    $newPath = "$currentPath;C:\Tools\node"
    [System.Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
    Write-Host "[SUCCESS] Added C:\Tools\node to User PATH" -ForegroundColor Green
    Write-Host "Note: Open a NEW terminal for changes to take effect" -ForegroundColor Yellow
}

# Display current PATH components that include 'Tools' or 'node'
Write-Host "`nRelevant PATH entries:" -ForegroundColor Cyan
$updatedPath = [System.Environment]::GetEnvironmentVariable('Path', 'User')
$updatedPath -split ';' | Where-Object { $_ -like '*Tools*' -or $_ -like '*node*' } | ForEach-Object {
    Write-Host "  - $_" -ForegroundColor White
}
