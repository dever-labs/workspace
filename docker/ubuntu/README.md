# Linux Development Desktop for Windows

A Docker-based Linux development environment with full graphical desktop (XFCE) accessible via RDP. Designed to provide a complete development environment for Windows users working in restricted or limited Windows environments.

## Features

### Desktop Environment
- **XFCE4 Desktop** - Lightweight, responsive desktop environment
- **xrdp** - Remote Desktop Protocol server for seamless Windows integration
- **Full graphical applications** support

### Development Tools
- **Version Control**: Git, Git LFS
- **Build Tools**: GCC, CMake, Make, Autotools
- **Programming Languages**:
  - Python 3 with pip, pipenv, poetry
  - Node.js with npm, yarn, pnpm
  - Go, Rust, Java (easily added)
- **Editors**: Vim, Neovim, Nano
- **Terminal Tools**: tmux, screen, zsh, fish
- **Container Tools**: Docker CLI, Docker Compose
- **Database Clients**: PostgreSQL, MySQL, SQLite
- **Modern CLI Tools**: ripgrep, fd, bat, eza, jq, httpie

### Developer Experience
- **Drive redirection** - Access Windows files from within the container
- **Clipboard sharing** - Copy/paste between Windows and Linux
- **Docker-in-Docker** support via socket mounting
- **Persistent home directory** - Your settings and files are saved
- **SSH access** (optional) - Alternative to RDP
- **Custom startup scripts** - Automate your environment setup

## Quick Start

### Prerequisites
- Windows 10/11 with Docker Desktop installed
- At least 8GB RAM (16GB recommended)
- Remote Desktop Connection (built into Windows)

### Basic Setup

1. **Clone or download these files** to a directory on your Windows machine

2. **Create environment configuration**:
   ```powershell
   cd docker\ubuntu
   copy .env.example .env
   ```

3. **Edit `.env` file** with your preferences:
   - Set a secure password
   - Configure your workspace path
   - Set your Git username/email

4. **Build and start the container**:
   ```powershell
   docker-compose up -d
   ```

5. **Connect via Remote Desktop**:
   - Open **Remote Desktop Connection** (mstsc.exe)
   - Connect to: `localhost:3389`
   - Username: `dev`
   - Password: (what you set in `.env` or default `dev`)

### Advanced Setup

#### With Docker-in-Docker Support

To run Docker commands inside the container:

```yaml
# In docker-compose.yml, uncomment:
volumes:
  - /var/run/docker.sock:/var/run/docker.sock
```

Then inside the container, you can run `docker ps`, `docker build`, etc.

#### With SSH Access

```yaml
# In docker-compose.yml, set:
environment:
  - ENABLE_SSH=true
```

Then connect via SSH: `ssh -p 2222 dev@localhost`

#### Mount Your SSH Keys

```yaml
# In docker-compose.yml, uncomment:
volumes:
  - ${HOME}/.ssh:/run/secrets/ssh:ro
```

This gives the container access to your SSH keys for Git operations.

#### Match Host User ID (for file permissions)

```yaml
# In docker-compose.yml, uncomment:
environment:
  - USER_UID=1000  # Your Windows user ID
  - USER_GID=1000  # Your Windows group ID
```

## Usage

### Accessing Your Windows Files

Your Windows workspace (configured in `.env`) is available at:
- `/workspace` in the container
- `~/workspace-shared` (symlink)

### Installing Additional Software

The container runs as Ubuntu 24.04. Install packages normally:

```bash
sudo apt update
sudo apt install <package-name>
```

Or using language-specific package managers:
```bash
pip install <python-package>
npm install -g <npm-package>
```

### Custom Startup Scripts

Place executable shell scripts in `/etc/container-startup.d/`:

```bash
sudo vi /etc/container-startup.d/my-startup.sh
sudo chmod +x /etc/container-startup.d/my-startup.sh
```

They'll run automatically on container start.

### Persistence

The following are persisted across container restarts:
- `/home/dev` - Your entire home directory
- `/workspace` - Your Windows projects (if mounted)

To reset your environment, delete the Docker volume:
```powershell
docker-compose down -v
docker-compose up -d
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `USERNAME` | `dev` | Linux username |
| `PASSWORD` | `dev` | User password (⚠️ Change this!) |
| `USER_UID` | - | Match Windows user ID |
| `USER_GID` | - | Match Windows group ID |
| `TZ` | `Etc/UTC` | Timezone |
| `ENABLE_SSH` | `false` | Enable SSH server |
| `GIT_USER_NAME` | - | Git author name |
| `GIT_USER_EMAIL` | - | Git author email |

### Ports

| Port | Service | Description |
|------|---------|-------------|
| 3389 | RDP | Remote Desktop Protocol |
| 22 | SSH | Secure Shell (if enabled) |

## Troubleshooting

### Can't Connect via RDP

1. Check container is running: `docker ps`
2. Check logs: `docker-compose logs -f`
3. Verify port 3389 isn't in use: `netstat -an | findstr 3389`
4. Try restarting: `docker-compose restart`

### Black Screen After Login

This usually means XFCE failed to start. Check logs:
```powershell
docker-compose exec dev-desktop cat /var/log/xrdp-sesman.log
```

### Permission Denied on Files

Set `USER_UID` and `USER_GID` in `.env` to match your Windows user:
```powershell
# Get your user ID in WSL or container
id -u
id -g
```

### Docker Commands Don't Work Inside Container

Ensure Docker socket is mounted and user `dev` is in the `docker` group:
```bash
docker ps  # Should work without sudo
```

### High CPU Usage

Reduce CPU limits in `docker-compose.yml`:
```yaml
deploy:
  resources:
    limits:
      cpus: '2'  # Reduce from 4
```

## Customization

### Add More Development Tools

Edit the `Dockerfile` and add packages:

```dockerfile
RUN apt-get update && apt-get install -y \
    golang-go \
    rustc \
    openjdk-17-jdk \
    && apt-get clean
```

Rebuild: `docker-compose build`

### Change Desktop Environment

Replace XFCE with another desktop:

```dockerfile
# Instead of xfce4 packages, install:
RUN apt-get install -y \
    kde-plasma-desktop  # Or gnome-session, lxde, etc.
```

Update `startwm.sh` accordingly.

### Install VS Code Server (Optional)

For web-based VS Code in the container:

```dockerfile
RUN curl -fsSL https://code-server.dev/install.sh | sh
```

## Performance Tips

1. **Allocate sufficient resources** in Docker Desktop settings (Resources → Advanced)
2. **Use SSD storage** for Docker volumes
3. **Disable Windows Defender** real-time scanning for Docker directories
4. **Use WSL2 backend** in Docker Desktop (Settings → General)
5. **Close unused RDP sessions** to free resources

## Security Considerations

⚠️ **Important Security Notes**:

1. **Change default password** - Don't use `dev:dev` in production
2. **Use Docker secrets** for sensitive data:
   ```bash
   echo "mypassword" | docker secret create user_password -
   ```
3. **Don't expose to internet** - This is for local development only
4. **Review sudo permissions** - Currently passwordless; adjust if needed
5. **Limit Docker socket access** - Only mount if you need Docker-in-Docker

## Common Use Cases

### Web Development
- Node.js, Python, PHP, Ruby projects
- Run dev servers accessible from Windows browser
- Database containers via Docker

### DevOps & Infrastructure
- Terraform, Ansible, Kubernetes tools
- Cloud CLI tools (AWS, Azure, GCP)
- Container orchestration

### Data Science
- Python with Jupyter notebooks
- R, Julia development
- Database analysis tools

### Systems Programming
- C/C++ with full build toolchain
- Rust development
- Linux kernel development

## Support

For issues or questions:
1. Check container logs: `docker-compose logs -f`
2. Verify Docker Desktop is running
3. Check system resources aren't exhausted
4. Try rebuilding: `docker-compose build --no-cache`

## License

This configuration is provided as-is for educational and development purposes.

## Credits

Built with:
- Ubuntu 24.04 LTS
- XFCE Desktop Environment  
- xrdp by Neutrinolabs
- Docker
