#!/bin/bash
#
# Bootstrap script to install system dependencies for dotfiles
# Detects OS and installs required packages automatically
#

set -e # Exit immediately if a command exits with a non-zero status

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
        VER=$(cat /etc/debian_version)
        log_info "Debian-based system detected (version $VER)"
    elif [ -f /etc/alpine-release ]; then
        OS="alpine"
        VER=$(cat /etc/alpine-release)
        log_info "Alpine-based system detected (version $VER)"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        VER=$(sw_vers -productVersion)
        log_info "macOS detected (version $VER)"
    elif [ -f /etc/fedora-release ]; then
        OS="fedora"
        VER=$(sed 's/^.*release \([0-9]*\).*/\1/' /etc/fedora-release)
        log_info "Fedora detected (version $VER)"
    elif [ -f /etc/redhat-release ]; then
        # Covers RHEL, CentOS, Rocky, AlmaLinux
        OS="rhel"
        VER=$(sed 's/^.*release \([0-9.]*\).*/\1/' /etc/redhat-release)
        log_info "Red Hat-based system detected (version $VER)"
    elif [ -f /etc/arch-release ] || [ -f /etc/arch-version ]; then
        OS="arch"
        log_info "Arch-based system detected"
    else
        # Additional fallback: check for common RHEL family files
        if ls /etc/*-release 2>/dev/null | grep -q "rhel\|centos\|rocky\|almalinux"; then
            OS="rhel"
            log_info "Red Hat-based system detected via release info"
        else
            OS="unknown"
            log_warn "Unknown OS detected. You may need to install dependencies manually."
        fi
    fi
}

# --- Dependency Installation ---

# Debian/Ubuntu package mappings
DEBIAN_PACKAGES=(
    "zsh"
    "vim-nox"
    "tmux"
    "git"
    "rsync"
    "bzip2"
    "rxvt-unicode"
    "keychain"
    "mosh"
    "xclip"
    "xscreensaver"
    "libcom-err2"  # for compotn
)

# Alpine package mappings
ALPINE_PACKAGES=(
    "zsh"
    "vim"
    "tmux"
    "git"
    "rsync"
    "bzip2"
    "rxvt-unicode"
    "keychain"
    "mosh"
    "xclip"
    "xscreensaver"
)

# macOS/Brew packages
BREW_PACKAGES=(
    "zsh"
    "vim"
    "tmux"
    "git"
    "rsync"
    "mosh"
    "xclip"  # via 'xclip' formula or alternatives
)

# Check and install a package if missing
check_and_install_apt() {
    local pkg="$1"
    local alt_pkg="$2"  # Alternative package name
    
    # Check if the package or alternative exists
    if command_exists "$pkg" || command_exists "$alt_pkg" || dpkg -l | grep -q "^ii  $pkg "; then
        echo -e "  ${GREEN}✓${NC} $pkg is already installed"
        return 0
    fi
    
    if [ "$alt_pkg" ] && dpkg -l | grep -q "^ii  $alt_pkg "; then
        echo -e "  ${GREEN}✓${NC} $alt_pkg (as $pkg) is already installed"
        return 0
    fi
    
    echo "  Installing $pkg..."
    if command_exists sudo; then
        sudo apt-get install -y "$pkg"
    else
        apt-get install -y "$pkg"
    fi
    echo -e "  ${GREEN}✓${NC} $pkg installed"
}

check_and_install_apk() {
    local pkg="$1"
    
    if command_exists "$pkg"; then
        echo -e "  ${GREEN}✓${NC} $pkg is already installed"
        return 0
    fi
    
    echo "  Installing $pkg..."
    if command_exists sudo; then
        sudo apk add "$pkg"
    else
        apk add "$pkg"
    fi
    echo -e "  ${GREEN}✓${NC} $pkg installed"
}

install_debian_dependencies() {
    log_info "Installing Debian/Ubuntu dependencies..."
    
    # Update package lists
    echo "  Updating package lists..."
    if command_exists sudo; then
        sudo apt-get update -qq
    else
        apt-get update -qq
    fi
    
    local missing=()
    local deps=(
        "zsh:zsh"
        "vim:vim-nox:vim"
        "tmux:tmux"
        "git:git"
        "rsync:rsync"
        "bzip2:bzip2"
        "rxvt-unicode:urxvt"
        "keychain:keychain"
        "mosh:mosh"
        "xclip:xclip"
        "xscreensaver:xscreensaver"
        "compton:compton:picom"
    )
    
    for dep in "${deps[@]}"; do
        IFS=':' read -r target primary alt <<< "$dep"
        
        # Check if already installed
        if command_exists "$primary" || ( [ -n "$alt" ] && command_exists "$alt" ); then
            echo -e "  ${GREEN}✓${NC} $target ($primary) is already installed"
        else
            echo "  Marking $target for installation..."
            missing+=("$primary")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo "  Installing ${#missing[@]} missing package(s)..."
        if command_exists sudo; then
            sudo apt-get install -y "${missing[@]}"
        else
            apt-get install -y "${missing[@]}"
        fi
        log_success "Debian dependencies installation complete"
    else
        log_success "All Debian dependencies already satisfied"
    fi
}

install_alpine_dependencies() {
    log_info "Installing Alpine dependencies..."
    
    # Update package lists
    echo "  Updating package lists..."
    if command_exists sudo; then
        sudo apk update
    else
        apk update
    fi
    
    local missing=()
    local deps=(
        "zsh"
        "vim"
        "tmux"
        "git"
        "rsync"
        "bzip2"
        "rxvt-unicode"
        "keychain"
        "mosh"
        "xclip"
        "xscreensaver"
    )
    
    for pkg in "${deps[@]}"; do
        if command_exists "$pkg"; then
            echo -e "  ${GREEN}✓${NC} $pkg is already installed"
        else
            echo "  Marking $pkg for installation..."
            missing+=("$pkg")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo "  Installing ${#missing[@]} missing package(s)..."
        if command_exists sudo; then
            sudo apk add "${missing[@]}"
        else
            apk add "${missing[@]}"
        fi
        log_success "Alpine dependencies installation complete"
    else
        log_success "All Alpine dependencies already satisfied"
    fi
}

install_rhel_dependencies() {
    log_info "Installing RHEL/CentOS/Fedora/Rocky dependencies..."
    
    # Update package lists
    echo "  Updating package lists..."
    if command_exists dnf; then
        if command_exists sudo; then
            sudo dnf makecache -qq
            sudo dnf upgrade -y -qq
        else
            dnf makecache -qq
            dnf upgrade -y -qq
        fi
    elif command_exists yum; then
        if command_exists sudo; then
            sudo yum makecache -qq
            sudo yum upgrade -y -qq
        else
            yum makecache -qq
            yum upgrade -y -qq
        fi
    fi
    
    local missing=()
    local deps=(
        "zsh"
        "vim-enhanced:vim"
        "tmux"
        "git"
        "rsync"
        "bzip2"
        "keychain"
        "mosh"
        "xclip"
    )
    
    for dep in "${deps[@]}"; do
        IFS=':' read -r pkg name <<< "$dep"
        
        # Check if package is already installed
        if command_exists "$name"; then
            echo -e "  ${GREEN}✓${NC} $name is already installed"
        else
            echo "  Marking $pkg for installation..."
            missing+=("$pkg")
        fi
    done
    
    # xscreensaver is in EPEL on RHEL/CentOS, so we need to enable it first
    if command_exists sudo; then
        if ! rpm -qa | grep -q epel-release; then
            echo "  Installing EPEL repository..."
            if command_exists dnf; then
                sudo dnf install -y epel-release
            elif command_exists yum; then
                sudo yum install -y epel-release
            fi
        fi
        # Enable PowerTools/CR for xscreensaver on certain RHEL versions
        if command_exists dnf; then
            sudo dnf config-manager --set-enabled PowerTools 2>/dev/null || true
            sudo dnf config-manager --set-enabled cr 2>/dev/null || true
        fi
    fi
    
    # Check for xscreensaver separately
    if command_exists xscreensaver; then
        echo -e "  ${GREEN}✓${NC} xscreensaver is already installed"
    else
        echo "  Marking xscreensaver for installation (may need EPEL)..."
        missing+=("xscreensaver")
    fi
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo "  Installing ${#missing[@]} missing package(s)..."
        if command_exists sudo; then
            sudo dnf install -y "${missing[@]}" 2>/dev/null || sudo yum install -y "${missing[@]}"
        else
            dnf install -y "${missing[@]}" 2>/dev/null || yum install -y "${missing[@]}"
        fi
        log_success "RHEL dependencies installation complete"
    else
        log_success "All RHEL dependencies already satisfied"
    fi
}

install_homebrew_dependencies() {
    log_info "Installing macOS/Homebrew dependencies..."
    
    # Install Homebrew if not present
    if ! command_exists brew; then
        log_warn "Homebrew not found. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        echo "  Please add Homebrew to your PATH:"
        echo "    brew shellenv"
        log_info "Continuing with remaining installations..."
    fi
    
    # Evaluate brew shellenv if available
    if command_exists brew; then
        eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv 2>/dev/null)" || true
    fi
    
    local missing=()
    local deps=(
        "zsh"
        "vim"
        "tmux"
        "git"
        "rsync"
        "mosh"
    )
    
    for pkg in "${deps[@]}"; do
        if brew list --versions "$pkg" &>/dev/null; then
            echo -e "  ${GREEN}✓${NC} $pkg is already installed"
        else
            echo "  Marking $pkg for installation..."
            missing+=("$pkg")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo "  Installing ${#missing[@]} missing package(s)..."
        brew install "${missing[@]}"
        log_success "Homebrew dependencies installation complete"
    else
        log_success "All Homebrew dependencies already satisfied"
    fi
}

# --- Special Tool Installation ---

install_mise() {
    log_info "Checking mise installation..."
    
    if command_exists mise; then
        log_success "mise is already installed"
        return 0
    fi
    
    log_info "Installing mise..."
    
    # Try to detect preferred installation method
    if [ -L "$HOME/.local/bin/mise" ] || [ -f "$HOME/.local/bin/mise" ]; then
        log_info "mise found in $HOME/.local/bin (not in PATH)"
        return 0
    fi
    
    # Install mise via official installer
    if command_exists curl; then
        curl https://mise.run | sh
        log_success "mise installed. Add to PATH:"
        echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    elif command_exists wget; then
        wget -qO- https://mise.run | sh
        log_success "mise installed. Add to PATH:"
        echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    else
        log_warn "curl or wget not available. Please install mise manually:"
        echo "  curl https://mise.run | sh"
    fi
}

install_fzf() {
    log_info "Checking fzf installation..."
    
    if command_exists fzf; then
        log_success "fzf is already installed"
        return 0
    fi
    
    # Check if it's installed as a git submodule (common setup)
    if [ -d "$HOME/.fzf" ] || [ -d "$DOTFILES_DIR/fzf" ]; then
        log_info "fzf directory found. Run '$DOTFILES_DIR/fzf/install.sh' or 'git submodule update --init'"
        return 0
    fi
    
    log_info "Installing fzf..."
    if command_exists brew; then
        brew install fzf
        log_info "Run 'brew uninstall fzf' to remove the symlink if needed"
    elif command_exists apt-get; then
        sudo apt-get install -y fzf
    elif command_exists apk; then
        apk add fzf
    elif command_exists dnf || command_exists yum; then
        # Try dnf first (Fedora/RHEL 8+), fall back to yum
        sudo dnf install -y fzf 2>/dev/null || sudo yum install -y fzf
    else
        log_warn "Please install fzf manually: git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf"
    fi
}

install_direnv() {
    log_info "Checking direnv installation..."
    
    if command_exists direnv; then
        log_success "direnv is already installed"
        return 0
    fi
    
    log_info "Installing direnv..."
    if command_exists brew; then
        brew install direnv
    elif command_exists apt-get; then
        sudo apt-get install -y direnv
    elif command_exists apk; then
        apk add direnv
    elif command_exists yum; then
        sudo yum install -y direnv
    else
        log_warn "Please install direnv manually: https://direnv.net/docs/installation.html"
    fi
}

install_terraform() {
    log_info "Checking terraform installation..."
    
    if command_exists terraform; then
        log_success "terraform is already installed"
        return 0
    fi
    
    log_info "Installing terraform..."
    if command_exists brew; then
        brew install terraform
    elif command_exists apt-get; then
        sudo apt-get install -y software-properties-common
        sudo add-apt-repository -y ppa:hashicorp/terraform 2>/dev/null || true
        sudo apt-get update -qq 2>/dev/null || true
        sudo apt-get install -y terraform
    elif command_exists apk; then
        # Add Alpine repo
        wget -qO- https://get.hashicorp.com/gpgkey | gpg --dearmor | sudo dd of=/etc/apk/keys/hashicorp.gpg
        sudo apk add --repository https://dl-cdn.alpinelinux.org/alpine/edge/testing/ terraform
    elif command_exists dnf || command_exists yum; then
        # Install HashiCorp repo on RHEL/Fedora
        echo "  Installing HashiCorp release repository..."
        if command_exists dnf; then
            sudo dnf install -y dnf-utils
            sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
            sudo dnf install -y terraform
        elif command_exists yum; then
            sudo yum install -y yum-utils
            sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
            sudo yum install -y terraform
        fi
    else
        log_warn "Please install terraform manually: https://developer.hashicorp.com/terraform/downloads"
    fi
}

install_gh() {
    log_info "Checking GitHub CLI (gh) installation..."
    
    if command_exists gh; then
        log_success "gh is already installed"
        return 0
    fi
    
    log_info "Installing GitHub CLI..."
    if command_exists brew; then
        brew install gh
    elif command_exists apt-get; then
        sudo apt-get install -y gh
    elif command_exists apk; then
        sudo apk add gh
    elif command_exists dnf || command_exists yum; then
        # Install GitHub CLI repository
        echo "  Installing GH releases repository..."
        if command_exists dnf; then
            sudo dnf config-manager --add-repo https://packagecloud.io/cli/cli/dnf/cli.repo
            sudo dnf install -y gh
        elif command_exists yum; then
            sudo yum install -y yum-utils
            sudo yum-config-manager --add-repo https://packagecloud.io/cli/cli/yum/cli.repo
            sudo yum install -y gh
        fi
    else
        log_warn "Please install gh manually: https://cli.github.com/"
    fi
}

install_zsh_antigen() {
    log_info "Checking zsh-antigen installation..."
    
    # Common locations where antigen might be installed
    local antigen_paths=(
        "/usr/share/zsh-antigen/antigen.zsh"
        "/usr/local/share/zsh-antigen/antigen.zsh"
        "$HOME/.zsh/antigen/zsh-antigen/antigen.zsh"
    )
    
    for path in "${antigen_paths[@]}"; do
        if [ -f "$path" ]; then
            log_success "antigen is already installed at $path"
            return 0
        fi
    done
    
    log_info "Installing antigen to ~/.zsh/antigen..."
    mkdir -p "$HOME/.zsh"
    
    if command_exists brew; then
        brew install antigen
    elif command_exists apt-get; then
        sudo apt-get install -y zsh-antigen
    elif command_exists apk; then
        # Alpine doesn't have antigen in repos, install via git
        git clone --depth 1 https://github.com/zsh-users/antigen "$HOME/.zsh/antigen/zsh-antigen"
        log_success "antigen installed to ~/.zsh/antigen"
        return 0
    elif command_exists git; then
        git clone --depth 1 https://github.com/zsh-users/antigen "$HOME/.zsh/antigen/zsh-antigen"
    else
        log_warn "Please install antigen manually: git clone --depth 1 https://github.com/zsh-users/antigen ~/.zsh/antigen/zsh-antigen"
        return 1
    fi
    
    log_success "antigen installation complete"
}

# --- Main Script ---

main() {
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  ${GREEN}Dotfiles Bootstrap${NC} - Installing Dependencies"
    echo -e "${BLUE}════════════════════════════════════════════════════${NC}"
    echo ""
    
    detect_os
    
    case "$OS" in
        debian|ubuntu|Linux)
            install_debian_dependencies
            ;;
        alpine)
            install_alpine_dependencies
            ;;
        fedora|rhel)
            install_rhel_dependencies
            ;;
        macos|Darwin)
            install_homebrew_dependencies
            ;;
        *)
            log_warn "Unknown or unsupported OS: $OS"
            log_info "Please install the following packages manually:"
            echo ""
            echo "  Required:"
            echo "    - zsh, vim, tmux, git, rsync, bzip2"
            echo "    - keychain, xclip, mosh"
            echo ""
            echo "  Optional:"
            echo "    - fzf, direnv, terraform, gh (GitHub CLI)"
            echo ""
            exit 1
            ;;
    esac
    
    # Install special tools (check if present, offer to install if missing)
    echo ""
    log_info "Checking/installing special tools..."
    
    # Tools that are more commonly installed manually
    install_mise
    install_fzf
    install_direnv
    install_terraform
    install_gh
    install_zsh_antigen
    
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════${NC}"
    log_success "Bootstrap complete!"
    echo -e "${GREEN}════════════════════════════════════════════════════${NC}"
    echo ""
    echo "You can now run the installation script:"
    echo "  ./install.sh"
    echo ""
    echo "If mise was installed, remember to add it to your PATH:"
    echo '  export PATH="$HOME/.local/bin:$PATH"'
    echo ""
}

# Run main function
main "$@"
