# Quick start script for Windows/Local development

Write-Host "=== Developer Workstation - Quick Start ===" -ForegroundColor Cyan
Write-Host ""

# Check Docker is running
try {
    docker info | Out-Null
    Write-Host "[OK] Docker is running" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Docker is not running. Please start Docker Desktop." -ForegroundColor Red
    exit 1
}

# Create .env file if it doesn't exist
if (-not (Test-Path .env)) {
    Write-Host "Creating .env file..." -ForegroundColor Yellow
    
    @"
# Developer workstation configuration

# Password for dev user (change this!)
DEV_PASSWORD=dev

# Timezone
TIMEZONE=UTC

# Git configuration
GIT_USER_NAME=
GIT_USER_EMAIL=

# Remote Access Options
# RDP - Built-in Windows compatibility (50-150ms latency)
ENABLE_RDP=true
# X2Go - Better performance (10-30ms latency) - requires X2Go client
ENABLE_X2GO=false
# SSH - Required for X2Go, useful for terminal access
ENABLE_SSH=true
# Sunshine - BEST performance (5-15ms, 60 FPS) GPU-accelerated streaming
ENABLE_SUNSHINE=true

# Resource limits
CPU_LIMIT=8
MEMORY_LIMIT=16G
CPU_RESERVATION=4
MEMORY_RESERVATION=8G

# NVIDIA GPU support
NVIDIA_VISIBLE_DEVICES=all
NVIDIA_DRIVER_CAPABILITIES=all
"@ | Out-File -FilePath .env -Encoding UTF8
    
    Write-Host "[OK] Created .env file" -ForegroundColor Green
    
    # Open in VS Code if available
    if (Get-Command code -ErrorAction SilentlyContinue) {
        code .env
    } else {
        notepad .env
    }
    
    Read-Host "Press Enter after editing .env to continue"
}

Write-Host ""
Write-Host "Building and starting container..." -ForegroundColor Cyan
docker compose up -d --build

Write-Host ""
Write-Host "=== Waiting for services to start ===" -ForegroundColor Cyan
Start-Sleep -Seconds 5

# Check container is running
$containerStatus = docker compose ps --format json 2>$null
if ($containerStatus -and ($containerStatus | ConvertFrom-Json | Select-Object -First 1).State -eq "running") {
    Write-Host "[OK] Container is running" -ForegroundColor Green
} else {
    Write-Host "ERROR: Container failed to start" -ForegroundColor Red
    Write-Host "Check logs with: docker compose logs" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "=== Developer Workstation Ready! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Access Methods:" -ForegroundColor Cyan
Write-Host "  RDP:  localhost:3389 (user: dev, password: from .env)"
Write-Host "  SSH:  ssh -p 2222 dev@localhost"
Write-Host "  X2Go: localhost:2222"
Write-Host ""
Write-Host "Management Commands:" -ForegroundColor Cyan
Write-Host "  View logs:    docker compose logs -f"
Write-Host "  Restart:      docker compose restart"
Write-Host "  Stop:         docker compose down"
Write-Host "  Update:       docker compose pull; docker compose up -d"
Write-Host ""
Write-Host "Quick Connect:" -ForegroundColor Cyan
Write-Host "  RDP: mstsc" -ForegroundColor Yellow -NoNewline
Write-Host " /v:localhost:3389"
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Connect via RDP to localhost:3389"
Write-Host "  2. Install your IDEs (JetBrains Toolbox, VS Code, etc.)"
Write-Host "  3. Configure Git and SSH keys"
Write-Host ""
Write-Host "For Sunshine/Moonlight setup, see SUNSHINE_SETUP.md" -ForegroundColor Yellow

# Offer to open RDP
Write-Host ""
$openRDP = Read-Host "Open RDP connection now? (Y/N)"
if ($openRDP -eq "Y" -or $openRDP -eq "y") {
    Start-Process mstsc -ArgumentList "/v:localhost:3389"
}
