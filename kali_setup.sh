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

# Ensure .zshrc exists
touch ~/.zshrc

# Backup existing .zshrc
if [ -f ~/.zshrc ]; then
    cp ~/.zshrc ~/.zshrc.bak-$(date +%Y%m%d-%H%M%S)
    echo "Backed up .zshrc to ~/.zshrc.bak-$(date +%Y%m%d-%H%M%S)"
fi

# Remove all conflicting prompt settings
echo "Removing old and conflicting prompt settings from .zshrc..."
sed -i '/# Custom Zsh prompt/,/\$/d' ~/.zshrc
sed -i '/configure_prompt/d' ~/.zshrc
sed -i '/PROMPT_ALTERNATIVE/d' ~/.zshrc
sed -i '/START KALI CONFIG VARIABLES/,/STOP KALI CONFIG VARIABLES/d' ~/.zshrc
sed -i '/prompt_symbol/d' ~/.zshrc
sed -i '/case "$PROMPT_ALTERNATIVE" in/,/esac/d' ~/.zshrc
sed -i '/PROMPT=/d' ~/.zshrc
sed -i '/if \[ "$color_prompt" = yes \] then/,/fi/d' ~/.zshrc
sed -i '/color_prompt=/d' ~/.zshrc
sed -i '/force_color_prompt/d' ~/.zshrc
sed -i '/toggle_oneline_prompt/d' ~/.zshrc
sed -i '/zle -N toggle_oneline_prompt/d' ~/.zshrc
sed -i '/bindkey \^P toggle_oneline_prompt/d' ~/.zshrc
sed -i '/RPROMPT=/d' ~/.zshrc
sed -i '/NEWLINE_BEFORE_PROMPT/d' ~/.zshrc

# Append custom prompt to .zshrc
echo "Adding custom prompt to .zshrc..."
cat << 'EOF' >> ~/.zshrc

# Custom Zsh prompt with date, time, user@host, and cwd
autoload -Uz add-zsh-hook  # Ensure prompt-related functions are available
PROMPT='%F{green}[%D{%a %b %d} %T]%f %F{yellow}%n%f@%F{red}%m%f %F{blue}[%~]%f\$ '
EOF
echo "Custom prompt added to .zshrc."

# Fix permissions on .zshrc
echo "Fixing permissions on .zshrc..."
chmod 644 ~/.zshrc
chown $USER:$USER ~/.zshrc

# Reload .zshrc if running in Zsh, otherwise inform user
if [ -n "$ZSH_VERSION" ]; then
    echo "Reloading Zsh configuration..."
    if ! source ~/.zshrc; then
        echo "Warning: Failed to reload .zshrc. Try manually with 'source ~/.zshrc'"
    else
        echo "Current prompt after reload: $PROMPT"
    fi
else
    echo "Not running in Zsh. To apply changes, run 'source ~/.zshrc' or switch to Zsh with 'zsh'"
    echo "To make Zsh your default shell, run 'chsh -s $(which zsh)' and log out/in."
fi

echo "Kali setup complete at $(date). You’re ready to roll!"
