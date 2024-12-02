#!/bin/zsh

THEME="baddcafe"
THEME_NAME="$THEME.zsh-theme"
GIST_URL="https://gist.githubusercontent.com/dimgatz98/1d1363667ff4c64398b9a2e6f03c1322/raw/$THEME_NAME"

ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}
THEME_DIR="$ZSH_CUSTOM/themes"

mkdir -p "$THEME_DIR"

curl -fsSL "$GIST_URL" -o "$THEME_DIR/$THEME_NAME"

sed -i.bak "s/^ZSH_THEME=.*/ZSH_THEME=\"$THEME\"/" ~/.zshrc

source ~/.zshrc

