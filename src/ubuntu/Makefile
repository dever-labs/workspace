.PHONY: help build up down restart logs shell exec clean rebuild status health rdp k8s-apply k8s-delete helm-install helm-upgrade

RDP_HOST ?= localhost
RDP_PORT ?= 3389
RDP_USER ?= dev
K8S_NAMESPACE ?= workspace
HELM_CHART ?= ./helm/workspace
HELM_RELEASE ?= workspace

ifeq ($(OS),Windows_NT)
SLEEP_CMD = powershell -NoProfile -Command "Start-Sleep -Seconds 5"
else
SLEEP_CMD = sleep 5
endif

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
	@echo "  k8s-apply - Apply Kubernetes manifest"
	@echo "  k8s-delete - Delete Kubernetes manifest"
	@echo "  helm-install - Install Helm chart (use SIZE_HOME/SIZE_WORKSPACE)"
	@echo "  helm-upgrade - Upgrade Helm chart (use SIZE_HOME/SIZE_WORKSPACE)"
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
	$(if $(strip $(CMD)),,$(error Usage: make exec CMD='your command'))
	docker compose exec workspace $(CMD)

# Stop and remove everything including volumes
clean:
	@echo "⚠️  This will delete all data in the container!"
	@echo "Press Ctrl+C to cancel, or wait 5 seconds to continue..."
	@$(SLEEP_CMD)
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
	@echo "  Host:     $(RDP_HOST)"
	@echo "  Port:     $(RDP_PORT)"
	@echo "  Username: $(RDP_USER)"
	@echo "  Password: (check your .env file)"
	@echo "═══════════════════════════════════════"
	@echo ""
	@echo "To connect:"
	@echo "  1. Open Remote Desktop Connection (mstsc.exe)"
	@echo "  2. Enter: $(RDP_HOST):$(RDP_PORT)"
	@echo "  3. Login with credentials above"

# Kubernetes (manifest)
k8s-apply:
	kubectl apply -f k8s/workspace.yaml

k8s-delete:
	kubectl delete -f k8s/workspace.yaml

# Kubernetes (Helm)
helm-install:
	$(if $(strip $(SIZE_HOME)),,$(error Usage: make helm-install SIZE_HOME=20Gi SIZE_WORKSPACE=20Gi))
	$(if $(strip $(SIZE_WORKSPACE)),,$(error Usage: make helm-install SIZE_HOME=20Gi SIZE_WORKSPACE=20Gi))
	helm install $(HELM_RELEASE) $(HELM_CHART) -n $(K8S_NAMESPACE) --create-namespace \
	  --set persistent.home.size=$(SIZE_HOME) \
	  --set persistent.workspace.size=$(SIZE_WORKSPACE)

helm-upgrade:
	$(if $(strip $(SIZE_HOME)),,$(error Usage: make helm-upgrade SIZE_HOME=20Gi SIZE_WORKSPACE=20Gi))
	$(if $(strip $(SIZE_WORKSPACE)),,$(error Usage: make helm-upgrade SIZE_HOME=20Gi SIZE_WORKSPACE=20Gi))
	helm upgrade $(HELM_RELEASE) $(HELM_CHART) -n $(K8S_NAMESPACE) \
	  --set persistent.home.size=$(SIZE_HOME) \
	  --set persistent.workspace.size=$(SIZE_WORKSPACE)
