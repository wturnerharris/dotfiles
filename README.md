# Dotfiles
Configs for vim, git, and [Hyper](https://hyper.is/). Almost all of these settings were borrowed from [@colepeters](https://github.com/colepeters), [@mrmrs](https://github.com/mrmrs), based on Cole's comments, the [YADR](https://github.com/skwp/dotfiles) dotfiles library, and curated by [@estrattonbailey](https://github.com/estrattonbailey), including finding this matching terminal theme [like this one](https://github.com/nathanbuchar/atom-one-dark-terminal) for terminal and iterm.

My enhancements include some bash alias for helpful shortcuts around the Mac.

## Install
1. Clone this repo to a directory in your root.
```bash
git clone git@github.com:wturnerharris/dotfile.git ~/.dotfile
```

2. Install or update vim. Autocompletion requires that it be installed with Lua.
```bash
brew install vim --with-lua
brew upgrade vim
```

3. Create symlinks:
```bash
ln -s ~/.dotfile/vimrc/ ~/.vimrc
ln -s ~/.dotfile/gitconfig ~/.gitconfig
ln -s ~/.dotfile/gitignore_global ~/.gitignore_global
ln -s ~/.dotfile/hyper.js ~/.hyper.js
ln -s ~/.dotfile/.bash_alias ~/.bash_alias
```

4. Install Vim Plug:
For more info, check out [the repo](https://github.com/junegunn/vim-plug), otherwise just use the CURL below.
```bash
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
```

5. Install plugins:
```bash
vim +PlugInstall +qa
```

6. Use it:
```bash
vim <filename>
```

7. Profit:
```bash
echo "source ~/.bash_alias" >> ~/.bashrc
```

## Usage
- `,` - LEADER 
- `h` - move left
- `j` - move down
- `k` - move up
- `l` - move right
- `i` - enter insert mode
- `a` - move to next character and enter insert mode
- `A` - go to end of line in insert mode
- `v` - enter visual selection mode
- `V` - select whole line 
- `e` - go to end of next word
- `b` - go to beginning of last word
- `$` - go to end of line
- `0` - go to beginning of line
- `o` - add line above
- `O` - add line below
- `H` - go to top of window
- `L` - go to bottom of window
- `y` - copy to system clipboard
- `p` - paste from system clipboard
- `u` - undo
- `Ctrl+r` - redo
- `/` - begin search
- `//` - clear last search

MIT License
