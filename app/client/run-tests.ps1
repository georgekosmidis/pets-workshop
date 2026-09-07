#!/usr/bin/env pwsh
# Simple test script that starts the app and runs Playwright tests (Windows / PowerShell).

$ErrorActionPreference = 'Stop'

Write-Host "Starting application servers in background..."

$ScriptDir = $PSScriptRoot
Set-Location (Join-Path $ScriptDir '..')

# Start the application using the existing PowerShell script
$appProcess = Start-Process pwsh `
    -ArgumentList @('-NoProfile', '-File', (Join-Path 'scripts' 'start-app.ps1')) `
    -PassThru

function Invoke-Cleanup {
    Write-Host "Cleaning up..."
    if ($appProcess -and -not $appProcess.HasExited) {
        Stop-Process -Id $appProcess.Id -Force -ErrorAction SilentlyContinue
    }
    Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -match 'app\.py' -or $_.CommandLine -match 'astro.*dev' } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
}

try {
    Write-Host "Waiting for servers to start..."
    Start-Sleep -Seconds 10

    $ready = $false
    for ($i = 1; $i -le 30; $i++) {
        $clientUp = $false
        $serverUp = $false
        try { $clientUp = (Invoke-WebRequest -UseBasicParsing -Uri 'http://localhost:4321' -TimeoutSec 2).StatusCode -eq 200 } catch {}
        try { $serverUp = (Invoke-WebRequest -UseBasicParsing -Uri 'http://localhost:5100/api/dogs' -TimeoutSec 2).StatusCode -eq 200 } catch {}
        if ($clientUp -and $serverUp) { $ready = $true; Write-Host "Servers are ready!"; break }
        Write-Host "Waiting for servers... ($i/30)"
        Start-Sleep -Seconds 2
    }

    if (-not $ready) {
        Write-Host "Servers failed to start"
        exit 1
    }

    Write-Host "Running Playwright tests..."
    Set-Location client
    npx playwright test @args
    $testExit = $LASTEXITCODE

    Write-Host "Tests completed!"
    exit $testExit
} finally {
    Invoke-Cleanup
}
