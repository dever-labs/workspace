# Migration Guide - Restructured Repository

Your repository has been restructured to support flexible deployment (local, remote VM, Kubernetes) with Sunshine/Moonlight integration for optimal performance.

## What Changed

### New Files Created

1. **Dockerfile.new** - Clean, production-ready Dockerfile
2. **compose.yaml** - Base Docker Compose configuration
3. **compose.override.yaml** - Local development overrides
4. **compose.remote.yaml** - Remote VM configuration
5. **k8s/devworkstation.yaml** - Kubernetes StatefulSet manifests
6. **SUNSHINE_SETUP.md** - Complete Sunshine/Moonlight setup guide
7. **start.sh / start.ps1** - Quick start scripts
8. **deploy-remote.sh** - Remote deployment script
9. **README.new.md** - Comprehensive documentation

### File Structure

```
Before:                          After:
docker-compose.yml       →      compose.yaml (base)
                                compose.override.yaml (local)
                                compose.remote.yaml (remote)
Dockerfile              →       Dockerfile (simplified)
README.md               →       README.md (comprehensive)
                        +       SUNSHINE_SETUP.md (new guide)
                        +       k8s/ (Kubernetes manifests)
                        +       start.sh, start.ps1 (quick start)
                        +       deploy-remote.sh (deployment)
```

## Migration Steps

### Step 1: Backup Current Setup

```powershell
# Stop current container
docker compose down

# Backup volumes (optional)
docker run --rm -v dev-home:/data -v ${PWD}:/backup alpine tar czf /backup/backup-pre-migration.tar.gz -C /data .
```

### Step 2: Replace Files

```powershell
# Backup originals
Move-Item Dockerfile Dockerfile.old
Move-Item docker-compose.yml docker-compose.yml.old
Move-Item README.md README.old.md

# Use new files
Move-Item Dockerfile.new Dockerfile
Move-Item README.new.md README.md

# docker-compose.yml is now split:
# - compose.yaml (already created)
# - compose.override.yaml (already created)  
# - compose.remote.yaml (already created)
```

### Step 3: Update Configuration

```powershell
# Edit .env with your settings
code .env  # or notepad .env

# Key settings to update:
# - DEV_PASSWORD (change from default!)
# - TIMEZONE
# - GIT_USER_NAME
# - GIT_USER_EMAIL
```

### Step 4: Start New Setup

**Option A: Quick Start (Recommended)**
```powershell
.\start.ps1
```

**Option B: Manual**
```powershell
# Build and start
docker compose up -d --build

# Check status
docker compose ps

# View logs
docker compose logs -f
```

### Step 5: Test Connection

```powershell
# RDP (Windows)
mstsc /v:localhost:3389

# Or SSH
ssh -p 2222 dev@localhost
```

## New Capabilities

### 1. Local Development (Unchanged)

```powershell
docker compose up -d
```
- Automatically uses `compose.yaml` + `compose.override.yaml`
- GPU support enabled
- Docker socket mounted

### 2. Remote VM Deployment (New!)

```bash
# Deploy to remote VM
./deploy-remote.sh user@remote-vm

# Or manually
docker context create remote --docker "host=ssh://user@remote-vm"
docker --context remote compose -f compose.yaml -f compose.remote.yaml up -d
```

### 3. Kubernetes Deployment (New!)

```bash
# Deploy
kubectl apply -f k8s/devworkstation.yaml

# Check status
kubectl get pods -n devworkstations

# Access
kubectl get svc -n devworkstations
# Connect to <node-ip>:30389
```

### 4. Sunshine/Moonlight (New!)

For near-native performance (5-15ms latency):

1. Install Sunshine on host/VM: `winget install LizardByte.Sunshine`
2. Install Moonlight on laptop: `winget install MoonlightGameStreamingProject.Moonlight`
3. Follow complete setup: [SUNSHINE_SETUP.md](SUNSHINE_SETUP.md)

## Advantages Over Old Setup

| Feature | Old | New |
|---------|-----|-----|
| **Performance** | RDP only (50-150ms) | Sunshine/Moonlight (5-15ms) |
| **Deployment** | Local only | Local + Remote + K8s |
| **Configuration** | Single compose file | Modular (base + overrides) |
| **Remote Access** | Manual setup | Built-in scripts |
| **Security** | Basic | WireGuard VPN integration |
| **Documentation** | Basic README | Complete guides |
| **Management** | Manual docker commands | Quick start scripts + Makefile |

## Troubleshooting

### Old container still running

```powershell
# Using old compose file
docker-compose down  # Note: dash, not space

# Or force remove
docker container rm -f devworkstation
docker container rm -f dev-desktop
```

### Port conflicts

Edit `.env`:
```bash
RDP_PORT=3390  # Instead of 3389
SSH_PORT=2223  # Instead of 2222
```

### GPU not working

```powershell
# Test GPU access
docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi

# If fails, check Docker Desktop GPU settings
# Settings → Resources → GPU
```

### Can't find compose.yaml

```powershell
# Make sure you're in the correct directory
cd C:\Users\caspe\Repos\workspace\docker\ubuntu

# Check files exist
dir compose.*
```

## What to Keep

- **Keep:** `.env` (your settings)
- **Keep:** Volume data (automatically preserved)
- **Optional:** `Dockerfile.old`, `docker-compose.yml.old` (backup)

## What to Delete (After Testing)

Once you've confirmed new setup works:

```powershell
Remove-Item Dockerfile.old
Remove-Item docker-compose.yml.old
Remove-Item README.old.md
Remove-Item .gitignore.new  # Use if you want the new gitignore
```

## Next Steps

1. ✅ **Test locally** - `.\start.ps1`
2. ✅ **Change password** - Edit `.env`, set `DEV_PASSWORD`
3. ✅ **Configure Git** - Edit `.env`, set `GIT_USER_NAME` and `GIT_USER_EMAIL`
4. ⬜ **Setup Sunshine** - Follow [SUNSHINE_SETUP.md](SUNSHINE_SETUP.md) for optimal performance
5. ⬜ **Deploy remotely** - Use `deploy-remote.sh` if needed
6. ⬜ **Install IDEs** - Inside container, install JetBrains Toolbox or snap packages

## Support

- **Quick reference:** `make help` (shows all available commands)
- **Sunshine setup:** See [SUNSHINE_SETUP.md](SUNSHINE_SETUP.md)
- **Full documentation:** See [README.md](README.md)
- **Issues:** Check logs with `docker compose logs -f`

---

## Commands Cheat Sheet

```powershell
# Start
docker compose up -d

# Stop
docker compose down

# Logs
docker compose logs -f

# Shell access
docker compose exec devworkstation bash

# Restart
docker compose restart

# Update
docker compose pull && docker compose up -d

# Backup
make backup  # or see Makefile for manual command

# Remote deployment
./deploy-remote.sh user@remote-vm

# Kubernetes
kubectl apply -f k8s/devworkstation.yaml
```

---

**Your existing data (home directory, workspace) is preserved!**

The new setup uses the same volume names, so all your files, settings, and installed applications are untouched.
