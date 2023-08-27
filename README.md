# dotfiles
Repository for my dotfiles and minor scripting to make installation and maintenance faster

## Expected packages - Ideally Ansible or a post-install script deploys these (names are based on Debian)
### Workstation
tmux rsync bzip2 vim-nox rxvt-unicode keychain zsh zsh-antigen zsh-doc zsh-syntax-highlighting mosh compton xclip xscreensaver
#### From brew
direnv asdf fzf podman
#### External
google-chrome-stable  From google
Homebrew from brew.sh


### Notes
ssh config is incomplete and has a reference to child configs in `config.d/*`.  This is to ensure that secret information isn't accidentally passed along.
