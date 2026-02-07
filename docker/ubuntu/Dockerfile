FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
    locales tzdata ca-certificates sudo \
    xfce4 xfce4-terminal xfce4-session \
    dbus-x11 x11-xserver-utils \
    xserver-xorg-core xserver-xorg-input-all \
    xfonts-base fonts-dejavu-core \
    xauth \
    xrdp xorgxrdp \
    # syslog so we can see PAM/Xorg errors reliably
    rsyslog \
    procps iproute2 net-tools \
    nano vim htop \
    tini \
 && locale-gen en_US.UTF-8 \
 && update-ca-certificates \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# dev user
RUN useradd -m -s /bin/bash dev \
 && echo "dev:dev" | chpasswd \
 && adduser dev sudo \
 && adduser xrdp ssl-cert \
 && echo "startxfce4" > /home/dev/.xsession \
 && chown dev:dev /home/dev/.xsession

# XRDP config:
# - keep the working IPv4 fix: port=tcp://:3389
# - force DEBUG logging
# - FORCE sesman to log to /var/log/xrdp-sesman.log + syslog
RUN set -eux; \
    sed -ri 's|^port=.*|port=tcp://:3389|' /etc/xrdp/xrdp.ini; \
    sed -ri '/^address=/d' /etc/xrdp/xrdp.ini; \
    sed -ri 's/^LogLevel=.*/LogLevel=DEBUG/' /etc/xrdp/xrdp.ini || true; \
    \
    # sesman logging knobs (these are the important ones)
    if grep -q '^LogLevel=' /etc/xrdp/sesman.ini; then \
      sed -ri 's/^LogLevel=.*/LogLevel=DEBUG/' /etc/xrdp/sesman.ini; \
    else \
      printf '\nLogLevel=DEBUG\n' >> /etc/xrdp/sesman.ini; \
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

# Robust startwm (no heredoc weirdness)
RUN cat > /etc/xrdp/startwm.sh <<'EOF'
#!/bin/sh
export XDG_SESSION_DESKTOP=xfce
export XDG_CURRENT_DESKTOP=XFCE
export DESKTOP_SESSION=xfce

# user dbus session helps a lot with xfce in containers
if command -v dbus-launch >/dev/null 2>&1; then
  eval "$(dbus-launch --sh-syntax)" >/dev/null 2>&1
fi

exec startxfce4
EOF

RUN chmod +x /etc/xrdp/startwm.sh

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 3389
ENTRYPOINT ["/usr/bin/tini","--"]
CMD ["/entrypoint.sh"]
