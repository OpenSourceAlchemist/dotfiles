#!/bin/bash
#
# Test harness for dotfiles installation
# Runs in a Debian 13 container

set -euo pipefail

DOTFILES_DIR="/dotfiles"
TEST_USER="testuser"
TEST_HOME="/home/testuser"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0
SKIPPED=0

log_test() {
    echo -e "${YELLOW}[TEST]${NC} $1"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    PASSED=$((PASSED + 1))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    FAILED=$((FAILED + 1))
}

log_skip() {
    echo -e "${YELLOW}[SKIP]${NC} $1"
    SKIPPED=$((SKIPPED + 1))
}

assert_file_exists() {
    if [ -e "$1" ]; then
        log_pass "File exists: $1"
    else
        log_fail "File missing: $1"
    fi
}

assert_is_symlink() {
    if [ -L "$1" ]; then
        log_pass "Is symlink: $1"
    else
        log_fail "Not a symlink: $1"
    fi
}

assert_symlink_targets() {
    local link="$1"
    local expected_target="$2"
    if [ -L "$link" ] && [ "$(readlink "$link")" = "$expected_target" ]; then
        log_pass "Symlink $link -> $expected_target"
    else
        log_fail "Symlink $link does not target $expected_target (found: $(readlink "$link" 2>/dev/null || echo 'N/A'))"
    fi
}

assert_command_exists() {
    if command -v "$1" &>/dev/null; then
        log_pass "Command exists: $1"
    else
        log_fail "Command missing: $1"
    fi
}

echo "=============================================="
echo "  Dotfiles Installation Test Harness"
echo "  Debian 13 (trixie)"
echo "=============================================="
echo ""

# Test 1: Verify dotfiles repo structure
echo "--- Repository Structure ---"
log_test "Checking repository structure..."
assert_file_exists "$DOTFILES_DIR/install.sh"
assert_file_exists "$DOTFILES_DIR/bash/.bashrc"
assert_file_exists "$DOTFILES_DIR/zsh/.zshrc"
assert_file_exists "$DOTFILES_DIR/vim/.vimrc"
assert_file_exists "$DOTFILES_DIR/git/.gitconfig"
assert_file_exists "$DOTFILES_DIR/tmux/.tmux.conf"
assert_file_exists "$DOTFILES_DIR/mise/.asdfrc"
assert_file_exists "$DOTFILES_DIR/mise/.tool-versions"
assert_file_exists "$DOTFILES_DIR/direnv/.envrc"
assert_file_exists "$DOTFILES_DIR/fzf/.fzf.bash"
assert_file_exists "$DOTFILES_DIR/fzf/.fzf.zsh"
assert_file_exists "$DOTFILES_DIR/ssh/config"
assert_file_exists "$DOTFILES_DIR/zsh/dotzsh/aliases"
assert_file_exists "$DOTFILES_DIR/zsh/dotzsh/env"
assert_file_exists "$DOTFILES_DIR/zsh/dotzsh/kaliases"
echo ""

# Test 2: Verify dependencies are installed
echo "--- Dependency Check ---"
log_test "Verifying installed packages..."
assert_command_exists zsh
assert_command_exists vim
assert_command_exists tmux
assert_command_exists git
assert_command_exists direnv
assert_command_exists terraform
assert_command_exists gh
echo ""

# Test 3: Run the installation script
echo "--- Installation Test ---"
log_test "Running install.sh as $TEST_USER..."
su -c "cd $DOTFILES_DIR && bash install.sh" "$TEST_USER" || {
    log_fail "Installation script failed"
    exit 1
}
echo ""

# Test 4: Verify symlinks were created
echo "--- Symlink Verification ---"
log_test "Verifying symlinks in $TEST_HOME..."
assert_is_symlink "$TEST_HOME/.bashrc"
assert_is_symlink "$TEST_HOME/.zshrc"
assert_is_symlink "$TEST_HOME/.profile"
assert_is_symlink "$TEST_HOME/.vimrc"
assert_is_symlink "$TEST_HOME/.gitconfig"
assert_is_symlink "$TEST_HOME/.tmux.conf"
assert_is_symlink "$TEST_HOME/.asdfrc"
assert_is_symlink "$TEST_HOME/.tool-versions"
assert_is_symlink "$TEST_HOME/.envrc"
assert_is_symlink "$TEST_HOME/.fzf.bash"
assert_is_symlink "$TEST_HOME/.fzf.zsh"
assert_is_symlink "$TEST_HOME/.ssh/config"
assert_is_symlink "$TEST_HOME/.dotzsh/aliases"
assert_is_symlink "$TEST_HOME/.dotzsh/env"
assert_is_symlink "$TEST_HOME/.dotzsh/kaliases"
echo ""

# Test 5: Verify symlink targets
echo "--- Symlink Target Verification ---"
log_test "Verifying symlink targets..."
assert_symlink_targets "$TEST_HOME/.bashrc" "$DOTFILES_DIR/bash/.bashrc"
assert_symlink_targets "$TEST_HOME/.zshrc" "$DOTFILES_DIR/zsh/.zshrc"
assert_symlink_targets "$TEST_HOME/.profile" "$DOTFILES_DIR/shell/.profile"
assert_symlink_targets "$TEST_HOME/.vimrc" "$DOTFILES_DIR/vim/.vimrc"
assert_symlink_targets "$TEST_HOME/.tmux.conf" "$DOTFILES_DIR/tmux/.tmux.conf"
assert_symlink_targets "$TEST_HOME/.dotzsh/aliases" "$DOTFILES_DIR/zsh/dotzsh/aliases"
echo ""

# Test 6: Verify backup was created
echo "--- Backup Verification ---"
log_test "Checking backup directory..."
BACKUP_COUNT=$(ls -1d "$TEST_HOME"/.dotfiles_backup_* 2>/dev/null | wc -l)
if [ "$BACKUP_COUNT" -ge 1 ]; then
    log_pass "Backup directory created"
else
    log_fail "No backup directory found"
fi
echo ""

# Test 7: Verify idempotency (run again)
echo "--- Idempotency Test ---"
log_test "Running installation again (should handle existing symlinks)..."
IDEMPOTENCY_OUTPUT=$(su -c "cd $DOTFILES_DIR && bash install.sh" "$TEST_USER" 2>&1)
if echo "$IDEMPOTENCY_OUTPUT" | grep -q "correct symlink already exists"; then
    log_pass "Idempotency check passed - handles existing symlinks"
else
    log_fail "Idempotency check failed"
fi
echo ""

# Test 8: Verify .config/gh symlinks
echo "--- GitHub CLI Config Verification ---"
log_test "Checking gh config symlinks..."
assert_symlink_targets "$TEST_HOME/.config/gh/config.yml" "$DOTFILES_DIR/dotconfig/gh/config.yml"
assert_symlink_targets "$TEST_HOME/.config/gh/hosts.yml" "$DOTFILES_DIR/dotconfig/gh/hosts.yml"
echo ""

# Test 9: Verify .zsh directories were created
echo "--- Zsh Directory Verification ---"
log_test "Checking .dotzsh directory structure..."
assert_file_exists "$TEST_HOME/.dotzsh/aliases"
assert_file_exists "$TEST_HOME/.dotzsh/env"
assert_file_exists "$TEST_HOME/.dotzsh/kaliases"
echo ""

# Summary
echo "=============================================="
echo "  Test Summary"
echo "=============================================="
echo -e "  ${GREEN}Passed:${NC} $PASSED"
echo -e "  ${RED}Failed:${NC} $FAILED"
echo -e "  ${YELLOW}Skipped:${NC} $SKIPPED"
echo "=============================================="

if [ "$FAILED" -gt 0 ]; then
    echo -e "${RED}Tests FAILED${NC}"
    exit 1
else
    echo -e "${GREEN}All tests PASSED${NC}"
    exit 0
fi
