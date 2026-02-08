# Development Container Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      Windows Host                           │
│                                                             │
│  ┌────────────────┐          ┌──────────────────┐           │
│  │  RDP Client    │◄─────────┤  Docker Desktop  │           │
│  │  (mstsc.exe)   │  :3389   │                  │           │
│  └────────────────┘          │  ┌────────────────────────┐  │
│                              │  │  Ubuntu Container      │  │
│  ┌────────────────┐          │  │                        │  │
│  │  Windows Files │◄─────────┼──┤  /workspace (mount)    │  │
│  │  (Projects)    │  Volume  │  │                        │  │
│  └────────────────┘          │  │  ┌──────────────────┐  │  │
│                              │  │  │  XFCE Desktop    │  │  │
│  ┌────────────────┐          │  │  │                  │  │  │
│  │  Docker Socket │◄─────────┼──┤  │  • Terminal      │  │  │
│  │                │  Mount   │  │  │  • Editors       │  │  │
│  └────────────────┘          │  │  │  • Browsers      │  │  │
│                              │  │  │  • Dev Tools     │  │  │
│                              │  │  └──────────────────┘  │  │
│                              │  │                        │  │
│                              │  │  Services:             │  │
│                              │  │  • xrdp (RDP)          │  │
│                              │  │  • SSH (optional)      │  │
│                              │  │  • Docker CLI          │  │
│                              │  └────────────────────────┘  │
│                              └──────────────────┘           |
└─────────────────────────────────────────────────────────────┘
```

## Component Stack

### Layer 1: Base System
- **Ubuntu 24.04 LTS** - Long-term support OS
- **systemd services** - rsyslog, dbus
- **Tini** - Proper init system for containers

### Layer 2: Desktop Environment
- **XFCE4** - Lightweight desktop
- **Xorg** - Display server
- **xrdp + xorgxrdp** - RDP server

### Layer 3: Development Tools

#### Languages & Runtimes
- Python 3 + pip, pipenv, poetry
- Node.js + npm, yarn, pnpm
- GCC/G++ toolchain
- Build tools (make, cmake, autotools)

#### Version Control
- Git + Git LFS
- Pre-configured for container use

#### Editors & Terminals
- Vim, Neovim, Nano
- tmux, screen
- zsh, fish shells

#### Container Tools
- Docker CLI
- Docker Compose
- Container-in-container support

#### Utilities
- Modern CLI: ripgrep, fd, bat, eza
- Network: curl, wget, httpie
- Database clients: PostgreSQL, MySQL, SQLite
- JSON/YAML: jq, yq

## Data Flow

### File Access
```
Windows Files ──► Volume Mount ──► /workspace ──► Container Access
                                   ~/workspace-shared (symlink)
```

### Network Access
```
Windows RDP Client ──► Port 3389 ──► xrdp ──► Xorg ──► XFCE Desktop
Windows Browser    ──► Port XXXX ──► Container Web Server
```

### Docker-in-Docker
```
Windows Docker Desktop ──► Socket Mount ──► Container Docker CLI ──► Manage Containers
```

## File Structure

```
src/ubuntu/
├── Dockerfile              # Container image definition
├── entrypoint.sh          # Startup script
├── compose.yaml           # Base deployment configuration
├── compose.override.yaml  # Local development overrides
├── compose.remote.yaml    # Remote VM overrides
├── .env.example           # Configuration template
├── start.ps1              # Windows quick start script
├── start.sh               # Linux/macOS quick start script
├── manage.ps1             # Windows management script
├── Makefile               # Make commands (optional)
├── README.md              # Full documentation
├── QUICKSTART.md          # Quick reference
├── example-startup.sh     # Custom startup script template
├── .dockerignore          # Build context filter
└── .gitignore            # Git exclusions

Container Runtime:
/home/dev/                 # User home (persisted)
├── .ssh/                  # SSH keys
├── .config/               # Application configs
├── .local/bin/            # User binaries
├── workspace/             # Project directory
└── .xsession             # Desktop session config

/workspace/                # Workspace volume
/etc/container-startup.d/  # Custom startup scripts
/var/log/                  # System logs (xrdp, syslog, auth)
```

## Network Ports

| Port | Service | Purpose | Exposure |
|------|---------|---------|----------|
| 3389 | xrdp | RDP remote desktop | Windows host |
| 22 | SSH | Alternative access | Optional |
| 3350 | xrdp-sesman | Session manager | Internal |
| * | User apps | Dev servers | As configured |

## Volume Mounts

| Windows Path | Container Path | Purpose |
|--------------|----------------|---------|
| (Docker Volume) | /home/dev | User home persistence |
| ./workspace or C:\Projects | /workspace | Shared project files |
| /var/run/docker.sock | /var/run/docker.sock | Docker-in-Docker |
| ~/.ssh | /run/secrets/ssh | SSH keys (optional) |

## Environment Variables

### Required
- `USERNAME` - Linux user (default: dev)
- `PASSWORD` - User password (⚠️ change from default!)

### Optional
- `USER_UID` - Match Windows user ID
- `USER_GID` - Match Windows group ID
- `TZ` - Timezone setting
- `ENABLE_SSH` - Enable SSH server
- `GIT_USER_NAME` - Git configuration
- `GIT_USER_EMAIL` - Git configuration

## Security Model

```
┌──────────────────────────────────────────┐
│  Windows Host                             │
│  ├── Isolated Docker Network             │
│  │   └── Container with:                 │
│  │       • User-level access (dev user)  │
│  │       • Sudo privileges (configurable)│
│  │       • Network isolation             │
│  │       • Resource limits               │
│  └── Port exposure (localhost only)      │
└──────────────────────────────────────────┘

Recommendations:
✓ Change default password
✓ Use Docker secrets for sensitive data
✓ Don't expose 3389 to internet
✓ Review sudo permissions
✓ Keep software updated
```

## Resource Allocation

### Recommended Minimums
- **CPU**: 2 cores
- **RAM**: 4GB
- **Disk**: 20GB
- **Shared Memory**: 2GB

### Recommended for Comfortable Development
- **CPU**: 4+ cores
- **RAM**: 8GB+
- **Disk**: 50GB+
- **Shared Memory**: 2GB

### Configuration Location
- Docker Desktop → Settings → Resources → Advanced

## Workflow Examples

### Web Development
```
1. Start container: manage.ps1 start
2. Connect via RDP
3. Open terminal in container
4. cd /workspace/my-project
5. npm install && npm run dev
6. Access from Windows: http://localhost:3000
```

### Python Development
```
1. Connect to container
2. Create venv: python3 -m venv /workspace/myproject/venv
3. Activate: source /workspace/myproject/venv/bin/activate
4. Install deps: pip install -r requirements.txt
5. Code in mounted directory (visible in Windows)
```

### Docker-based Development
```
1. Ensure docker.sock is mounted
2. In container: docker compose up -d
3. Manage containers from within dev environment
4. All containers run in host Docker
```

## Maintenance

### Regular
- Check logs: `manage.ps1 logs`
- Monitor resources in Docker Desktop
- Update packages: `sudo apt update && sudo apt upgrade`

### Periodic
- Rebuild image: `manage.ps1 rebuild`
- Clean Docker: `docker system prune`
- Review security settings

### Backup
What to backup:
- `.env` file (configuration)
- Custom startup scripts
- Dockerfile modifications (if any)

What's automatically persisted:
- User home directory (Docker volume)
- Workspace files (Windows mount)
