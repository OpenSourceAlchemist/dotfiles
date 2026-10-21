#!/bin/bash
#
# This script creates symlinks from the home directory to the dotfiles in this repository.
# It also creates a backup of any existing dotfiles.
#
# IMPORTANT: Run ./bootstrap.sh first to install system dependencies!
#

set -e # Exit immediately if a command exits with a non-zero status.

# Directory configuration
DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d%H%M%S)"
MAX_BACKUPS="${MAX_BACKUPS:-5}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Component definitions
declare -A COMPONENT_FILES
COMPONENT_FILES[shell]="bash/.bashrc bash/.bash_profile shell/.profile zsh/.zshrc zsh/dotzsh/aliases:.dotzsh/aliases zsh/dotzsh/env:.dotzsh/env zsh/dotzsh/kaliases:.dotzsh/kaliases"
COMPONENT_FILES[editor]="vim/.vimrc"
COMPONENT_FILES[multiplexer]="tmux/.tmux.conf tmux/.tmux.conf.goodies"
COMPONENT_FILES[git]="git/.gitconfig"
COMPONENT_FILES[tools]="mise/.asdfrc mise/.tool-versions direnv/.envrc fzf/.fzf.bash fzf/.fzf.zsh terraform/.terraformrc Xorg/.Xdefaults ssh/config:.ssh/config dotconfig/gh/config.yml:.config/gh/config.yml dotconfig/gh/hosts.yml:.config/gh/hosts.yml dotconfig/openbox/rc.xml:.config/openbox/rc.xml"
COMPONENT_FILES[agents]="agy/statusline.sh:.gemini/antigravity-cli/statusline.sh agents/skills/skeptical-auditor/SKILL.md:.agents/skills/skeptical-auditor/SKILL.md agents/rules/skeptical-auditor.md:.agents/rules/skeptical-auditor.md pi/prompts/skeptical-audit.md:.pi/agent/prompts/skeptical-audit.md"

ALL_COMPONENTS=("shell" "editor" "multiplexer" "git" "tools" "agents")

# --- Helper Functions ---

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

print_usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Options:
    -i, --interactive       Prompt for each component to install
    -c, --component <name>  Install specific component(s) (comma-separated or repeatable):
                            [shell, editor, multiplexer, git, tools, agents, all]
    -p, --profile <name>    Apply environment profile (e.g., work, personal)
    -v, --verify            Verify symlinks, tools, and configs without installing
    --clean-backups [N]     Prune old backups keeping N most recent (default: 5)
    -h, --help              Show this help message

Default:
    Installs all components non-interactively.
EOF
}

# --- Hook Execution (Issue #23) ---

run_hooks() {
    local phase="$1"
    local hook_dirs=(
        "$DOTFILES_DIR/hooks/$phase"
        "$HOME/.dotfiles.hooks.d/$phase"
    )

    for dir in "${hook_dirs[@]}"; do
        if [ -d "$dir" ]; then
            for hook in "$dir"/*; do
                if [ -f "$hook" ] && [ -x "$hook" ]; then
                    log_info "Executing $phase hook: $(basename "$hook")..."
                    "$hook" || log_warn "Hook $hook exited with status $?"
                fi
            done
        fi
    done
}

# --- Backup Rotation (Issue #25) ---

rotate_backups() {
    local max="${1:-$MAX_BACKUPS}"
    local backup_dirs=()

    # Collect existing backup directories matching strict naming pattern
    while IFS= read -r dir; do
        [ -n "$dir" ] && [ -d "$dir" ] && backup_dirs+=("$dir")
    done < <(find "$HOME" -maxdepth 1 -type d -name ".dotfiles_backup_*" 2>/dev/null | sort)

    local total="${#backup_dirs[@]}"
    if [ "$total" -le "$max" ] || [ "$total" -le 1 ]; then
        log_info "Backups count ($total) within threshold ($max). No pruning needed."
        return 0
    fi

    local to_remove=$((total - max))
    log_info "Pruning $to_remove old backup(s) (retaining $max most recent)..."

    for ((i=0; i<to_remove; i++)); do
        local dir_to_delete="${backup_dirs[i]}"
        local dirname
        dirname="$(basename "$dir_to_delete")"

        # Safety check: ensure directory strictly matches backup naming pattern
        if [[ "$dirname" =~ ^\.dotfiles_backup_[0-9]{8,14}$ ]]; then
            log_info "  Removing old backup: $dir_to_delete"
            rm -rf "$dir_to_delete"
        else
            log_warn "  Skipping unexpected directory name: $dir_to_delete"
        fi
    done
}

# --- Profile Support (Issue #24) ---

apply_profile() {
    local profile="$1"
    if [ -z "$profile" ]; then
        return 0
    fi

    if [[ ! "$profile" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        log_error "Invalid profile name '$profile'. Only letters, numbers, hyphens, and underscores are allowed."
        exit 1
    fi

    local profile_dir="$DOTFILES_DIR/profiles/$profile"
    if [ ! -d "$profile_dir" ]; then
        log_error "Profile '$profile' does not exist in $DOTFILES_DIR/profiles/"
        echo "Available profiles:"
        ls -1 "$DOTFILES_DIR/profiles" 2>/dev/null || echo "  (none)"
        exit 1
    fi

    log_info "Applying profile: $profile..."
    if [ -f "$profile_dir/gitconfig" ]; then
        create_symlink "profiles/$profile/gitconfig" ".gitconfig.local"
    fi
    if [ -f "$profile_dir/dotfiles.local" ]; then
        create_symlink "profiles/$profile/dotfiles.local" ".dotfiles.local"
    fi
}

# --- Ensure Antigen (Issue #16) ---

ensure_antigen() {
    local antigen_paths=(
        "${ANTIGEN_PATH:-}"
        "$HOME/.antigen/antigen.zsh"
        "$HOME/.local/share/antigen/antigen.zsh"
        "$HOME/.zsh/antigen/zsh-antigen/antigen.zsh"
        "/usr/share/zsh-antigen/antigen.zsh"
        "/usr/local/share/zsh-antigen/antigen.zsh"
        "${HOMEBREW_PREFIX:-}/share/antigen/antigen.zsh"
    )
    for p in "${antigen_paths[@]}"; do
        if [ -n "$p" ] && [ -f "$p" ]; then
            return 0
        fi
    done

    log_info "Antigen not detected. Downloading to ~/.antigen/antigen.zsh..."
    mkdir -p "$HOME/.antigen"
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL --connect-timeout 5 --max-time 15 "https://raw.githubusercontent.com/zsh-users/antigen/master/bin/antigen.zsh" -o "$HOME/.antigen/antigen.zsh" 2>/dev/null || true
    elif command -v wget >/dev/null 2>&1; then
        wget -q --timeout=15 --tries=1 -O "$HOME/.antigen/antigen.zsh" "https://raw.githubusercontent.com/zsh-users/antigen/master/bin/antigen.zsh" 2>/dev/null || true
    fi
}

# --- Symlink Creation ---

create_symlink() {
    local repo_path="$1"
    local home_path="$2"
    local source_file="$DOTFILES_DIR/$repo_path"
    local target_file="$HOME/$home_path"

    # Create backup directory lazily on first backup
    if [ -e "$target_file" ] || [ -L "$target_file" ]; then
        # Check if it's already a symlink pointing to the correct file
        if [ -L "$target_file" ] && [ "$(readlink "$target_file")" == "$source_file" ]; then
            echo "  Skipping, correct symlink already exists: $target_file"
            return
        fi
        mkdir -p "$BACKUP_DIR"
        echo "  Backing up existing file: $target_file -> $BACKUP_DIR/$home_path"
        mkdir -p "$(dirname "$BACKUP_DIR/$home_path")"
        mv "$target_file" "$BACKUP_DIR/$home_path"
    fi

    echo "  Creating symlink: $target_file -> $source_file"
    mkdir -p "$(dirname "$target_file")"
    ln -s "$source_file" "$target_file"
}

# --- Agent Configurations (Issue #3 & Antigravity) ---

configure_agy() {
    local agy_settings="$HOME/.gemini/antigravity-cli/settings.json"
    local agy_statusline_cmd="$HOME/.gemini/antigravity-cli/statusline.sh"
    mkdir -p "$(dirname "$agy_settings")"

    if [ ! -f "$agy_settings" ]; then
        log_info "Creating initial $agy_settings with statusLine configuration..."
        cat > "$agy_settings" <<EOF
{
  "statusLine": {
    "type": "",
    "command": "$agy_statusline_cmd",
    "enabled": true
  }
}
EOF
        chmod 600 "$agy_settings"
    elif command -v jq &> /dev/null; then
        log_info "Updating statusLine configuration in $agy_settings..."
        local tmp_settings
        tmp_settings="$(mktemp)"
        jq --arg cmd "$agy_statusline_cmd" '.statusLine = {"type": "", "command": $cmd, "enabled": true}' "$agy_settings" > "$tmp_settings" && mv "$tmp_settings" "$agy_settings"
        chmod 600 "$agy_settings"
    elif command -v python3 &> /dev/null; then
        log_info "Updating statusLine configuration in $agy_settings..."
        python3 - "$agy_settings" "$agy_statusline_cmd" <<'PYEOF'
import json, os, sys
path, cmd = sys.argv[1], sys.argv[2]
try:
    with open(path, "r") as f:
        data = json.load(f)
except Exception:
    data = {}
data["statusLine"] = {"type": "", "command": cmd, "enabled": True}
with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
os.chmod(path, 0o600)
PYEOF
    fi
}

configure_pi_agent() {
    local pi_dir="$HOME/.pi/agent"
    mkdir -p "$pi_dir"

    # Merge or copy settings.json
    local pi_settings="$pi_dir/settings.json"
    local src_settings="$DOTFILES_DIR/pi/settings.json"
    if [ -f "$src_settings" ]; then
        if [ ! -f "$pi_settings" ]; then
            log_info "Creating initial $pi_settings..."
            cp "$src_settings" "$pi_settings"
            chmod 600 "$pi_settings"
        elif command -v python3 &> /dev/null; then
            log_info "Merging non-sensitive settings in $pi_settings..."
            python3 - "$pi_settings" "$src_settings" <<'PYEOF'
import json, os, sys
dest_path, src_path = sys.argv[1], sys.argv[2]
try:
    with open(dest_path, "r") as f:
        dest = json.load(f)
except Exception:
    dest = {}
try:
    with open(src_path, "r") as f:
        src = json.load(f)
except Exception:
    src = {}
# Merge keys from src if not set or default
for k in ["defaultModel", "defaultProvider", "defaultThinkingLevel", "packages", "extensions", "theme"]:
    if k in src and (k not in dest or not dest[k]):
        dest[k] = src[k]
with open(dest_path, "w") as f:
    json.dump(dest, f, indent=2)
    f.write("\n")
os.chmod(dest_path, 0o600)
PYEOF
        fi
    fi

    # Merge or copy models.json without overwriting private API keys
    local pi_models="$pi_dir/models.json"
    local src_models="$DOTFILES_DIR/pi/models.json"
    if [ -f "$src_models" ]; then
        if [ ! -f "$pi_models" ]; then
            log_info "Creating initial $pi_models..."
            cp "$src_models" "$pi_models"
            chmod 600 "$pi_models"
        elif command -v python3 &> /dev/null; then
            log_info "Merging provider models in $pi_models without overriding secrets..."
            python3 - "$pi_models" "$src_models" <<'PYEOF'
import json, os, sys
dest_path, src_path = sys.argv[1], sys.argv[2]
try:
    with open(dest_path, "r") as f:
        dest = json.load(f)
except Exception:
    dest = {"providers": {}}
try:
    with open(src_path, "r") as f:
        src = json.load(f)
except Exception:
    src = {"providers": {}}
if "providers" not in dest:
    dest["providers"] = {}
for prov, prov_data in src.get("providers", {}).items():
    if prov not in dest["providers"]:
        dest["providers"][prov] = prov_data
    else:
        # Preserve existing apiKey while updating/adding models
        existing_key = dest["providers"][prov].get("apiKey")
        for k, v in prov_data.items():
            if k == "apiKey" and existing_key:
                continue
            dest["providers"][prov][k] = v
with open(dest_path, "w") as f:
    json.dump(dest, f, indent=2)
    f.write("\n")
os.chmod(dest_path, 0o600)
PYEOF
        fi
    fi
}

# --- Shell Switching Prompt (Issue #13) ---

prompt_shell_change() {
    local current_shell
    current_shell="$(basename "${SHELL:-}")"

    if [ "$current_shell" == "zsh" ]; then
        return 0
    fi

    echo ""
    log_info "Current default login shell is '$current_shell'."

    # Skip interactive prompt if not a TTY or in automated/CI environment
    if [ ! -t 0 ] || [ -n "${CI:-}" ] || [ -n "${BATS_TEST_FILENAME:-}" ] || [ -n "${DEBIAN_FRONTEND:-}" ] || [ -n "${NONINTERACTIVE:-}" ]; then
        log_info "Non-interactive or automated environment detected. To switch to zsh later, run: chsh -s \$(which zsh)"
        return 0
    fi

    read -r -p "Would you like to switch your default login shell to zsh? [y/N]: " change_shell
    if [[ "$change_shell" =~ ^[Yy]$ ]]; then
        local zsh_path
        zsh_path="$(command -v zsh 2>/dev/null || true)"
        if [ -n "$zsh_path" ]; then
            log_info "Changing shell to $zsh_path..."
            chsh -s "$zsh_path" || log_warn "chsh failed. You can change manually with: chsh -s $zsh_path"
        else
            log_warn "zsh binary not found. Please install zsh first."
        fi
    fi
}

# --- Installation Verification (Issue #12) ---

verify_installation() {
    local target_components=("$@")
    if [ ${#target_components[@]} -eq 0 ]; then
        target_components=("${ALL_COMPONENTS[@]}")
    fi

    local failures=0
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  ${GREEN}Dotfiles Verification (--verify)${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════${NC}"
    echo ""

    echo "1. Checking Symlinks:"
    echo "-------------------"
    for comp in "${target_components[@]}"; do
        for item in ${COMPONENT_FILES[$comp]}; do
            local repo_path="${item%%:*}"
            local home_path="${item##*:}"
            if [ "$repo_path" == "$home_path" ]; then
                local base="${repo_path##*/}"
                if [[ "$base" == .* ]]; then
                    home_path="$base"
                else
                    home_path=".$base"
                fi
            fi

            local target_file="$HOME/$home_path"
            local source_file="$DOTFILES_DIR/$repo_path"

            if [ -L "$target_file" ]; then
                local actual_target
                actual_target="$(readlink "$target_file")"
                if [ "$actual_target" == "$source_file" ]; then
                    echo -e "  ${GREEN}✓${NC} ~/$home_path -> $repo_path"
                else
                    echo -e "  ${RED}✗${NC} ~/$home_path -> $actual_target (expected: $source_file)"
                    failures=$((failures + 1))
                fi
            elif [ -e "$target_file" ]; then
                echo -e "  ${YELLOW}⚠${NC} ~/$home_path exists but is NOT a symlink"
                failures=$((failures + 1))
            else
                echo -e "  ${RED}✗${NC} ~/$home_path does not exist"
                failures=$((failures + 1))
            fi
        done
    done

    echo ""
    echo "2. Checking Required Dependencies:"
    echo "--------------------------------"
    local check_tools=("zsh" "vim" "tmux" "git")
    for tool in "${check_tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            echo -e "  ${GREEN}✓${NC} $tool is available ($(command -v "$tool"))"
        else
            echo -e "  ${RED}✗${NC} $tool is MISSING"
            failures=$((failures + 1))
        fi
    done

    echo ""
    echo "3. Checking Shell Configuration Syntax:"
    echo "--------------------------------------"
    if command -v bash &> /dev/null && [ -f "$HOME/.bashrc" ]; then
        if bash -n "$HOME/.bashrc" 2>/dev/null; then
            echo -e "  ${GREEN}✓${NC} ~/.bashrc syntax is valid"
        else
            echo -e "  ${RED}✗${NC} ~/.bashrc has syntax errors"
            failures=$((failures + 1))
        fi
    fi

    if command -v zsh &> /dev/null && [ -f "$HOME/.zshrc" ]; then
        if zsh -n "$HOME/.zshrc" 2>/dev/null; then
            echo -e "  ${GREEN}✓${NC} ~/.zshrc syntax is valid"
        else
            echo -e "  ${RED}✗${NC} ~/.zshrc has syntax errors"
            failures=$((failures + 1))
        fi
    fi

    echo ""
    if [ "$failures" -eq 0 ]; then
        log_success "All verification checks passed!"
        return 0
    else
        log_error "Verification completed with $failures issue(s)."
        return 1
    fi
}

# --- Main Script ---

main() {
    local interactive=false
    local verify_only=false
    local selected_components=()
    local profile="${DOTFILES_PROFILE:-}"
    local clean_backups_only=false
    local clean_backups_count="$MAX_BACKUPS"

    # Argument parsing
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -i|--interactive)
                interactive=true
                shift
                ;;
            -c|--component)
                if [ -n "$2" ] && [[ "$2" != -* ]]; then
                    IFS=',' read -ra ADDR <<< "$2"
                    for comp in "${ADDR[@]}"; do
                        selected_components+=("$comp")
                    done
                    shift 2
                else
                    log_error "Option --component requires an argument."
                    print_usage
                    exit 1
                fi
                ;;
            --component=*)
                IFS=',' read -ra ADDR <<< "${1#*=}"
                for comp in "${ADDR[@]}"; do
                    selected_components+=("$comp")
                done
                shift
                ;;
            -p|--profile)
                if [ -n "$2" ] && [[ "$2" != -* ]]; then
                    profile="$2"
                    shift 2
                else
                    log_error "Option --profile requires an argument."
                    print_usage
                    exit 1
                fi
                ;;
            --profile=*)
                profile="${1#*=}"
                shift
                ;;
            -v|--verify)
                verify_only=true
                shift
                ;;
            --clean-backups)
                clean_backups_only=true
                if [ -n "$2" ] && [[ "$2" =~ ^[0-9]+$ ]]; then
                    clean_backups_count="$2"
                    shift 2
                else
                    shift
                fi
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

    # Clean backups mode
    if [ "$clean_backups_only" = true ]; then
        rotate_backups "$clean_backups_count"
        exit 0
    fi

    # Verification mode
    if [ "$verify_only" = true ]; then
        verify_installation "${selected_components[@]}"
        exit $?
    fi

    # Interactive component selection (Issue #11)
    if [ "$interactive" = true ]; then
        echo ""
        echo -e "${BLUE}Interactive Component Selection${NC}"
        echo "Select which configuration components to install:"
        echo ""
        selected_components=()
        for comp in "${ALL_COMPONENTS[@]}"; do
            read -r -p "Install $comp configurations? [Y/n]: " ans
            if [[ -z "$ans" || "$ans" =~ ^[Yy]$ ]]; then
                selected_components+=("$comp")
            fi
        done
        if [ ${#selected_components[@]} -eq 0 ]; then
            log_warn "No components selected. Exiting."
            exit 0
        fi
    fi

    # If no specific components selected, default to all
    if [ ${#selected_components[@]} -eq 0 ]; then
        selected_components=("${ALL_COMPONENTS[@]}")
    else
        # Handle "all" keyword
        for c in "${selected_components[@]}"; do
            if [ "$c" == "all" ]; then
                selected_components=("${ALL_COMPONENTS[@]}")
                break
            fi
        done
    fi

    # Validate selected components
    for comp in "${selected_components[@]}"; do
        if [ -z "${COMPONENT_FILES[$comp]+x}" ]; then
            log_error "Unknown component: '$comp'. Valid options: ${ALL_COMPONENTS[*]}, all"
            exit 1
        fi
    done

    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  ${GREEN}Dotfiles Installer${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════${NC}"
    echo "Selected components: ${selected_components[*]}"
    [ -n "$profile" ] && echo "Active profile: $profile"
    echo ""

    # Pre-install hook (Issue #23)
    run_hooks "pre-install"

    # Dependency & Antigen checks
    ensure_antigen

    # Symlinking selected components
    log_info "Creating symlinks..."
    for comp in "${selected_components[@]}"; do
        for item in ${COMPONENT_FILES[$comp]}; do
            local repo_path="${item%%:*}"
            local home_path="${item##*:}"
            if [ "$repo_path" == "$home_path" ]; then
                local base="${repo_path##*/}"
                if [[ "$base" == .* ]]; then
                    home_path="$base"
                else
                    home_path=".$base"
                fi
            fi
            create_symlink "$repo_path" "$home_path"
        done
    done

    # Component-specific initializers
    for comp in "${selected_components[@]}"; do
        if [ "$comp" == "agents" ]; then
            configure_agy
            configure_pi_agent
        fi
    done

    # Apply environment profile if requested (Issue #24)
    if [ -n "$profile" ]; then
        apply_profile "$profile"
    fi

    # Post-install hook (Issue #23)
    run_hooks "post-install"

    # Backup rotation (Issue #25)
    rotate_backups "$MAX_BACKUPS"

    echo ""
    log_success "Dotfiles installation complete!"
    [ -d "$BACKUP_DIR" ] && echo "Backed up existing files to $BACKUP_DIR"

    # Shell switching prompt (Issue #13)
    prompt_shell_change

    echo ""
    echo "You may need to restart your shell (e.g., 'exec zsh' or 'source ~/.bashrc') for changes to take effect."
}

main "$@"
