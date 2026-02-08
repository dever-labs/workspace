#!/usr/bin/env bash
set -euo pipefail

# Container entrypoint for Developer Workstation
# 
# Remote Access Options:
#   1. RDP (xrdp) - Built-in, works from Windows. Moderate latency (50-150ms)
#      Set ENABLE_RDP=true (default)
#   
#   2. X2Go - Better performance than RDP (10-30ms)
#      Set ENABLE_X2GO=true and ENABLE_SSH=true
#      Connect with X2Go client to SSH port, session type: XFCE
#   
#   3. Sunshine/Moonlight - Best performance (5-15ms, 60 FPS)
#      Install Sunshine on HOST/VM, not in container
#      Sunshine captures the container's display output
#      See SUNSHINE_SETUP.md for complete setup guide
#      Can disable RDP to save resources: ENABLE_RDP=false

# Logging function with timestamp
log() { echo "[$(date -Is)] $*"; }
warn() { echo "[$(date -Is)] WARNING: $*" >&2; }
error() { echo "[$(date -Is)] ERROR: $*" >&2; }

# Configuration from environment
USERNAME="${USERNAME:-dev}"
PASSWORD="${PASSWORD:-dev}"
USER_UID="${USER_UID:-}"
USER_GID="${USER_GID:-}"
ENABLE_SSH="${ENABLE_SSH:-false}"
ENABLE_RDP="${ENABLE_RDP:-true}"       # Set to false if using Sunshine/Moonlight only
ENABLE_X2GO="${ENABLE_X2GO:-false}"    # Better performance than RDP
ENABLE_SUNSHINE="${ENABLE_SUNSHINE:-false}"  # GPU-accelerated streaming (best performance)
TIMEZONE="${TZ:-Etc/UTC}"

log "=== Starting Development Container ==="
log "Username: ${USERNAME}"
log "Enable SSH: ${ENABLE_SSH}"
log "Enable RDP: ${ENABLE_RDP}"
log "Enable X2Go: ${ENABLE_X2GO}"
log "Enable Sunshine: ${ENABLE_SUNSHINE}"
log "Timezone: ${TIMEZONE}"

# Validate user exists
if ! id "${USERNAME}" >/dev/null 2>&1; then
  error "user '${USERNAME}' does not exist."
  log "Available users: $(getent passwd | cut -d: -f1 | tr '\n' ' ')"
  exit 1
fi

# Set user password (support for Docker secrets)
if [ -f /run/secrets/user_password ]; then
  PASSWORD="$(cat /run/secrets/user_password)"
  log "Password loaded from Docker secret"
elif [ "${PASSWORD}" = "dev" ]; then
  warn "Using default password 'dev' - consider setting PASSWORD env var or use Docker secrets for production"
fi

echo "${USERNAME}:${PASSWORD}" | chpasswd
log "Password configured for '${USERNAME}'"

# Adjust UID/GID if specified (useful for matching host user)
if [ -n "${USER_UID}" ] && [ -n "${USER_GID}" ]; then
  log "Adjusting UID to ${USER_UID} and GID to ${USER_GID}"
  groupmod -g "${USER_GID}" "${USERNAME}" 2>/dev/null || true
  usermod -u "${USER_UID}" -g "${USER_GID}" "${USERNAME}" 2>/dev/null || true
fi

# Runtime dirs required
log "Setting up runtime directories..."
mkdir -p /tmp/.X11-unix /run/dbus /var/run/xrdp /var/run/xrdp/sockdir /run/xrdp
chmod 1777 /tmp/.X11-unix
chmod 0755 /run/dbus /var/run/xrdp /var/run/xrdp/sockdir /run/xrdp

# Additional directories for session management
mkdir -p /var/run/xrdp/sessions
chmod 0755 /var/run/xrdp/sessions

# Setup home directory
HOME_DIR="$(getent passwd "${USERNAME}" | cut -d: -f6)"
log "Home directory: ${HOME_DIR}"

# Ensure .xsession exists
if [ ! -f "${HOME_DIR}/.xsession" ]; then
  echo "startxfce4" > "${HOME_DIR}/.xsession"
  log "Created .xsession file"
fi

# Create common development directories
mkdir -p "${HOME_DIR}/.ssh" \
         "${HOME_DIR}/.config" \
         "${HOME_DIR}/.local/bin" \
         "${HOME_DIR}/workspace" \
         "${HOME_DIR}/.cache" \
         "${HOME_DIR}/.local/share"

# Ensure .xsession-errors is writable for debugging
touch "${HOME_DIR}/.xsession-errors"

# Ensure proper Xauthority setup
touch "${HOME_DIR}/.Xauthority"

# Configure git if credentials provided
if [ -n "${GIT_USER_NAME:-}" ]; then
  sudo -u "${USERNAME}" git config --global user.name "${GIT_USER_NAME}"
  log "Git user.name set to: ${GIT_USER_NAME}"
fi
if [ -n "${GIT_USER_EMAIL:-}" ]; then
  sudo -u "${USERNAME}" git config --global user.email "${GIT_USER_EMAIL}"
  log "Git user.email set to: ${GIT_USER_EMAIL}"
fi

# Setup SSH keys if mounted
if [ -d "/run/secrets/ssh" ] && [ "$(ls -A /run/secrets/ssh 2>/dev/null)" ]; then
  log "Copying SSH keys from secrets..."
  cp -r /run/secrets/ssh/* "${HOME_DIR}/.ssh/"
  chmod 700 "${HOME_DIR}/.ssh"
  chmod 600 "${HOME_DIR}/.ssh/"* 2>/dev/null || true
  chmod 644 "${HOME_DIR}/.ssh/"*.pub 2>/dev/null || true
fi

# Set ownership
chown -R "${USERNAME}:${USERNAME}" "${HOME_DIR}" || true
log "Home directory permissions updated"

# Start system services
log "Starting system services..."
service rsyslog start >/dev/null 2>&1 || warn "rsyslog failed to start"
service dbus start >/dev/null 2>&1 || warn "dbus failed to start"
service avahi-daemon start >/dev/null 2>&1 || warn "avahi-daemon failed to start"
log "rsyslog + dbus + avahi started"

# Start SSH server if enabled (required for X2Go)
if [ "${ENABLE_SSH}" = "true" ] || [ "${ENABLE_X2GO}" = "true" ]; then
  log "Starting SSH server..."
  service ssh start >/dev/null 2>&1 || warn "SSH failed to start"
  log "SSH server started on port 22"
fi

# Start X2Go server if enabled (better performance than RDP)
if [ "${ENABLE_X2GO}" = "true" ]; then
  log "X2Go enabled - connect via X2Go client to SSH port 22"
fi

# Start Sunshine streaming server if enabled
if [ "${ENABLE_SUNSHINE}" = "true" ]; then
  log "Starting Sunshine streaming server..."
  
  # Start a virtual X server for Sunshine to capture
  # With GPU encoding (NVENC), you can use higher resolutions like 5120x1440
  # Without GPU, use 1920x1080 for smooth software encoding
  XVFB_RESOLUTION="${SUNSHINE_RESOLUTION:-5120x1440x24}"
  log "Starting Xvfb on DISPLAY=:10 with resolution ${XVFB_RESOLUTION}..."
  Xvfb :10 -screen 0 ${XVFB_RESOLUTION} +extension GLX +render -noreset &
  XVFB_PID=$!
  sleep 2
  
  # Verify Xvfb is running
  if ! kill -0 ${XVFB_PID} 2>/dev/null; then
    warn "Xvfb failed to start - Sunshine may not work"
  else
    log "Xvfb started (PID: ${XVFB_PID}) on DISPLAY=:10"
  fi
  
  # Start XFCE desktop on the virtual display
  sudo -u "${USERNAME}" DISPLAY=:10 startxfce4 &
  sleep 3
  log "XFCE desktop started on virtual display"
  
  # Load uinput kernel module (for virtual input devices)
  if [ -e /dev/uinput ]; then
    chmod 666 /dev/uinput 2>/dev/null || warn "Could not set uinput permissions"
    log "uinput device configured"
  else
    warn "uinput device not available - will use XTest fallback"
  fi
  
  # Create Sunshine config directory
  mkdir -p "${HOME_DIR}/.config/sunshine"
  
  # Create basic Sunshine configuration if it doesn't exist
  if [ ! -f "${HOME_DIR}/.config/sunshine/sunshine.conf" ]; then
    # Auto-detect encoder: nvenc (GPU) or x264 (software fallback)
    ENCODER="software"
    if [ -e /dev/dri/renderD128 ] && [ -e /dev/dri/card0 ]; then
      log "GPU devices detected, will try hardware encoding"
      ENCODER="nvenc"
    fi
    
    cat > "${HOME_DIR}/.config/sunshine/sunshine.conf" <<SUNEOF
{
  "sunshine_name": "DevWorkstation",
  "output_name": 0,
  "origin_pin_allowed": "pc",
  "origin_web_ui_allowed": "pc",
  "address_family": "ipv4",
  "ping_timeout": 60000,
  "channels": 2,
  "fps": [30, 60, 120],
  "resolutions": [
    "1920x1080",
    "2560x1440",
    "3440x1440",
    "5120x1440"
  ],
  "min_log_level": 2,
  "encoder": "${ENCODER}",
  "sw_preset": "ultrafast",
  "pkey": "/home/dev/.config/sunshine/credentials/cakey.pem",
  "cert": "/home/dev/.config/sunshine/credentials/cacert.pem"
}
SUNEOF
    chown -R "${USERNAME}:${USERNAME}" "${HOME_DIR}/.config/sunshine"
    log "Created default Sunshine configuration (encoder: ${ENCODER})"
  fi
  
  # Start Sunshine as the dev user
  log "Starting Sunshine with console logging enabled..."
  sudo -u "${USERNAME}" DISPLAY=:10 sunshine &
  SUNSHINE_PID=$!
  log "Sunshine started (PID: ${SUNSHINE_PID})"
  
  # Tail the Sunshine log file to Docker console with [sunshine] prefix
  # Wait for log file to be created
  sleep 2
  if [ -f "${HOME_DIR}/.config/sunshine/sunshine.log" ]; then
    sudo -u "${USERNAME}" tail -f "${HOME_DIR}/.config/sunshine/sunshine.log" 2>/dev/null | sed 's/^/[sunshine] /' &
    log "Sunshine log streaming to console enabled"
  fi
  
  log "Sunshine web UI: https://localhost:47990"
  log "Connect with Moonlight client to this container's IP"
  log "Sunshine logs will appear in 'docker logs devworkstation'"
fi

log "Session type: XFCE"

# Run custom startup scripts if present
if [ -d /etc/container-startup.d ]; then
  for script in /etc/container-startup.d/*.sh; do
    if [ -f "$script" ] && [ -x "$script" ]; then
      log "Running startup script: $(basename "$script")"
      "$script" || warn "Startup script $(basename "$script") failed"
    fi
  done
fi

# Skip XRDP startup if disabled (e.g., when using Sunshine/Moonlight streaming)
if [ "${ENABLE_RDP}" != "true" ]; then
  log "=== RDP disabled - container running in display-only mode ==="
  log "Use X2Go or Sunshine/Moonlight for remote access"
  log "Container will keep running for services..."
  # Keep container alive
  tail -f /dev/null
fi

# Display XRDP configuration for debugging
log "=== XRDP Configuration ==="
log "Xwrapper.config:"
cat /etc/X11/Xwrapper.config 2>/dev/null || warn "Xwrapper.config not found"

if [ -f /usr/lib/xorg/Xorg.wrap ]; then
  log "Xorg.wrap permissions: $(ls -la /usr/lib/xorg/Xorg.wrap 2>/dev/null)"
fi

log "XRDP port config:"
grep -E '^port=' /etc/xrdp/xrdp.ini 2>/dev/null || true

log "SESMAN config:"
grep -E '^(LogLevel|LogFile|EnableSyslog)=' /etc/xrdp/sesman.ini 2>/dev/null || true

# Ensure log files exist
touch /var/log/xrdp.log /var/log/xrdp-sesman.log /var/log/syslog /var/log/auth.log
log "Log files initialized"

# Tail logs to stdout for docker logs visibility
log "=== Starting Log Streaming ==="
stdbuf -oL -eL tail -n 0 -F \
  /var/log/xrdp.log \
  /var/log/xrdp-sesman.log \
  /var/log/syslog \
  /var/log/auth.log 2>/dev/null &

# Tail Xorg logs when they appear
( sleep 2; stdbuf -oL -eL tail -n 0 -F /var/log/Xorg.*.log 2>/dev/null ) &

# Clean any existing xrdp processes
log "=== Starting XRDP Services ==="
pkill -x xrdp 2>/dev/null || true
pkill -x xrdp-sesman 2>/dev/null || true
sleep 0.5

# Start xrdp-sesman
log "Starting xrdp-sesman..."
( /usr/sbin/xrdp-sesman --nodaemon 2>&1 | stdbuf -oL -eL tee -a /var/log/xrdp-sesman.console.log ) &
SESMAN_PID=$!

# Give sesman more time to fully initialize
sleep 2

# Verify sesman is running
if ! kill -0 ${SESMAN_PID} 2>/dev/null; then
  error "xrdp-sesman failed to start"
  tail -20 /var/log/xrdp-sesman.log 2>/dev/null || true
  exit 1
fi

log "xrdp-sesman started (PID: ${SESMAN_PID})"

# Wait for sesman to be ready on port 3350
MAX_WAIT=10
COUNTER=0
while [ $COUNTER -lt $MAX_WAIT ]; do
  if ss -tulpn 2>/dev/null | grep -q ':3350'; then
    log "xrdp-sesman is listening on port 3350"
    break
  fi
  COUNTER=$((COUNTER + 1))
  sleep 1
done

if [ $COUNTER -eq $MAX_WAIT ]; then
  warn "xrdp-sesman may not be listening on port 3350"
fi

log "Socket status: $(ss -tulpn 2>/dev/null | grep ':3350' || echo 'port 3350 not found')"

# Start xrdp main daemon
log "Starting xrdp daemon..."
log "=== Container Ready for RDP Connections ==="
log "Connect to: localhost:3389 (or <container-ip>:3389)"
log "Username: ${USERNAME}"
log "==="

exec /usr/sbin/xrdp --nodaemon 2>&1 | stdbuf -oL -eL tee -a /var/log/xrdp.console.log
