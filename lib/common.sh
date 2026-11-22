# shellcheck shell=bash
# Shared helpers for install.sh and uninstall.sh. Works with macOS /bin/bash 3.2.

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
MANIFEST="$STATE_DIR/manifest.tsv"
TERMINAL_PROFILE="One Dark"
TERMINAL_DOMAIN="com.apple.Terminal"

# Files linked into $HOME: "repo path|home path"
LINKS_CORE="zsh/zshrc|.zshrc
zsh/zprofile|.zprofile
git/gitconfig|.gitconfig
git/gitignore_global|.gitignore_global
vim/vimrc|.vimrc"
LINKS_BASH="bash/bashrc|.bashrc
bash/bash_profile|.bash_profile"

# Homebrew formulae the setup uses
BREW_FORMULAE="vim fzf zsh-autosuggestions zsh-syntax-highlighting"

DRY_RUN=0

if [ -t 1 ]; then
  C_YELLOW=$'\e[33m'; C_GREEN=$'\e[32m'; C_RED=$'\e[31m'; C_DIM=$'\e[2m'; C_RESET=$'\e[0m'
else
  C_YELLOW=; C_GREEN=; C_RED=; C_DIM=; C_RESET=
fi

step() { printf '%s==> %s%s\n' "$C_YELLOW" "$*" "$C_RESET"; }
info() { printf '    %s\n' "$*"; }
ok()   { printf '    %s%s%s\n' "$C_GREEN" "$*" "$C_RESET"; }
warn() { printf '    %swarning:%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; }
die()  { printf '%serror:%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; exit 1; }

# Run a command, or only print it in dry-run mode
run() {
  if [ "$DRY_RUN" = 1 ]; then
    printf '    %s[dry-run]%s %s\n' "$C_DIM" "$C_RESET" "$*"
  else
    "$@"
  fi
}

# Manifest lines are tab-separated: kind, path/name, extra
record() {
  [ "$DRY_RUN" = 1 ] && return 0
  local IFS=$'\t'
  printf '%s\n' "$*" >> "$MANIFEST"
}

# True if the manifest already has a line starting with these fields
recorded() {
  [ -f "$MANIFEST" ] || return 1
  local IFS=$'\t'
  grep -qF -- "$*" "$MANIFEST"
}

# Paths in the manifest are stored with a literal ~ for readability
expand_home() { case "$1" in "~"/*) printf '%s\n' "$HOME/${1#\~/}" ;; *) printf '%s\n' "$1" ;; esac; }
tilde() { case "$1" in "$HOME"/*) printf '~/%s\n' "${1#"$HOME"/}" ;; *) printf '%s\n' "$1" ;; esac; }

# Read a Terminal setting, or print __absent__
terminal_pref() {
  defaults read "$TERMINAL_DOMAIN" "$1" 2>/dev/null || echo "__absent__"
}

# True if Terminal has a profile with this name
terminal_has_profile() {
  local tmp rc
  tmp="$(mktemp -t dotfiles)"
  defaults export "$TERMINAL_DOMAIN" "$tmp" 2>/dev/null || { rm -f "$tmp"; return 1; }
  plutil -extract "Window Settings.$1" xml1 -o /dev/null "$tmp" >/dev/null 2>&1
  rc=$?
  rm -f "$tmp"
  return $rc
}
