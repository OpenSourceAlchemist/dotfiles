#!/bin/bash
#
# End-to-end container test for Ubuntu 24.04 and 26.04 LTS
#
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONTAINER_CLI="docker"
if ! command -v docker >/dev/null 2>&1 && command -v podman >/dev/null 2>&1; then
    CONTAINER_CLI="podman"
fi

test_ubuntu_version() {
    local version="$1"
    local image="ubuntu:$version"
    echo ""
    echo "===================================================="
    echo "  Running Ubuntu $version E2E Test ($image)  "
    echo "===================================================="

    $CONTAINER_CLI run --rm \
        -e CI=true \
        -e NONINTERACTIVE=true \
        -e DEBIAN_FRONTEND=noninteractive \
        -v "$REPO_DIR:/dotfiles:ro" \
        "$image" bash -c '
            set -e
            echo "=== 1. Preparing minimal Ubuntu container ==="
            apt-get update -qq
            apt-get install -y --no-install-recommends sudo ca-certificates bash curl git

            echo "=== 2. Creating non-root test user ==="
            useradd -m -s /bin/bash testuser
            echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

            echo "=== 3. Running bootstrap and install as testuser ==="
            su - testuser -c "
                set -e
                cp -r /dotfiles ~/dotfiles
                cd ~/dotfiles

                echo \"--- Running bootstrap.sh (headless mode) ---\"
                ./bootstrap.sh --headless

                echo \"--- Running install.sh (headless mode) ---\"
                ./install.sh --headless

                echo \"--- Running verification ---\"
                ./install.sh --verify --component shell,editor,multiplexer,git,tools,agents

                echo \"--- Testing shell configuration in zsh ---\"
                zsh -f -c \"source ~/.zshrc; alias ga\"

                echo \"--- Testing uninstallation ---\"
                ./uninstall.sh --force --skip-backup

                echo \"Ubuntu test completed successfully!\"
            "
        '
}

VERSIONS=("24.04" "26.04")
if [ -n "$1" ]; then
    VERSIONS=("$1")
fi

for ver in "${VERSIONS[@]}"; do
    test_ubuntu_version "$ver"
done

echo ""
echo "All Ubuntu E2E tests completed successfully!"
