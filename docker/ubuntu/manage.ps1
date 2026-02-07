# Quick Start Script for Development Container
# Run this script to set up and start your development environment

param(
    [Parameter(Position=0)]
    [ValidateSet('start', 'stop', 'restart', 'logs', 'shell', 'status', 'clean', 'rebuild', 'help')]
    [string]$Command = 'start'
)

$ErrorActionPreference = "Stop"

function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  $Message" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
}

function Show-RDPInfo {
    Write-Header "RDP Connection Information"
    Write-Host "  Host:     " -NoNewline -ForegroundColor White
    Write-Host "localhost" -ForegroundColor Green
    Write-Host "  Port:     " -NoNewline -ForegroundColor White
    Write-Host "3389" -ForegroundColor Green
    Write-Host "  Username: " -NoNewline -ForegroundColor White
    Write-Host "dev" -ForegroundColor Green
    Write-Host "  Password: " -NoNewline -ForegroundColor White
    Write-Host "(check your .env file)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To connect:" -ForegroundColor White
    Write-Host "  1. Open Remote Desktop Connection (Win+R, type: mstsc)" -ForegroundColor Gray
    Write-Host "  2. Enter: localhost:3389" -ForegroundColor Gray
    Write-Host "  3. Login with credentials above" -ForegroundColor Gray
    Write-Host ""
}

function Start-Container {
    Write-Header "Starting Development Container"
    
    # Check if .env exists
    if (-not (Test-Path ".env")) {
        Write-Host "⚠️  .env file not found!" -ForegroundColor Yellow
        Write-Host "Creating .env from .env.example..." -ForegroundColor Yellow
        Copy-Item ".env.example" ".env"
        Write-Host ""
        Write-Host "✓ Created .env file" -ForegroundColor Green
        Write-Host "⚠️  Please edit .env and set your password!" -ForegroundColor Yellow
        Write-Host "   Then run this script again." -ForegroundColor Yellow
        Write-Host ""
        notepad .env
        exit 0
    }
    
    docker-compose up -d
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✓ Container started successfully!" -ForegroundColor Green
        Start-Sleep -Seconds 2
        Show-RDPInfo
    } else {
        Write-Host "✗ Failed to start container" -ForegroundColor Red
        exit 1
    }
}

function Stop-Container {
    Write-Header "Stopping Development Container"
    docker-compose down
    Write-Host "✓ Container stopped" -ForegroundColor Green
}

function Restart-Container {
    Write-Header "Restarting Development Container"
    docker-compose restart
    Write-Host "✓ Container restarted" -ForegroundColor Green
}

function Show-Logs {
    Write-Header "Container Logs (Ctrl+C to exit)"
    docker-compose logs -f --tail=100
}

function Open-Shell {
    Write-Header "Opening Shell in Container"
    docker-compose exec dev-desktop bash
}

function Show-Status {
    Write-Header "Container Status"
    docker-compose ps
    Write-Host ""
    
    $health = docker inspect --format='{{.State.Health.Status}}' dev-desktop 2>$null
    if ($health) {
        Write-Host "Health: " -NoNewline
        if ($health -eq "healthy") {
            Write-Host $health -ForegroundColor Green
        } else {
            Write-Host $health -ForegroundColor Yellow
        }
    }
}

function Clean-Environment {
    Write-Header "Clean Environment"
    Write-Host "⚠️  This will delete all data in the container!" -ForegroundColor Red
    Write-Host "⚠️  Including your home directory files!" -ForegroundColor Red
    Write-Host ""
    $confirm = Read-Host "Are you sure? Type 'yes' to continue"
    
    if ($confirm -eq 'yes') {
        docker-compose down -v
        Write-Host "✓ Environment cleaned" -ForegroundColor Green
    } else {
        Write-Host "Cancelled" -ForegroundColor Yellow
    }
}

function Rebuild-Container {
    Write-Header "Rebuild Container"
    Write-Host "This will rebuild the container from scratch..." -ForegroundColor Yellow
    docker-compose build --no-cache
    docker-compose up -d
    Write-Host "✓ Rebuild complete!" -ForegroundColor Green
    Show-RDPInfo
}

function Show-Help {
    Write-Header "Development Container Management"
    Write-Host "Usage: ./manage.ps1 [command]" -ForegroundColor White
    Write-Host ""
    Write-Host "Commands:" -ForegroundColor White
    Write-Host "  start     " -NoNewline -ForegroundColor Green
    Write-Host "- Start the development container (default)"
    Write-Host "  stop      " -NoNewline -ForegroundColor Green
    Write-Host "- Stop the container"
    Write-Host "  restart   " -NoNewline -ForegroundColor Green
    Write-Host "- Restart the container"
    Write-Host "  logs      " -NoNewline -ForegroundColor Green
    Write-Host "- View container logs"
    Write-Host "  shell     " -NoNewline -ForegroundColor Green
    Write-Host "- Open bash shell in container"
    Write-Host "  status    " -NoNewline -ForegroundColor Green
    Write-Host "- Show container status"
    Write-Host "  clean     " -NoNewline -ForegroundColor Green
    Write-Host "- Stop and remove container (including data!)"
    Write-Host "  rebuild   " -NoNewline -ForegroundColor Green
    Write-Host "- Rebuild container from scratch"
    Write-Host "  help      " -NoNewline -ForegroundColor Green
    Write-Host "- Show this help message"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor White
    Write-Host "  ./manage.ps1 start     " -ForegroundColor Gray -NoNewline
    Write-Host "# Start container"
    Write-Host "  ./manage.ps1 logs      " -ForegroundColor Gray -NoNewline
    Write-Host "# Watch logs"
    Write-Host "  ./manage.ps1 shell     " -ForegroundColor Gray -NoNewline
    Write-Host "# Open shell"
    Write-Host ""
}

# Main script
try {
    switch ($Command) {
        'start'   { Start-Container }
        'stop'    { Stop-Container }
        'restart' { Restart-Container }
        'logs'    { Show-Logs }
        'shell'   { Open-Shell }
        'status'  { Show-Status }
        'clean'   { Clean-Environment }
        'rebuild' { Rebuild-Container }
        'help'    { Show-Help }
        default   { Show-Help }
    }
}
catch {
    Write-Host ""
    Write-Host "✗ Error: $_" -ForegroundColor Red
    Write-Host ""
    exit 1
}
