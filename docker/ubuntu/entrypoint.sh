#!/usr/bin/env bash
set -euo pipefail

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
TIMEZONE="${TZ:-Etc/UTC}"

log "=== Starting Development Container ==="
log "Username: ${USERNAME}"
log "Enable SSH: ${ENABLE_SSH}"
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
mkdir -p /tmp/.X11-unix /run/dbus /var/run/xrdp /var/run/xrdp/sockdir
chmod 1777 /tmp/.X11-unix
chmod 0755 /run/dbus /var/run/xrdp /var/run/xrdp/sockdir

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
         "${HOME_DIR}/.cache"

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
log "rsyslog + dbus started"

# Start SSH server if enabled
if [ "${ENABLE_SSH}" = "true" ]; then
  log "Starting SSH server..."
  service ssh start >/dev/null 2>&1 || warn "SSH failed to start"
  log "SSH server started on port 22"
fi

# Run custom startup scripts if present
if [ -d /etc/container-startup.d ]; then
  for script in /etc/container-startup.d/*.sh; do
    if [ -f "$script" ] && [ -x "$script" ]; then
      log "Running startup script: $(basename "$script")"
      "$script" || warn "Startup script $(basename "$script") failed"
    fi
  done
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

sleep 1

# Verify sesman is running
if ! kill -0 ${SESMAN_PID} 2>/dev/null; then
  error "xrdp-sesman failed to start"
  tail -20 /var/log/xrdp-sesman.log 2>/dev/null || true
  exit 1
fi

log "xrdp-sesman started (PID: ${SESMAN_PID})"
log "Listening on port 3350: $(ss -tulpn 2>/dev/null | grep ':3350' || echo 'checking...')"

# Start xrdp main daemon
log "Starting xrdp daemon..."
log "=== Container Ready for RDP Connections ==="
log "Connect to: localhost:3389 (or <container-ip>:3389)"
log "Username: ${USERNAME}"
log "==="

exec /usr/sbin/xrdp --nodaemon 2>&1 | stdbuf -oL -eL tee -a /var/log/xrdp.console.log
