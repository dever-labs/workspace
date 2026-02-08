.PHONY: help build up down restart logs shell exec clean rebuild status health

# Default target
help:
	@echo "Development Container Management"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  build     - Build the container image"
	@echo "  up        - Start the container"
	@echo "  down      - Stop the container"
	@echo "  restart   - Restart the container"
	@echo "  logs      - View container logs (follow mode)"
	@echo "  shell     - Open bash shell in container"
	@echo "  exec      - Execute command in container (use CMD='your command')"
	@echo "  clean     - Stop and remove container and volumes"
	@echo "  rebuild   - Clean rebuild (no cache)"
	@echo "  status    - Show container status"
	@echo "  health    - Show container health"
	@echo "  rdp       - Show RDP connection info"
	@echo ""
	@echo "Examples:"
	@echo "  make up              - Start the dev environment"
	@echo "  make logs            - Watch logs in real-time"
	@echo "  make shell           - Open shell in container"
	@echo "  make exec CMD='ls -la'  - Run command in container"

# Build the image
build:
	docker compose build

# Start the container
up:
	docker compose up -d
	@echo ""
	@echo "✓ Container started!"
	@make rdp

# Stop the container
down:
	docker compose down

# Restart the container
restart:
	docker compose restart
	@echo "✓ Container restarted!"

# View logs
logs:
	docker compose logs -f --tail=100

# Open bash shell
shell:
	docker compose exec workspace bash

# Execute arbitrary command
exec:
	docker compose exec workspace $(CMD)

# Stop and remove everything including volumes
clean:
	@echo "⚠️  This will delete all data in the container!"
	@echo "Press Ctrl+C to cancel, or wait 5 seconds to continue..."
	@timeout /t 5 /nobreak > nul 2>&1 || sleep 5
	docker compose down -v
	@echo "✓ Cleaned up!"

# Rebuild from scratch
rebuild: clean
	docker compose build --no-cache
	docker compose up -d
	@echo "✓ Rebuild complete!"

# Show status
status:
	@docker compose ps

# Show health
health:
	@docker inspect --format='{{.State.Health.Status}}' workspace 2>nul || echo "Container not running"

# Show RDP connection info
rdp:
	@echo "═══════════════════════════════════════"
	@echo "  RDP Connection Information"
	@echo "═══════════════════════════════════════"
	@echo "  Host:     localhost"
	@echo "  Port:     3389"
	@echo "  Username: dev"
	@echo "  Password: (check your .env file)"
	@echo "═══════════════════════════════════════"
	@echo ""
	@echo "To connect:"
	@echo "  1. Open Remote Desktop Connection (mstsc.exe)"
	@echo "  2. Enter: localhost:3389"
	@echo "  3. Login with credentials above"
