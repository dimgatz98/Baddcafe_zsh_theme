#!/bin/zsh

THEME="baddcafe"
THEME_NAME="$THEME.zsh-theme"
GIST_URL="https://gist.githubusercontent.com/dimgatz98/1d1363667ff4c64398b9a2e6f03c1322/raw/$THEME_NAME"

ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}
THEME_DIR="$ZSH_CUSTOM/themes"
ZSHRC="$HOME/.zshrc"
ZSHRC_BACKUP_DIR="$HOME/$THEME"
ZSHRC_BACKUP="$ZSHRC_BACKUP_DIR/zshrc.bak"

install_theme() {
    mkdir -p "$THEME_DIR"

    # Download the theme
    curl -fsSL "$GIST_URL" -o "$THEME_DIR/$THEME_NAME"
    echo "Theme downloaded successfully."

    # Check if the theme is already set to baddcafe
    if grep -q "^ZSH_THEME=\"$THEME\"$" "$ZSHRC"; then
        echo "The theme is already set to $THEME. No changes are needed."
        exit 0
    fi

    # Backup .zshrc if not already backed up
    mkdir -p $ZSHRC_BACKUP_DIR
    if [[ ! -f "$ZSHRC_BACKUP" ]]; then
        cp "$ZSHRC" "$ZSHRC_BACKUP"
    fi

    # Modify .zshrc to use the new theme
    if grep -q "^ZSH_THEME=" "$ZSHRC"; then
        sed -i.bak "s/^ZSH_THEME=.*$/# &\nZSH_THEME=\"$THEME\"/" "$ZSHRC"  # Comment out the existing ZSH_THEME line
    else
        # echo "ZSH_THEME=\"$THEME\"" >> "$ZSHRC"
        sed -i "1s/^/ZSH_THEME=\"$THEME\"\n/" "$ZSHRC"
    fi

    echo "Theme installed successfully. Please restart your terminal or run 'source ~/.zshrc' to apply the changes."
}

uninstall_theme() {
    # Remove the theme file
    if [[ -f "$THEME_DIR/$THEME_NAME" ]]; then
        rm "$THEME_DIR/$THEME_NAME"
        echo "Theme file removed."
    else
        echo "Theme file not found."
    fi

    # Restore the original ZSH_THEME line
    if [[ -f "$ZSHRC_BACKUP" ]]; then
        mv "$ZSHRC_BACKUP" "$ZSHRC"
        echo "Original .zshrc restored from backup."
    else
        echo "Backup file not found. Please manually restore your .zshrc if necessary."
    fi

    echo "Theme uninstalled successfully."
}

show_help() {
    echo "Usage: $0 [option]"
    echo "Options:"
    echo "  (no argument)    Install the theme."
    echo "  uninstall        Uninstall the theme and restore previous configuration."
    echo "  help             Show this help message."
}

if [[ "$1" == "uninstall" ]]; then
    uninstall_theme
elif [[ -z "$1" ]]; then
    install_theme
else
    show_help
fi
