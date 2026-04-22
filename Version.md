# Version Compatibility

This document lists the tested and supported versions for all tools and operating systems.

## Operating System Support

| OS | Version | Support Level | Test Status |
|----|---------|---------------|-------------|
| Debian | 11 (Bullseye) | Full | ✅ Tested |
| Debian | 12 (Bookworm) | Full | ✅ Tested |
| Ubuntu | 22.04 LTS (Jammy) | Full | ✅ Tested |
| Ubuntu | 24.04 LTS (Noble) | Full | ✅ Tested |
| Fedora | 39+ | Full | ⚠️ Partial |
| RHEL/CentOS/Rocky | 9+ | Full | ⚠️ Partial |
| Alpine Linux | 3.19+ | Full | ✅ Tested |
| macOS | 12 (Monterey) | Full | ✅ Tested |
| macOS | 13 (Ventura) | Full | ✅ Tested |
| macOS | 14 (Sonoma) | Full | ✅ Tested |
| Arch Linux | Latest | Partial | ⚠️ Unofficial |

## Shell Versions

| Tool | Minimum Version | Recommended | Tested |
|------|-----------------|-------------|--------|
| zsh | 5.8 | 5.9+ | ✅ 5.9 |
| bash | 4.4 | 5.1+ | ✅ 5.2 |
| tmux | 3.2 | 3.3+ | ✅ 3.3a |

## Tool Versions

| Tool | Version | Install Method | Notes |
|------|---------|----------------|-------|
| mise | 2024.x | bootstrap.sh / manual | asdf replacement |
| fzf | 0.44+ | fzf/install / package manager | Fuzzy finder |
| direnv | 2.32+ | package manager / official installer | Environment loader |
| keychain | 2.8+ | package manager | SSH agent manager |
| OpenTofu | 1.6+ | bootstrap.sh / manual | Terraform fork |
| gh (GitHub CLI) | 2.40+ | package manager | GitHub CLI |
| zsh-antigen | 2.2+ | bootstrap.sh | Plugin manager |

## Package Manager Compatibility

| Manager | OS | Packages Supported |
|---------|-----|-------------------|
| apt / apt-get | Debian/Ubuntu | Full support |
| dnf | Fedora/RHEL/Rocky | Full support |
| apk | Alpine | Full support |
| brew | macOS/Ubuntu | Full support |
| pacman | Arch | Manual configuration |

## Known Conflicts

### zsh-antigen Installation Paths
- System-wide: `/usr/share/zsh-antigen/` (Debian/Ubuntu)
- User-local: `~/.zsh/antigen/` (macOS/Alpine)

### SSH Config Includes
- The SSH config includes `~/.ssh/config.d/*`
- Ensure the directory exists to avoid SSH errors

### mise/asdf
- If asdf is already installed, mise will not override it
- Ensure only one version manager is active

## Deprecations

| Tool | Replaced By | Version | Notes |
|------|-------------|---------|-------|
| Terraform CLI | OpenTofu | 1.7+ | Open source fork |

## Minimum System Requirements

- 1GB RAM (for minimal shell operations)
- 500MB disk space for dotfiles and dependencies
- Network connectivity for package installation

## Updating Dotfiles

To ensure compatibility after updating:

```bash
# Pull latest changes
git pull

# Re-run installation to update symlinks
./install.sh

# Verify all tools are accessible
./install.sh --verify  # If available
```

## Reporting Compatibility Issues

If you encounter issues on a specific OS or version:

1. Check your `bootstrap.sh` and `install.sh` logs
2. Verify tool versions match requirements above
3. Open an issue with your OS version and error output

## Changelog

### v1.0.0 (Current)
- Debian 11/12, Ubuntu 22.04/24.04 fully tested
- macOS 12-14 supported
- Alpine 3.19+ supported
- OpenTofu 1.6+ instead of Terraform
- mise 2024.x for asdf
