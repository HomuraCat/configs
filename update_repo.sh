#!/usr/bin/env bash

# neovim
rm -rf nvim/*
cp -r ~/.config/nvim/* nvim/ 2&> /dev/null

# tmux
rm -rf tmux/*
cp -r ~/.config/tmux/* tmux/ 2&> /dev/null
cp ~/.config/tmux/.tmux.conf tmux/.tmux.conf 2&> /dev/null

# fish
rm -rf fish/*
cp -r ~/.config/fish/* fish/ 2&> /dev/null

# kitty
rm -rf kitty/*
cp -r ~/.config/kitty/* kitty/ 2&> /dev/null

# system
rm -rf system/*
cp ~/.config/system/* system/ 2&> /dev/null

# git config
cp ~/.gitconfig .gitconfig 2&> /dev/null

# deprecated
rm -rf alacritty/* emacs/* zsh/*
cp ~/.config/alacritty/* alacritty/ 2&> /dev/null
cp ~/.config/emacs/*.el emacs/ 2&> /dev/null
cp ~/.config/zsh/.zshrc zsh/ 2&> /dev/null
cp ~/.zshenv zsh/ 2&> /dev/null

# brew
switch (uname)
    case Darwin
        brew list --formula > brew_output.txt
        brew list --cask > brew_cask_output.txt
    case '*'
end
