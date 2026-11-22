#!/bin/bash
# Undo install.sh: put back every file it replaced, remove what it added,
# uninstall the Homebrew formulae it installed and restore Terminal settings.
# Works from the manifest install.sh writes, newest change first.
set -u

usage() {
  cat <<'EOF'
Usage: ./uninstall.sh [options]

  --dry-run         Show what would happen without changing anything
  --keep-packages   Leave the Homebrew formulae that install.sh added
  -y, --yes         Don't ask for confirmation
  -h, --help        Show this help

The repo itself (this folder) is left in place; delete it yourself if you want.
EOF
}

. "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

KEEP_PACKAGES=0; YES=0
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --keep-packages) KEEP_PACKAGES=1 ;;
    -y|--yes) YES=1 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; die "unknown option: $1" ;;
  esac
  shift
done

[ -f "$MANIFEST" ] || die "no install manifest at $(tilde "$MANIFEST"); nothing to undo"

if [ "$YES" = 0 ] && [ "$DRY_RUN" = 0 ]; then
  printf 'This restores your pre-install dotfiles and settings. Continue? [y/N] '
  read -r answer
  case "$answer" in [yY]|[yY][eE][sS]) ;; *) echo "Cancelled."; exit 1 ;; esac
fi

PROBLEMS=0
# In a dry run nothing is deleted, so remember what would have been,
# letting later steps (restoring backups) be simulated correctly
DRY_GONE=$'\n'
gone() { [ "$DRY_RUN" = 1 ] && DRY_GONE="$DRY_GONE$1"$'\n'; return 0; }
present() { case "$DRY_GONE" in *$'\n'"$1"$'\n'*) return 1 ;; esac; [ -e "$1" ] || [ -L "$1" ]; }
problem() { warn "$*"; PROBLEMS=$((PROBLEMS + 1)); }

# Refuse to delete anything outside $HOME, or $HOME itself
safe_path() {
  case "$1" in "$HOME"/?*) ;; *) return 1 ;; esac
  case "$1" in *"/../"*|*"/.."|*"/./"*) return 1 ;; esac
  return 0
}

BREW=""
for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do [ -x "$b" ] && BREW="$b" && break; done
BREW_REMOVE=""
STATEDIRS=""

step "Undoing changes listed in $(tilde "$MANIFEST")"
# tail -r prints the file backwards (BSD), so the newest change is undone first
while IFS=$'\t' read -r kind a b c; do
  case "$kind" in ''|'#'*) continue ;; esac
  case "$kind" in
    link)
      target="$(expand_home "$a")"
      if [ -L "$target" ] && [ "$(readlink "$target")" = "$b" ]; then
        run rm "$target" && gone "$target" && ok "removed link $a"
      elif present "$target"; then
        problem "$a is no longer the installed link; left it alone"
      fi
      ;;
    backup)
      target="$(expand_home "$a")"; saved="$(expand_home "$b")"
      if [ ! -e "$saved" ] && [ ! -L "$saved" ]; then
        problem "backup $b is missing; can't restore $a"
      elif present "$target"; then
        problem "$a exists, so the backup was not restored; it is still at $b"
      else
        run mv "$saved" "$target" && ok "restored $a"
      fi
      ;;
    created|generated)
      target="$(expand_home "$a")"
      if [ -e "$target" ] || [ -L "$target" ]; then
        if safe_path "$target"; then
          run rm -rf "$target" && ok "removed $a"
        else
          problem "refusing to remove $a (outside home folder)"
        fi
      fi
      ;;
    brew)
      BREW_REMOVE="$BREW_REMOVE $a"
      ;;
    defaults)
      # a = domain, b = key, c = previous value or __absent__
      if [ "$c" = "__absent__" ]; then
        run defaults delete "$a" "$b" 2>/dev/null
        ok "$b: removed (was not set before)"
      else
        run defaults write "$a" "$b" -string "$c" && ok "$b: restored to $c"
      fi
      ;;
    terminal-profile)
      if [ "$DRY_RUN" = 1 ]; then
        info "[dry-run] would remove Terminal profile \"$a\""
      elif [ "$(terminal_pref "Default Window Settings")" = "$a" ] || \
         [ "$(terminal_pref "Startup Window Settings")" = "$a" ]; then
        problem "Terminal profile \"$a\" is still the default; left it in place"
      elif terminal_has_profile "$a"; then
        tmp_all="$(mktemp -t dotfiles)"; tmp_ws="$(mktemp -t dotfiles)"
        if defaults export "$TERMINAL_DOMAIN" "$tmp_all" &&
           plutil -extract "Window Settings" xml1 -o "$tmp_ws" "$tmp_all" &&
           /usr/libexec/PlistBuddy -c "Delete \":$a\"" "$tmp_ws" >/dev/null; then
          run defaults write "$TERMINAL_DOMAIN" "Window Settings" "$(cat "$tmp_ws")" &&
            ok "removed Terminal profile \"$a\""
        else
          problem "could not remove Terminal profile \"$a\""
        fi
        rm -f "$tmp_all" "$tmp_ws"
      fi
      ;;
    statedir)
      STATEDIRS="$STATEDIRS $a"
      ;;
    *)
      problem "unknown manifest entry: $kind"
      ;;
  esac
done < <(tail -r "$MANIFEST")

if [ -n "$BREW_REMOVE" ]; then
  if [ "$KEEP_PACKAGES" = 1 ]; then
    info "keeping Homebrew formulae:$BREW_REMOVE"
  elif [ -z "$BREW" ]; then
    problem "Homebrew not found; could not remove:$BREW_REMOVE"
  else
    step "Removing Homebrew formulae install.sh added"
    still=""
    for f in $BREW_REMOVE; do "$BREW" list --formula "$f" >/dev/null 2>&1 && still="$still $f"; done
    if [ -n "$still" ]; then
      # Removed together so their dependencies on each other don't block it.
      # shellcheck disable=SC2086
      if run "$BREW" uninstall --formula $still; then
        ok "removed:$still"
      else
        problem "brew uninstall failed; something else may depend on these:$still"
      fi
    fi
  fi
fi

step "Cleaning up"
if [ "$PROBLEMS" -gt 0 ]; then
  warn "$PROBLEMS item(s) need a look (see above). Kept $(tilde "$STATE_DIR") so nothing is lost."
  exit 1
fi
run rm -rf "$STATE_DIR" && ok "removed $(tilde "$STATE_DIR")"
# Folders install.sh created to hold its state, deepest first, only if empty
for d in $STATEDIRS; do
  dir="$(expand_home "$d")"
  [ -d "$dir" ] && run rmdir "$dir" 2>/dev/null && ok "removed empty $d"
done

step "Done"
if [ "$DRY_RUN" = 1 ]; then
  info "dry run: nothing was changed"
else
  info "Open a new Terminal window (quit and reopen Terminal for the profile change)."
fi
