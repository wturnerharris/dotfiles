# shellcheck shell=bash
# Functions shared by zsh and bash.

# Name of the repo's main branch: main if it exists, else master
_git_main_branch() {
  if git show-ref -q --verify refs/heads/main || git show-ref -q --verify refs/remotes/origin/main; then
    echo main
  else
    echo master
  fi
}

# Reset the local main/master branch to match origin
gituptodate() {
  local main local_sha remote_sha
  main=$(_git_main_branch)
  git fetch --all || return
  local_sha=$(git rev-parse "$main") || return
  remote_sha=$(git rev-parse "origin/$main") || return
  if [ "$local_sha" != "$remote_sha" ]; then
    git checkout "$main" && git reset --hard "$remote_sha" || return
    echo "Updated local $main $(echo "$local_sha" | cut -c1-7) -> $(echo "$remote_sha" | cut -c1-7)"
    git status
  else
    echo "$main is already up to date with origin/$main"
  fi
}

# Delete every local branch except main/master/develop and the current one
gittyup() {
  git branch --format='%(refname:short)' \
    | grep -vxE "main|master|develop|$(git rev-parse --abbrev-ref HEAD)" \
    | xargs -n 1 git branch -D
}

# Copy this machine's SSH public key to the clipboard
sshkey() {
  local k
  for k in ~/.ssh/id_ed25519.pub ~/.ssh/id_rsa.pub; do
    if [ -f "$k" ]; then pbcopy < "$k" && echo "Copied $k"; return; fi
  done
  echo "No SSH public key found in ~/.ssh" >&2; return 1
}

# Hide or show a file in Finder: hide on|off path
hide() {
  if [ $# -lt 2 ] || [ "$1" = "help" ]; then
    echo "Usage: hide on|off path_to_file"; return 1
  fi
  local flag=nohidden
  [ "$1" = "on" ] && flag=hidden
  chflags "$flag" "$2" 2>/dev/null || sudo chflags "$flag" "$2"
}

# Add a user to a group: adduser <user> <group>
adduser() {
  if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: adduser <user> <group>"; return 1
  fi
  sudo dseditgroup -o edit -a "$1" -t user "$2"
}
