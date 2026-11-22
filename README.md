# Dotfiles

Shell, vim, git and Terminal settings for macOS. zsh first (the macOS default), with bash
kept working for machines that still use it.

Originally borrowed from [@colepeters](https://github.com/colepeters), [@mrmrs](https://github.com/mrmrs),
[YADR](https://github.com/skwp/dotfiles) and [@estrattonbailey](https://github.com/estrattonbailey),
with the [One Dark](https://github.com/nathanbuchar/atom-one-dark-terminal) terminal colors.

## Install

```sh
git clone git@github.com:wturnerharris/dotfiles.git ~/.dotfiles
~/.dotfiles/install.sh --dry-run   # see what it would do
~/.dotfiles/install.sh
```

Then quit and reopen Terminal.

The installer:

- links `~/.zshrc`, `~/.zprofile`, `~/.gitconfig`, `~/.gitignore_global` and `~/.vimrc` to this repo
  (plus `~/.bashrc` and `~/.bash_profile` with `--bash`, or when your login shell is bash);
- moves any file it replaces into `~/.local/state/dotfiles/backups/`; if it replaces a real
  `~/.gitconfig`, that machine's old settings are kept in `~/.gitconfig.local`;
- installs `vim`, `fzf`, `zsh-autosuggestions` and `zsh-syntax-highlighting` with Homebrew,
  skipping any that Homebrew would have to compile (common on Intel Macs). Then the system vim
  is used, and vim-plug downloads fzf's prebuilt binary into `~/.vim/plugged/fzf` instead.
  `--allow-source-builds` compiles them anyway;
- installs [vim-plug](https://github.com/junegunn/vim-plug) and the vim plugins into `~/.vim`;
- imports the **One Dark** Terminal profile and makes it the default.

Options: `--dry-run`, `--bash`, `--no-brew`, `--allow-source-builds`, `--no-vim`, `--no-terminal`. Running it again is safe.

## Uninstall

```sh
~/.dotfiles/uninstall.sh --dry-run   # see what it would do
~/.dotfiles/uninstall.sh
```

Puts the machine back the way it was before `install.sh`: restores every backed-up file, removes
the links and anything the installer created (`~/.vim`, `~/.gitconfig.local`, `~/.zcompdump`),
uninstalls the Homebrew formulae it added (dependencies included), removes the Terminal profile
and restores the previous default. It works from the manifest at
`~/.local/state/dotfiles/manifest.tsv`, newest change first. Anything it can't safely undo
(for example a file you've since replaced by hand) is left alone and reported, and the backups are
kept. `--keep-packages` leaves the Homebrew formulae installed. The repo folder itself is left in
place.

## Layout

| Path | What |
| --- | --- |
| `zsh/zshrc`, `zsh/zprofile` | zsh: history, completion, prompt, fzf, plugins |
| `bash/bashrc`, `bash/bash_profile` | the same for bash |
| `shell/env.sh` | exports and PATH shared by both shells |
| `shell/aliases.sh`, `shell/functions.sh` | aliases and functions shared by both shells |
| `shell/work.sh` | client aliases (Pantheon, WP Engine, Acquia, Lando); off by default |
| `git/gitconfig`, `git/gitignore_global` | git settings and aliases |
| `vim/vimrc` | vim settings, keys and plugins |
| `terminal/One Dark.terminal` | Terminal.app profile (Menlo 14) |

## Machine-only settings (never committed)

| File | Use |
| --- | --- |
| `~/.private` | secrets and tokens (e.g. `PANTHEON_TOKEN`), private hosts and aliases. `~/.bash_private` is also read. |
| `~/.zshrc.local`, `~/.bashrc.local` | shell tweaks for one machine |
| `~/.gitconfig.local` | git settings for one machine |

To turn on the client aliases on a machine, add `export DOTFILES_WORK=1` to `~/.private`.

To use a work email for repos under one folder, add this to `~/.gitconfig.local`:

```ini
[includeIf "gitdir:~/work/"]
	path = ~/.gitconfig.work
```

and put `[user]` with the work `email` in `~/.gitconfig.work`.

## Shell

Prompt: a blank line, `user@host:` in green, the path in yellow, then `$` on its own line.

| Alias / function | Does |
| --- | --- |
| `b` | current git branch |
| `push`, `force-push` | push the current branch to origin (`force-push` uses `--force-with-lease`) |
| `gituptodate` | reset local main/master to origin |
| `gittyup` | delete every local branch except main, master, develop and the current one |
| `version` | latest `v*` tag |
| `sync_basic`, `sync_new` | push develop and master/main plus the latest tag |
| `ipaddr` | public IP address |
| `flushdns` | flush the DNS cache |
| `brewski` | update, upgrade, clean up and check Homebrew |
| `sshkey` | copy your SSH public key to the clipboard |
| `hide on\|off <file>` | hide or show a file in Finder |

fzf adds Ctrl-R (history search), Ctrl-T (file picker) and Alt-C (cd into a folder).

## Vim

`,` is the leader.

| Keys | Does |
| --- | --- |
| `//` | clear search highlight |
| `vv`, `ss` | vertical, horizontal split |
| `Ctrl-h/j/k/l` | move between splits |
| `th tj tk tl tn tm` | first, next, previous, last, new, move tab |
| `,ff` `,fg` `,fb` `,fl` | fzf: files, git files, buffers, lines |
| `,jr` `,js` `,jd` | fzf: files in the repo, `src/`, `dist/` |
| `,fi` | search the repo (vim-grepper) |
| `Enter` | add a line below without entering insert mode |
| `rr` | reload `~/.vimrc` |
| `Ctrl-n` / `Ctrl-p` | built-in completion in insert mode |

Plugins: onedark, airline, fugitive, surround, commentary, delimitMate, grepper, fzf.vim,
liquid, mustache/handlebars.

MIT License
