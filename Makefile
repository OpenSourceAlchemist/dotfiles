# Dotfiles Development Makefile
# Common operations for installation, uninstallation, and development

.PHONY: help install uninstall verify backup clean-backups lint test setup dev-setup pre-commit-check help gitleaks secret-scan

# Default target
.DEFAULT_GOAL := help

# Configuration
DOTFILES_DIR := $(shell pwd)
BACKUP_PREFIX := ~/.dotfiles_backup_
BACKUP_DIR := $(shell ls -t $(BACKUP_PREFIX)* 2>/dev/null | head -1)

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m # No Color

# --- Help ---

help:
	@echo -e "${BLUE}Dotfiles Development Makefile${NC}"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  install        : Install dotfiles by creating symlinks"
	@echo "  uninstall      : Remove symlinks (restore from backup if available)"
	@echo "  verify         : Verify symlinks are correctly configured"
	@echo "  backup         : Create a backup of existing dotfiles"
	@echo "  clean-backups  : Prune old backups keeping 5 most recent"
	@echo "  lint           : Run all linters (shellcheck, markdownlint, gitleaks)"
	@echo "  shellcheck     : Run shellcheck on all shell scripts"
	@echo "  markdownlint   : Run markdownlint on all markdown files"
	@echo "  secret-scan    : Run gitleaks secret detection"
	@echo "  pre-commit-check : Run pre-commit hooks manually"
	@echo ""
	@echo "Development Setup:"
	@echo "  dev-setup      : Install development tools for local testing"
	@echo "  setup          : Alias for dev-setup"
	@echo ""
	@echo "  Use './dev-setup.sh --help' for more options"
	@echo ""
	@echo "Examples:"
	@echo "  make install      # Install dotfiles"
	@echo "  make lint         # Run all linters"
	@echo "  make dev-setup    # Set up development environment"

# --- Installation ---

install:
	@echo -e "${BLUE}Installing dotfiles...${NC}"
	@chmod +x ./install.sh
	@./install.sh
	@echo ""
	@echo -e "${GREEN}Dotfiles installed successfully!${NC}"
	@echo ""
	@echo "To switch to zsh, run:"
	@echo "  chsh -s \$(which zsh)"
	@echo ""
	@echo "Then log out and log back in."

uninstall:
	@if [ -f ./uninstall.sh ]; then
		@echo -e "${BLUE}Uninstalling dotfiles...${NC}"
		@chmod +x ./uninstall.sh
		@./uninstall.sh
		@echo ""
		@echo -e "${GREEN}Dotfiles uninstalled successfully!${NC}"
	else
		@echo -e "${YELLOW}Warning: uninstall.sh not found.${NC}"
		@echo "Manual uninstallation instructions:"
		@echo ""
		@echo "  # Remove symlinks"
		@echo "  rm -f ~/.bashrc ~/.zshrc ~/.vimrc ~/.tmux.conf"
		@echo "  rm -f ~/.gitconfig ~/.ssh/config ~/.asdfrc"
		@echo ""
		@echo "  # Restore from backup if available"
		@BACKUP=$$(ls -d $(BACKUP_PREFIX)* 2>/dev/null | head -1); \
		if [ -n "$$BACKUP" ]; then \
			echo "  Restoring from backup: $$BACKUP"; \
			echo "  cp -r \"$$BACKUP\"/* ~"; \
		fi
	fi

# --- Verification ---

verify:
	@./install.sh --verify

# --- Backup & Cleanup ---

backup:
	@echo -e "${BLUE}Creating backup...${NC}"
	@BACKUP_DIR="$(BACKUP_PREFIX)$$(date +%Y%m%d_%H%M%S)"; \
	mkdir -p "$$BACKUP_DIR"; \
	for file in .bashrc .zshrc .vimrc .tmux.conf .gitconfig .ssh/config .asdfrc .fzf.bash .fzf.zsh; do \
		if [ -f "$$HOME/$$file" ] && [ ! -L "$$HOME/$$file" ]; then \
			cp "$$HOME/$$file" "$$BACKUP_DIR/"; \
		fi; \
	done; \
	echo "Backup created at: $$BACKUP_DIR"

clean-backups:
	@echo -e "${BLUE}Cleaning old dotfiles backups...${NC}"
	@./install.sh --clean-backups

# --- Linting ---

lint: shellcheck markdownlint gitleaks
	@echo ""
	@echo -e "${GREEN}All linting checks passed!${NC}"

gitleaks:
	@echo -e "${BLUE}Running gitleaks secret scan...${NC}"
	@./scripts/run-gitleaks.sh --all

secret-scan: gitleaks

shellcheck:
	@echo -e "${BLUE}Running shellcheck...${NC}"
	@if command -v shellcheck > /dev/null 2>&1; then \
		shellcheck -e SC1009,SC1090,SC1091,SC2002,SC2010,SC2016,SC2034,SC2154 install.sh bootstrap.sh 2>/dev/null || \
		shellcheck -e SC1009,SC1090,SC1091,SC2002,SC2010,SC2016,SC2034,SC2154 install.sh bootstrap.sh; \
	else \
		echo -e "${YELLOW}shellcheck not found. Install with: sudo apt-get install shellcheck${NC}"; \
		exit 1; \
	fi

markdownlint:
	@echo -e "${BLUE}Running markdownlint...${NC}"
	@if command -v markdownlint > /dev/null 2>&1; then \
		markdownlint README.md INSTALL.md TODO.md Version.md SYMLINKS.md || exit 0; \
	else \
		echo -e "${YELLOW}markdownlint not found. Install with: npm install -g markdownlint-cli${NC}"; \
		exit 0; \
	fi

# --- Pre-commit ---

pre-commit-check:
	@echo -e "${BLUE}Running pre-commit hooks...${NC}"
	@if command -v pre-commit > /dev/null 2>&1; then \
		pre-commit run --all-files; \
	else \
		echo -e "${RED}pre-commit not found. Run: make dev-setup${NC}"; \
		exit 1; \
	fi

# --- Development Setup ---

dev-setup setup:
	@echo -e "${BLUE}Setting up development environment...${NC}"
	@chmod +x ./dev-setup.sh
	@./dev-setup.sh --install

# --- Testing ---

test: lint verify
	@echo ""
	@echo -e "${GREEN}All tests passed!${NC}"
	@echo ""
	@echo "Run individual checks:"
	@echo "  make lint        # Run all linters"
	@echo "  make verify      # Verify installation"
	@echo "  make shellcheck  # Check shell scripts"
