# Dependencies: antigen
# Set up the prompt

setopt histignorealldups sharehistory notify

# Use emacs keybindings even if our EDITOR is set to vi
bindkey -e

# Keep 1000 lines of history within the shell and save it to ~/.zsh_history:
HISTSIZE=100000
SAVEHIST=100000
HISTFILE=~/.zsh_history

# Dynamic Antigen discovery
ANTIGEN_LOADED=0
ANTIGEN_CANDIDATES=(
    "${ANTIGEN_PATH:-}"
    "$HOME/.antigen/antigen.zsh"
    "$HOME/.local/share/antigen/antigen.zsh"
    "$HOME/.zsh/antigen/zsh-antigen/antigen.zsh"
    "/usr/share/zsh-antigen/antigen.zsh"
    "/usr/local/share/zsh-antigen/antigen.zsh"
    "${HOMEBREW_PREFIX:-}/share/antigen/antigen.zsh"
    "/opt/homebrew/share/antigen/antigen.zsh"
    "/usr/local/share/antigen/antigen.zsh"
)

for candidate in "${ANTIGEN_CANDIDATES[@]}"; do
    if [ -n "$candidate" ] && [ -f "$candidate" ]; then
        source "$candidate"
        ANTIGEN_LOADED=1
        break
    fi
done

if [ "$ANTIGEN_LOADED" -eq 1 ]; then
    # Load the oh-my-zsh library
    antigen use oh-my-zsh

    # Bundles from default repo (oh-my-zsh)
    antigen bundle git
    antigen bundle pip
    antigen bundle lein
    antigen bundle command-not-found

    # Alien Minimal theme configuration: omit prompt start tag (_)
    export AM_LEFT_SECTION=(am_ssh_st am_prompt_dir am_vi_prompt am_prompt_end_tag am_venv)

    #antigen bundle zsh-user/zsh-syntax-highlighting
    antigen theme eendroroy/alien-minimal alien-minimal

    antigen apply
    am_prompt_start_tag() { :; }
fi

# Dynamic GitOps tools (if present)
if [ -d "${GITOPS_TOOLS:-$HOME/src/internal/gitops-tools}" ]; then
    export GITOPS_TOOLS="${GITOPS_TOOLS:-$HOME/src/internal/gitops-tools}"
    [ -d "$GITOPS_TOOLS/bin" ] && export PATH="$GITOPS_TOOLS/bin:$PATH"
fi

# .local bin
[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"

# Dynamic HomeBrew initialization
if [ -z "${HOMEBREW_PREFIX:-}" ]; then
    if [ -x "/opt/homebrew/bin/brew" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x "/usr/local/bin/brew" ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    elif [ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    elif [ -x "$HOME/.linuxbrew/bin/brew" ]; then
        eval "$("$HOME/.linuxbrew/bin/brew" shellenv)"
    elif command -v brew >/dev/null 2>&1; then
        eval "$(brew shellenv)"
    fi
fi

# Keychain
if command -v keychain >/dev/null 2>&1; then
    eval "$(keychain --eval --quiet 2>/dev/null)"
fi

# Modular shell configs (check ~/.dotzsh and ~/.zsh)
for _zdir in "$HOME/.dotzsh" "$HOME/.zsh"; do
    if [ -d "$_zdir" ]; then
        [ -f "$_zdir/aliases" ] && source "$_zdir/aliases"
        [ -f "$_zdir/env" ] && source "$_zdir/env"
        [ -f "$_zdir/kaliases" ] && source "$_zdir/kaliases"
        break
    fi
done
unset _zdir

# rbenv
if command -v rbenv >/dev/null 2>&1; then
    eval "$(rbenv init - zsh)"
fi

[ -f "$HOME/.fzf.zsh" ] && source "$HOME/.fzf.zsh"

if [ -t 0 ] && command -v tty >/dev/null 2>&1; then
    export GPG_TTY=$(tty)
fi

# direnv
if command -v direnv >/dev/null 2>&1; then
    eval "$(direnv hook zsh)"
fi

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
[ -d "$PYENV_ROOT/bin" ] && export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv >/dev/null 2>&1; then
    eval "$(pyenv init -)"
fi

# Dynamic mise activation
if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate zsh)"
elif [ -x "$HOME/.local/bin/mise" ]; then
    eval "$("$HOME/.local/bin/mise" activate zsh)"
fi

# Load machine-specific local overrides
if [ -f "$HOME/.dotfiles.local" ]; then
    # shellcheck source=/dev/null
    source "$HOME/.dotfiles.local"
fi
