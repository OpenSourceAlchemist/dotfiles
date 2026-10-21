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

@test "install.sh prints usage with --help" {
    run "$REPO_DIR/install.sh" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "--component" ]]
    [[ "$output" =~ "--profile" ]]
    [[ "$output" =~ "--verify" ]]
}

@test "install.sh fails gracefully on unknown flag" {
    run "$REPO_DIR/install.sh" --invalid-flag
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Unknown option" ]]
}

@test "install.sh rejects invalid profile names with special characters" {
    run "$REPO_DIR/install.sh" --profile "../../../etc"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Invalid profile name" ]]
}

@test "install.sh rejects nonexistent profile" {
    run "$REPO_DIR/install.sh" --profile "nonexistent_profile_123"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "does not exist" ]]
}

@test "install.sh creates symlinks for shell component" {
    run "$REPO_DIR/install.sh" --component shell
    [ "$status" -eq 0 ]
    [ -L "$HOME/.bashrc" ]
    [ -L "$HOME/.bash_profile" ]
    [ -L "$HOME/.profile" ]
    [ -L "$HOME/.zshrc" ]
    [ -L "$HOME/.dotzsh/aliases" ]
    [ "$(readlink "$HOME/.bashrc")" = "$REPO_DIR/bash/.bashrc" ]
}

@test "install.sh creates symlinks for git component and applies profile" {
    run "$REPO_DIR/install.sh" --component git --profile work
    [ "$status" -eq 0 ]
    [ -L "$HOME/.gitconfig" ]
    [ -L "$HOME/.gitconfig.local" ]
    [ "$(readlink "$HOME/.gitconfig.local")" = "$REPO_DIR/profiles/work/gitconfig" ]
}

@test "install.sh --verify reports success when symlinks exist" {
    run "$REPO_DIR/install.sh" --component shell,git
    [ "$status" -eq 0 ]
    run "$REPO_DIR/install.sh" --verify --component shell,git
    [ "$status" -eq 0 ]
    [[ "$output" =~ "All verification checks passed" ]]
}

@test "install.sh with --headless installs CLI dotfiles and omits GUI dotfiles" {
    run "$REPO_DIR/install.sh" --headless
    [ "$status" -eq 0 ]
    # CLI dotfiles should be installed
    [ -L "$HOME/.bashrc" ]
    [ -L "$HOME/.zshrc" ]
    [ -L "$HOME/.vimrc" ]
    [ -L "$HOME/.tmux.conf" ]
    [ -L "$HOME/.gitconfig" ]
    # GUI dotfiles should NOT be installed
    [ ! -e "$HOME/.Xdefaults" ]
    [ ! -e "$HOME/.config/openbox/rc.xml" ]
}

@test "install.sh --verify catches missing symlinks" {
    run "$REPO_DIR/install.sh" --verify --component shell
    [ "$status" -eq 1 ]
    [[ "$output" =~ "does not exist" ]]
}
