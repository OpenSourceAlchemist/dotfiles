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
- [x] Add uninstall/revert script (`uninstall.sh`)
- [x] Create `Makefile` for common operations
  - [x] `make install`
  - [x] `make uninstall`
  - [x] `make verify`
  - [x] `make backup`

## Configuration Improvements
- [x] Fix missing `ssh/config.d/` directory (create or remove reference)
- [x] Handle mise installation in `bootstrap.sh` (currently skips)
- [x] Add macOS/Homebrew support to installer
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

## Optional / Nice-to-Have
- [x] CI/CD for testing on multiple environments
- [x] Implement pre-commit hook framework for linting and parallel execution
  - [x] Create .pre-commit-config.yaml
  - [x] Add shellcheck, markdownlint, yamllint hooks
  - [x] Update CI/CD to run pre-commit
  - [x] Document pre-commit setup in AGENTS.md and INSTALL.md
  - [x] Parallel shellcheck execution
  - [x] Helper scripts for pre-commit operations
