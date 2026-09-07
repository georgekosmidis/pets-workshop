#!/usr/bin/env pwsh
#
# Reset the demo repository back to the tagged baseline between sessions.
# Discards working-tree changes, removes untracked files, deletes the
# live-authored Copilot instructions, and resets to the demo-baseline tag.

$ErrorActionPreference = 'Stop'

# The canonical upstream repository. The reset is destructive, so refuse to
# run it against upstream on main to avoid pointing it at the wrong repo.
$Upstream    = 'github-samples/pets-workshop'
$BaselineTag = 'demo-baseline'

Set-Location (git rev-parse --show-toplevel)

$branch    = (git rev-parse --abbrev-ref HEAD)
$originUrl = (git config --get remote.origin.url)
if (-not $originUrl) { $originUrl = '' }

if ($branch -eq 'main' -and $originUrl -match [regex]::Escape($Upstream)) {
    Write-Error "Refusing to run: origin is the upstream ($Upstream) and the branch is 'main'. Point this at your own demo fork before resetting."
    exit 1
}

git rev-parse -q --verify "refs/tags/$BaselineTag" 1>$null 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Error "Tag '$BaselineTag' not found. Create it first (see scripts/README.md)."
    exit 1
}

Write-Host "Discarding working-tree changes..."
git reset --hard

Write-Host "Removing untracked files..."
git clean -fd

Write-Host "Removing live-authored Copilot instructions (if present)..."
Remove-Item -Force '.github/copilot-instructions.md' -ErrorAction SilentlyContinue

Write-Host "Resetting to tag '$BaselineTag'..."
git reset --hard $BaselineTag

Write-Host "Done. Repository is back at '$BaselineTag'."
