# Setup fzf
# ---------

# Determine Homebrew or custom fzf bin directory dynamically
_fzf_bin=""
if [ -n "${HOMEBREW_PREFIX:-}" ] && [ -d "${HOMEBREW_PREFIX}/opt/fzf/bin" ]; then
    _fzf_bin="${HOMEBREW_PREFIX}/opt/fzf/bin"
elif [ -d "/opt/homebrew/opt/fzf/bin" ]; then
    _fzf_bin="/opt/homebrew/opt/fzf/bin"
elif [ -d "/usr/local/opt/fzf/bin" ]; then
    _fzf_bin="/usr/local/opt/fzf/bin"
elif [ -d "/home/linuxbrew/.linuxbrew/opt/fzf/bin" ]; then
    _fzf_bin="/home/linuxbrew/.linuxbrew/opt/fzf/bin"
elif [ -d "$HOME/.fzf/bin" ]; then
    _fzf_bin="$HOME/.fzf/bin"
fi

if [ -n "$_fzf_bin" ] && [[ ! "$PATH" == *"${_fzf_bin}"* ]]; then
    PATH="${PATH:+${PATH}:}${_fzf_bin}"
fi
unset _fzf_bin

# Auto-completion & Key bindings
# Search candidates across Homebrew, Debian/Ubuntu, Alpine, and ~/.fzf
_fzf_completion=""
_fzf_key_bindings=""

for _dir in \
    "${HOMEBREW_PREFIX:-}/opt/fzf/shell" \
    "/opt/homebrew/opt/fzf/shell" \
    "/usr/local/opt/fzf/shell" \
    "/home/linuxbrew/.linuxbrew/opt/fzf/shell" \
    "$HOME/.fzf/shell" \
    "/usr/share/doc/fzf/examples" \
    "/usr/share/fzf" \
    "/usr/share/zsh/site-functions"; do
    if [ -z "$_fzf_completion" ] && [ -f "$_dir/completion.zsh" ]; then
        _fzf_completion="$_dir/completion.zsh"
    fi
    if [ -z "$_fzf_key_bindings" ] && [ -f "$_dir/key-bindings.zsh" ]; then
        _fzf_key_bindings="$_dir/key-bindings.zsh"
    fi
done

[[ $- == *i* ]] && [ -n "$_fzf_completion" ] && source "$_fzf_completion" 2> /dev/null
[ -n "$_fzf_key_bindings" ] && source "$_fzf_key_bindings" 2> /dev/null

unset _dir _fzf_completion _fzf_key_bindings
