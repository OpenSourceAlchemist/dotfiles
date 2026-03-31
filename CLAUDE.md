# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## Repository Overview

This is a dotfiles repository containing configuration files for a Linux desktop environment. Dotfiles are installed by running `./install.sh`, which creates symlinks from the home directory to files in this repository.

## Installation

Run the installation script to create symlinks:

```bash
./install.sh
```

The script will:
- Check for dependencies (zsh, vim, tmux, git, fzf, direnv, terraform, gh, mise)
- Attempt to auto-install missing packages on Debian/Alpine systems
- Create backups of existing dotfiles in `~/.dotfiles_backup_*`
- Create symlinks from `~` to files in this repository

## Repository Structure

```
dotfiles/
├── install.sh           # Main installation script
├── README.md            # Package requirements overview
├── TODO.md              # Development checklist
│
├── bash/                # Bash shell configuration
│   └── .bashrc
│
├── zsh/                 # Zsh shell configuration
│   ├── .zshrc           # Main zsh config with antigen, plugins
│   └── dotzsh/          # Custom zsh files
│       ├── aliases      # PATH manipulation, tool setup
│       ├── env          # Directory traversal aliases, pipe shortcuts
│       └── kaliases     # Keychain config
│
├── shell/               # Non-interactive shell profile
│   └── .profile
│
├── vim/                 # Vim configuration
│
├── tmux/                # Tmux configuration
│   ├── .tmux.conf
│   └── .tmux.conf.goodies
│
├── git/                 # Git configuration
│   └── .gitconfig
│
├── terraform/           # Terraform configuration
│   └── .terraformrc
│
├── mise/                # mise (asdf) configuration
│   ├── .asdfrc
│   └── .tool-versions   # terraform 1.5.6, ruby 3.2.2, nodejs *
│
├── direnv/              # Direnv per-directory config
│   └── .envrc           # PATH management, env setup
│
├── fzf/                 # Fuzzy finder config
│   ├── .fzf.bash
│   └── .fzf.zsh
│
├── Xorg/                # X11 configuration
│   └── .Xdefaults
│
├── ssh/                 # SSH configuration
│   ├── config           # Base SSH config
│   └── config.d/        # Additional configs (private)
│
└── dotconfig/           # External application configs
    ├── gh/              # GitHub CLI (config.yml, hosts.yml)
    └── openbox/         # Openbox window manager (rc.xml)
```

## Key Technologies

- **mise**: Language version manager (replaces asdf)
- **antigen**: Zsh plugin manager for oh-my-zsh
- **direnv**: Per-directory environment management
- **keychain**: SSH agent management
- **rbenv**: Ruby version management
- **pyenv**: Python version management

## Development Workflow

### Shell Configuration
The zsh setup uses antigen for plugin management with oh-my-zsh. Key files:
- `.zshrc`: Main entry point
- `~/.zsh/aliases`: Custom aliases for directory traversal (`..`, `...`, etc.) and pipe shortcuts
- `~/.zsh/env`: PATH setup, tool configurations
- `~/.zsh/kaliases`: Keychain initialization

### SSH Configuration
Base `ssh/config` includes from `config.d/home` for private host configurations. The repo excludes secrets to prevent accidental commits.

### Direnv
The `.envrc` manages PATH additions for various tools (rbenv, brew, kubeseal, gitops-tools). Ensure `direnv allow` is run in directories with `.envrc` files.

## Important Notes

- The `.tool-versions` file specifies: terraform 1.5.6, ruby 3.2.2, nodejs (auto-managed)
- SSH config has an incomplete `config.d/*` reference - secrets should go there but aren't committed
- For detailed TODO items, see `TODO.md` (security hardening, bootstrap improvements, macOS support)
- The install script has a TODO: `~/.dotzsh/` symlinks point to `zsh/dotzsh/*` but may not exist
