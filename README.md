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
| `uninstall.sh` | Remove symlinks (when available) |

## Development

### Pre-Commit Hooks

This project uses pre-commit hooks to ensure code quality:

#### Quick Setup

```bash
# Run once to install all development tools
./scripts/develop-setup.sh install

# Or manually:
pip3 install pre-commit
pre-commit install
```

#### Available Commands

| Command | Description |
|--|--|
| `./scripts/develop-setup.sh install` | Install pre-commit and all tools |
| `./scripts/develop-setup.sh install-hooks` | Install git hooks only |
| `./scripts/develop-setup.sh run` | Run checks on staged files |
| `./scripts/develop-setup.sh run-all` | Run checks on all files |
| `./scripts/develop-setup.sh status` | Check what's installed |

#### What Gets Checked

When you commit, pre-commit automatically checks:
- Shell script syntax and style (shellcheck)
- Markdown formatting (markdownlint)
- YAML syntax (yamllint)
- No trailing whitespace
- No private keys in .ssh/
- Executable permissions on scripts

To run all checks manually:
```bash
./scripts/develop-setup.sh run-all
# or
pre-commit run --all-files
```

### Supported Systems

- Debian/Ubuntu
- Fedora/RHEL/CentOS/Rocky/AlmaLinux
- Alpine Linux
- macOS (with Homebrew)

## License

This project is licensed under the MIT License - see [LICENSE](LICENSE) for details.
