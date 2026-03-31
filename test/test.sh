#!/bin/bash
# Simple wrapper to run tests - no make required
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONTAINER_NAME="dotfiles-test-$$"

echo "Building test container..."
podman build -t dotfiles-test "$PROJECT_ROOT" -f "$SCRIPT_DIR/Dockerfile"

echo "Running tests..."
trap "podman rm -f $CONTAINER_NAME 2>/dev/null || true" EXIT
podman run --name "$CONTAINER_NAME" dotfiles-test

echo ""
echo "Tests completed successfully!"
