#!/usr/bin/env bash
# Example custom startup script
# This file demonstrates how to customize your container startup
# Copy this to /etc/container-startup.d/ inside the container and make it executable

set -e

echo "[CUSTOM] Running example startup script..."

# Example 1: Set up custom environment variables
# export MY_APP_ENV=development
# export PATH="/home/dev/.local/bin:$PATH"

# Example 2: Start a background service
# if ! pgrep -x "my-daemon" > /dev/null; then
#     sudo -u dev /usr/local/bin/my-daemon &
# fi

# Example 3: Clone repositories on first run
# REPO_DIR="/home/dev/projects/my-repo"
# if [ ! -d "$REPO_DIR" ]; then
#     sudo -u dev git clone https://github.com/user/repo.git "$REPO_DIR"
# fi

# Example 4: Install additional packages dynamically
# if [ ! -f /usr/bin/some-tool ]; then
#     apt-get update && apt-get install -y some-package
# fi

# Example 5: Set up Docker connection for remote Docker host
# if [ -n "${DOCKER_HOST}" ]; then
#     echo "Docker host: ${DOCKER_HOST}"
# fi

# Example 6: Configure proxy settings if needed
# if [ -n "${HTTP_PROXY}" ]; then
#     git config --global http.proxy "${HTTP_PROXY}"
#     npm config set proxy "${HTTP_PROXY}"
# fi

# Example 7: Health check for required services
# check_service() {
#     if ! systemctl is-active --quiet "$1"; then
#         echo "WARNING: $1 is not running"
#     fi
# }
# check_service docker

echo "[CUSTOM] Startup script completed"
