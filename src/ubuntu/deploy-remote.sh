#!/usr/bin/env bash
# Deploy to remote VM

set -e

echo "=== Developer Workstation - Remote Deployment ==="
echo ""

# Check for required parameters
if [ -z "$1" ]; then
    echo "Usage: $0 <remote-host> [docker-context-name]"
    echo ""
    echo "Examples:"
    echo "  $0 user@remote-vm.com"
    echo "  $0 10.10.0.10 remote-workstation"
    echo ""
    exit 1
fi

REMOTE_HOST="$1"
CONTEXT_NAME="${2:-remote}"

echo "Remote host: $REMOTE_HOST"
echo "Docker context: $CONTEXT_NAME"
echo ""

# Check if context already exists
if docker context inspect "$CONTEXT_NAME" > /dev/null 2>&1; then
    echo "✓ Docker context '$CONTEXT_NAME' already exists"
else
    echo "Creating Docker context..."
    docker context create "$CONTEXT_NAME" --docker "host=ssh://$REMOTE_HOST"
    echo "✓ Created Docker context '$CONTEXT_NAME'"
fi

# Switch to remote context
echo "Switching to remote context..."
docker context use "$CONTEXT_NAME"
echo "✓ Using context '$CONTEXT_NAME'"

echo ""
echo "Testing connection..."
if docker info > /dev/null 2>&1; then
    echo "✓ Connected to remote Docker"
else
    echo "ERROR: Cannot connect to remote Docker"
    echo "Make sure:"
    echo "  1. SSH access is configured"
    echo "  2. Docker is installed on remote host"
    echo "  3. Your user can run docker commands"
    exit 1
fi

echo ""
echo "Building and deploying container..."
docker compose -f compose.yaml -f compose.remote.yaml up -d --build

echo ""
echo "=== Deployment Complete! ==="
echo ""
echo "Container is running on: $REMOTE_HOST"
echo ""
echo "Access via WireGuard VPN:"
echo "  1. Connect to WireGuard VPN"
echo "  2. RDP to <workstation-vpn-ip>:3389"
echo "  3. Or use Sunshine/Moonlight (see SUNSHINE_SETUP.md)"
echo ""
echo "Management commands (on remote):"
echo "  View logs:    docker --context $CONTEXT_NAME compose logs -f"
echo "  Restart:      docker --context $CONTEXT_NAME compose restart"
echo "  Stop:         docker --context $CONTEXT_NAME compose down"
echo ""
echo "To switch back to local context:"
echo "  docker context use default"
