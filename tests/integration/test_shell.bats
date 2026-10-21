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

@test "zshrc loads cleanly without syntax errors" {
    run "$REPO_DIR/install.sh" --component shell
    [ "$status" -eq 0 ]

    if command -v zsh >/dev/null 2>&1; then
        # Check syntax
        run zsh -n "$HOME/.zshrc"
        [ "$status" -eq 0 ]

        # Source .zshrc in an isolated non-interactive subshell
        run zsh -f -c "HOME='$HOME' source '$HOME/.zshrc'"
        [ "$status" -eq 0 ]
    else
        skip "zsh not installed"
    fi
}

@test "bashrc loads cleanly without syntax errors" {
    run "$REPO_DIR/install.sh" --component shell
    [ "$status" -eq 0 ]

    # Check syntax
    run bash -n "$HOME/.bashrc"
    [ "$status" -eq 0 ]

    # Source in subshell
    run bash -c "HOME='$HOME' source '$HOME/.bashrc'"
    [ "$status" -eq 0 ]
}

@test "zsh aliases and environment variables are defined after sourcing" {
    run "$REPO_DIR/install.sh" --component shell
    [ "$status" -eq 0 ]

    if command -v zsh >/dev/null 2>&1; then
        # Verify that an alias from dotzsh/aliases exists
        run zsh -f -c "HOME='$HOME'; source '$HOME/.zshrc'; alias ga"
        [ "$status" -eq 0 ]
        [[ "$output" =~ "git add" ]]
    else
        skip "zsh not installed"
    fi
}

@test "kaliases loads cleanly without glob error when kube conf.d is missing or empty" {
    run "$REPO_DIR/install.sh" --component shell
    [ "$status" -eq 0 ]

    if command -v zsh >/dev/null 2>&1; then
        run zsh -f -c "HOME='$HOME'; source '$HOME/.dotzsh/kaliases'"
        [ "$status" -eq 0 ]
        [[ ! "$output" =~ "no matches found" ]]
    else
        skip "zsh not installed"
    fi
}

@test "alien-minimal left prompt excludes start tag underscore prefix" {
    run "$REPO_DIR/install.sh" --component shell
    [ "$status" -eq 0 ]

    if command -v zsh >/dev/null 2>&1; then
        run zsh -f -c "HOME='$HOME'; source '$HOME/.amrc'; echo \"\${AM_LEFT_SECTION[*]}\""
        [ "$status" -eq 0 ]
        [[ ! "$output" =~ "am_prompt_start_tag" ]]
    else
        skip "zsh not installed"
    fi
}
