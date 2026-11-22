# shellcheck shell=bash
# Aliases shared by zsh and bash. Client/work aliases live in shell/work.sh.

### Git
alias b='git rev-parse --abbrev-ref HEAD'
alias push='git push origin "$(b)"'
alias force-push='git push --force-with-lease origin "$(b)"'
alias git-diff='git diff --ignore-space-change'
alias version='git tag --sort v:refname | grep "^v" | tail -1'
alias bump='git commit -am "Update changelog and bump versions"'
alias process='git commit -am "Process scripts and/or styles"'
alias sync_basic='git push origin develop; git checkout master; git push origin master; git push origin $(version)'
alias sync_new='git push origin develop; git checkout main; git push origin main; git push origin $(version)'
# Increment the last number in a string: echo v1.2.9 | increment -> v1.2.10
alias increment="perl -pe 's/([0-9]+)\b/0\$1~01234567890/g' | perl -pe 's/0(?!9*~)|([0-9])(?=9*~[0-9]*?\1([0-9]))|~[0-9]*/\$2/g'"

### Network
alias ping='ping -c 4'
alias ipaddr='curl -s https://checkip.amazonaws.com'
alias flushdns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'
alias spy='sudo arp-scan --interface=en0 --localnet'
alias homevpn='sudo openvpn --config ~/.openvpn/client3.ovpn --ca ~/.openvpn/ca.crt --cert ~/.openvpn/client.crt --key ~/.openvpn/client.key'
alias ssh-fingerprint='ssh-keygen -lf'

### Homebrew
alias brewski='brew update && brew upgrade && brew cleanup && brew doctor'

### Files and system
alias sites='cd ~/Sites'
alias hosts='sudo vim /etc/hosts'
alias octal='stat -f "%Mp%Lp %N" *'
alias shrug='printf "%s" "¯\_(ツ)_/¯" | pbcopy'

### Dev
alias nukenode='rm -rf node_modules/ && npm i && npm run build'
alias docker-kill-all='docker ps --format "{{.ID}}" | xargs docker kill'
alias pg='pg_ctl -D "$HOMEBREW_PREFIX/var/postgres" -l "$HOMEBREW_PREFIX/var/postgres/server.log"'
alias brake='bundle exec rake'
