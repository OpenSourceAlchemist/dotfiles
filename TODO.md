# Dotfiles Installation Improvements Checklist

## Critical Security
- [ ] Create `.gitignore` to prevent committing sensitive data
  - [ ] SSH private keys
  - [ ] API tokens and credentials
  - [ ] Personal config overrides
  - [ ] Editor backup files

## Installation Enhancements
- [ ] Create `bootstrap.sh` for system dependency installation
  - [ ] Auto-detect OS (Debian/Alpine/macOS)
  - [ ] Install all required packages in one step
  - [ ] Handle mise, brew, antigen separately
- [ ] Add interactive installation mode (`--interactive` or `--component`)
- [ ] Add uninstall/revert script (`uninstall.sh`)
- [ ] Add installation verification (`--verify` flag)
- [ ] Handle shell change prompt after install
- [ ] Create `Makefile` for common operations
  - [ ] `make install`
  - [ ] `make uninstall`
  - [ ] `make verify`
  - [ ] `make backup`

## Configuration Improvements
- [ ] Replace hardcoded paths with variables
  - [ ] `/home/linuxbrew/.linuxbrew`
  - [ ] `/usr/share/zsh-antigen/antigen.zsh`
  - [ ] `kevin@opensourcealchemist.com`
  - [ ] Internal paths (`~/src/internal/*`)
- [ ] Create `.dotfiles.local` override file mechanism
- [ ] Fix missing `ssh/config.d/` directory (create or remove reference)
- [ ] Handle mise installation in `bootstrap.sh` (currently skips)
- [ ] Add macOS/Homebrew support to installer
- [ ] Auto-install antigen in user's home directory

## Documentation
- [ ] Create `INSTALL.md` with step-by-step instructions
- [ ] Add troubleshooting section
- [ ] Document symlink structure clearly
- [ ] Add compatible versions list (Version.md)
- [ ] Update README with installation badges/status

## Testing
- [ ] Test on fresh Debian system
- [ ] Test on fresh Alpine system
- [ ] Test on fresh macOS system
- [ ] Test shell switching (bash -> zsh)
- [ ] Test uninstall/revert process

## Optional / Nice-to-Have
- [ ] Add pre/post install hooks
- [ ] Support for different "profiles" (work, personal, etc.)
- [ ] Add backup rotation/cleanup
- [ ] CI/CD for testing on multiple environments
