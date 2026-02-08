FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=all

# Install base system and desktop environment
RUN apt-get update && apt-get install -y --no-install-recommends \
    locales tzdata ca-certificates sudo tini dos2unix wget \
    # XFCE Desktop
    xfce4 xfce4-terminal xfce4-goodies thunar-archive-plugin file-roller \
    dbus-x11 x11-xserver-utils xserver-xorg-core xserver-xorg-input-all \
    xfonts-base fonts-dejavu-core fonts-liberation fonts-noto xauth \
    # Remote access (RDP for Windows, X2Go for performance)
    xrdp xorgxrdp x2goserver x2goserver-xsession openssh-server \
    # Virtual X server for Sunshine
    xvfb \
    # Avahi for Moonlight auto-discovery (mDNS)
    avahi-daemon avahi-utils \
    # GPU acceleration (required for Sunshine encoding)
    mesa-utils libgl1-mesa-dri mesa-vulkan-drivers vulkan-tools \
    libglvnd0 libglx0 libgles2 libegl1 va-driver-all vdpau-driver-all \
    libevdev2 libwayland-client0 libpulse0 libopus0 libxtst6 libayatana-appindicator3-1 \
    # System services
    rsyslog \
 && locale-gen en_US.UTF-8 \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install development tools and Docker CLI
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Version control
    git git-lfs \
    # Build tools
    build-essential cmake automake autoconf libtool pkg-config \
    # Editors and shells
    nano vim neovim tmux screen zsh fish \
    # CLI utilities
    curl wget httpie jq yq unzip zip p7zip-full \
    tree ripgrep fd-find bat eza htop btop ncdu \
    netcat-openbsd telnet traceroute dnsutils iputils-ping \
    # Prerequisites for Docker repository
    gnupg lsb-release ca-certificates \
    # Programming languages
    python3 python3-pip python3-venv python3-dev \
    python3-pytest python3-flake8 python3-autopep8 \
    nodejs npm \
    # Database clients
    postgresql-client mysql-client sqlite3 \
 && install -m 0755 -d /etc/apt/keyrings \
 && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
 && chmod a+r /etc/apt/keyrings/docker.gpg \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list \
 && apt-get update \
 && apt-get install -y docker-ce-cli docker-compose-plugin \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install browsers
RUN apt-get update && apt-get install -y --no-install-recommends \
  firefox \
 && install -m 0755 -d /etc/apt/keyrings \
 && curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg \
 && chmod a+r /etc/apt/keyrings/google-chrome.gpg \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends google-chrome-stable \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Python development tools
RUN pip3 install --no-cache-dir --break-system-packages --ignore-installed \
    pipenv poetry black pylint mypy ipython

# Install Node.js package managers
RUN npm install -g yarn pnpm && npm cache clean --force

# Create docker group and developer user
RUN groupadd -f docker \
 && groupadd -f input \
 && useradd -m -s /bin/bash -G sudo,docker,input,video,render dev \
 && echo "dev:dev" | chpasswd \
 && echo "dev ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/dev \
 && chmod 0440 /etc/sudoers.d/dev

# Configure XFCE for better RDP performance (disable compositor)
RUN mkdir -p /home/dev/.config/xfce4/xfconf/xfce-perchannel-xml \
 && cat > /home/dev/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="use_compositing" type="bool" value="false"/>
    <property name="frame_opacity" type="int" value="100"/>
  </property>
</channel>
EOF

# Configure Git defaults
RUN git config --system init.defaultBranch main \
 && git config --system core.editor vim \
 && git config --system pull.rebase false

# Create workspace directories
RUN mkdir -p /workspace /home/dev/workspace /etc/container-startup.d \
 && ln -sf /workspace /home/dev/workspace-shared \
 && chown -R dev:dev /home/dev

# Configure X11 permissions for container Xorg
RUN mkdir -p /etc/X11 \
 && printf "allowed_users=anybody\nneeds_root_rights=yes\n" > /etc/X11/Xwrapper.config

# Configure XRDP for optimal performance
RUN sed -i 's/^port=.*/port=tcp:\/\/:3389/' /etc/xrdp/xrdp.ini \
 && sed -i '/^port=tcp/a # Performance optimizations\nperf.wallpaper=false\nperf.font_smoothing=false\nperf.desktop_composition=false\nperf.full_window_drag=true\nperf.menu_anims=false\nperf.themes=false\nperf.cursor_blink=false' /etc/xrdp/xrdp.ini

# Configure SSH server
RUN mkdir -p /run/sshd \
 && sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config \
 && sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Install Sunshine for GPU-accelerated streaming
RUN wget -O /tmp/sunshine.deb https://github.com/LizardByte/Sunshine/releases/download/v0.23.1/sunshine-ubuntu-24.04-amd64.deb \
 && apt-get update && apt-get install -y /tmp/sunshine.deb \
 && rm /tmp/sunshine.deb \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# Configure Sunshine defaults
RUN mkdir -p /home/dev/.config/sunshine \
 && chown -R dev:dev /home/dev/.config

# Create XFCE startup script
RUN cat > /home/dev/.xsession <<'EOF'
#!/bin/bash
startxfce4
EOF
RUN chmod +x /home/dev/.xsession && chown dev:dev /home/dev/.xsession

# Copy and configure entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && dos2unix /entrypoint.sh 2>/dev/null || sed -i 's/\r$//' /entrypoint.sh

# Expose ports
EXPOSE 3389 22 47984 47989 47990 48010

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
  CMD pgrep -x xrdp >/dev/null || pgrep -x sunshine >/dev/null || exit 1

# Volumes for persistence
VOLUME ["/workspace", "/home/dev"]

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/entrypoint.sh"]
