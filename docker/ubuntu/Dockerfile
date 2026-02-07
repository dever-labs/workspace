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
    rsyslog \
    # System utilities
    procps iproute2 net-tools \
    software-properties-common apt-transport-https \
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
RUN set -eux; \
    sed -ri 's|^port=.*|port=tcp://:3389|' /etc/xrdp/xrdp.ini; \
    sed -ri '/^address=/d' /etc/xrdp/xrdp.ini; \
    sed -ri 's/^LogLevel=.*/LogLevel=INFO/' /etc/xrdp/xrdp.ini || true; \
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

# startwm: predictable XFCE startup
RUN cat > /etc/xrdp/startwm.sh <<'EOF'
#!/bin/sh
export XDG_SESSION_DESKTOP=xfce
export XDG_CURRENT_DESKTOP=XFCE
export DESKTOP_SESSION=xfce

# User session dbus helps XFCE in headless/container environments
if command -v dbus-launch >/dev/null 2>&1; then
  eval "$(dbus-launch --sh-syntax)" >/dev/null 2>&1
fi

exec startxfce4
EOF

RUN chmod +x /etc/xrdp/startwm.sh

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Create custom startup directory for user scripts
RUN mkdir -p /etc/container-startup.d /home/dev/.config

EXPOSE 3389 22
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
  CMD pgrep -x xrdp >/dev/null && pgrep -x xrdp-sesman >/dev/null || exit 1

VOLUME ["/workspace", "/home/dev"]
ENTRYPOINT ["/usr/bin/tini","--"]
CMD ["/entrypoint.sh"]
