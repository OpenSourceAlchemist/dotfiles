#!/usr/bin/env bats

setup() {
    export REPO_DIR="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    export TEST_HOME="$BATS_TEST_TMPDIR/fakehome"
    rm -rf "$TEST_HOME"
    mkdir -p "$TEST_HOME"
    export HOME="$TEST_HOME"
}

teardown() {
    rm -rf "$TEST_HOME"
}

@test "uninstall.sh removes symlinks and restores backed-up files" {
    # 1. Pre-populate mock home with user's original files
    echo "# Custom user bashrc" > "$HOME/.bashrc"
    echo "# Custom user vimrc" > "$HOME/.vimrc"
    echo "# Custom gitconfig" > "$HOME/.gitconfig"

    # 2. Run install.sh to generate backup and link dotfiles
    run "$REPO_DIR/install.sh" --component shell,editor,git
    [ "$status" -eq 0 ]
    [ -L "$HOME/.bashrc" ]
    [ -L "$HOME/.vimrc" ]
    [ -L "$HOME/.gitconfig" ]

    # Verify backup directory was created
    backup_count=$(find "$HOME" -maxdepth 1 -type d -name ".dotfiles_backup_*" | wc -l)
    [ "$backup_count" -ge 1 ]

    # 3. Run uninstall.sh --restore
    run "$REPO_DIR/uninstall.sh" --restore --force
    [ "$status" -eq 0 ]

    # 4. Verify symlinks were removed and replaced with restored original files
    [ ! -L "$HOME/.bashrc" ]
    [ ! -L "$HOME/.vimrc" ]
    [ ! -L "$HOME/.gitconfig" ]
    [ -f "$HOME/.bashrc" ]
    [ -f "$HOME/.vimrc" ]
    [ -f "$HOME/.gitconfig" ]

    # Verify original file content was preserved
    grep -q "Custom user bashrc" "$HOME/.bashrc"
    grep -q "Custom user vimrc" "$HOME/.vimrc"
    grep -q "Custom gitconfig" "$HOME/.gitconfig"
}

@test "uninstall.sh runs cleanly when no backup exists" {
    # Install symlinks without pre-existing files (no backup created)
    run "$REPO_DIR/install.sh" --component shell
    [ "$status" -eq 0 ]
    [ -L "$HOME/.bashrc" ]

    # Run uninstall with --skip-backup
    run "$REPO_DIR/uninstall.sh" --skip-backup --force
    [ "$status" -eq 0 ]
    [ ! -e "$HOME/.bashrc" ]
}
