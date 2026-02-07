#!/usr/bin/env bash
set -euo pipefail
log() { echo "[$(date -Is)] $*"; }

USERNAME="${USERNAME:-dev}"
PASSWORD="${PASSWORD:-dev}"

if ! id "${USERNAME}" >/dev/null 2>&1; then
  log "ERROR: user '${USERNAME}' does not exist."
  log "Users: $(getent passwd | cut -d: -f1 | tr '\n' ' ')"
  exit 1
fi

echo "${USERNAME}:${PASSWORD}" | chpasswd
log "Password set for '${USERNAME}'"

# runtime dirs needed for Xorg + xrdp in containers
mkdir -p /tmp/.X11-unix /run/dbus /var/run/xrdp /var/run/xrdp/sockdir
chmod 1777 /tmp/.X11-unix
chmod 0755 /run/dbus /var/run/xrdp /var/run/xrdp/sockdir

HOME_DIR="$(getent passwd "${USERNAME}" | cut -d: -f6)"
if [ ! -f "${HOME_DIR}/.xsession" ]; then
  echo "startxfce4" > "${HOME_DIR}/.xsession"
fi
chown -R "${USERNAME}:${USERNAME}" "${HOME_DIR}" || true

# Start syslog + dbus so we can actually see errors
rsyslog_started=false
if command -v rsyslogd >/dev/null 2>&1; then
  if rsyslogd -n &>/dev/null & then
    rsyslog_started=true
  else
    log "WARNING: failed to start rsyslogd"
  fi
else
  log "WARNING: rsyslogd binary not found; syslog will be unavailable"
fi

dbus_started=false
if command -v dbus-daemon >/dev/null 2>&1; then
  if dbus-daemon --system --nofork --nopidfile &>/dev/null & then
    dbus_started=true
  else
    log "WARNING: failed to start dbus-daemon"
  fi
else
  log "WARNING: dbus-daemon binary not found; D-Bus will be unavailable"
fi

if [ "${rsyslog_started}" = true ] && [ "${dbus_started}" = true ]; then
  log "rsyslog + dbus started"
elif [ "${rsyslog_started}" = true ]; then
  log "rsyslog started; dbus not running (see warnings above)"
elif [ "${dbus_started}" = true ]; then
  log "dbus started; rsyslog not running (see warnings above)"
else
  log "WARNING: neither rsyslog nor dbus could be started; logs may be incomplete"
fi
log "XRDP key config:"
grep -E '^(port|LogLevel)=' /etc/xrdp/xrdp.ini || true

log "SESMAN key config:"
grep -E '^(LogLevel|LogFile|EnableSyslog)=' /etc/xrdp/sesman.ini || true

# ensure log files exist
touch /var/log/xrdp.log /var/log/xrdp-sesman.log /var/log/syslog /var/log/auth.log

log "Tailing logs to stdout (xrdp, sesman, syslog, auth)"
stdbuf -oL -eL tail -n 0 -F \
  /var/log/xrdp.log \
  /var/log/xrdp-sesman.log \
  /var/log/syslog \
  /var/log/auth.log &

# Tail Xorg session logs (these appear only if Xorg actually starts)
log "Tailing Xorg session logs to stdout (when they appear)"
( sh -lc '
  # Wait until at least one Xorg session log exists, then start tailing
  while :; do
    set -- /home/*/.xorgxrdp.*.log
    if [ "$1" != "/home/*/.xorgxrdp.*.log" ]; then
      break
    fi
    sleep 1
  done
log "Waiting for xrdp-sesman to listen on port 3350 (timeout 10s)..."
timeout_deadline=$((SECONDS + 10))
while [ "${SECONDS}" -lt "${timeout_deadline}" ]; do
  if ss -tulpn 2>/dev/null | egrep -q ':3350\b'; then
    log "xrdp-sesman is listening on port 3350"
    break
  fi
  sleep 0.2
done
if ! ss -tulpn 2>/dev/null | egrep -q ':3350\b'; then
  log "WARNING: xrdp-sesman did not start listening on port 3350 within 10 seconds"
fi
' ) &

# clean restart
pkill -x xrdp 2>/dev/null || true
pkill -x xrdp-sesman 2>/dev/null || true

log "Starting xrdp-sesman"
/usr/sbin/xrdp-sesman --nodaemon &

sleep 0.4
log "Listen sockets (xrdp should be 3389, sesman should be 3350):"
ss -tulpn | egrep ':(3389|3350)\b' || true

log "Starting xrdp"
exec /usr/sbin/xrdp --nodaemon
