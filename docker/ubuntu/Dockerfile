FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# Install base system, desktop environment, and xrdp
RUN apt-get update && apt-get install -y --no-install-recommends \
    locales tzdata ca-certificates sudo \
    # Desktop environment
    xfce4 xfce4-terminal xfce4-session xfce4-goodies \
    thunar-archive-plugin file-roller \
    dbus-x11 x11-xserver-utils \
    xserver-xorg-core xserver-xorg-input-all \
    xserver-xorg-legacy \
    xfonts-base fonts-dejavu-core fonts-liberation fonts-noto \
    xauth \
    # RDP server
    xrdp xorgxrdp \
    tigervnc-standalone-server tigervnc-common \
    rsyslog \
    # System utilities
    procps iproute2 net-tools \
    software-properties-common apt-transport-https \
    dos2unix \
    tini \
 && locale-gen en_US.UTF-8 \
 && update-ca-certificates \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Install development tools and languages
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Version control
    git git-lfs \
    # Build tools
    build-essential cmake automake autoconf libtool pkg-config \
    # Editors and terminal tools
    nano vim neovim tmux screen \
    zsh fish \
    # System tools
    curl wget httpie jq yq unzip zip p7zip-full \
    tree ripgrep fd-find bat eza \
    htop btop ncdu \
    openssh-client openssh-server \
    # Network tools
    netcat-openbsd telnet traceroute dnsutils iputils-ping \
    # Python
    python3 python3-pip python3-venv python3-dev \
    # Node.js (from Ubuntu repo for now)
    nodejs npm \
    # Database clients
    postgresql-client mysql-client sqlite3 \
    # Container tools
    ca-certificates gnupg lsb-release \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Install Docker CLI (for Docker-in-Docker or socket mounting)
RUN install -m 0755 -d /etc/apt/keyrings \
 && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
 && chmod a+r /etc/apt/keyrings/docker.gpg \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
   > /etc/apt/sources.list.d/docker.list \
 && apt-get update \
 && apt-get install -y docker-ce-cli docker-compose-plugin \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Install additional Python tools via apt where possible
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-pytest python3-pytest-cov \
    python3-flake8 python3-autopep8 \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Install Python tools that need pip (avoiding system package conflicts)
# Using --ignore-installed to avoid conflicts with system packages
RUN pip3 install --no-cache-dir --break-system-packages --ignore-installed urllib3 \
    pipenv poetry \
    black pylint mypy \
    ipython

# Install Node.js package managers (using system npm version)
# Note: Ubuntu 24.04's Node.js is older; users can upgrade Node.js later if needed
RUN npm install -g yarn pnpm \
 && npm cache clean --force

# Create dev user with better default setup
RUN useradd -m -s /bin/bash dev \
 && echo "dev:dev" | chpasswd \
 && adduser dev sudo \
 && adduser dev docker 2>/dev/null || true \
 && adduser xrdp ssl-cert \
 && echo "startxfce4" > /home/dev/.xsession \
 && chown dev:dev /home/dev/.xsession \
 # Passwordless sudo for convenience (change if security is a concern)
 && echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/dev \
 && chmod 0440 /etc/sudoers.d/dev

# Configure git defaults
RUN git config --system init.defaultBranch main \
 && git config --system core.editor vim \
 && git config --system pull.rebase false

# Create workspace directory
RUN mkdir -p /workspace /home/dev/workspace \
 && chown dev:dev /home/dev/workspace \
 && ln -sf /workspace /home/dev/workspace-shared

# ---- CRITICAL: allow Xorg to run under xrdp-sesman in a container ----
RUN set -eux; \
    mkdir -p /etc/X11; \
    printf "allowed_users=anybody\nneeds_root_rights=yes\n" > /etc/X11/Xwrapper.config; \
    # Make sure the wrapper exists and can run as root
    if [ -f /usr/lib/xorg/Xorg.wrap ]; then \
      chown root:root /usr/lib/xorg/Xorg.wrap; \
      chmod u+s /usr/lib/xorg/Xorg.wrap; \
    fi

# XRDP + SESMAN config:
# - keep the working IPv4 workaround: port=tcp://:3389
# - INFO level logging (DEBUG if needed for troubleshooting)
# - Enable drive redirection for file sharing
# - Configure Xvnc as default (more stable than Xorg in containers)
RUN set -eux; \
    sed -ri 's|^port=.*|port=tcp://:3389|' /etc/xrdp/xrdp.ini; \
    sed -ri '/^address=/d' /etc/xrdp/xrdp.ini; \
    sed -ri 's/^LogLevel=.*/LogLevel=INFO/' /etc/xrdp/xrdp.ini || true; \
    # Reorder sessions: Remove existing Xorg and Xvnc sections, then add Xvnc first (as default)
    sed -i '/^\[Xorg\]/,$ d' /etc/xrdp/xrdp.ini; \
    # Add Xvnc as first/default session, then Xorg as fallback
    printf '\n[Xvnc]\nname=Xvnc\nlib=libvnc.so\nusername=ask\npassword=ask\nip=127.0.0.1\nport=-1\n\n' >> /etc/xrdp/xrdp.ini; \
    printf '[Xorg]\nname=Xorg\nlib=libxup.so\nusername=ask\npassword=ask\nport=-1\nip=127.0.0.1\n' >> /etc/xrdp/xrdp.ini; \
    # Enable drive redirection for mounting Windows drives
    sed -ri 's/^; FuseMountName=.*/FuseMountName=thinclient_drives/' /etc/xrdp/sesman.ini || \
      printf '\nFuseMountName=thinclient_drives\n' >> /etc/xrdp/sesman.ini; \
    \
    # sesman logging configuration
    if grep -q '^LogLevel=' /etc/xrdp/sesman.ini; then \
      sed -ri 's/^LogLevel=.*/LogLevel=INFO/' /etc/xrdp/sesman.ini; \
    else \
      printf '\nLogLevel=INFO\n' >> /etc/xrdp/sesman.ini; \
    fi; \
    if grep -q '^LogFile=' /etc/xrdp/sesman.ini; then \
      sed -ri 's|^LogFile=.*|LogFile=/var/log/xrdp-sesman.log|' /etc/xrdp/sesman.ini; \
    else \
      printf 'LogFile=/var/log/xrdp-sesman.log\n' >> /etc/xrdp/sesman.ini; \
    fi; \
    if grep -q '^EnableSyslog=' /etc/xrdp/sesman.ini; then \
      sed -ri 's/^EnableSyslog=.*/EnableSyslog=true/' /etc/xrdp/sesman.ini; \
    else \
      printf 'EnableSyslog=true\n' >> /etc/xrdp/sesman.ini; \
    fi

# Configure SSH server for SSH access (alternative to RDP)
RUN mkdir -p /run/sshd \
 && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config \
 && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# startwm: predictable XFCE startup with better error handling
RUN cat > /etc/xrdp/startwm.sh <<'EOF'
#!/bin/sh
# Session startup script for xrdp

# Set up environment
export XDG_SESSION_DESKTOP=xfce
export XDG_CURRENT_DESKTOP=XFCE
export DESKTOP_SESSION=xfce
export XDG_DATA_DIRS=/usr/share/xfce4:/usr/local/share:/usr/share:/var/lib/snapd/desktop
export XDG_CONFIG_DIRS=/etc/xdg

# Logging
exec > /tmp/startwm-$USER.log 2>&1
echo "Starting XFCE session for $USER at $(date)"
echo "HOME=$HOME"
echo "DISPLAY=$DISPLAY"

# Start dbus if not running
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
  if command -v dbus-launch >/dev/null 2>&1; then
    echo "Starting dbus-launch"
    eval "$(dbus-launch --sh-syntax --exit-with-session)"
    export DBUS_SESSION_BUS_ADDRESS
  fi
fi

# Create required directories
mkdir -p "$HOME/.config" "$HOME/.cache" "$HOME/.local/share"

# Start XFCE
echo "Launching startxfce4"
exec startxfce4
EOF

RUN chmod +x /etc/xrdp/startwm.sh

# Fix line endings (in case of Windows development environment)
RUN sed -i 's/\r$//' /etc/xrdp/startwm.sh

# Additional xrdp session configuration
RUN set -eux; \
    # Ensure xrdp-sesman can create sessions
    sed -ri 's/^;?AutoLogon=.*/AutoLogon=false/' /etc/xrdp/sesman.ini; \
    sed -ri 's/^;?MaxSessions=.*/MaxSessions=10/' /etc/xrdp/sesman.ini; \
    # Make sesman listen on all interfaces (0.0.0.0) to avoid IPv4/IPv6 issues
    if grep -q '^ListenAddress=' /etc/xrdp/sesman.ini; then \
      sed -ri 's/^ListenAddress=.*/ListenAddress=0.0.0.0/' /etc/xrdp/sesman.ini; \
    else \
      sed -i '/^ListenPort=3350/a ListenAddress=0.0.0.0' /etc/xrdp/sesman.ini; \
    fi; \
    # Set session types
    if ! grep -q '\[Xorg\]' /etc/xrdp/sesman.ini; then \
      printf '\n[Xorg]\nparam=xrdp\n' >> /etc/xrdp/sesman.ini; \
    fi

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && sed -i 's/\r$//' /entrypoint.sh

# Create custom startup directory for user scripts
RUN mkdir -p /etc/container-startup.d /home/dev/.config

EXPOSE 3389 22
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
  CMD pgrep -x xrdp >/dev/null && pgrep -x xrdp-sesman >/dev/null || exit 1

VOLUME ["/workspace", "/home/dev"]
ENTRYPOINT ["/usr/bin/tini","--"]
CMD ["/entrypoint.sh"]
