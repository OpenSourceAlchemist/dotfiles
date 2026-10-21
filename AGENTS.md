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
| `INSTALL.md` | User installation guide |
| `README.md` | Repository overview |
| `AGENTS.md` | Agent development guidelines (this file) |
| `.gitignore` | Sensitive file protection |
| `Makefile` | Build, lint, and workflow automation |

## Directory Structure

```
.
├── agents/            # Universal Agent Skills and modular rules (cross-agent)
│   ├── rules/         # Modular rules (skeptical-auditor.md)
│   └── skills/        # Agent Skills standard (skeptical-auditor/SKILL.md)
├── agy/               # Antigravity CLI configuration (statusline.sh)
├── bash/              # Bash configuration (.bashrc, .bash_profile)
├── dotconfig/         # Application configs (not in root)
│   ├── gh/           # GitHub CLI configuration
│   └── openbox/      # Openbox window manager
├── direnv/           # direnv .envrc
├── fzf/              # fzf keybindings
├── git/              # Git configuration
├── mise/             # mise/asdf tool versions
├── pi/               # pi-coding-agent configuration and prompt shortcuts
│   ├── models.json   # Model provider configurations
│   ├── settings.json # Agent preferences and extensions
│   └── prompts/      # Custom slash command prompt shortcuts
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
| `zsh/.amrc` | `~/.amrc` |
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
| `agy/statusline.sh` | `~/.gemini/antigravity-cli/statusline.sh` |
| `agents/skills/skeptical-auditor/SKILL.md` | `~/.agents/skills/skeptical-auditor/SKILL.md` |
| `agents/rules/skeptical-auditor.md` | `~/.agents/rules/skeptical-auditor.md` |
| `pi/settings.json` | `~/.pi/agent/settings.json` |
| `pi/models.json` | `~/.pi/agent/models.json` |
| `pi/prompts/skeptical-audit.md` | `~/.pi/agent/prompts/skeptical-audit.md` |

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
- Antigravity CLI / Gemini OAuth tokens (`*oauth-token*`, `oauth_creds.json`) and runtime state (`agy/settings.json`, `agy/history.jsonl`)
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
4. Open a GitHub issue or pull request to track planned features

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

## Issue & Task Tracking

All bugs, backlog items, and planned enhancements are tracked directly via GitHub Issues. Do not maintain a separate `TODO.md` file.

## Development Workflow

### Setup (One-time)

Run the setup script to install all development tools:

```bash
# Install pre-commit and all hooks
make dev-setup

# Or check what's installed first
./dev-setup.sh --verify
```

### Making Changes

1. **Branch First**: Always create a dedicated branch (e.g., `feat/...`, `fix/...`, `docs/...`) from `main`. Never push directly to `main`.
2. **Make Changes**: Edit dotfiles, scripts, or documentation.
3. **Test Locally**: Run test suites (`bats tests/unit tests/integration`) and verify on clean environments when possible.
4. **Validate**: Run pre-commit checks and linting before committing:
   ```bash
   # On staged files (before commit)
   pre-commit run

   # Or on all files
   make lint
   pre-commit run --all-files
   ```
5. **Document**: Update relevant documentation if behavior or configuration changes.
6. **Create Pull Request**: Push the branch to remote and open a Pull Request (`gh pr create`) for review to ensure secondary validation via GitHub Actions CI checks prior to merging.
7. **Squash and Merge**: The default merge policy is **squash merge with source branch deletion** (`gh pr merge <PR> --squash --delete-branch`).

### Pre-Commit Hooks

This repository uses the `pre-commit` framework for automated validation:

| Hook | Purpose | Files |
|--||--|--|--------|
| shellcheck | Bash/Zsh linting | *.sh, bootstrap.sh, install.sh, .fzf.* |
| bash-syntax | Syntax validation (bash -n) | *.sh |
| markdownlint | Markdown formatting | *.md |
| detect-private-key | Find private keys | .ssh/*, ssh/* |
| gitleaks | Secret and credential scanning | all files |
| trailing-whitespace | Remove trailing spaces | all text files |
| end-of-file-fixer | Ensure newline at EOF | all text files |
| check-exec-permissions | Verify script permissions | bootstrap.sh, install.sh |

### ShellCheck Configuration

ShellCheck warnings are automatically skipped:
- **SC1091**: File not found (for source/require statements)
- **SC2002**: Useless cat (sometimes clearer in config files)
- **SC2154**: Variable not declared (for env vars passed by parent shell)

### Quick Setup

```bash
# Install all development tools automatically
./dev-setup.sh --install

# Check what's installed
./dev-setup.sh --verify

# Run all checks
make lint
```

### Helper Scripts

- `scripts/run-shellcheck-parallel.sh` - Run shellcheck on all scripts in parallel
- `scripts/run-precommit.sh` - Simple pre-commit runner wrapper
- `scripts/run-gitleaks.sh` - Run gitleaks secret detection

### Validation & Automation

Validation and security enforcement are handled at multiple layers:
- **Local Pre-Commit**: Pre-commit runs `shellcheck`, `bash -n`, `markdownlint`, `detect-private-key`, and `gitleaks` prior to commits.
- **Makefile Automation**: `make lint` executes linting and secret scanning; `make secret-scan` scans the repository with `gitleaks`.
- **GitHub Secret Scanning & Push Protection**: Enabled on the GitHub repository to block pushes containing credentials at the transport level.
- **GitHub Actions CI Backstop**: `.github/workflows/ci.yml` runs automated secret scanning (`gitleaks-action`) and pre-commit lint validation on all pull requests and pushes to `main`.

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

## Security Context

- Secrets and credential leaks are guarded locally by gitleaks and detect-private-key hooks
- SSH configs and local overrides are excluded from version control via .gitignore

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
