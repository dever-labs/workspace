# Developer Workstation Container

A containerized Linux development environment with full desktop (XFCE), optimized for remote access via Sunshine/Moonlight streaming or RDP. Escape IT restrictions by running your entire development stack (JetBrains IDEs, VS Code, Docker, etc.) in an isolated container.

## Features

- ✅ **Full Linux Desktop (XFCE)** - Complete GUI environment
- ✅ **GPU Acceleration** - NVIDIA GPU support for hardware encoding and 3D applications
- ✅ **Multiple Access Methods** - RDP, SSH, X2Go, or Sunshine/Moonlight
- ✅ **JetBrains IDEs Ready** - Optimized for Rider, WebStorm, IntelliJ IDEA
- ✅ **Docker-in-Docker** - Run containers within the workspace
- ✅ **Persistent Storage** - Home directory and caches preserved across restarts
- ✅ **Flexible Deployment** - Local Docker Desktop, Remote VM, or Kubernetes

## Quick Start

### Prerequisites

- Docker Desktop (Windows/Mac) or Docker Engine (Linux)
- NVIDIA GPU (optional, for hardware acceleration)
- 16GB+ RAM recommended

### Start Locally (5 minutes)

**Windows:**
```powershell
.\start.ps1
```

**Linux/Mac:**
```bash
chmod +x start.sh
./start.sh
```

**Manual:**
```bash
docker compose up -d
```

Connect via RDP: `localhost:3389` (user: `dev`, password: `dev`)

---

## Deployment Options

### 1. Local Development (Docker Desktop)

Perfect for testing or bypassing local IT restrictions.

```bash
# Start
docker compose up -d

# Connect
mstsc /v:localhost:3389    # Windows RDP
# or
ssh -p 2222 dev@localhost  # SSH
```

**Files used:**
- `compose.yaml` - Base configuration
- `compose.override.yaml` - Local overrides (GPU, Docker socket)

---

### 2. Remote VM (Docker Engine)

Deploy to a cloud VM for remote development.

```bash
# One-time setup
./deploy-remote.sh user@remote-vm

# Or manually
docker context create remote --docker "host=ssh://user@remote-vm"
docker --context remote compose -f compose.yaml -f compose.remote.yaml up -d
```

**Access:**
- Via WireGuard VPN (recommended): `<vpn-ip>:3389`
- Via Sunshine/Moonlight: See [SUNSHINE_SETUP.md](SUNSHINE_SETUP.md)

**Files used:**
- `compose.yaml` - Base configuration
- `compose.remote.yaml` - Remote-specific settings (isolated Docker-in-Docker)

---

### 3. Kubernetes

Deploy to K8s cluster for enterprise scenarios.

```bash
# Deploy
kubectl apply -f k8s/devworkstation.yaml

# Get access info
kubectl get svc -n devworkstations

# Access via NodePort
mstsc /v:<node-ip>:30389
```

**Features:**
- StatefulSet with persistent volumes
- GPU support via NVIDIA GPU Operator
- ConfigMap/Secret for configuration
- NodePort or LoadBalancer service

---

## Architecture

### Sunshine/Moonlight (Recommended for Remote)

```
Laptop                    Remote VM
┌──────────┐             ┌─────────────────┐
│Moonlight │◄─WireGuard──│  Sunshine       │
│Client    │   VPN       │  (GPU encode)   │
└──────────┘             │      ↓          │
                          │  Container      │
                          │  +RDP+Desktop   │
                          └─────────────────┘
```

**Why Sunshine/Moonlight?**
- **5-15ms latency** (vs 50-150ms RDP)
- **60 FPS** smooth desktop
- **Native-feeling** IDE performance  
- Originally designed for game streaming

> **⚠️ Known Limitation:** Sunshine/Moonlight does **not work** with Docker Desktop on Windows due to bridge networking ping verification issues. Works perfectly on Linux Docker Engine, Kubernetes, and native WSL2 Docker. For local Windows development, use X2Go or RDP instead.

**Setup Guide:** [SUNSHINE_SETUP.md](SUNSHINE_SETUP.md)

---

## Configuration

### Environment Variables

Create `.env` file (see `.env.example`):

```bash
# User credentials
DEV_PASSWORD=your-secure-password

# Timezone
TIMEZONE=America/New_York

# Git configuration
GIT_USER_NAME=Your Name
GIT_USER_EMAIL=your.email@example.com

# Remote Access Options
ENABLE_RDP=true        # RDP server (xrdp) for Windows native access
ENABLE_X2GO=false      # X2Go for better performance (10-30ms)
ENABLE_SSH=true        # SSH server (required for X2Go)
ENABLE_SUNSHINE=true   # Sunshine/Moonlight streaming (5-15ms, best performance)

# Resource limits
CPU_LIMIT=8
MEMORY_LIMIT=16G

# GPU support
NVIDIA_VISIBLE_DEVICES=all
```

**Remote Access Guide:**
- **RDP (default):** Native Windows client, 50-150ms latency, easy setup
- **X2Go:** Better performance (10-30ms), requires X2Go client application
- **Sunshine/Moonlight (recommended):** Best performance (5-15ms, 60 FPS), Sunshine runs in container with GPU encoding, connect with Moonlight client

### Persistent Data

Volumes for data persistence:
- `dev-home` - User home directory (`/home/dev`)
- `workspace` - Shared workspace (`/workspace`)
- `nuget-cache` - .NET package cache
- `npm-cache` - Node.js package cache
- `pip-cache` - Python package cache
- `cargo-cache` - Rust package cache

---

## Installed Tools

### Desktop Environment
- XFCE4 (lightweight, fast)
- Terminal, file manager, text editor
- GPU acceleration (NVIDIA, Mesa)

### Development Tools
- **Languages:** Python 3, Node.js, GCC/G++
- **Version Control:** Git, Git LFS
- **Editors:** vim, neovim, nano
- **CLI Tools:** tmux, screen, ripgrep, fd, bat, htop, jq
- **Build Tools:** cmake, make, automake
- **Package Managers:** pip, npm, yarn, pnpm, pipenv, poetry

### Container Tools
- Docker CLI
- Docker Compose
- Docker-in-Docker support

### Database Clients
- PostgreSQL client
- MySQL client
- SQLite3

---

## Common Tasks

### Install JetBrains IDEs

```bash
# Inside container terminal
# Download JetBrains Toolbox
wget https://download.jetbrains.com/toolbox/jetbrains-toolbox-latest.tar.gz
tar -xzf jetbrains-toolbox-latest.tar.gz
./jetbrains-toolbox

# Or install directly
sudo snap install rider --classic
sudo snap install webstorm --classic
```

### Install Moonlight (for Sunshine streaming)

**Windows:**
```powershell
# Option 1: WinGet (recommended)
winget install MoonlightGameStreamingProject.Moonlight

# Option 2: Chocolatey
choco install moonlight-qt

# Option 3: Direct download from GitHub
# https://github.com/moonlight-stream/moonlight-qt/releases
```

**macOS:**
```bash
brew install --cask moonlight
# Or download from: https://github.com/moonlight-stream/moonlight-qt/releases
```

**Linux:**
```bash
# Flatpak (recommended)
flatpak install flathub com.moonlight_stream.Moonlight

# Snap
sudo snap install moonlight

# AppImage - download from GitHub releases
```

**Mobile:**
- iOS: App Store → "Moonlight Game Streaming"
- Android: Play Store → "Moonlight Game Streaming"

### Configure Git

```bash
# Set via environment variables in .env
# Or inside container:
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### Mount Local Code

Add to `compose.override.yaml`:

```yaml
volumes:
  - /path/to/your/code:/workspace/projects
```

### Docker-in-Docker

```bash
# Docker socket is mounted - just use docker normally
docker run hello-world
docker compose up
```

### Backup/Restore

```bash
# Backup home directory
docker run --rm -v dev-home:/data -v $(pwd):/backup alpine \
  tar czf /backup/home-backup.tar.gz -C /data .

# Restore
docker run --rm -v dev-home:/data -v $(pwd):/backup alpine \
  sh -c "cd /data && tar xzf /backup/home-backup.tar.gz"
```

---

## Troubleshooting

### GPU not detected

```bash
# Check NVIDIA drivers on host
nvidia-smi

# Check GPU in container
docker exec devworkstation nvidia-smi

# Verify Docker GPU support
docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi
```

### RDP connection fails

```bash
# Check container is running
docker compose ps

# Check xrdp service
docker exec devworkstation pgrep xrdp

# View logs
docker compose logs -f
```

### Performance is slow

- Use Sunshine/Moonlight instead of RDP (see [SUNSHINE_SETUP.md](SUNSHINE_SETUP.md))
- Increase resource limits in `.env`
- Check GPU acceleration is working
- Disable compositor in XFCE (Settings → Window Manager → Compositor)

### Can't access from remote network

- Set up WireGuard VPN (see [SUNSHINE_SETUP.md](SUNSHINE_SETUP.md))
- Configure firewall to allow only VPN access
- Never expose RDP/SSH directly to internet

---

## Security

### Best Practices

1. **Change default password** in `.env`
2. **Use WireGuard VPN** for remote access
3. **Never expose RDP/SSH** to public internet
4. **Use SSH keys** instead of passwords
5. **Bind Sunshine** to VPN interface only
6. **Regular updates:** `docker compose pull && docker compose up -d`

### Firewall Rules (Remote VM)

```bash
# Allow only WireGuard
sudo ufw allow 51820/udp

# Allow Sunshine from VPN only
sudo ufw allow from 10.10.0.0/24 to any port 47984:47990 proto tcp

# Enable firewall
sudo ufw enable
```

---

## File Structure

```
.
├── Dockerfile                  # Container image definition
├── entrypoint.sh              # Container startup script
├── compose.yaml               # Base Docker Compose config
├── compose.override.yaml      # Local development overrides  
├── compose.remote.yaml        # Remote VM configuration
├── k8s/
│   └── devworkstation.yaml    # Kubernetes manifests
├── start.sh / start.ps1       # Quick start scripts
├── deploy-remote.sh           # Remote deployment script
├── SUNSHINE_SETUP.md          # Sunshine/Moonlight guide
├── README.md                  # This file
└── .env.example               # Example configuration
```

---

## Performance Comparison

| Method | Latency | Smoothness | Complexity |
|--------|---------|------------|------------|
| Sunshine/Moonlight | 5-15ms | ⭐⭐⭐⭐⭐ | Medium |
| X2Go | 10-30ms | ⭐⭐⭐⭐ | Easy |
| RDP (xrdp) | 50-150ms | ⭐⭐⭐ | Easy |
| VNC | 100-200ms | ⭐⭐ | Easy |

**Recommendation:** Use Sunshine/Moonlight for best experience with remote workstations.

---

## Contributing

Issues and pull requests welcome!

## License

MIT License - Use freely for personal or commercial projects.

---

## FAQ

**Q: Can I run Windows applications?**
A: No, this is a Linux container. Use Wine if needed, or run Windows in a VM.

**Q: Will this work with my AMD/Intel GPU?**
A: Partiallly. Mesa drivers are installed, but NVIDIA GPUs have best Sunshine encoding support.

**Q: Can I use VSCode instead of JetBrains IDEs?**
A: Yes! Install from snap: `snap install code --classic` or download `.deb` from microsoft.com

**Q: How much does this cost?**
A: Zero. All components are free and open source.

**Q: Can I deploy multiple workstations?**
A: Yes! Use different container names in compose or deploy multiple K8s StatefulSets.

**Q: Does this bypass antivirus/DLP?**
A: It isolates your development environment. What you do in the container is isolated from the host.

---

## Support

- **Documentation:** See [SUNSHINE_SETUP.md](SUNSHINE_SETUP.md) for Sunshine/Moonlight setup
- **Issues:** Open GitHub issue
- **Discussions:** GitHub Discussions

---

**Built to Free Developers from IT Restrictions** 🚀
