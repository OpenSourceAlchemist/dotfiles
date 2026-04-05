# Dotfiles Installation Guide

This guide walks you through installing these dotfiles on a fresh system.

## Table of Contents

- [Overview](#overview)
- [Requirements](#requirements)
- [Quick Start](#quick-start)
- [Detailed Installation](#detailed-installation)
- [Post-Installation](#post-installation)
- [Uninstallation](#uninstallation)
- [Troubleshooting](#troubleshooting)
- [Customization](#customization)

---

## Overview

This repository contains configuration files (dotfiles) for:

| Category | Tools |
|----------|-------|
| **Shell** | zsh, bash, keychain |
| **Editor** | vim |
| **Terminal** | tmux, rxvt-unicode |
| **Tools** | git, fzf, direnv, mise, OpenTofu, gh |
| **X11** | Xorg, Openbox |
| **SSH** | ssh client configuration |

---

## Requirements

### Operating System Support

| OS | Support Level | Package Manager |
|------|----|--|
| Debian/Ubuntu | Full | `apt`, `apt-get` |
| Fedora/RHEL/CentOS/Rocky | Full | `dnf`, `yum` |
| Alpine Linux | Full | `apk` |
| macOS | Full | `brew` |
| Arch Linux | Partial | `pacman` (manual setup may be needed) |

### Network Requirements

- Internet connection for package installation
- SSH access for private repository tools (if applicable)

### Manual Installation (Optional)

If automated installation fails, ensure these packages are installed before proceeding:

```bash
# Required (minimum)
zsh vim tmux git rsync bzip2 keychain xclip mosh

# Optional (recommended)
fzf direnv mise opentofu gh
```

---

## Quick Start

The fastest way to install:

```bash
# 1. Clone the repository
git clone https://github.com/YOUR_USERNAME/dotfiles.git
cd dotfiles

# 2. Install system dependencies
./bootstrap.sh

# 3. Create symlinks to dotfiles
./install.sh

# 4. Restart your shell or reboot
exec zsh
```

---

## Detailed Installation

### Step 1: Clone the Repository

```bash
# Using HTTPS
git clone https://github.com/YOUR_USERNAME/dotfiles.git
cd dotfiles

# Or using SSH
git clone git@github.com:YOUR_USERNAME/dotfiles.git
cd dotfiles
```

### Step 2: Install System Dependencies

Run the bootstrap script to automatically install all required packages:

```bash
./bootstrap.sh
```

The script will:
- Detect your operating system
- Install required system packages
- Offer to install optional tools (mise, fzf, direnv, opentofu, gh)
- Install zsh-antigen for zsh plugin management

**If the script fails** or your OS is not detected, install dependencies manually:

```bash
# Debian/Ubuntu
sudo apt-get update
sudo apt-get install -y zsh vim tmux git rsync bzip2 keychain xclip mosh

# Fedora/RHEL/CentOS
sudo dnf install -y zsh vim-enhanced tmux git rsync bzip2 keychain xclip mosh

# Alpine
sudo apk add zsh vim tmux git rsync bzip2 keychain xclip mosh

# macOS (with Homebrew)
brew install zsh vim tmux git rsync mosh fzf
```

### Step 3: Install Optional Tools

Some tools may need manual installation:

#### mise (asf replacement)

```bash
curl https://mise.run | sh
export PATH="$HOME/.local/bin:$PATH"
```

#### fzf

```bash
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install
```

#### direnv

```bash
# Or use your package manager
curl -sfL https://direnv.net/install.sh | bash
```

#### OpenTofu (terraform-compatible IaC tool)

```bash
# Use your package manager or download from:
# https://opentofu.org/docs/intro/install/
```

#### GitHub CLI (gh)

```bash
# Use your package manager or:
# https://cli.github.com/
```

### Step 4: Create Symlinks

Run the installation script to symlink dotfiles:

```bash
./install.sh
```

This will:
- Check for missing dependencies
- Back up any existing dotfiles to `~/.dotfiles_backup_YYYYMMDDHHMMSS`
- Create symlinks from your home directory to this repository

**What gets symlinked:**

| Home File | Source |
|-----------|--------|
| `~/.bashrc` | `bash/.bashrc` |
| `~/.zshrc` | `zsh/.zshrc` |
| `~/.vimrc` | `vim/.vimrc` |
| `~/.tmux.conf` | `tmux/.tmux.conf` |
| `~/.gitconfig` | `git/.gitconfig` |
| `~/.ssh/config` | `ssh/config` |
| `~/.asdfrc` | `mise/.asdfrc` |
| `~/.fzf.bash` | `fzf/.fzf.bash` |
| ... and more | See `install.sh` for full list |

### Step 5: Change Your Shell (Optional)

If you're switching to zsh:

```bash
chsh -s $(which zsh)
```

Log out and log back in for the change to take effect.

---

## Post-Installation

### 1. Verify Installation

```bash
# Check symlinks are correct
ls -la ~/.zshrc ~/.bashrc ~/.vimrc ~/.tmux.conf

# Verify tools are accessible
which zsh git vim tmux

# Test fzf
zsh -c 'zle -I && fzf'

# Test direnv
direnv version
```

### 2. Configure SSH

Edit your SSH config to match your machine:

```bash
# Add your internal SSH configurations
mkdir -p ~/.ssh/config.d
nano ~/.ssh/config.d/home
```

**Important:** The `config.d/home` file is excluded from the repository. Add machine-specific settings there.

### 3. Set Personal Variables

Customize your shell by creating a local override file:

```bash
# Create local overrides (not tracked by Git)
cp ~/.zshrc ~/.zshrc.local
nano ~/.zshrc.local
```

### 4. Configure mise

```bash
# Set up your tools and versions
mise use node@18
mise use python@3.11
```

### 5. Enable Directory Permissions

Ensure directories exist with correct ownership:

```bash
mkdir -p ~/.config/gh
mkdir -p ~/.dotzsh
mkdir -p ~/.ssh/config.d
```

---

## Uninstallation

To remove dotfiles and restore original files:

```bash
# Run the uninstall script
./uninstall.sh
```

The uninstall script will:
- Remove all symlinks
- Restore backed-up files (if available)
- Clean up created directories

### Manual Uninstall (if script unavailable)

```bash
# Remove symlinks
rm -f ~/.bashrc ~/.zshrc ~/.vimrc ~/.tmux.conf ~/.gitconfig
rm -f ~/.fzf.bash ~/.fzf.zsh ~/.asdfrc
rm -f ~/.ssh/config ~/.config/gh/*.yml

# Restore from backup (if exists)
BACKUP_DIR=$(ls -d ~/.dotfiles_backup_* 2>/dev/null | head -1)
if [ -n "$BACKUP_DIR" ]; then
  cp -r "$BACKUP_DIR/"* ~
  rm -rf "$BACKUP_DIR"
fi
```

---

## Troubleshooting

### Common Issues

#### 1. "command not found" after installation

**Problem:** Shell doesn't recognize installed commands

**Solution:**
```bash
# Ensure PATH is correct
echo $PATH

# Restart your shell
exec zsh
# or log out and back in
```

#### 2. zsh shows "antigen not found"

**Problem:** zsh-antigen not installed correctly

**Solutions:**
```bash
# Check antigen location
ls -la /usr/share/zsh-antigen/antigen.zsh
ls -la ~/.zsh/antigen/zsh-antigen/antigen.zsh

# Install manually if missing
mkdir -p ~/.zsh
git clone --depth 1 https://github.com/zsh-users/antigen ~/.zsh/antigen/zsh-antigen
```

#### 3. mise not found after bootstrap

**Problem:** mise installed but not in PATH

**Solution:**
```bash
# Add mise to PATH
export PATH="$HOME/.local/bin:$PATH"

# Add to your shell config
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

#### 4. SSH config errors

**Problem:** SSH complains about missing include files

**Solution:**
```bash
# Create the expected directory
mkdir -p ~/.ssh/config.d
touch ~/.ssh/config.d/home

# Or remove the Include line from ~/.ssh/config
nano ~/.ssh/config
```

#### 5. Syntax errors in configuration files

**Problem:** Shell shows errors on startup

**Solutions:**
```bash
# Check which file has the error
zsh -x 2>&1 | head -50

# Temporarily disable problematic config
mv ~/.zshrc ~/.zshrc.bak
source ~/.zshrc

# Review your backup
cat ~/.dotfiles_backup_*/.zshrc
```

#### 6. Permission denied when installing packages

**Problem:** `sudo` fails or asks for password repeatedly

**Solutions:**
```bash
# Ensure your user has sudo access
whoami
sudo -v

# On some systems, use sudo with -H
sudo -H ./bootstrap.sh

# Or ensure PATH is preserved
sudo -E ./bootstrap.sh
```

### Getting Help

1. Check existing issues in the repository
2. Review the error messages in the script output
3. Try running the script with verbose output:
   ```bash
   bash -x ./bootstrap.sh 2>&1 | tee bootstrap.log
   ```

---

## Customization

### Creating User Overrides

Create a `.dotfiles.local` file for personal settings:

```bash
# Example: ~/.dotfiles.local
export EMAIL="your@email.com"
export GITOPS_TOOLS="/different/path"
```

Then source it from your main config:
```bash
# In ~/.zshrc (add at the end)
[ -f ~/.dotfiles.local ] && source ~/.dotfiles.local
```

### Machine-Specific Configurations

For settings that vary between machines:

1. Create configs in ignored locations (`.gitignore`ed)
2. Use conditional logic in your configs:
   ```bash
   # In ~/.zshrc
   if [ -f ~/.dotfiles-machines/my-machine ]; then
       source ~/.dotfiles-machines/my-machine
   fi
   ```

### Disabling Features

To disable certain features, modify the source files:

```bash
# Disable direnv
# Comment out in ~/.zshrc:
# eval "$(direnv hook zsh)"

# Disable pyenv
# Comment out in ~/.zshrc:
# eval "$(pyenv init -)"
```

---

## Quick Reference

### Common Commands

```bash
# Update dotfiles
git pull
./install.sh

# Backup current config
cp -r ~/{.zshrc,.vimrc,...} ~/dotfiles_backup_$(date +%Y%m%d)

# Switch between shells
chsh -s /bin/zsh
chsh -s /bin/bash

# Revert to backups
rm ~/.zshrc ~/.bashrc  # Remove symlinks
cp -r ~/.dotfiles_backup_YYYYMMDD/* ~  # Restore files
```

### File Locations

| Config | Local Path | Repo Path |
|--------|---|-----------|
| Shell | `~/.zshrc` | `zsh/.zshrc` |
| Vim | `~/.vimrc` | `vim/.vimrc` |
| Git | `~/.gitconfig` | `git/.gitconfig` |
| Tmux | `~/.tmux.conf` | `tmux/.tmux.conf` |
| SSH | `~/.ssh/config` | `ssh/config` |

---

**Happy configuring!** 🎉
