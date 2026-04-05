# Agent Harness Guide - Dotfiles Repository

This document provides guidelines and context for AI agents (and human developers) working with this dotfiles repository.

## Repository Overview

This is a **cross-platform dotfiles management repository** that:
- Manages user configuration files (dotfiles) via symlinks
- Provides automated system dependency installation
- Supports multiple Linux distributions and macOS
- Uses a modular, extensible architecture

## Quick Navigation

| File/Directory | Purpose |
|---------------|---------|
| `install.sh` | Symlink creation script |
| `bootstrap.sh` | System dependency installer |
| `TODO.md` | Feature backlog and task tracking |
| `INSTALL.md` | User installation guide |
| `README.md` | Repository overview |
| `AGENTS.md` | Agent development guidelines (this file) |
| `.gitignore` | Sensitive file protection |
| `~/.gitlab-ci.yml` | CI/CD pipeline configuration |

## Directory Structure

```
.
├── bash/              # Bash configuration (.bashrc, .bash_profile)
├── dotconfig/         # Application configs (not in root)
│   ├── gh/           # GitHub CLI configuration
│   └── openbox/      # Openbox window manager
├── direnv/           # direnv .envrc
├── fzf/              # fzf keybindings
├── git/              # Git configuration
├── mise/             # mise/asdf tool versions
├── shell/            # Shared shell configuration (.profile)
├── ssh/              # SSH configuration (includes config.d/ for local overrides)
├── terraform/        # OpenTofu configuration (terraformrc compatible)
├── tmux/             # tmux configuration (.tmux.conf, .tmux.conf.goodies)
├── vim/              # Vim configuration (.vimrc)
├── Xorg/             # X11 configuration (.Xdefaults)
├── zsh/              # Zsh configuration
│   ├── .zshrc
│   └── dotzsh/       # Zsh modular configs (aliases, env, kaliases)
└── [scripts]         # bootstrap.sh, install.sh
```

## Symlink Mapping

The `install.sh` script creates symlinks according to this mapping:

| Repo Path | Home Path |
|-----------|-----------|
| `bash/.bashrc` | `~/.bashrc` |
| `bash/.bash_profile` | `~/.bash_profile` |
| `shell/.profile` | `~/.profile` |
| `zsh/.zshrc` | `~/.zshrc` |
| `zsh/dotzsh/aliases` | `~/.dotzsh/aliases` |
| `zsh/dotzsh/env` | `~/.dotzsh/env` |
| `tmux/.tmux.conf` | `~/.tmux.conf` |
| `git/.gitconfig` | `~/.gitconfig` |
| `ssh/config` | `~/.ssh/config` |
| `direnv/.envrc` | `~/.envrc` |
| `mise/.tool-versions` | `~/.tool-versions` |
| `mise/.asdfrc` | `~/.asdfrc` |
| `fzf/.fzf.bash` | `~/.fzf.bash` |
| `fzf/.fzf.zsh` | `~/.fzf.zsh` |
| `terraform/.terraformrc` | `~/.terraformrc` | (OpenTofu config, backward compatible filename)
| `Xorg/.Xdefaults` | `~/.Xdefaults` |
| `dotconfig/gh/config.yml` | `~/.config/gh/config.yml` |
| `dotconfig/gh/hosts.yml` | `~/.config/gh/hosts.yml` |

## Key Scripts

### bootstrap.sh
- **Purpose**: Installs system-level dependencies
- **OS Detection**: Debian, Alpine, macOS, RHEL/Fedora
- **Special Tools**: mise, fzf, direnv, tofu (OpenTofu), gh, antigen
- **Entry Point**: Always run this BEFORE `install.sh`

### install.sh
- **Purpose**: Creates symlinks from repo to home directory
- **Safety Features**: Backs up existing files before overwriting
- **Dependency Check**: Validates required tools before proceeding
- **Entry Point**: Run AFTER `bootstrap.sh`

## Configuration Patterns

### Local Overrides
- `.dotfiles.local`, `~/.zshrc.local`, `~/.ssh/config.d/*`
- All local override patterns are in `.gitignore`
- These files contain user-specific or secret information

### Modular Configs
- `~/.dotzsh/*` contains shell-specific modular configs
- SSH config.d/ allows per-host secret configuration
- `.tmux.conf.goodies` provides optional tmux extensions

### Version Management
- `mise/.tool-versions` tracks tool versions (replaces `.tool-versions` directly in mise dir)
- Tool management via mise (asdf-compatible)

## Supported Platforms

| Platform | Package Manager | Notes |
|----------|----------------|-------|
| Debian/Ubuntu | apt | Full support |
| RHEL/Fedora/Rocky/Alma | dnf/yum | EPEL for some packages |
| Alpine | apk | Full support |
| macOS | Homebrew | Full support |

## Security Considerations

### Never Commit:
- SSH private keys (`.ssh/*_key`)
- SSH known_hosts
- SSH local config overrides (`.ssh/config.d/*`)
- GitHub CLI auth tokens (`dotconfig/gh/hosts.yml`)
- Personal `.local` and `.override` files

### Always Protected By:
- `.gitignore` patterns
- SSH config.d/ design pattern for secrets
- `.gitkeep` files to maintain directory structure

## Common Agent Tasks

### Adding a New Dotfile
1. Create file in appropriate directory (e.g., `vim/new-plugin.vim`)
2. Add symlink mapping to `install.sh` `FILES_TO_SYMLINK` array
3. Update `.gitignore` if the file could contain sensitive data
4. Consider adding to `TODO.md` if it's a planned feature

### Updating Dependencies
1. Review package mappings in `bootstrap.sh` for each OS
2. Ensure new packages are idempotent (check if already installed)
3. Update `INSTALL.md` if requirements change
4. Test on multiple platforms

### Adding OS Support
1. Add detection logic to `bootstrap.sh`
2. Create OS-specific package installation function
3. Test with fresh VM/container
4. Update `Supported Systems` table

## Current TODO Items

- Interactive installation mode (`--interactive`)
- Uninstall/revert script (`uninstall.sh`)
- Installation verification (`--verify` flag)
- Makefile for common operations
- hk for pre-commit hook parallelization

## Development Workflow

1. **Make Changes**: Edit dotfiles or scripts
2. **Test Locally**: Use a clean VM/container if possible
3. **Validate**: Run pre-commit checks
   ```bash
   # Install pre-commit (one-time)
   pip3 install pre-commit
   
   # Install git hooks (one-time)
   pre-commit install
   
   # Run on all files
   pre-commit run --all-files
   
   # Run on staged files
   pre-commit run
   ```
4. **Document**: Update relevant docs if behavior changes
5. **Test Integration**: Run `bootstrap.sh` then `install.sh` on clean system

## Pre-Commit Hooks

This repository uses the `pre-commit` framework for automated validation:

| Hook | Purpose | Files |
|--||--|--|--------|
| shellcheck | Bash/Zsh linting | *.sh, bootstrap.sh, install.sh, .fzf.* |
| bash-syntax | Syntax validation (bash -n) | *.sh |
| markdownlint | Markdown formatting | *.md |
| yamllint | YAML validation | .gitlab-ci.yml |
| check-exec-permissions | Verify script permissions | bootstrap.sh, install.sh |
| trailing-whitespace | Remove trailing spaces | all text files |
| end-of-file-fixer | Ensure newline at EOF | all text files |
| detect-private-key | Find private keys | .ssh/* |

### ShellCheck Configuration

ShellCheck warnings are skipped:
- **SC1091**: File not found (for source/require statements)
- **SC2002**: Useless cat (sometimes clearer in config files)
- **SC2154**: Variable not declared (for env vars passed by parent shell)

### CI/CD Integration

The `.gitlab-ci.yml` runs `pre-commit run --all-files` on:
- Merge requests
- main branch commits

This replaces the previous individual validation jobs (shellcheck, bash_syntax, markdown_lint, validate_yaml).

## File Locations for Reference

| Category | Config Files |
|----------|-------------|
| **Shell** | `~/.bashrc`, `~/.zshrc`, `~/.profile`, `~/.dotzsh/*` |
| **Terminal Multiplexer** | `~/.tmux.conf` |
| **Editor** | `~/.vimrc` |
| **Version Control** | `~/.gitconfig` |
| **Environment** | `~/.envrc`, `~/.tool-versions` |
| **Tooling** | `~/.fzf.bash`, `~/.fzf.zsh` |
| **Graphics** | `~/.Xdefaults` |
| **Applications** | `~/.config/gh/*`, `~/.terraformrc` (OpenTofu) |

## CI/CD Context

- GitLab CI pipeline configured in root
- Tests run on multiple distributions
- SSH config and local overrides excluded from testing

## Glossary

| Term | Definition |
|------|------------|
| **Dotfile** | A hidden config file starting with `.` |
| **OpenTofu (tofu)** | Open-source fork of Terraform, compatible with Terraform configurations |
| **mise** | Modern project/runtime version manager (asdf-compatible) |
| **direnv** | Environment variable manager that loads on directory change |
| **antigen** | Zsh plugin manager |
| **keychain** | SSH agent credential caching |
| **hk** | Pre-commit hook parallelization tool (planned) |

## Contact/Author

- Author: deathsyn
- License: MIT
- This AGENTS.md created for improved AI agent collaboration

---

*Last Updated: Based on repository state as of 2024*
