#!/bin/bash
#
# Uninstall script for dotfiles
# Removes symlinks and optionally restores backed-up files
#

set -e # Exit immediately if a command exits with a non-zero status

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# --- Configuration ---

# List of files/directories managed by this dotfiles repo
MANAGED_FILES=(
    ".bashrc"
    ".zshrc"
    ".inputrc"
    ".vimrc"
    ".tmux.conf"
    ".gitconfig"
    ".gitignore_global"
    ".ssh/config"
    ".asdfrc"
    ".fzf.bash"
    ".fzf.zsh"
)

BACKUP_PREFIX=~/.dotfiles_backup_

# --- Functions ---

find_latest_backup() {
    ls -t ${BACKUP_PREFIX}* 2>/dev/null | head -1
}

remove_symlink() {
    local file="$1"
    local target="$HOME/$file"

    if [ -L "$target" ]; then
        rm -f "$target"
        log_success "Removed symlink: ~/$file"
    elif [ -f "$target" ]; then
        log_warn "Not a symlink: ~/$file (skipping)"
    else
        log_info "Does not exist: ~/$file"
    fi
}

restore_backup() {
    local backup_dir="$1"
    local file="$2"

    if [ -f "$backup_dir/$file" ]; then
        cp "$backup_dir/$file" "$HOME/$file"
        log_success "Restored: ~/$file from backup"
    else
        log_warn "No backup found for: ~/$file"
    fi
}

print_welcome() {
    echo ""
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo -e "${BLUE}  ${RED}Dotfiles Uninstallation${NC}             "
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo ""
}

print_usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Options:
    --restore         Restore backed-up files (if available)
    --skip-backup     Skip backup check, just remove symlinks
    --force           Remove without confirmation
    -h, --help        Show this help message

Example:
    $(basename "$0") --restore      # Remove symlinks and restore backups
    $(basename "$0") --skip-backup  # Just remove symlinks without checking backups
EOF
}

# --- Main Script ---

main() {
    local restore_backup=false
    local skip_backup_check=false
    local force=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --restore)
                restore_backup=true
                shift
                ;;
            --skip-backup)
                skip_backup_check=true
                shift
                ;;
            --force)
                force=true
                shift
                ;;
            -h|--help)
                print_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                print_usage
                exit 1
                ;;
        esac
    done

    print_welcome

    # Confirmation prompt
    if [ "$force" = false ]; then
        echo -e "${YELLOW}Warning:${NC} This will remove all symlinks created by the dotfiles installer."
        echo "Your original files (if any) will be lost unless you have a backup."
        echo ""

        # Check for backups
        if [ "$skip_backup_check" = false ]; then
            LATEST_BACKUP=$(find_latest_backup)
            if [ -n "$LATEST_BACKUP" ]; then
                log_info "Latest backup found: $LATEST_BACKUP"
                echo "You can restore from this backup by running with --restore flag."
                echo ""
            else
                log_warn "No backups found! Your original files will be lost."
                echo ""
            fi
        fi

        read -p "Are you sure you want to continue? (y/N): " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "Aborted."
            exit 0
        fi
    fi

    echo ""
    log_info "Removing symlinks..."
    echo ""

    # Remove all managed symlinks
    for file in "${MANAGED_FILES[@]}"; do
        # Skip SSH config.d includes as they may be user-created
        if [[ "$file" =~ \.d/ ]]; then
            log_info "Skipping (not managed): ~/$file"
            continue
        fi
        remove_symlink "$file"
    done

    echo ""
    log_info "Removing symlinked directories..."

    # Handle vim directory if symlinked
    if [ -L "$HOME/.vim" ]; then
        rm -rf "$HOME/.vim"
        log_success "Removed symlink: ~/.vim"
    fi

    # Handle config directories
    for dir in ".config/gh" ".config/direnv"; do
        target="$HOME/$dir"
        if [ -L "$target" ]; then
            rm -rf "$target"
            log_success "Removed symlink: ~/$dir"
        fi
    done

    echo ""

    # Restore from backup if requested
    if [ "$restore_backup" = true ]; then
        log_info "Restoring from backup..."
        echo ""

        LATEST_BACKUP=$(find_latest_backup)
        if [ -n "$LATEST_BACKUP" ] && [ -d "$LATEST_BACKUP" ]; then
            # Create temp file to store backup path for restore
            create_temp_backup_info() {
                local backup_id="$LATEST_BACKUP"
                echo "$backup_id" > /tmp/last_backup_info
            }

            create_temp_backup_info

            for file in "${MANAGED_FILES[@]}"; do
                restore_backup "$LATEST_BACKUP" "$file"
            done

            echo ""
            log_success "Restored from backup: $LATEST_BACKUP"
            log_info "If you want to restore more files manually:"
            echo "  ls $LATEST_BACKUP"
            echo "  cp $LATEST_BACKUP/<file> ~/..."
        else
            log_warn "No backup directory found at: $LATEST_BACKUP"
            if [ "$skip_backup_check" = false ]; then
                log_info "Available backups:"
                ls -la ${BACKUP_PREFIX}* 2>/dev/null || echo "  No backups found"
            fi
        fi
    fi

    echo ""
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    log_success "Uninstallation complete!"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo ""

    # Post-uninstallation notes
    echo "What you should do next:"
    echo "  1. If you removed symlinks to your shell config,"
    echo "     you may need to start a new shell:"
    echo "     exec zsh  # or exec bash"
    echo ""
    echo "  2. If you want to reinstall:"
    echo "     ./install.sh"
    echo ""
    echo "  3. If you want to restore backups:"
    echo "     ./uninstall.sh --restore"
    echo ""
}

# Run main function
main "$@"
