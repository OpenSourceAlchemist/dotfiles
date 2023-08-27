# Dependencies: antigen
# Set up the prompt

setopt histignorealldups sharehistory notify

# Use emacs keybindings even if our EDITOR is set to vi
bindkey -e

# Keep 1000 lines of history within the shell and save it to ~/.zsh_history:
HISTSIZE=1000
SAVEHIST=1000
HISTFILE=~/.zsh_history

#Antigen
source /usr/share/zsh-antigen/antigen.zsh
# Load the oh-my-zsh library
antigen use oh-my-zsh

#Bundles from default repo (oh-my-zsh)
antigen bundle git
antigen bundle pip
antigen bundle lein
antigen bundle command-not-found

#antigen bundle zsh-user/zsh-syntax-highlighting
antigen theme eendroroy/alien-minimal alien-minimal

antigen apply

# GitOps tools
export GITOPS_TOOLS="$HOME/src/internal/gitops-tools"
export PATH="$HOME/src/internal/gitops-tools/bin:$PATH"
#source $GITOPS_TOOLS/shell/zsh/completion.zsh

# .local bin
export PATH="$HOME/.local/bin:$PATH"

#HomeBrew
test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

#Keychain
eval `keychain --eval`

#TJ Stuff
source ~/.zsh/aliases
source ~/.zsh/env
source ~/.zsh/kaliases

[ -f /home/linuxbrew/.linuxbrew/opt/asdf/libexec/asdf.sh ] && source /home/linuxbrew/.linuxbrew/opt/asdf/libexec/asdf.sh

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

export GPG_TTY=$(tty)

if command -v direnv >/dev/null 2>&1
then
  eval "$(direnv hook zsh)"
fi

