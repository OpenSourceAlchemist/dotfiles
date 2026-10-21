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

@test "backup rotation prunes backups beyond threshold" {
    # Create 7 dummy backups
    for i in {1..7}; do
        mkdir -p "$HOME/.dotfiles_backup_2026102${i}000000"
        echo "file $i" > "$HOME/.dotfiles_backup_2026102${i}000000/test.txt"
    done

    # Run clean-backups keeping 3
    run "$REPO_DIR/install.sh" --clean-backups 3
    [ "$status" -eq 0 ]

    # Count remaining backup directories
    remaining_count=$(find "$HOME" -maxdepth 1 -type d -name ".dotfiles_backup_*" | wc -l)
    [ "$remaining_count" -eq 3 ]

    # Verify the newest 3 backups were preserved
    [ -d "$HOME/.dotfiles_backup_20261025000000" ]
    [ -d "$HOME/.dotfiles_backup_20261026000000" ]
    [ -d "$HOME/.dotfiles_backup_20261027000000" ]

    # Verify the oldest backups were deleted
    [ ! -d "$HOME/.dotfiles_backup_20261021000000" ]
    [ ! -d "$HOME/.dotfiles_backup_20261022000000" ]
}

@test "backup rotation preserves single backup even if threshold is 0" {
    mkdir -p "$HOME/.dotfiles_backup_20261021000000"
    echo "sole backup" > "$HOME/.dotfiles_backup_20261021000000/keep.txt"

    run "$REPO_DIR/install.sh" --clean-backups 0
    [ "$status" -eq 0 ]

    # Invariant: Never delete the only backup
    [ -d "$HOME/.dotfiles_backup_20261021000000" ]
    [ -f "$HOME/.dotfiles_backup_20261021000000/keep.txt" ]
}

@test "backup rotation ignores directories not matching pattern" {
    mkdir -p "$HOME/.dotfiles_backup_20261021000000"
    mkdir -p "$HOME/.dotfiles_backup_20261022000000"
    mkdir -p "$HOME/.dotfiles_backup_safe_notes"
    mkdir -p "$HOME/.dotfiles_backup_20261023000000"

    run "$REPO_DIR/install.sh" --clean-backups 1
    [ "$status" -eq 0 ]

    # Safe directory must remain untouched
    [ -d "$HOME/.dotfiles_backup_safe_notes" ]
}
