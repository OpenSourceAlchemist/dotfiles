#!/bin/bash
# Pre-commit helper script
# Usage: ./scripts/run-precommit.sh [--all]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if pre-commit is installed
if ! command -v pre-commit &>/dev/null; then
    log_warn "pre-commit is not installed"
    log_info "To install pre-commit, run one of the following:"
    echo ""
    echo "  pip3 install pre-commit"
    echo "  pipx install pre-commit"
    echo "  brew install pre-commit (macOS)"
    echo "  sudo apt-get install pre-commit (Debian/Ubuntu)"
    echo ""
    exit 1
fi

# Run hooks
if [ "$1" == "--all" ]; then
    log_info "Running pre-commit hooks on ALL files..."
    pre-commit run --all-files
    exit_code=$?

    if [ $exit_code -eq 0 ]; then
        log_success "All pre-commit hooks passed!"
    else
        log_warn "Some pre-commit hooks failed. Please fix the issues above."
        exit 1
    fi
else
    log_info "Running pre-commit hooks on staged files..."
    pre-commit run
    exit_code=$?

    if [ $exit_code -eq 0 ]; then
        log_success "All pre-commit hooks passed!"
    else
        log_warn "Some pre-commit hooks failed. Please fix the issues above."
        exit 1
    fi
fi
