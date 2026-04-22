#!/bin/bash
#
# Development Setup Script
# Prepares your system for dotfiles development and testing
# Installs pre-commit, shellcheck, and other linting tools
#

set -e # Exit immediately if a command exits with a non-zero status

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Helper Functions ---

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

command_exists() {
    command -v "$1" &> /dev/null
}

# --- OS Detection ---

detect_os() {
    if [ -f /etc/debian_version ]; then
        OS="debian"
        log_info "Debian-based system detected"
    elif [ -f /etc/alpine-release ]; then
        OS="alpine"
        log_info "Alpine-based system detected"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        log_info "macOS detected"
    elif [ -f /etc/fedora-release ]; then
        OS="fedora"
        log_info "Fedora detected"
    elif [ -f /etc/redhat-release ]; then
        OS="rhel"
        log_info "Red Hat-based system detected"
    else
        OS="unknown"
        log_warn "Unknown OS detected. You may need to install dependencies manually."
    fi
}

# --- Dependency Installation ---

install_debian_dev_tools() {
    log_info "Installing Debian development tools..."

    # Update package lists
    if command_exists sudo; then
        sudo apt-get update -qq
    else
        apt-get update -qq
    fi

    # Install development tools
    local packages=(
        "shellcheck"
        "python3"
        "python3-pip"
        "git"
    )

    for pkg in "${packages[@]}"; do
        if command_exists "$pkg"; then
            log_success "$pkg is already installed"
        else
            if command_exists sudo; then
                sudo apt-get install -y "$pkg"
            else
                apt-get install -y "$pkg"
            fi
            log_success "$pkg installed"
        fi
    done
}

install_alpine_dev_tools() {
    log_info "Installing Alpine development tools..."

    # Update package lists
    if command_exists sudo; then
        sudo apk update -q
    else
        apk update -q
    fi

    # Install development tools
    local packages=(
        "shellcheck"
        "py3-pip"
        "python3"
        "git"
    )

    for pkg in "${packages[@]}"; do
        if command_exists "$pkg"; then
            log_success "$pkg is already installed"
        else
            if command_exists sudo; then
                sudo apk add "$pkg"
            else
                apk add "$pkg"
            fi
            log_success "$pkg installed"
        fi
    done
}

install_fedora_dev_tools() {
    log_info "Installing Fedora development tools..."

    # Update package lists
    if command_exists sudo; then
        sudo dnf makecache -qq
    else
        dnf makecache -qq
    fi

    # Install development tools
    local packages=(
        "shellcheck"
        "python3-pip"
        "git"
    )

    for pkg in "${packages[@]}"; do
        if command_exists "$pkg"; then
            log_success "$pkg is already installed"
        else
            if command_exists sudo; then
                sudo dnf install -y "$pkg"
            else
                dnf install -y "$pkg"
            fi
            log_success "$pkg installed"
        fi
    done
}

install_rhel_dev_tools() {
    log_info "Installing RHEL development tools..."

    # Enable EPEL repository if needed
    if ! command_exists rpm && ! rpm -qa | grep -q epel-release; then
        if command_exists sudo; then
            sudo dnf install -y epel-release
        fi
    fi

    # Install development tools
    if command_exists sudo; then
        sudo dnf install -y shellcheck python3-pip git
    fi

    log_success "Development tools installed"
}

install_macos_dev_tools() {
    log_info "Installing macOS development tools..."

    # Install Homebrew if not present
    if ! command_exists brew; then
        log_warn "Homebrew not found. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        echo "  Please add Homebrew to your PATH:"
        echo "    brew shellenv"
    fi

    # Evaluate brew shellenv if available
    if command_exists brew; then
        eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv 2>/dev/null)" || true
    fi

    # Install development tools
    local packages=(
        "shellcheck"
    )

    for pkg in "${packages[@]}"; do
        if brew list --versions "$pkg" &>/dev/null; then
            log_success "$pkg is already installed"
        else
            brew install "$pkg"
            log_success "$pkg installed"
        fi
    done

    # Install pip3 if not present
    if ! command_exists pip3; then
        brew install python
        log_success "pip3 installed"
    fi
}

install_pip_packages() {
    log_info "Installing Python development packages..."

    # Install pre-commit using pip
    if command_exists pre-commit; then
        log_success "pre-commit is already installed"
    else
        local install_success=false

        # Try apt first (Debian/Ubuntu have pre-commit package)
        if [ "$OS" = "debian" ] && command_exists apt-get; then
            log_info "Trying apt package manager..."
            if sudo apt-get install -y pre-commit 2>/dev/null; then
                log_success "pre-commit installed via apt"
                install_success=true
            fi
        fi

        # Try pipx (recommended for Python applications on PEP 668 systems)
        if [ "$install_success" = false ] && command_exists pipx; then
            log_info "Attempting pipx installation..."
            sudo -H pipx install pre-commit 2>/dev/null && {
                log_success "pre-commit installed via pipx"
                install_success=true
            }
        fi

        # Fall back to pip with --user flag (if external packages are allowed)
        if [ "$install_success" = false ]; then
            if command_exists pip3; then
                log_info "Attempting pip3 --user installation..."
                if pip3 install --user pre-commit 2>/dev/null; then
                    log_success "pre-commit installed via pip3 --user"
                    install_success=true
                fi
            fi
        fi

        # Last resort: --break-system-packages (not recommended but works)
        if [ "$install_success" = false ] && command_exists pip3; then
            log_warn "Standard methods failed. Using --break-system-packages (not recommended)..."
            sudo -H pip3 install --break-system-packages pre-commit 2>/dev/null && {
                log_success "pre-commit installed via pip3 (system-wide)"
                install_success=true
            }
        fi

        if [ "$install_success" = false ]; then
            log_warn "Could not install pre-commit automatically. Install manually:"
            echo "  pipx install pre-commit"
            echo "  OR"
            echo "  pip3 install --user pre-commit"
            echo "  OR"
            echo "  sudo apt install pre-commit"
            echo ""
            return 1
        fi
    fi
}

install_markdownlint() {
    log_info "Installing markdownlint..."

    # Try different methods to install markdownlint
    if command_exists markdownlint; then
        log_success "markdownlint is already installed"
        return 0
    fi

    local install_success=false

    # Method 1: npm (if available)
    if command_exists npm; then
        log_info "Attempting npm installation..."
        if npm install -g markdownlint-cli@0.37.0 2>/dev/null; then
            log_success "markdownlint-cli installed via npm"
            install_success=true
        fi
    fi

    # Method 2: Try nodejs if npm not available
    if [ "$install_success" = false ] && command_exists node; then
        log_info "Node is available but npm failed..."
        # npm should have been available with node
    fi

    # Method 3: gem (if Ruby available)
    if [ "$install_success" = false ] && command_exists gem; then
        log_info "Attempting gem installation..."
        if sudo gem install markdownlint 2>/dev/null; then
            log_success "markdownlint installed via gem"
            install_success=true
        fi
    fi

    # Method 4: apt (Debian/Ubuntu has markdownlint)
    if [ "$install_success" = false ] && [ "$OS" = "debian" ] && command_exists apt-get; then
        log_info "Trying apt package manager..."
        if sudo apt-get install -y markdownlint 2>/dev/null; then
            log_success "markdownlint installed via apt"
            install_success=true
        fi
    fi

    # Method 5: Skip (warn user)
    if [ "$install_success" = false ]; then
        log_warn "markdownlint not installed. Install manually:"
        echo "  npm install -g markdownlint-cli"
        echo "  OR"
        echo "  sudo apt install nodejs npm && npm install -g markdownlint-cli"
        echo "  OR (Debian/Ubuntu only)"
        echo "  sudo apt install markdownlint"
        return 0
    fi
}

install_yamllint() {
    log_info "Installing yamllint..."

    # Try different methods to install yamllint
    if command_exists yamllint; then
        log_success "yamllint is already installed"
        return 0
    fi

    local install_success=false

    # Method 1: apt (Debian/Ubuntu)
    if [ "$OS" = "debian" ] && command_exists apt-get; then
        log_info "Trying apt package manager..."
        if sudo apt-get install -y yamllint 2>/dev/null; then
            log_success "yamllint installed via apt"
            install_success=true
        fi
    fi

    # Method 2: pipx
    if [ "$install_success" = false ] && command_exists pipx; then
        log_info "Attempting pipx installation..."
        sudo -H pipx install yamllint 2>/dev/null && {
            log_success "yamllint installed via pipx"
            install_success=true
        }
    fi

    # Method 3: pip --user
    if [ "$install_success" = false ] && command_exists pip3; then
        log_info "Attempting pip3 --user installation..."
        if pip3 install --user yamllint 2>/dev/null; then
            log_success "yamllint installed via pip3 --user"
            install_success=true
        fi
    fi

    # Method 4: pip --break-system-packages (last resort)
    if [ "$install_success" = false ] && command_exists pip3; then
        log_warn "Standard methods failed. Using --break-system-packages (not recommended)..."
        sudo -H pip3 install --break-system-packages yamllint 2>/dev/null && {
            log_success "yamllint installed via pip3 (system-wide)"
            install_success=true
        }
    fi

    # Method 5: Skip (warn user)
    if [ "$install_success" = false ]; then
        log_warn "yamllint not installed. Install manually:"
        echo "  sudo apt install yamllint"
        echo "  OR"
        echo "  pipx install yamllint"
        return 0
    fi
}

# --- Setup Pre-Commit Hooks ---

setup_pre_commit_hooks() {
    log_info "Setting up pre-commit hooks..."

    # Check if we're in a git repository
    if ! git rev-parse --git-dir &>/dev/null; then
        log_error "Not in a git repository. Please run this script in your dotfiles directory."
        return 1
    fi

    # Initialize pre-commit
    if command_exists pre-commit; then
        if [ -f .pre-commit-config.yaml ]; then
            pre-commit install
            log_success "pre-commit hooks installed"
        else
            log_warn "No .pre-commit-config.yaml found. Skipping pre-commit setup."
        fi
    else
        log_warn "pre-commit not installed. Install with: pip3 install pre-commit"
    fi
}

# --- Verification ---

verify_installation() {
    log_info "Verifying development environment..."

    echo ""
    echo "Development Tools Status:"
    echo "========================="

    local all_good=true

    # Check shellcheck
    if command_exists shellcheck; then
        echo -e "  ${GREEN}✓${NC} shellcheck $(shellcheck --version | grep version | awk '{print $3}')"
    else
        echo -e "  ${RED}✗${NC} shellcheck (NOT INSTALLED)"
        all_good=false
    fi

    # Check pre-commit
    if command_exists pre-commit; then
        echo -e "  ${GREEN}✓${NC} pre-commit $(pre-commit --version)"
    else
        echo -e "  ${RED}✗${NC} pre-commit (NOT INSTALLED)"
        all_good=false
    fi

    # Check yamllint
    if command_exists yamllint; then
        echo -e "  ${GREEN}✓${NC} yamllint $(yamllint --version 2>&1 | head -1)"
    else
        echo -e "  ${YELLOW}✗${NC} yamllint (OPTIONAL - some checks may fail)"
    fi

    # Check markdownlint
    if command_exists markdownlint; then
        echo -e "  ${GREEN}✓${NC} markdownlint"
    else
        echo -e "  ${YELLOW}✗${NC} markdownlint (OPTIONAL - some checks may fail)"
    fi

    # Check git hooks
    if [ -f .git/hooks/pre-commit ]; then
        echo -e "  ${GREEN}✓${NC} pre-commit hooks configured"
    else
        echo -e "  ${YELLOW}✗${NC} pre-commit hooks (not installed)"
    fi

    echo ""

    if $all_good; then
        log_success "Development environment is ready!"
    else
        log_warn "Some required tools are missing. Install them and run this script again."
    fi

    echo ""
    echo "Next Steps:"
    echo "  1. Review .pre-commit-config.yaml and update exclusions if needed"
    echo "  2. Run 'pre-commit run --all-files' to check your code"
    echo "  3. Run 'pre-commit run' to check staged files on commit"
}

# --- Main Script ---

print_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Options:
    -i, --install       Install all development tools
    -v, --verify        Verify development environment
    -s, --setup         Install tools and setup pre-commit hooks
    -p, --precommit     Only install pre-commit hooks
    --markdown          Install markdownlint only
    --yaml              Install yamllint only
    -h, --help          Show this help message

Example:
    $(basename "$0") --install    # Install all tools
    $(basename "$0") --verify     # Check what's installed
    $(basename "$0") --setup      # Install everything and setup hooks
EOF
}

main() {
    # Parse arguments
    local action=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -i|--install)
                action="install"
                shift
                ;;
            -v|--verify)
                action="verify"
                shift
                ;;
            -s|--setup)
                action="setup"
                shift
                ;;
            -p|--precommit)
                action="precommit"
                shift
                ;;
            --markdown)
                action="markdown"
                shift
                ;;
            --yaml)
                action="yaml"
                shift
                ;;
            -h|--help)
                print_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                print_help
                exit 1
                ;;
        esac
    done

    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  ${GREEN}Dotfiles Development Setup${NC} - Prepare Your Environment"
    echo -e "${BLUE}═════════════════════════════════════════════════════${NC}"
    echo ""

    detect_os

    case "$action" in
        install)
            log_info "Installing development tools based on OS..."

            case "$OS" in
                debian)
                    install_debian_dev_tools
                    ;;
                alpine)
                    install_alpine_dev_tools
                    ;;
                fedora|rhel)
                    install_fedora_dev_tools
                    ;;
                macos)
                    install_macos_dev_tools
                    ;;
                *)
                    log_warn "Unknown OS. Trying to install via pip3..."
                    ;;
            esac

            install_pip_packages
            install_yamllint
            install_markdownlint
            setup_pre_commit_hooks
            ;;
        verify)
            verify_installation
            ;;
        setup)
            action="install"
            ;;
        precommit)
            setup_pre_commit_hooks
            ;;
        markdown)
            install_markdownlint
            ;;
        yaml)
            install_yamllint
            ;;
        *)
            echo "No action specified. Choose from:"
            echo "  --install    Install all development tools"
            echo "  --verify     Verify development environment"
            echo "  --setup      Install tools and setup pre-commit hooks"
            echo ""
            print_help
            ;;
    esac

    echo ""
    log_success "Setup complete!"
}

# Run main function
main "$@"
