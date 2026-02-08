# Workspace

A collection of containerized development environments designed to provide complete, isolated, and portable development workstations. Break free from IT restrictions and work anywhere with consistent tooling.

## 🚀 Quick Start

### Ubuntu Developer Workstation (Recommended)

Full-featured Linux desktop environment with GPU-accelerated remote access:

```powershell
cd src/ubuntu
.\start.ps1
```

Then connect via:
- **RDP:** `localhost:3389` (user: `dev`, password: from `.env`)
- **Sunshine/Moonlight:** Ultra-low latency streaming (5-15ms) with NVENC GPU encoding
- **SSH/X2Go:** Terminal or remote desktop via port 2222

**📖 [Full Documentation →](src/ubuntu/README.md)**

---

## 📦 What's Inside

### [src/ubuntu](src/ubuntu/) - Developer Workstation Container

A complete Ubuntu 24.04 XFCE desktop environment optimized for development work:

#### Features
- ✅ **Full Linux Desktop (XFCE)** - Complete GUI environment
- ✅ **GPU Acceleration** - NVIDIA NVENC hardware video encoding (RTX GPUs)
- ✅ **Multiple Access Methods** - RDP, SSH, X2Go, Sunshine/Moonlight streaming
- ✅ **JetBrains IDEs Ready** - Optimized for Rider, WebStorm, IntelliJ IDEA, etc.
- ✅ **Docker-in-Docker** - Run containers within the workspace
- ✅ **Persistent Storage** - Home directory and caches preserved across restarts
- ✅ **Flexible Deployment** - Local Docker Desktop, Remote VM, or Kubernetes

#### Deployment Options

**Local Development (Docker Desktop):**
```bash
cd src/ubuntu
docker compose up -d
```

**Remote VM (with WireGuard VPN):**
```bash
cd src/ubuntu
./deploy-remote.sh user@remote-vm
```

**Kubernetes:**
```bash
cd src/ubuntu
kubectl apply -f k8s/devworkstation.yaml
```

#### Technologies
- **Base:** Ubuntu 24.04 LTS
- **Desktop:** XFCE4 (lightweight & fast)
- **Streaming:** Sunshine v0.23.1 with NVENC GPU encoding
- **Remote Access:** xrdp, OpenSSH, X2Go
- **Tools:** Git, Docker CLI, Python 3, Node.js, build tools
- **IDEs:** Ready for JetBrains Toolbox, VS Code, etc.

#### Performance Comparison

| Access Method | Latency | Smoothness | Use Case |
|--------------|---------|------------|----------|
| Sunshine/Moonlight | 5-15ms | ⭐⭐⭐⭐⭐ 60-120 FPS | Best for remote work |
| X2Go | 10-30ms | ⭐⭐⭐⭐ | Excellent alternative |
| RDP (xrdp) | 50-150ms | ⭐⭐⭐ | Local/testing |

**Note:** Sunshine on Windows Docker Desktop has a networking limitation causing 10-second timeouts. Works perfectly on Linux Docker Engine and Kubernetes.

---

## 🎯 Use Cases

### Bypass IT Restrictions
Run your entire development stack (IDEs, Docker, databases, tools) in an isolated container that IT can't restrict or monitor.

### Consistent Development Environment
Same tools, same versions, same setup across your laptop, workstation, and remote VMs.

### Remote Development
Access your full desktop development environment from anywhere via ultra-low latency streaming or RDP.

### Team Standardization
Share the exact same development environment across your entire team via container images.

### Cloud Development
Deploy development workstations to cloud VMs or Kubernetes clusters for powerful remote coding.

---

## 📋 Requirements

- **Local:**
  - Docker Desktop (Windows/Mac) or Docker Engine (Linux)
  - 16GB+ RAM recommended
  - NVIDIA GPU (optional, for hardware encoding)
  
- **Remote:**
  - Linux VM with Docker Engine
  - NVIDIA GPU (optional, for Sunshine NVENC encoding)
  - WireGuard VPN (recommended for secure access)

- **Kubernetes:**
  - K8s cluster with NVIDIA GPU Operator (for GPU support)
  - Persistent Volume support
  - NodePort or LoadBalancer service

---

## 🔧 Configuration

Each environment has its own `.env` file for configuration:

```bash
# Core settings
DEV_PASSWORD=your-secure-password
TIMEZONE=America/New_York
GIT_USER_NAME=Your Name
GIT_USER_EMAIL=your.email@example.com

# Remote access options (choose based on your needs)
ENABLE_RDP=true        # Windows native client (50-150ms)
ENABLE_X2GO=true       # Better performance (10-30ms)
ENABLE_SSH=true        # Terminal access
ENABLE_SUNSHINE=true   # Best performance (5-15ms, 60 FPS)

# Resource limits
CPU_LIMIT=8
MEMORY_LIMIT=16G

# GPU support
NVIDIA_VISIBLE_DEVICES=all
NVIDIA_DRIVER_CAPABILITIES=all
```

---

## 📚 Documentation

- **[Ubuntu Dev Workstation](src/ubuntu/README.md)** - Complete feature guide
- **[Sunshine/Moonlight Setup](src/ubuntu/SUNSHINE_SETUP.md)** - GPU streaming setup
- **[Migration Guide](src/ubuntu/MIGRATION.md)** - Upgrading from old structure

---

## 🔐 Security Best Practices

1. **Change default passwords** - Never use `dev:dev` in production
2. **Use WireGuard VPN** - For remote access to development workstations
3. **Never expose RDP/SSH** - Don't open ports directly to internet
4. **Use SSH keys** - Disable password authentication for SSH
5. **Bind services to VPN interface** - Limit access to trusted networks only
6. **Regular updates** - `docker compose pull && docker compose up -d`

---

## 🛠️ Common Commands

### Local Development
```bash
cd src/ubuntu

# Start
docker compose up -d

# View logs
docker compose logs -f

# Shell access
docker compose exec devworkstation bash

# Restart
docker compose restart

# Stop
docker compose down

# Update
docker compose pull && docker compose up -d
```

### Remote Deployment
```bash
cd src/ubuntu

# Deploy
./deploy-remote.sh user@remote-vm

# Manage remotely
docker --context remote compose logs -f
docker --context remote compose restart

# Switch back to local
docker context use default
```

### Kubernetes
```bash
cd src/ubuntu

# Deploy
kubectl apply -f k8s/devworkstation.yaml

# Check status
kubectl get pods -n devworkstations
kubectl logs -n devworkstations devworkstation-0 -f

# Access
kubectl get svc -n devworkstations
# Connect to NodePort or LoadBalancer IP
```

---

## 🚀 What Makes This Special?

### GPU-Accelerated Streaming ✨
Unlike traditional remote desktop solutions, this setup uses **Sunshine** with **NVENC hardware encoding**:
- 5-15ms latency (game-streaming technology)
- 60-120 FPS smooth desktop
- Works at ultra-wide resolutions (5120x1440)
- Minimal CPU usage (encoding done on GPU)
- Supports RTX 3070 Ti and newer NVIDIA GPUs

### Modular Compose Architecture
Three-layer compose file structure for maximum flexibility:
- `compose.yaml` - Base configuration (works everywhere)
- `compose.override.yaml` - Local development overrides
- `compose.remote.yaml` - Remote VM specific settings

### Production-Ready Design
- StatefulSets for Kubernetes
- Persistent volumes for data
- Healthchecks and readiness probes
- Resource limits and reservations
- Security contexts and capabilities

---

## 🐛 Troubleshooting

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

### Sunshine/Moonlight disconnects after 10 seconds
This is a **known limitation** with Docker Desktop on Windows bridge networking. Sunshine's ping verification cannot reach back through the Docker bridge.

**Solutions:**
- Use **X2Go** instead (reliable on all platforms)
- Deploy to **Linux VM** or **Kubernetes** (works perfectly)
- Use **RDP** for local testing

See [SUNSHINE_SETUP.md](src/ubuntu/SUNSHINE_SETUP.md) for details.

---

## 📊 Performance Benchmarks

**Software Encoding (x264):**
- 1920x1080 @ 60 FPS: ✅ Works (40-60% CPU)
- 2560x1440 @ 30 FPS: ✅ Acceptable
- 5120x1440: ❌ Too slow, frame drops

**Hardware Encoding (NVENC - RTX 3070 Ti):**
- 1920x1080 @ 120 FPS: ✅ Smooth (5-10% CPU)
- 2560x1440 @ 120 FPS: ✅ Excellent
- 3440x1440 @ 60 FPS: ✅ Great
- 5120x1440 @ 60-120 FPS: ✅ Works! (100+ Mbps bitrate)

---

## 🤝 Contributing

Issues and pull requests welcome! This is a living project that evolves with development needs.

---

## 📄 License

MIT License - Use freely for personal or commercial projects.

---

## 🙏 Acknowledgments

Built with:
- Ubuntu 24.04 LTS
- XFCE Desktop Environment
- Sunshine/Moonlight streaming technology
- xrdp by Neutrinolabs
- Docker & Docker Compose
- Kubernetes

---

## 🎓 Learn More

- **Sunshine Documentation:** https://docs.lizardbyte.dev/projects/sunshine/
- **Moonlight Client:** https://moonlight-stream.org/
- **X2Go:** https://wiki.x2go.org/
- **Docker GPU Support:** https://docs.docker.com/config/containers/resource_constraints/#gpu

---

**Built to Free Developers from IT Restrictions** 🚀

Need help? Check the [Ubuntu Dev Workstation docs](src/ubuntu/README.md) or open an issue!
