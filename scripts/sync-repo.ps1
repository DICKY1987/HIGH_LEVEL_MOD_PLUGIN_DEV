# === Sync local ↔ GitHub (Option A: keep both histories) ===
# Creates safety snapshots, merges origin into local, and pushes.

$ErrorActionPreference = 'Continue'

# --- Config (edit if your path/remote change) ---
$RepoPath  = 'C:\Users\richg\HIGH_LEVEL_MOD_PLUGIN_DEV'
$RemoteUrl = 'https://github.com/DICKY1987/HIGH_LEVEL_MOD_PLUGIN_DEV.git'

# --- Go to repo folder ---
Set-Location -LiteralPath $RepoPath

# --- Ensure this is a git repo (init if needed) ---
git rev-parse --is-inside-work-tree 1>$null 2>$null
if ($LASTEXITCODE -ne 0) { git init -b main | Out-Null }

# --- Save any local work as a safety WIP commit (no error if nothing to commit) ---
git add -A
git commit -m "WIP: pre-sync safety snapshot" 1>$null 2>$null

# --- Ensure/point 'origin' remote to GitHub ---
$hasOrigin = git remote 2>$null | Select-String '^origin$'
if ($hasOrigin) { git remote set-url origin $RemoteUrl | Out-Null } else { git remote add origin $RemoteUrl | Out-Null }

# --- Fetch remote refs (prune deleted) ---
git fetch origin --prune

# --- Detect remote default branch (fall back to 'main') ---
$RemoteDefault = (git remote show origin 2>$null | Select-String 'HEAD branch:' | ForEach-Object { $_.ToString().Split(':')[1].Trim() })
if ([string]::IsNullOrWhiteSpace($RemoteDefault)) { $RemoteDefault = 'main' }

# --- Align local branch name with remote default (or create it) ---
git checkout -B $RemoteDefault

# --- Create rollback snapshots ---
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
git branch "backup/local-$stamp" 2>$null
git branch "backup/remote-$stamp" "origin/$RemoteDefault" 2>$null

# --- Does the remote branch exist? (empty repo case) ---
$remoteHead = git ls-remote --heads origin $RemoteDefault
$HasRemoteBranch = -not [string]::IsNullOrWhiteSpace(($remoteHead | Out-String))

if (-not $HasRemoteBranch) {
  Write-Host "No '$RemoteDefault' found on remote; publishing local branch as initial."
} else {
  # --- Try a normal merge first (keeps both histories) ---
  git merge "origin/$RemoteDefault"
  $mergeExit = $LASTEXITCODE

  # If merge failed, check if we're in a conflict state
  $inMerge = (git rev-parse -q --verify MERGE_HEAD 2>$null) -ne $null

  if ($mergeExit -ne 0 -and -not $inMerge) {
    # Possibly unrelated histories; try again permitting it
    Write-Host "Retrying merge with --allow-unrelated-histories..."
    git merge "origin/$RemoteDefault" --allow-unrelated-histories
    $mergeExit = $LASTEXITCODE
    $inMerge = (git rev-parse -q --verify MERGE_HEAD 2>$null) -ne $null
  }

  if ($inMerge) {
    Write-Host ""
    Write-Host "⚠️ Merge conflicts detected. Resolve them, then run:"
    Write-Host "   git add -A"
    Write-Host "   git commit"
    Write-Host "   git push -u origin $RemoteDefault"
    Write-Host ""
    Write-Host "Tip: See conflicted files:"
    Write-Host "   git status"
    return
  }

  if ($mergeExit -ne 0) {
    Write-Host "❌ Merge failed (not in conflict state). Inspect logs and try again."
    Write-Host "   git log --oneline --graph --decorate -20"
    Write-Host "   git status"
    exit 1
  }
}

# --- Push the result (sets upstream if missing) ---
git push -u origin $RemoteDefault

# --- Nice-to-have global settings for future pulls ---
git config --global fetch.prune true
git config --global pull.rebase true
git config --global rebase.autoStash true

Write-Host ""
Write-Host "✅ Sync complete. Branch: $RemoteDefault"
Write-Host "   Backup branches: backup/local-$stamp, backup/remote-$stamp (if remote existed)"
Write-Host "   Next time: use  ->  git pull --rebase --autostash ; git push"
