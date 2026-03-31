#!/bin/bash
# Simple wrapper to run tests - no make required
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTAINER_NAME="dotfiles-test-$$"

echo "Building test container..."
podman build -t dotfiles-test "$SCRIPT_DIR"

echo "Running tests..."
trap "podman rm -f $CONTAINER_NAME 2>/dev/null || true" EXIT
podman run --name "$CONTAINER_NAME" dotfiles-test

echo ""
echo "Tests completed successfully!"
