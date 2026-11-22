# shellcheck shell=bash
# Environment shared by zsh and bash. Sourced by zsh/zshrc and bash/bashrc.

# Colors for ls and friends (BSD ls on macOS)
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad

export EDITOR=vim
export VISUAL=vim

# Merge without opening an editor for the commit message
export GIT_MERGE_AUTOEDIT=no

# PATH: personal bins first, optional tool bins last (only if present)
_dotfiles_path_prepend() { [ -d "$1" ] && case ":$PATH:" in *":$1:"*) ;; *) PATH="$1:$PATH" ;; esac; }
_dotfiles_path_append()  { [ -d "$1" ] && case ":$PATH:" in *":$1:"*) ;; *) PATH="$PATH:$1" ;; esac; }
_dotfiles_path_prepend "$HOME/.local/bin"
_dotfiles_path_prepend "$HOME/.bin"
_dotfiles_path_append "$HOME/.composer/vendor/bin"
_dotfiles_path_append "$HOME/.serverless/bin"
# fzf downloaded by vim-plug, used when Homebrew has no fzf for this Mac
_dotfiles_path_append "$HOME/.vim/plugged/fzf/bin"
unset -f _dotfiles_path_prepend _dotfiles_path_append
export PATH

# Secrets and machine-only settings live outside the repo.
# ~/.bash_private is the old name and is still read if present.
for _f in "$HOME/.private" "$HOME/.bash_private"; do
  [ -f "$_f" ] && . "$_f"
done
unset _f
