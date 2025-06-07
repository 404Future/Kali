#!/bin/bash

# Ensure script is run on Kali
OS_NAME=$(grep ^ID= /etc/os-release | cut -d= -f2 | tr -d '"')
if [[ "$OS_NAME" != "kali" ]]; then
    echo "Error: This script is intended for Kali Linux only. Detected OS: $OS_NAME"
    exit 1
fi

echo "Starting setup for Kali Linux at $(date)..."

# Check for sudo privileges
if ! sudo -n true 2>/dev/null; then
    echo "Error: This script requires sudo privileges. Please run as root or with sudo."
    exit 1
fi

# Step 1: Update and upgrade system
echo "Updating and upgrading system packages..."
if ! sudo apt update; then
    echo "Error: Failed to update package lists. Check your internet or sources."
    exit 1
fi
if ! sudo apt full-upgrade -y; then
    echo "Error: Failed to upgrade packages. Check logs for details."
    exit 1
fi

# Step 2: Install spice-vdagent
echo "Checking and installing spice-vdagent..."
if dpkg -l | grep -q spice-vdagent; then
    echo "spice-vdagent is already installed. Skipping..."
else
    if ! sudo apt install -y spice-vdagent; then
        echo "Error: Failed to install spice-vdagent. Check logs or internet."
        exit 1
    fi
    echo "spice-vdagent installed successfully."
fi

# Step 3: Check for Zsh and configure prompt
echo "Configuring Zsh prompt..."
if ! command -v zsh >/dev/null 2>&1; then
    echo "Zsh not found. Installing Zsh..."
    if ! sudo apt install -y zsh; then
        echo "Error: Failed to install Zsh. Skipping prompt configuration."
        exit 1
    fi
fi

# Ensure .zshrc exists for current user
ZSHRC="$HOME/.zshrc"
touch "$ZSHRC"

# Backup existing .zshrc
if [ -f "$ZSHRC" ]; then
    cp "$ZSHRC" "$ZSHRC.bak-$(date +%Y%m%d-%H%M%S)"
    echo "Backed up .zshrc to $ZSHRC.bak-$(date +%Y%m%d-%H%M%S)"
fi

# Remove all conflicting prompt settings
echo "Removing old and conflicting prompt settings from .zshrc..."
sed -i '/# Custom Zsh prompt/,/\$/d' "$ZSHRC"
sed -i '/configure_prompt/d' "$ZSHRC"
sed -i '/PROMPT_ALTERNATIVE/d' "$ZSHRC"
sed -i '/START KALI CONFIG VARIABLES/,/STOP KALI CONFIG VARIABLES/d' "$ZSHRC"
sed -i '/prompt_symbol/d' "$ZSHRC"
sed -i '/case "$PROMPT_ALTERNATIVE" in/,/esac/d' "$ZSHRC"
sed -i '/PROMPT=/d' "$ZSHRC"
sed -i '/if \[ "$color_prompt" = yes \] then/,/fi/d' "$ZSHRC"
sed -i '/color_prompt=/d' "$ZSHRC"
sed -i '/force_color_prompt/d' "$ZSHRC"
sed -i '/toggle_oneline_prompt/d' "$ZSHRC"
sed -i '/zle -N toggle_oneline_prompt/d' "$ZSHRC"
sed -i '/bindkey \^P toggle_oneline_prompt/d' "$ZSHRC"
sed -i '/RPROMPT=/d' "$ZSHRC"
sed -i '/NEWLINE_BEFORE_PROMPT/d' "$ZSHRC"

# Append custom prompt to .zshrc
echo "Adding custom prompt to .zshrc..."
cat << 'EOF' >> "$ZSHRC"

# Custom Zsh prompt with date, time, user@host, and cwd
autoload -Uz add-zsh-hook  # Ensure prompt-related functions are available
PROMPT='%F{green}[%D{%a %b %d} %T]%f %F{yellow}%n%f@%F{red}%m%f %F{blue}[%~]%f\$ '
EOF
echo "Custom prompt added to .zshrc."

# Fix permissions on .zshrc
echo "Fixing permissions on .zshrc..."
chmod 644 "$ZSHRC"
chown $USER:$USER "$ZSHRC"

# Check for global config overrides
echo "Checking for global Zsh config overrides..."
if [ -f /etc/zsh/zshrc ] && grep -q "PROMPT=" /etc/zsh/zshrc; then
    echo "Warning: /etc/zsh/zshrc contains PROMPT settings that may override .zshrc!"
fi
if [ -f "$HOME/.zprofile" ] && grep -q "PROMPT=" "$HOME/.zprofile"; then
    echo "Warning: $HOME/.zprofile contains PROMPT settings that may override .zshrc!"
fi

# Reload .zshrc if running in Zsh, otherwise inform user
if [ -n "$ZSH_VERSION" ]; then
    echo "Reloading Zsh configuration..."
    if ! source "$ZSHRC"; then
        echo "Warning: Failed to reload .zshrc. Try manually with 'source ~/.zshrc'"
    else
        echo "Current prompt after reload: $PROMPT"
    fi
else
    echo "Not running in Zsh. To apply changes, run 'source ~/.zshrc' or switch to Zsh with 'zsh'"
    echo "To make Zsh your default shell, run 'chsh -s $(which zsh)' and log out/in."
fi

echo "Kali setup complete at $(date). You’re ready to roll!"
