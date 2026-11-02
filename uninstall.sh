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

# --- Helper Functions ---

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# --- Configuration ---

DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

MANAGED_FILES=(
    ".bashrc"
    ".bash_profile"
    ".profile"
    ".zshrc"
    ".amrc"
    ".dotzsh/aliases"
    ".dotzsh/env"
    ".dotzsh/kaliases"
    ".vimrc"
    ".tmux.conf"
    ".tmux.conf.goodies"
    ".gitconfig"
    ".gitconfig.local"
    ".dotfiles.local"
    ".asdfrc"
    ".tool-versions"
    ".envrc"
    ".fzf.bash"
    ".fzf.zsh"
    ".terraformrc"
    ".Xdefaults"
    ".ssh/config"
    ".config/openbox/rc.xml"
    ".gemini/antigravity-cli/statusline.sh"
    ".agents/skills/skeptical-auditor/SKILL.md"
    ".agents/rules/skeptical-auditor.md"
    ".pi/agent/prompts/skeptical-audit.md"
)

BACKUP_PREFIX=~/.dotfiles_backup_

# --- Functions ---

find_latest_backup() {
    # Sort backups in reverse chronological order
    find "$HOME" -maxdepth 1 -type d -name ".dotfiles_backup_*" 2>/dev/null | sort -r | head -1
}

remove_symlink() {
    local file="$1"
    local target="$HOME/$file"

    if [ -L "$target" ]; then
        rm -f "$target"
        log_success "Removed symlink: ~/$file"
    elif [ -f "$target" ]; then
        log_warn "Not a symlink: ~/$file (skipping to protect local file)"
    else
        log_info "Does not exist: ~/$file"
    fi
}

cleanup_legacy_symlinks() {
    local target_dir="${1:-$HOME}"
    local dotfiles_root="${2:-$DOTFILES_DIR}"
    local canonical_repo
    canonical_repo="$(cd "$dotfiles_root" 2>/dev/null && pwd -P || echo "$dotfiles_root")"

    while IFS= read -r link; do
        [ -z "$link" ] && continue
        if [ -L "$link" ]; then
            local base
            base="$(basename "$link")"
            if [[ "$base" == ..* && "$base" != ".." ]]; then
                local dest
                dest="$(readlink "$link" 2>/dev/null || true)"
                local canonical_dest
                canonical_dest="$(readlink -f "$link" 2>/dev/null || true)"
                if [[ "$dest" == "$dotfiles_root"* ]] || { [ -n "$canonical_dest" ] && [[ "$canonical_dest" == "$canonical_repo"* ]]; }; then
                    rm -f "$link"
                    log_success "Removed legacy duplicate symlink: ~/$base"
                fi
            fi
        fi
    done < <(find "$target_dir" -maxdepth 1 -name "..*" -type l 2>/dev/null)

    # Clean deprecated GitHub CLI symlinks that point into dotfiles
    for deprecated_gh in "$target_dir/.config/gh/hosts.yml" "$target_dir/.config/gh/config.yml"; do
        if [ -L "$deprecated_gh" ]; then
            local dest
            dest="$(readlink "$deprecated_gh" 2>/dev/null || true)"
            local canonical_dest
            canonical_dest="$(readlink -f "$deprecated_gh" 2>/dev/null || true)"
            if [[ "$dest" == "$dotfiles_root"* ]] || { [ -n "$canonical_dest" ] && [[ "$canonical_dest" == "$canonical_repo"* ]]; }; then
                rm -f "$deprecated_gh"
                log_success "Removed deprecated gh config symlink: $deprecated_gh"
            fi
        fi
    done
}

restore_backup() {
    local backup_dir="$1"
    local file="$2"
    local src="$backup_dir/$file"
    local dst="$HOME/$file"

    if [ -e "$src" ] || [ -L "$src" ]; then
        mkdir -p "$(dirname "$dst")"
        cp -a "$src" "$dst"
        log_success "Restored: ~/$file from backup"
    else
        log_info "No backup found for: ~/$file"
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
    -f, --force       Remove without interactive confirmation
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
            -f|--force)
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

    # Interactive confirmation prompt (skip if --force or non-interactive/CI)
    if [ "$force" = false ]; then
        if [ ! -t 0 ] || [ -n "${CI:-}" ] || [ -n "${BATS_TEST_FILENAME:-}" ] || [ -n "${NONINTERACTIVE:-}" ]; then
            log_info "Non-interactive environment detected, proceeding with uninstallation..."
        else
            echo -e "${YELLOW}Warning:${NC} This will remove all symlinks created by the dotfiles installer."
            echo ""

            if [ "$skip_backup_check" = false ]; then
                local latest
                latest="$(find_latest_backup)"
                if [ -n "$latest" ]; then
                    log_info "Latest backup found: $latest"
                    echo "You can restore from this backup by running with --restore flag."
                    echo ""
                else
                    log_warn "No backups found."
                    echo ""
                fi
            fi

            read -r -p "Are you sure you want to continue? (y/N): " confirm
            if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
                echo "Aborted."
                exit 0
            fi
        fi
    fi

    echo ""
    log_info "Removing symlinks..."
    echo ""

    # Remove all managed symlinks
    for file in "${MANAGED_FILES[@]}"; do
        remove_symlink "$file"
    done

    # Remove legacy duplicate symlinks if present
    cleanup_legacy_symlinks "$HOME" "$DOTFILES_DIR"

    # Clean up empty parent directories if created by dotfiles
    for dir in ".dotzsh" ".agents/skills/skeptical-auditor" ".agents/rules" ".pi/agent/prompts"; do
        if [ -d "$HOME/$dir" ] && [ ! "$(ls -A "$HOME/$dir" 2>/dev/null)" ]; then
            rmdir -p "$HOME/$dir" 2>/dev/null || true
        fi
    done

    # Restore from backup if requested
    if [ "$restore_backup" = true ]; then
        echo ""
        log_info "Restoring from backup..."
        echo ""

        local latest_backup
        latest_backup="$(find_latest_backup)"
        if [ -n "$latest_backup" ] && [ -d "$latest_backup" ]; then
            # Restore all files found in backup directory
            while IFS= read -r rel_file; do
                restore_backup "$latest_backup" "$rel_file"
            done < <(cd "$latest_backup" && find . -type f 2>/dev/null | sed 's|^\./||')

            echo ""
            log_success "Restored from backup: $latest_backup"
        else
            log_warn "No backup directory found matching $BACKUP_PREFIX*"
        fi
    fi

    echo ""
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    log_success "Uninstallation complete!"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo ""
}

main "$@"
