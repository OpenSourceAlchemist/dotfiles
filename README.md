# dotfiles

Repository for my dotfiles and minor scripting to make installation and maintenance faster.

## Quick Start

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/dotfiles.git
cd dotfiles

# Install system dependencies
./bootstrap.sh

# Create symlinks
./install.sh
```

For detailed instructions, see [INSTALL.md](INSTALL.md).

## Documentation

| Document | Description |
|----------|-------------|
| [INSTALL.md](INSTALL.md) | Complete installation guide |
| [TODO.md](TODO.md) | Planned improvements and feature tracking |
| [Version.md](Version.md) | Compatibility and version information |
| [bootstrap.sh](bootstrap.sh) | System dependency installer |
| [install.sh](install.sh) | Dotfiles symlink installer |

## Expected Packages

### Workstation (Debian/Ubuntu names)

**Core:**
```
tmux rsync bzip2 vim-nox rxvt-unicode keychain zsh
zsh-antigen zsh-doc zsh-syntax-highlighting mosh
compton xclip xscreensaver
```

**Via Package Manager or Brew:**
```
direnv mise fzf podman
```

**External:**
- google-chrome-stable (from Google's repo)
- Homebrew (from brew.sh)

## Configuration Notes

### SSH

The SSH config is incomplete and references child configs in `config.d/*`. This ensures secret information isn't accidentally committed to the repository.

Create your own SSH overrides:
```bash
mkdir -p ~/.ssh/config.d
nano ~/.ssh/config.d/home
```

### Personal Overrides

For settings that vary between machines or users, create local override files:

```bash
# Shell overrides
~/.dotfiles.local
~/.zshrc.local

# These files are excluded from Git via .gitignore
```

## Available Scripts

| Script | Description |
|--------|-------------|
| `bootstrap.sh` | Install system dependencies |
| `install.sh` | Create symlinks to dotfiles |
| `uninstall.sh` | Remove symlinks (with restore option) |
| `dev-setup.sh` | Install development tools |
| `scripts/run-shellcheck-parallel.sh` | Run shellcheck in parallel |

## Development

### Pre-Commit Hooks

This project uses pre-commit hooks to ensure code quality:

#### Quick Setup

```bash
# Run once to install all development tools
./dev-setup.sh --install

# Or manually:
pip3 install pre-commit
pre-commit install
```

#### Available Commands

| Command | Description |
|--|--|
| `make dev-setup` | Install pre-commit and all tools |
| `make lint` | Run all linters on all files |
| `make verify` | Verify installation |
| `make backup` | Create backup of existing dotfiles |
| `./dev-setup.sh --verify` | Check what dev tools are installed |
| `pre-commit run` | Run checks on staged files |
| `pre-commit run --all-files` | Run checks on all files |

#### What Gets Checked

When you commit, pre-commit automatically checks:
- Shell script syntax and style (shellcheck)
- Bash syntax validation (bash -n)
- Markdown formatting (markdownlint)
- YAML syntax (yamllint)
- No trailing whitespace
- No private keys in .ssh/
- Executable permissions on scripts

To run all checks manually:
```bash
make lint
# or
pre-commit run --all-files
```

## Supported Systems

- Debian/Ubuntu
- Fedora/RHEL/CentOS/Rocky/AlmaLinux
- Alpine Linux
- macOS (with Homebrew)

## Symlink Structure

This repository uses symlinks to manage dotfiles. When you run `./install.sh`, the following symlinks are created:

| Home File | Repository Source | Purpose |
|-----------|-------------------|----------|
| `~/.bashrc` | `bash/.bashrc` | Bash shell configuration |
| `~/.zshrc` | `zsh/.zshrc` | Zsh shell configuration |
| `~/.vimrc` | `vim/.vimrc` | Vim editor configuration |
| `~/.tmux.conf` | `tmux/.tmux.conf` | Tmux terminal multiplexer config |
| `~/.gitconfig` | `git/.gitconfig` | Git global configuration |
| `~/.ssh/config` | `ssh/config` | SSH client configuration |
| `~/.asdfrc` | `mise/.asdfrc` | mise version manager config |
| `~/.fzf.bash` | `fzf/.fzf.bash` | Fzf Bash integration |
| `~/.fzf.zsh` | `fzf/.fzf.zsh` | Fzf Zsh integration |
| `~/.config/gh/*.yml` | `*.yml` | GitHub CLI configuration |
| `~/.config/direnv/*.toml` | `*.toml` | direnv environment overrides |

**Important Files:**
- `~/.ssh/config.d/home` - Machine-specific SSH overrides (not committed)
- `~/.dotfiles.local` - Personal overrides (not committed)
- `~/.zshrc.local` - Shell-specific local overrides (not committed)

For complete details, see [INSTALL.md](INSTALL.md#detailed-installation).

## Troubleshooting

| Issue | Quick Fix |
|-------|----------|
| `command not found` after install | Run `exec zsh` or log out/in |
| `antigen not found` | Clone antigen: `git clone --depth 1 https://github.com/zsh-users/antigen ~/.zsh/antigen/zsh-antigen` |
| `mise not found` | Add `$HOME/.local/bin` to PATH |
| SSH config errors | Create `~/.ssh/config.d/` directory |
| Syntax errors on startup | Check `~/.dotfiles_backup_*` for original files |

For detailed troubleshooting, see [INSTALL.md#troubleshooting](INSTALL.md#troubleshooting).

## License

This project is licensed under the MIT License - see [LICENSE](LICENSE) for details.
