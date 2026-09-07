#!/usr/bin/env pwsh
# GitHub Copilot Enablement for TKE - environment check (Windows / PowerShell)
# Run from the root of the workshop repository:  .\check-env.ps1
# Exits 0 if you are ready, 1 if something needs fixing.

$ErrorActionPreference = 'Continue'

$script:Pass = 0
$script:Fail = 0
$script:Warn = 0

function Ok   { param([string]$Msg) Write-Host "  [ OK ]   $Msg" -ForegroundColor Green; $script:Pass++ }
function Bad  { param([string]$Msg, [string]$Fix) Write-Host "  [FAIL]   $Msg" -ForegroundColor Red;    Write-Host "           -> $Fix"; $script:Fail++ }
function Warn { param([string]$Msg, [string]$Fix) Write-Host "  [WARN]   $Msg" -ForegroundColor Yellow; Write-Host "           -> $Fix"; $script:Warn++ }

# Compare dotted versions: (Test-VersionGe '22.12.0' '22.12.0') -> $true
function Test-VersionGe {
    param([string]$Have, [string]$Need)
    try {
        $h = [version]("$Have".Split('-')[0])
        $n = [version]$Need
        return $h -ge $n
    } catch {
        return $false
    }
}

function Test-Command {
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

# Look for an installed VS Code extension by id. Checks user-installed extensions
# and bundled (built-in) extensions, which 'code --list-extensions' does not report.
function Test-VSCodeExtension {
    param([string]$Id, [string[]]$CliList)
    if ($CliList -contains $Id.ToLower()) { return $true }
    $shortId = $Id.Split('.')[-1]
    $roots = @(
        (Join-Path $env:USERPROFILE '.vscode/extensions')
        (Join-Path $env:USERPROFILE 'AppData/Local/Programs/Microsoft VS Code')
        "$env:ProgramFiles/Microsoft VS Code"
    )
    foreach ($root in $roots) {
        if (-not (Test-Path $root)) { continue }
        $hit = Get-ChildItem $root -Directory -Recurse -Depth 4 -Filter $shortId -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -match 'extensions' } | Select-Object -First 1
        if ($hit) { return $true }
    }
    return $false
}

Write-Host ""
Write-Host "GitHub Copilot Enablement - environment check (Windows)"
Write-Host "======================================================="
Write-Host ""

Write-Host "Runtimes"
if (Test-Command git) {
    $gitVersion = if ((git --version) -match '(\d+\.\d+\.\d+)') { $Matches[1] } else { '' }
    Ok "git $gitVersion"
} else {
    Bad "git not found" "Install the git CLI: winget install --id Git.Git  (or https://git-scm.com/downloads)"
}

$NodeFix = "Astro 6 needs Node 22.12.0 or newer. Install the LTS build: winget install --id OpenJS.NodeJS.LTS  (or https://nodejs.org). Open a new terminal afterwards."
if (Test-Command node) {
    $nodeVersion = (node -v) -replace '^v', ''
    if (Test-VersionGe $nodeVersion '22.12.0') { Ok "Node.js $nodeVersion" }
    else { Bad "Node.js $nodeVersion is too old" $NodeFix }
} else {
    Bad "Node.js not found" $NodeFix
}

if (Test-Command npm) {
    $npmVersion = (npm -v)
    if (Test-VersionGe $npmVersion '9.6.5') { Ok "npm $npmVersion" }
    else { Bad "npm $npmVersion is too old" "Needs npm 9.6.5 or newer. Run: npm install -g npm" }
} else {
    Bad "npm not found" "npm ships with Node.js - reinstall Node"
}

$py = $null
foreach ($candidate in @('py', 'python', 'python3')) {
    if (Test-Command $candidate) {
        $v = (& $candidate -c 'import sys;print("%d.%d.%d"%sys.version_info[:3])' 2>$null)
        if ($v -and (Test-VersionGe $v '3.11.0')) { $py = $candidate; Ok "Python $v ($candidate)"; break }
    }
}
if (-not $py) {
    Bad "No Python 3.11 or newer found" "Install Python 3.11+: winget install --id Python.Python.3.12  (or https://python.org). Tick 'Add python.exe to PATH'."
}

Write-Host ""
Write-Host "Repository"
if ((Test-Path 'app/server/requirements.txt') -and (Test-Path 'app/client/package.json')) {
    Ok "Running from the repository root"
} else {
    Bad "Not in the repository root" "cd into the folder you cloned, then run this script again"
}

if (Test-Path '.git') {
    Ok "This is a git clone"
} else {
    Warn "No .git folder found" "You are probably in a downloaded ZIP. Clone the repo instead so Copilot can index it."
}

Write-Host ""
Write-Host "Editor and Copilot"
if (Test-Command code) {
    Ok "VS Code CLI available"
    $ext = (code --list-extensions 2>$null) | ForEach-Object { $_.ToLower() }
    if (Test-VSCodeExtension 'github.copilot' $ext) {
        Ok "GitHub Copilot extension"
    } else {
        Warn "GitHub Copilot not listed by the VS Code CLI" "Newer VS Code builds bundle Copilot as a built-in extension, which the CLI does not list. Confirm Copilot works in the editor. If it does not, install it from the Extensions view by searching for 'GitHub Copilot'."
    }
    if (Test-VSCodeExtension 'github.copilot-chat' $ext) {
        Ok "GitHub Copilot Chat extension"
    } else {
        Warn "GitHub Copilot Chat not listed by the VS Code CLI" "Newer VS Code builds may bundle Copilot Chat. Confirm the Chat view works in the editor; do not rely on 'code --install-extension GitHub.copilot-chat'."
    }
    if (Test-VSCodeExtension 'ms-python.python' $ext)    { Ok "Python extension" }              else { Warn "Python extension missing"            "Recommended: code --install-extension ms-python.python" }
    if (Test-VSCodeExtension 'ms-toolsai.jupyter' $ext)  { Ok "Jupyter extension" }             else { Warn "Jupyter extension missing"           "Needed for the notebook demo: code --install-extension ms-toolsai.jupyter" }
} else {
    Warn "VS Code CLI ('code') not on PATH" "Not fatal. Open VS Code and confirm manually that Copilot and Copilot Chat are installed and signed in."
}

Write-Host ""
Write-Host "Dependencies install correctly"
if ($py -and (Test-Path 'app/server/requirements.txt')) {
    $venvCheck = '.venv-check'
    & $py -m venv $venvCheck 2>$null
    $vpy = Join-Path $venvCheck 'Scripts/python.exe'
    if (-not (Test-Path $vpy)) { $vpy = Join-Path $venvCheck 'bin/python' }
    if (Test-Path $vpy) {
        & $vpy -m pip install -q -r app/server/requirements.txt 2>$null
        if ($LASTEXITCODE -eq 0) {
            Ok "Python dependencies install"
            Push-Location app/server
            & (Join-Path '..' (Join-Path '..' $vpy)) -m unittest test_app 2>$null 1>$null
            $testExit = $LASTEXITCODE
            Pop-Location
            if ($testExit -eq 0) { Ok "Backend test suite runs" }
            else { Warn "Backend tests did not pass" "Not fatal on the day, but tell the trainer what error you saw." }
        } else {
            Bad "Python dependencies failed to install" "Usually a proxy or certificate issue. Send the pip error to your IT contact."
        }
    } else {
        Bad "Could not create a Python virtual environment" "Ensure Python is fully installed and on PATH, then run this script again."
    }
    if (Test-Path $venvCheck) { Remove-Item -Recurse -Force $venvCheck -ErrorAction SilentlyContinue }
}

if ((Test-Command npm) -and (Test-Path 'app/client/package.json')) {
    Push-Location app/client
    npm install --no-audit --no-fund 2>$null 1>$null
    $npmExit = $LASTEXITCODE
    Pop-Location
    if ($npmExit -eq 0) { Ok "Node dependencies install" }
    else { Bad "Node dependencies failed to install" "Usually a proxy or registry restriction. Send the npm error to your IT contact." }
}

Write-Host ""
Write-Host "======================================================="
Write-Host "  $script:Pass passed, $script:Warn warnings, $script:Fail failures"
Write-Host ""
if ($script:Fail -gt 0) {
    Write-Host "  Not ready yet. Fix the FAIL items above, then run this again."
    Write-Host "  Still stuck? Reply to the invitation with this whole output."
    Write-Host ""
    exit 1
}
if ($script:Warn -gt 0) {
    Write-Host "  Ready. The warnings are optional but worth fixing before the session."
} else {
    Write-Host "  Ready. Nothing to do - see you in the session."
}
Write-Host ""
exit 0
