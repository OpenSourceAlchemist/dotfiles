# Symlink Reference Guide

This document provides a complete reference for all symlinks created by the dotfiles installation.

## Quick Overview

```
Repository Structure -> Home Directory Symlinks
```

The installation script (`install.sh`) creates symlinks from your home directory that point to files in this repository. This allows you to:
- Keep all configuration files version-controlled
- Maintain a single source of truth
- Easily sync across multiple machines
- Manage differences via local overrides (not committed)

## Complete Symlink Map

### Shell Configuration

| Home File | Repository Source | Shell | Description |
|------------|-------------------|-------|-------------|
| `~/.bashrc` | `bash/.bashrc` | Bash | Bash shell initialization |
| `~/.zshrc` | `zsh/.zshrc` | Zsh | Zsh shell initialization |
| `~/.inputrc` | `shell/.inputrc` | All | Readline key bindings |

### Editor Configuration

| Home File | Repository Source | Description |
|------------|-------------------|-------------|
| `~/.vimrc` | `vim/.vimrc` | Vim editor configuration |
| `~/.vim/` | `vim/` (directory) | Vim plugins/settings |

### Terminal Multiplexer

| Home File | Repository Source | Description |
|------------|-------------------|-------------|
| `~/.tmux.conf` | `tmux/.tmux.conf` | Tmux configuration |

### Version Control

| Home File | Repository Source | Description |
|------------|-------------------|-------------|
| `~/.gitconfig` | `git/.gitconfig` | Git global settings |
| `~/.gitignore_global` | `git/.gitignore_global` | Global Git ignore patterns |

### Secure Shell (SSH)

| Home File | Repository Source | Description |
|------------|-------------------|-------------|
| `~/.ssh/config` | `ssh/config` | SSH client configuration |

**Note:** The SSH config includes files from `~/.ssh/config.d/*`. Create machine-specific overrides there.

### Package/Version Managers

| Home File | Repository Source | Description |
|------------|-------------------|-------------|
| `~/.asdfrc` | `mise/.asdfrc` | mise (asf) configuration |

### Search Utilities

| Home File | Repository Source | Description |
|------------|-------------------|-------------|
| `~/.fzf.bash` | `fzf/.fzf.bash` | Fzf Bash integration |
| `~/.fzf.zsh` | `fzf/.fzf.zsh` | Fzf Zsh integration |

### Environment Management

| Home File | Repository Source | Description |
|------------|-------------------|-------------|
| `~/.config/gh/hosts.yml` | `*.yml` | GitHub CLI authentication |
| `~/.config/direnv/` | (user-defined) | direnv environment overrides |

## Local Override Files (Not Symlinked)

These files are intentionally **not** tracked by Git and should be created manually:

| File | Purpose | Example |
|------|---------|---------|
| `~/.ssh/config.d/home` | Machine-specific SSH settings | Host aliases, keys |
| `~/.dotfiles.local` | Global dotfile overrides | Personal variables |
| `~/.zshrc.local` | Zsh-specific overrides | Custom functions, aliases |
| `~/.bashrc.local` | Bash-specific overrides | Custom functions, aliases |

## Verification

To verify symlinks were created correctly:

```bash
# List all dotfiles symlinks
find ~ -maxdepth 1 -type l -name ".*" | grep -v ".git"

# Check specific symlinks
ls -la ~/.bashrc ~/.zshrc ~/.vimrc ~/.tmux.conf ~/.gitconfig ~/.ssh/config
```

To see where a symlink points:

```bash
readlink ~/.zshrc
# Output: /home/username/dotfiles/zsh/.zshrc
```

To test if symlinks are working:

```bash
# Verify shell config loads without errors
zsh -c 'source ~/.zshrc' && echo "Zsh config OK"
bash -c 'source ~/.bashrc' && echo "Bash config OK"
```

## Troubleshooting

### Symlink Already Exists

If `install.sh` fails because a file already exists:

```bash
# Option 1: Remove the existing file and rerun install
rm ~/.zshrc
./install.sh

# Option 2: Backup and create symlink
cp ~/.zshrc ~/.zshrc.backup
./install.sh
```

### Broken Symlinks

If you get "No such file or directory":

```bash
# Find broken symlinks
find ~ -maxdepth 1 -type l -exec test ! -e {} \; -print

# Remove and recreate
rm ~/.zshrc  # Example
./install.sh
```

### Permissions Issues

If you get permission errors:

```bash
# Ensure correct ownership
sudo chown $USER:$USER ~/.ssh/config
sudo chown $USER:$USER ~/.zshrc

# Verify permissions
chmod 600 ~/.ssh/config
chmod 644 ~/.zshrc
```

## Directory Structure

```
dotfiles/
├── bash/
│   └── .bashrc
├── zsh/
│   └── .zshrc
├── vim/
│   └── .vimrc
├── tmux/
│   └── .tmux.conf
├── git/
│   ├── .gitconfig
│   └── .gitignore_global
├── ssh/
│   └── config
├── mise/
│   └── .asdfrc
├── fzf/
│   ├── .fzf.bash
│   └── .fzf.zsh
└── install.sh
```

## Backup Location

When you run `install.sh`, existing files are backed up to:

```
~/.dotfiles_backup_YYYYMMDDHHMMSS/
├── .bashrc
├── .zshrc
├── .vimrc
└── ...
```

To restore from backup:

```bash
BACKUP_DIR=$(ls -d ~/.dotfiles_backup_* 2>/dev/null | sort | tail -1)
if [ -n "$BACKUP_DIR" ]; then
    cp "$BACKUP_DIR"/.zshrc ~
fi
```

## Summary Tables

### Complete Table by Category

| Category | Files | Symlinked | Overrides |
|----------|-------|---------------|-----------|
| Shell | 3 | Yes | `~/.zshrc.local`, `~/.bashrc.local` |
| Editor | 1 (+ vim/) | Yes | None |
| Terminal | 1 | Yes | None |
| Git | 1 (+ .gitignore_global) | Yes | None |
| SSH | 1 | Yes | `~/.ssh/config.d/*` |
| Version Mgmt | 1 | Yes | None |
| Search | 2 | Yes | None |
| Environment | 1+ | Partial | `~/.config/direnv/*` |

### File Access Pattern

When your shell starts:

1. Load base config from repository (e.g., `~/.zshrc` -> `dotfiles/zsh/.zshrc`)
2. Source local override if exists (`~/.zshrc.local`)
3. Execute tool-specific hooks (e.g., keychain, direnv)

---

**Need help?** See [INSTALL.md](INSTALL.md) for installation instructions or [Troubleshooting](INSTALL.md#troubleshooting) for common issues.
