#!/bin/bash
# Install these dotfiles on macOS. Safe to run more than once.
#
# Everything it changes is recorded in ~/.local/state/dotfiles/manifest.tsv,
# and every file it replaces is moved into ~/.local/state/dotfiles/backups/,
# so ./uninstall.sh can put the machine back the way it was.
set -u

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

  --dry-run       Show what would happen without changing anything
  --bash          Also link ~/.bashrc and ~/.bash_profile (default when your login shell is bash)
  --no-brew       Don't install Homebrew formulae (vim, fzf, zsh plugins)
  --allow-source-builds
                  Install formulae even when Homebrew has no prebuilt package for this Mac
                  and would compile them (slow; needs the Command Line Tools). By default
                  those are skipped: vim falls back to the system vim, fzf to a prebuilt
                  binary that vim-plug downloads into ~/.vim/plugged/fzf.
  --no-vim        Don't install vim-plug or vim plugins
  --no-terminal   Don't import the "One Dark" Terminal profile or make it the default
  -h, --help      Show this help
EOF
}

. "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

WITH_BASH=0; WITH_BREW=1; WITH_VIM=1; WITH_TERMINAL=1; SOURCE_BUILDS=0
case "${SHELL:-}" in */bash) WITH_BASH=1 ;; esac
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --bash) WITH_BASH=1 ;;
    --no-brew) WITH_BREW=0 ;;
    --no-vim) WITH_VIM=0 ;;
    --no-terminal) WITH_TERMINAL=0 ;;
    --allow-source-builds) SOURCE_BUILDS=1 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; die "unknown option: $1" ;;
  esac
  shift
done

[ "$(uname -s)" = Darwin ] || die "this installer is for macOS"

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$STATE_DIR/backups/$STAMP"

# ---------------------------------------------------------------- state
step "Preparing state directory $(tilde "$STATE_DIR")"
if [ ! -d "$STATE_DIR" ]; then
  # Record which parent folders we create so uninstall can remove them too
  missing=""
  d="$STATE_DIR"
  while [ ! -d "$d" ] && [ "$d" != "$HOME" ]; do missing="$d $missing"; d="$(dirname "$d")"; done
  run mkdir -p "$STATE_DIR"
  if [ "$DRY_RUN" = 0 ]; then
    printf '# dotfiles install manifest. Read by uninstall.sh; do not edit.\n' > "$MANIFEST"
    for d in $missing; do record statedir "$(tilde "$d")"; done
  fi
fi
info "manifest: $(tilde "$MANIFEST")"

# Remember files a shell or vim will generate later, if they don't exist yet,
# so uninstall can remove them.
for f in .zcompdump .viminfo; do
  if [ ! -e "$HOME/$f" ] && ! recorded generated "~/$f"; then record generated "~/$f"; fi
done

backup() {  # move an existing file or link out of the way, recording where it went
  local target="$1" dest
  dest="$BACKUP_DIR/$(basename "$target")"
  run mkdir -p "$BACKUP_DIR"
  run mv "$target" "$dest"
  record backup "$(tilde "$target")" "$(tilde "$dest")"
  info "backed up $(tilde "$target") -> $(tilde "$dest")"
}

link() {  # link repo file $1 to $HOME/$2
  local src="$DOTFILES/$1" target="$HOME/$2"
  [ -e "$src" ] || die "missing $src"
  if [ -L "$target" ] && [ "$(readlink "$target")" = "$src" ]; then
    info "$(tilde "$target") already linked"
    return
  fi
  if [ -e "$target" ] || [ -L "$target" ]; then
    backup "$target"
    if [ "$2" = .gitconfig ]; then seed_gitconfig_local "$BACKUP_DIR/.gitconfig"; fi
  fi
  run ln -s "$src" "$target"
  record link "$(tilde "$target")" "$src"
  ok "linked $(tilde "$target") -> $src"
}

# Keep this machine's old git settings (GUI tool paths and so on) in
# ~/.gitconfig.local, which the shared gitconfig includes.
seed_gitconfig_local() {
  local old="$1" local_cfg="$HOME/.gitconfig.local"
  [ -e "$local_cfg" ] && return
  if [ "$DRY_RUN" = 1 ]; then info "[dry-run] would copy old ~/.gitconfig settings to ~/.gitconfig.local"; return; fi
  [ -L "$old" ] && return   # old one was a symlink to somewhere else; nothing local to keep
  {
    printf '# Machine-specific git settings, not in the dotfiles repo.\n'
    printf '# Seeded from the previous ~/.gitconfig by install.sh on %s.\n\n' "$STAMP"
    cat "$old"
  } > "$local_cfg"
  record created "~/.gitconfig.local"
  ok "copied old ~/.gitconfig settings to ~/.gitconfig.local"
}

# ---------------------------------------------------------------- links
step "Linking dotfiles"
links="$LINKS_CORE"
[ "$WITH_BASH" = 1 ] && links="$links
$LINKS_BASH"
while IFS='|' read -r src target; do
  [ -n "$src" ] && link "$src" "$target"
done <<EOF
$links
EOF

# ---------------------------------------------------------------- brew
BREW=""
for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do [ -x "$b" ] && BREW="$b" && break; done

if [ "$WITH_BREW" = 1 ]; then
  step "Installing Homebrew formulae: $BREW_FORMULAE"
  if [ -z "$BREW" ]; then
    warn "Homebrew not found; skipping. Install it from https://brew.sh and re-run."
  else
    before="$("$BREW" list --formula -1 | sort)"
    todo=""
    for f in $BREW_FORMULAE; do
      if printf '%s\n' "$before" | grep -qx "$f"; then
        info "$f already installed"
      elif [ "$SOURCE_BUILDS" = 0 ] &&
           HOMEBREW_NO_AUTO_UPDATE=1 "$BREW" install --dry-run "$f" 2>&1 | grep -q "build from source"; then
        # e.g. Intel Macs, where Homebrew no longer ships prebuilt packages for everything
        warn "skipping $f: Homebrew has no prebuilt package for this Mac (use --allow-source-builds to compile it)"
      else
        todo="$todo $f"
      fi
    done
    if [ -n "$todo" ]; then
      # brew creates ~/.homebrew on its first install; remove it on uninstall if this made it
      if [ ! -e "$HOME/.homebrew" ] && ! recorded generated "~/.homebrew"; then record generated "~/.homebrew"; fi
      # shellcheck disable=SC2086
      brew_ok=1
      run "$BREW" install $todo || brew_ok=0
      if [ "$DRY_RUN" = 0 ]; then
        # Record everything that's new, dependencies included, so uninstall
        # removes exactly what this added. Done even if brew reported an error,
        # since some formulae may have installed before it failed.
        after="$("$BREW" list --formula -1 | sort)"
        for f in $(comm -13 <(printf '%s\n' "$before") <(printf '%s\n' "$after")); do
          record brew "$f"
        done
      fi
      if [ "$brew_ok" = 1 ]; then
        ok "installed:$todo"
      else
        for f in $todo; do
          if "$BREW" list --formula "$f" >/dev/null 2>&1; then
            info "$f is installed"
          else
            warn "$f did not install"
          fi
        done
        warn "brew reported an error (see its output above); continuing"
      fi
    fi
  fi
fi

# ---------------------------------------------------------------- vim
if [ "$WITH_VIM" = 1 ]; then
  step "Installing vim-plug and vim plugins"
  for p in "$HOME/.vim" "$HOME/.vim/autoload" "$HOME/.vim/plugged" "$HOME/.vim/undodir"; do
    if [ ! -e "$p" ]; then
      # Only the top-most new folder needs recording; uninstall removes it whole
      parent_new=0
      case "$p" in "$HOME/.vim/"*) recorded created "~/.vim" && parent_new=1 ;; esac
      run mkdir -p "$p"
      [ "$parent_new" = 1 ] || record created "$(tilde "$p")"
    fi
  done
  PLUG="$HOME/.vim/autoload/plug.vim"
  if [ ! -f "$PLUG" ]; then
    run curl -fsSLo "$PLUG" https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim \
      || die "could not download vim-plug"
    recorded created "~/.vim" || recorded created "~/.vim/autoload" || record created "~/.vim/autoload/plug.vim"
  fi
  VIM="vim"
  [ -n "$BREW" ] && [ -x "$("$BREW" --prefix)/bin/vim" ] && VIM="$("$BREW" --prefix)/bin/vim"
  # -i NONE: don't create ~/.viminfo; -E -s: silent Ex mode, no terminal UI
  run "$VIM" -i NONE -E -s -u "$HOME/.vimrc" +'PlugInstall --sync' +qall
  ok "vim plugins installed in ~/.vim/plugged"
fi

# ---------------------------------------------------------------- terminal
if [ "$WITH_TERMINAL" = 1 ]; then
  step "Setting up the \"$TERMINAL_PROFILE\" Terminal profile"
  if ! terminal_has_profile "$TERMINAL_PROFILE"; then
    if [ "$DRY_RUN" = 1 ]; then
      info "[dry-run] defaults write $TERMINAL_DOMAIN \"Window Settings\" -dict-add \"$TERMINAL_PROFILE\" <terminal/$TERMINAL_PROFILE.terminal>"
    else
      defaults write "$TERMINAL_DOMAIN" "Window Settings" -dict-add "$TERMINAL_PROFILE" \
        "$(cat "$DOTFILES/terminal/$TERMINAL_PROFILE.terminal")" || die "could not import Terminal profile"
    fi
    record terminal-profile "$TERMINAL_PROFILE"
    ok "imported profile"
  else
    info "profile already exists; leaving it as is"
  fi
  for key in "Default Window Settings" "Startup Window Settings"; do
    prev="$(terminal_pref "$key")"
    if [ "$prev" != "$TERMINAL_PROFILE" ]; then
      recorded defaults "$TERMINAL_DOMAIN" "$key" || record defaults "$TERMINAL_DOMAIN" "$key" "$prev"
      run defaults write "$TERMINAL_DOMAIN" "$key" -string "$TERMINAL_PROFILE"
      ok "$key: $prev -> $TERMINAL_PROFILE"
    else
      info "$key already $TERMINAL_PROFILE"
    fi
  done
fi

# ---------------------------------------------------------------- done
step "Done"
if [ "$DRY_RUN" = 1 ]; then
  info "dry run: nothing was changed"
else
  info "Open a new Terminal window to use it (quit and reopen Terminal for the new profile)."
  info "Secrets go in ~/.private; turn on client aliases with: export DOTFILES_WORK=1"
  info "Undo everything with: $DOTFILES/uninstall.sh"
fi
