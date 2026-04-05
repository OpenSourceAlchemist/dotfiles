#!/bin/bash
# Development Environment Setup Script
# Install tools needed for developing this repository
# Usage: ./scripts/develop-setup.sh [install|install-hooks|run|run-all|status]

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

# Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Install pre-commit
install_precommit() {
    log_info "Checking pre-commit installation..."
    
    if command_exists pre-commit; then
        log_success "pre-commit is already installed ($(pre-commit --version))"
        return 0
    fi
    
    log_info "Installing pre-commit..."
    
    # Try various methods
    if command_exists pip3; then
        pip3 install --user pre-commit
        log_success "pre-commit installed via pip3"
    elif command_exists pip; then
        pip install --user pre-commit
        log_success "pre-commit installed via pip"
    elif command_exists brew; then
        brew install pre-commit
        log_success "pre-commit installed via Homebrew"
    elif command_exists apt-get; then
        if sudo apt-get install -y --no-install-recommends python3-pre-commit 2>/dev/null; then
            log_success "pre-commit installed via apt"
        elif sudo apt-get install -y --no-install-recommends pre-commit 2>/dev/null; then
            log_success "pre-commit installed via apt"
        else
            log_warn "Could not install via apt, trying pip3..."
            pip3 install --user pre-commit || log_warn "Please install manually: pip3 install pre-commit"
        fi
    elif command_exists apk; then
        if sudo apk add python3-pre-commit 2>/dev/null; then
            log_success "pre-commit installed via apk"
        else
            pip3 install --user pre-commit || log_warn "Please install manually: pip3 install pre-commit"
        fi
    elif command_exists dnf || command_exists yum; then
        # Try pre-commit package name varies by distro
        if command_exists dnf; then
            sudo dnf install -y python3-pre-commit 2>/dev/null || \
            python3 -m pip install --user pre-commit
        else
            sudo yum install -y python3-pre-commit 2>/dev/null || \
            python3 -m pip install --user pre-commit
        fi
        log_success "pre-commit installed via dnf/yum or pip"
    else
        log_error "No suitable package manager found for pre-commit"
        log_info "Install pre-commit manually: pip3 install pre-commit"
        return 1
    fi
}

# Install golangci-lint (for Go linting if needed)
install_golangci_lint() {
    log_info "Checking golangci-lint installation..."
    
    if command_exists golangci-lint; then
        log_success "golangci-lint is already installed"
        return 0
    fi
    
    log_info "Installing golangci-lint..."
    
    if command_exists brew; then
        brew install golangci-lint
    elif command_exists curl; then
        curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b "$HOME/.local/bin"
        log_success "golangci-lint installed to ~/.local/bin"
    else
        log_warn "Please install golangci-lint manually: https://golangci-lint.run/usage/install/"
    fi
}

# Install shellcheck (if using distro packages, otherwise use pre-commit)
install_shellcheck() {
    log_info "Checking shellcheck installation..."
    
    if command_exists shellcheck; then
        log_success "shellcheck is already installed"
        return 0
    fi
    
    log_info "Installing shellcheck..."
    
    if command_exists apt-get; then
        sudo apt-get install -y shellcheck
    elif command_exists dnf || command_exists yum; then
        sudo dnf install -y shellcheck 2>/dev/null || sudo yum install -y shellcheck
    elif command_exists brew; then
        brew install shellcheck
    elif command_exists apk; then
        sudo apk add shellcheck
    else
        log_warn "Please install shellcheck manually or use pre-commit (which bundles shellcheck)"
    fi
}

# Install markdownlint
install_markdownlint() {
    log_info "Checking markdownlint installation..."
    
    if command_exists markdownlint; then
        log_success "markdownlint is already installed"
        return 0
    fi
    
    log_info "Installing markdownlint..."
    
    if command_exists npm; then
        npm install -g markdownlint-cli
        log_success "markdownlint installed via npm"
    elif command_exists brew; then
        brew install markdownlint
        log_success "markdownlint installed via Homebrew"
    else
        log_warn "Please install markdownlint manually: npm install -g markdownlint-cli"
    fi
}

# Install pre-commit hooks
install_hooks() {
    if ! command_exists pre-commit; then
        log_error "pre-commit not installed. Run: ./scripts/develop-setup.sh install"
        return 1
    fi
    
    log_info "Installing git hooks..."
    pre-commit install
    log_success "Git hooks installed"
}

# Run pre-commit on all files
run_all() {
    if ! command_exists pre-commit; then
        log_error "pre-commit not installed. Run: ./scripts/develop-setup.sh install"
        return 1
    fi
    
    log_info "Running pre-commit on all files..."
    pre-commit run --all-files
}

# Run pre-commit on staged files
run() {
    if ! command_exists pre-commit; then
        log_error "pre-commit not installed. Run: ./scripts/develop-setup.sh install"
        return 1
    fi
    
    log_info "Running pre-commit on staged files..."
    pre-commit run
}

# Check dev tool status
status() {
    echo "Development Tool Status:"
    echo "========================"
    
    local has_error=0
    
    echo -n "pre-commit: "
    if command_exists pre-commit; then
        echo -e "${GREEN}✓ installed${NC} ($(pre-commit --version))"
    else
        echo -e "${RED}✗ not installed${NC}"
        has_error=1
    fi
    
    echo -n "shellcheck: "
    if command_exists shellcheck; then
        echo -e "${GREEN}✓ installed${NC} ($(shellcheck --version 2>/dev/null | grep 'version' | cut -d' ' -f3))"
    else
        echo -e "${YELLOW}⚠ not installed (will use pre-commit's bundled version)${NC}"
    fi
    
    echo -n "golangci-lint: "
    if command_exists golangci-lint; then
        echo -e "${GREEN}✓ installed${NC}"
    else
        echo -e "${YELLOW}⚠ not installed${NC}"
    fi
    
    echo -n "git hooks: "
    if [ -f .git/hooks/pre-commit ]; then
        echo -e "${GREEN}✓ installed${NC}"
    else
        echo -e "${RED}✗ not installed${NC}"
        has_error=1
    fi
    
    if [ $has_error -eq 0 ]; then
        echo ""
        echo -e "${GREEN}All development tools are up to date!${NC}"
    else
        echo ""
        log_warn "Run './scripts/develop-setup.sh install' to install missing tools"
        return 1
    fi
}

# Show usage
usage() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  install        Install all development tools (pre-commit, shellcheck, etc.)"
    echo "  install-hooks  Install pre-commit git hooks"
    echo "  run-all        Run pre-commit on all files"
    echo "  run            Run pre-commit on staged files"
    echo "  status         Check status of development tools"
    echo ""
    echo "Examples:"
    echo "  $0 install           # Install all dev tools"
    echo "  $0 install-hooks     # Install git hooks only"
    echo "  $0 run-all           # Run all checks on all files"
    echo "  $0 status            # Check what's installed"
}

# Main
main() {
    case "$1" in
        install)
            log_info "Installing development tools..."
            install_precommit
            install_shellcheck  # Optional, pre-commit bundles it
            install_markdownlint  # Optional, pre-commit bundles it
            install_hooks
            log_success "Development tools installation complete!"
            echo ""
            echo "Next steps:"
            echo "  $0 run-all  # Run all checks"
            ;;
        install-hooks)
            install_hooks
            ;;
        run-all)
            run_all
            ;;
        run)
            run
            ;;
        status)
            status
            ;;
        *)
            usage
            exit 1
            ;;
    esac
}

main "$@"
