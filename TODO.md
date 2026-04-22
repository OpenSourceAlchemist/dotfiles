# Dotfiles Installation Improvements Checklist

## Critical Security
- [x] Create `.gitignore` to prevent committing sensitive data
  - [x] SSH private keys
  - [x] API tokens and credentials
  - [x] Personal config overrides
  - [x] Editor backup files

## Installation Enhancements
- [x] Create `bootstrap.sh` for system dependency installation
  - [x] Auto-detect OS (Debian/Alpine/macOS)
  - [x] Install all required packages in one step
  - [x] Handle mise, brew, antigen separately
- [ ] Add interactive installation mode (`--interactive` or `--component`)
- [x] Add uninstall/revert script (`uninstall.sh`)
- [ ] Add installation verification (`--verify` flag)
- [ ] Handle shell change prompt after install
- [x] Create `Makefile` for common operations
  - [x] `make install`
  - [x] `make uninstall`
  - [x] `make verify`
  - [x] `make backup`

## Configuration Improvements
- [ ] Replace hardcoded paths with variables
  - [ ] `/home/linuxbrew/.linuxbrew`
  - [ ] `/usr/share/zsh-antigen/antigen.zsh`
  - [ ] `kevin@opensourcealchemist.com`
  - [ ] Internal paths (`~/src/internal/*`)
- [ ] Create `.dotfiles.local` override file mechanism
- [x] Fix missing `ssh/config.d/` directory (create or remove reference)
- [x] Handle mise installation in `bootstrap.sh` (currently skips)
- [x] Add macOS/Homebrew support to installer
- [ ] Auto-install antigen in user's home directory
- [x] Migrate from Terraform to OpenTofu (open-source fork)
  - [x] Update `bootstrap.sh` to install `tofu` instead of `terraform`
  - [x] Keep `.terraformrc` filename for OpenTofu compatibility
  - [x] Migrate any existing Terraform state/configurations

## Documentation
- [x] Create `INSTALL.md` with step-by-step instructions
- [x] Add troubleshooting section
- [x] Document symlink structure clearly
- [x] Add compatible versions list (Version.md)
- [x] Update README with installation badges/status

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
- [x] CI/CD for testing on multiple environments
- [ ] Implement `hk` for pre-commit hook parallelization
