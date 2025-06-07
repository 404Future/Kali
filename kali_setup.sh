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

# Check if custom prompt already exists to avoid duplicates
if grep -q "Custom Zsh prompt" ~/.zshrc; then
    echo "Custom prompt already configured in .zshrc. Skipping..."
else
    # Append custom prompt to .zshrc
    cat << 'EOF' >> ~/.zshrc

# Custom Zsh prompt with date, time, user@host, and cwd
PROMPT="%F{green}[%D{%a %b %d} %*]%f-%F{yellow}%n%f@%F{red}%m%f
%F{blue}[%~]%f\$ "
EOF
    echo "Custom prompt added to .zshrc."
fi

# Reload .zshrc if running in Zsh, otherwise inform user
if [ -n "$ZSH_VERSION" ]; then
    echo "Reloading Zsh configuration..."
    if ! source ~/.zshrc; then
        echo "Warning: Failed to reload .zshrc. Try manually with 'source ~/.zshrc'"
    fi
else
    echo "Not running in Zsh. To apply changes, run 'source ~/.zshrc' or switch to Zsh with 'zsh'"
fi

echo "Kali setup complete at $(date). You’re ready to roll!"
