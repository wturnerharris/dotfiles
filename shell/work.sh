# shellcheck shell=bash
# Client/agency workflow aliases (Pantheon, WP Engine, Acquia, Lando).
# Off by default. Turn on by adding this line to ~/.private:
#   export DOTFILES_WORK=1
# Anything with hostnames, IPs or tokens belongs in ~/.private, not here.

alias test-tag='git tag --sort v:refname | grep _test_ | tail -1'
alias live-tag='git tag --sort v:refname | grep _live_ | tail -1'
alias increment-test='t=$(test-tag); p="pantheon_test_"; v=${t:${#p}}; echo $((v+1))'
alias increment-live='t=$(live-tag); p="pantheon_live_"; v=${t:${#p}}; echo $((v+1))'
alias pantheon-deploy-test='p="pantheon_test_$(increment-test)" && git tag "$p" && git push pantheon "$p"'
alias pantheon-deploy-live='p="pantheon_live_$(increment-live)" && git tag "$p" && git push pantheon "$p"'
alias sync_pantheon='git checkout develop && git push origin develop && git checkout master && git push origin master && git push pantheon master; git push origin $(version)'
alias sync_wpe='git checkout develop && git push origin develop && git checkout master && git push origin master && git push live master'
alias sync_acquia='git checkout develop && git push origin develop && git push acquia develop && git checkout master && git push origin master && git push acquia master'
alias php-syntax='git diff --diff-filter=ACMR --name-only origin/master | grep "\.php$" | xargs -L1 php -l'
alias terminus-login='terminus auth:login --machine-token="$PANTHEON_TOKEN"'
alias lando-login='lando terminus auth:login --machine-token="$PANTHEON_TOKEN"'
alias db='terminus site:pc --app=sequelpro "$(basename "$PWD").develop"'
alias list-multidevs='terminus multidev:list "$(basename "$PWD")" --field=Name'

# Tab completion for terminus (bash-style; zsh loads bashcompinit for it)
if command -v terminus >/dev/null 2>&1; then
  if [ -n "$ZSH_VERSION" ]; then
    autoload -Uz bashcompinit && bashcompinit
  fi
  _terminus_complete() {
    local cur=${COMP_WORDS[COMP_CWORD]}
    local IFS=$'\n'
    local opts=( $(terminus cli completions --line="$COMP_LINE" --point="$COMP_POINT") )
    if [ "${opts[0]}" = "<file>" ]; then
      COMPREPLY=( $(compgen -f -- "$cur") )
    else
      COMPREPLY=( "${opts[@]}" )
    fi
  }
  complete -o nospace -F _terminus_complete terminus
fi
