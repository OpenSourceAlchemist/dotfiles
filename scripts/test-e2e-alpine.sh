#!/bin/bash
#
# End-to-end container test for Alpine Linux
#
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONTAINER_CLI="docker"
if ! command -v docker >/dev/null 2>&1 && command -v podman >/dev/null 2>&1; then
    CONTAINER_CLI="podman"
fi

echo "Running Alpine Linux E2E container test using $CONTAINER_CLI..."

$CONTAINER_CLI run --rm \
    -e CI=true \
    -e NONINTERACTIVE=true \
    -v "$REPO_DIR:/dotfiles:ro" \
    alpine:latest /bin/sh -c '
        set -e
        echo "=== 1. Preparing minimal Alpine container ==="
        apk update
        apk add bash sudo curl ca-certificates shadow git

        echo "=== 2. Creating non-root test user with sudo privileges ==="
        useradd -m -s /bin/bash testuser
        echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

        echo "=== 3. Running bootstrap and install as testuser ==="
        su - testuser -c "
            set -e
            cp -r /dotfiles ~/dotfiles
            cd ~/dotfiles

            echo \"--- Running bootstrap.sh ---\"
            ./bootstrap.sh

            echo \"--- Running install.sh ---\"
            ./install.sh

            echo \"--- Running verification ---\"
            ./install.sh --verify

            echo \"--- Testing shell configuration in zsh ---\"
            zsh -f -c \"source ~/.zshrc; alias ga\"

            echo \"--- Testing uninstallation ---\"
            ./uninstall.sh --force --skip-backup

            echo \"Alpine Linux E2E test completed successfully!\"
        "
'
