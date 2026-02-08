#!/bin/bash
#
# This script creates symlinks from the home directory to the dotfiles in this repository.
# It also creates a backup of any existing dotfiles.

set -e # Exit immediately if a command exits with a non-zero status.

# The directory where this script is located
DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d%H%M%S)"

# --- Dependency Checking ---
echo "Checking for dependencies..."
DEPS=("zsh" "vim" "tmux" "git" "fzf" "direnv" "terraform" "gh" "asdf")
MISSING_DEPS=()
HAS_WARNING=0

for dep in "${DEPS[@]}"; do
  if ! command -v "$dep" &> /dev/null; then
    MISSING_DEPS+=("$dep")
  else
    echo "  -> Found '$dep'."
  fi
done

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
  if [ -f /etc/debian_version ]; then
    echo "Debian-based system detected. Attempting to install missing dependencies..."
    PKGS=()
    for dep in "${MISSING_DEPS[@]}"; do
      case "$dep" in
        "gh") PKGS+=("github-cli") ;;
        "asdf") echo "  -> Warning: 'asdf' requires manual installation. Skipping auto-install." ; HAS_WARNING=1 ;;
        *) PKGS+=("$dep") ;;
      esac
    done
    if [ ${#PKGS[@]} -gt 0 ]; then
      sudo apt-get update && sudo apt-get install -y "${PKGS[@]}" || HAS_WARNING=1
    fi
  elif [ -f /etc/alpine-release ]; then
    echo "Alpine-based system detected. Attempting to install missing dependencies..."
    PKGS=()
    for dep in "${MISSING_DEPS[@]}"; do
      case "$dep" in
        "gh") PKGS+=("github-cli") ;;
        "asdf") echo "  -> Warning: 'asdf' requires manual installation. Skipping auto-install." ; HAS_WARNING=1 ;;
        *) PKGS+=("$dep") ;;
      esac
    done
    if [ ${#PKGS[@]} -gt 0 ]; then
      sudo apk add "${PKGS[@]}" || HAS_WARNING=1
    fi
  else
    for dep in "${MISSING_DEPS[@]}"; do
      echo "  -> Warning: '$dep' is not installed. Some configurations may not work."
    done
    echo "Please install missing dependencies manually for your platform."
    HAS_WARNING=1
  fi
fi

if [ "$HAS_WARNING" -eq 1 ]; then
    echo "Some dependencies could not be automatically installed. Please check the output above."
    echo ""
fi
# --- End Dependency Checking ---


# List of files/directories to symlink
# The format is "repo_path:home_path"
# If home_path is omitted, it's assumed to be the same as the repo_path, prefixed with a dot.
declare -a FILES_TO_SYMLINK=(
    "bash/.bashrc"
    "bash/.bash_profile"
    "shell/.profile"
    "zsh/.zshrc"
    "vim/.vimrc"
    "git/.gitconfig"
    "tmux/.tmux.conf"
    "tmux/.tmux.conf.goodies"
    "asdf/.asdfrc"
    "asdf/.tool-versions"
    "direnv/.envrc"
    "fzf/.fzf.bash"
    "fzf/.fzf.zsh"
    "terraform/.terraformrc"
    "Xorg/.Xdefaults"
    "ssh/config:.ssh/config" # Note: target path is .ssh/config
    "dotconfig/gh/config.yml:.config/gh/config.yml"
    "dotconfig/gh/hosts.yml:.config/gh/hosts.yml"
    "dotconfig/openbox/rc.xml:.config/openbox/rc.xml"
    "zsh/dotzsh/aliases:.dotzsh/aliases"
    "zsh/dotzsh/env:.dotzsh/env"
    "zsh/dotzsh/kaliases:.dotzsh/kaliases"
)

echo "Creating backup directory at $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# Function to create a symlink, backing up the original file if it exists
create_symlink() {
    local repo_path="$1"
    local home_path="$2"
    local source_file="$DOTFILES_DIR/$repo_path"
    local target_file="$HOME/$home_path"

    # Create backup if target exists and is not already a symlink to the correct file
    if [ -e "$target_file" ] || [ -L "$target_file" ]; then
        # Check if it's a symlink pointing to the correct file already
        if [ -L "$target_file" ] && [ "$(readlink "$target_file")" == "$source_file" ]; then
            echo "Skipping, correct symlink already exists: $target_file"
            return
        fi
        echo "Backing up existing file: $target_file -> $BACKUP_DIR"
        # Ensure backup directory exists for the specific file path
        mkdir -p "$(dirname "$BACKUP_DIR/$home_path")"
        mv "$target_file" "$BACKUP_DIR/$home_path"
    fi

    echo "Creating symlink: $target_file -> $source_file"
    # Ensure the target directory exists
    mkdir -p "$(dirname "$target_file")"
    ln -s "$source_file" "$target_file"
}

echo ""
echo "Starting dotfiles symlinking process..."
# Loop through the files and create symlinks
for item in "${FILES_TO_SYMLINK[@]}"; do
    repo_path="${item%%:*}"
    home_path="${item##*:}"

    # If home_path is the same as repo_path, it means we use the default naming convention
    if [ "$repo_path" == "$home_path" ]; then
        # e.g., "bash/.bashrc" becomes ".bashrc"
        home_path=".${repo_path##*/}"
    fi

    create_symlink "$repo_path" "$home_path"
done

echo ""
echo "Dotfiles installation complete!"
echo "Backed up old files to $BACKUP_DIR"
echo "You may need to restart your shell (e.g., 'exec zsh' or 'source ~/.bashrc') for changes to take effect."

