#!/usr/bin/env bash
echo "Installation des fonts…"
brew tap homebrew/cask-fonts
FONTS=(
    font-inconsolata-nerd-font
    font-roboto
    font-clear-sans
    font-montserrat
    font-open-sans
    font-poppins
)
brew install ${FONTS[@]}