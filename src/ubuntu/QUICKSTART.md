# Quick Reference Guide

## Getting Started (5 Minutes)

```powershell
# 1. Setup
cd src\ubuntu
copy .env.example .env
notepad .env  # Set your password!

# 2. Start (quick start script)
.\start.ps1

# 3. Connect via RDP
# Open Remote Desktop Connection (Win+R, type: mstsc)
# Connect to: localhost:3389
# Username: dev
# Password: (what you set in .env)
```

## Common Commands

### Using PowerShell Script (Recommended for Windows)
```powershell
.\start.ps1             # Quick start (creates .env if missing)
.\manage.ps1 start      # Start container
.\manage.ps1 stop       # Stop container
.\manage.ps1 logs       # View logs
.\manage.ps1 shell      # Open shell
.\manage.ps1 status     # Check status
.\manage.ps1 restart    # Restart container
```

### Using Docker Compose Directly
```powershell
docker compose up -d --build            # Start
docker compose down                     # Stop
docker compose logs -f                  # View logs
docker compose exec workspace bash      # Shell
docker compose ps                       # Status
docker compose restart                  # Restart
```

## Frequent Tasks

### Install Software Inside Container

Via RDP (in Terminal):
```bash
sudo apt update
sudo apt install <package-name>

# Python packages
pip3 install <package>

# Node packages
npm install -g <package>
```

Via Shell from Windows:
```powershell
.\manage.ps1 shell
# Then run commands inside
```

### Access Your Windows Files

Your configured workspace appears at:
- `/workspace` - Direct mount
- `~/workspace-shared` - Symlink for convenience

Example:
```bash
cd /workspace
ls  # See your Windows files
```

### Use Docker Inside Container

The Docker CLI is available if you mounted the socket:

```bash
docker ps           # List containers
docker build .      # Build images
docker compose up   # Run compose files
```

### Configure Git

Set in `.env` before starting:
```ini
GIT_USER_NAME=Your Name
GIT_USER_EMAIL=your.email@example.com
```

Or configure manually:
```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### Add SSH Keys

Method 1 - In `compose.override.yaml`:
```yaml
volumes:
  - C:\Users\YourName\.ssh:/run/secrets/ssh:ro
```

Method 2 - Copy manually after starting:
```powershell
docker cp C:\Users\YourName\.ssh\id_rsa workspace:/home/dev/.ssh/
docker cp C:\Users\YourName\.ssh\id_rsa.pub workspace:/home/dev/.ssh/
docker exec workspace chown -R dev:dev /home/dev/.ssh
docker exec workspace chmod 600 /home/dev/.ssh/id_rsa
```

### Run Web Development Server

Inside container:
```bash
cd /workspace/my-project
npm run dev  # or python manage.py runserver, etc.
```

Access from Windows browser:
- If server binds to `0.0.0.0`: `http://localhost:<port>`
- Add port mapping in `compose.yaml` if needed:
  ```yaml
  ports:
    - "3000:3000"  # Add your port
    - "8080:8080"
  ```

### Persist Data

**Automatically persisted:**
- Everything in `/home/dev`
- Your workspace (Windows mount)

**Not persisted (ephemeral):**
- System files
- Installed apt packages (add to Dockerfile for permanence)

### Add Startup Scripts

1. Create script:
```bash
sudo nano /etc/container-startup.d/my-script.sh
```

2. Make executable:
```bash
sudo chmod +x /etc/container-startup.d/my-script.sh
```

3. Restart container:
```powershell
.\manage.ps1 restart
```

## Troubleshooting

### Can't Connect to RDP
```powershell
# Check container is running
docker ps | findstr workspace

# Check logs
.\manage.ps1 logs

# Restart
.\manage.ps1 restart
```

### Forgot Password
Edit `.env` file and restart:
```powershell
notepad .env
.\manage.ps1 restart
```

### Container Won't Start
```powershell
# View detailed logs
docker compose logs

# Try clean rebuild
.\manage.ps1 rebuild
```

### Run Out of Disk Space
```powershell
# Clean up Docker
docker system prune -a

# Remove old container data (⚠️ deletes your files!)
.\manage.ps1 clean
```

### Permission Issues with Files

Set your user ID in `.env`:
```ini
USER_UID=1000
USER_GID=1000
```

Then restart container.

### Slow Performance

1. Allocate more resources in Docker Desktop:
   - Settings → Resources → Advanced
   - Increase CPU and Memory

2. Use WSL2 backend:
   - Settings → General → Use WSL2

3. Exclude from Windows Defender:
   - Add Docker directory to exclusions

## Performance Tips

1. **Use WSL2 backend** in Docker Desktop
2. **Allocate 4+ CPU cores and 8+ GB RAM**
3. **Store workspace on SSD**
4. **Close unused RDP sessions**
5. **Disable Windows Defender scanning** for Docker directories
6. **Use local volumes** instead of bind mounts for better performance (if you don't need Windows access)

## Security Reminders

- ⚠️ Change default password in `.env`
- ⚠️ Don't commit `.env` to version control
- ⚠️ Don't expose port 3389 to internet
- ⚠️ Review sudo permissions if using in sensitive environments
- ⚠️ Keep software updated (rebuild occasionally)

## Resources

- [Dockerfile](Dockerfile) - Container image definition
- [entrypoint.sh](entrypoint.sh) - Container startup script
- [compose.yaml](compose.yaml) - Base deployment configuration
- [compose.override.yaml](compose.override.yaml) - Local overrides
- [compose.remote.yaml](compose.remote.yaml) - Remote VM overrides
- [README.md](README.md) - Full documentation
- [.env.example](.env.example) - Configuration template

## Get Help

Issues? Check:
1. Container logs: `.\manage.ps1 logs`
2. Container status: `.\manage.ps1 status`
3. Docker Desktop logs
4. System resources (CPU, RAM, Disk)

Still stuck? Try:
```powershell
.\manage.ps1 rebuild  # Nuclear option: rebuild from scratch
```
