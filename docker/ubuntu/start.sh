#!/usr/bin/env bash
# Quick start script for local development

set -e

echo "=== Developer Workstation - Quick Start ==="
echo ""

# Check Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "ERROR: Docker is not running. Please start Docker Desktop."
    exit 1
fi

echo "✓ Docker is running"

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "Creating .env file..."
    cat > .env <<EOF
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
EOF
    echo "✓ Created .env file - Please edit it with your settings"
    
    # Open .env in default editor
    if command -v code > /dev/null; then
        code .env
    elif command -v nano > /dev/null; then
        nano .env
    else
        echo "  Edit .env manually with your preferred editor"
    fi
    
    read -p "Press Enter after editing .env to continue..."
fi

echo ""
echo "Building and starting container..."
docker compose up -d --build

echo ""
echo "=== Waiting for services to start ==="
sleep 5

# Check container is running
if docker compose ps | grep -q "Up"; then
    echo "✓ Container is running"
else
    echo "ERROR: Container failed to start"
    echo "Check logs with: docker compose logs"
    exit 1
fi

echo ""
echo "=== Developer Workstation Ready! ==="
echo ""
echo "Access Methods:"
echo "  RDP:  localhost:3389 (user: dev, password: <from .env>)"
echo "  SSH:  ssh -p 2222 dev@localhost"
echo "  X2Go: localhost:2222"
echo ""
echo "Management Commands:"
echo "  View logs:    docker compose logs -f"
echo "  Restart:      docker compose restart"
echo "  Stop:         docker compose down"
echo "  Update:       docker compose pull && docker compose up -d"
echo ""
echo "Next steps:"
echo "  1. Connect via RDP to localhost:3389"
echo "  2. Install your IDEs (JetBrains Toolbox, VS Code, etc.)"
echo "  3. Configure Git and SSH keys"
echo ""
echo "For Sunshine/Moonlight setup, see SUNSHINE_SETUP.md"
