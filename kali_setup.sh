#!/bin/bash

# -----------------------------------------------------
# 1) Ensure script is run on Kali Linux
# -----------------------------------------------------
OS_NAME=$(grep ^ID= /etc/os-release | cut -d= -f2 | tr -d '"')
if [[ "$OS_NAME" != "kali" ]]; then
    echo "Error: This script is intended for Kali Linux only. Detected OS: $OS_NAME"
    exit 1
fi

echo "Starting Kali setup at $(date)..."

# -----------------------------------------------------
# 2) Detect if we were invoked under sudo (so we know whose ~/.zshrc to edit)
# -----------------------------------------------------
if [[ -n "$SUDO_USER" && "$SUDO_USER" != "root" ]]; then
    TARGET_USER="$SUDO_USER"
    TARGET_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    TARGET_USER="$USER"
    TARGET_HOME="$HOME"
fi

ZSHRC="$TARGET_HOME/.zshrc"

echo "→ Will install and configure prompt for user: $TARGET_USER (home: $TARGET_HOME)"

# -----------------------------------------------------
# 3) Check for sudo privileges (because we need to apt-install packages and maybe edit /etc files)
# -----------------------------------------------------
if ! sudo -n true 2>/dev/null; then
    echo "Error: This script requires sudo privileges. Please run as root or with sudo."
    exit 1
fi

# -----------------------------------------------------
# 4) Update & upgrade
# -----------------------------------------------------
echo "Updating package lists..."
if ! sudo apt update; then
    echo "Error: apt update failed."
    exit 1
fi
echo "Upgrading packages..."
if ! sudo apt full-upgrade -y; then
    echo "Error: apt full-upgrade failed."
    exit 1
fi

# -----------------------------------------------------
# 5) Install spice-vdagent if missing
# -----------------------------------------------------
echo "Checking for spice-vdagent..."
if dpkg -l | grep -q spice-vdagent; then
    echo "spice-vdagent already installed; skipping."
else
    echo "Installing spice-vdagent..."
    if ! sudo apt install -y spice-vdagent; then
        echo "Error: Failed to install spice-vdagent."
        exit 1
    fi
    echo "spice-vdagent installed."
fi

# -----------------------------------------------------
# 6) Install Zsh if needed
# -----------------------------------------------------
echo "Ensuring zsh is installed..."
if ! command -v zsh >/dev/null 2>&1; then
    echo "Zsh not found, installing..."
    if ! sudo apt install -y zsh; then
        echo "Error: Failed to install zsh. Exiting."
        exit 1
    fi
fi

# -----------------------------------------------------
# 7) Backup and prepare ~/.zshrc
# -----------------------------------------------------
# Make sure the target home dir exists (should, if passwd entry is valid)
if [[ ! -d "$TARGET_HOME" ]]; then
    echo "Error: Cannot find home directory for $TARGET_USER: $TARGET_HOME"
    exit 1
fi

# Create ~/.zshrc if missing
if [[ ! -f "$ZSHRC" ]]; then
    echo "→ Creating new $ZSHRC"
    sudo -u "$TARGET_USER" touch "$ZSHRC"
fi

# Backup existing ~/.zshrc
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
sudo -u "$TARGET_USER" cp "$ZSHRC" "${ZSHRC}.bak-$TIMESTAMP"
echo "Backed up $ZSHRC to ${ZSHRC}.bak-$TIMESTAMP"

# -----------------------------------------------------
# 8) Remove any prior “KALI_CUSTOM_PROMPT” block in ~/.zshrc
#    (so we don’t accumulate multiple copies over repeated runs)
# -----------------------------------------------------
sudo -u "$TARGET_USER" sed -i \
    '/## >>> KALI_CUSTOM_PROMPT >>>/,/## <<< KALI_CUSTOM_PROMPT <<</d' \
    "$ZSHRC"

# -----------------------------------------------------
# 9) Append our new prompt block (wrapped in markers)
# -----------------------------------------------------
echo "Adding new custom prompt block to $ZSHRC..."
sudo -u "$TARGET_USER" bash -c "cat << 'EOF' >> \"$ZSHRC\"

## >>> KALI_CUSTOM_PROMPT >>>
# Custom Zsh prompt: [Day Mon DD HH:MM:SS] user@host [cwd]$
autoload -Uz add-zsh-hook   # ensure prompt‐related functions are available
PROMPT='%F{green}[%D{%a %b %d} %T]%f %F{yellow}%n%f@%F{red}%m%f %F{blue}[%~]%f \$ '
## <<< KALI_CUSTOM_PROMPT <<<
EOF"

# -----------------------------------------------------
# 10) Fix permissions on ~/.zshrc
# -----------------------------------------------------
sudo chmod 644 "$ZSHRC"
sudo chown "$TARGET_USER":"$TARGET_USER" "$ZSHRC"

# -----------------------------------------------------
# 11) Warn about global overrides in /etc/zsh/zshrc or ~/.zprofile
# -----------------------------------------------------
echo "Checking for global Zsh overrides..."

if sudo grep -q '^ *PROMPT=' /etc/zsh/zshrc 2>/dev/null; then
    echo "WARNING: /etc/zsh/zshrc has its own PROMPT= setting. That may override your ~/.zshrc."
fi

if [[ -f "$TARGET_HOME/.zprofile" ]] && grep -q '^ *PROMPT=' "$TARGET_HOME/.zprofile"; then
    echo "WARNING: $TARGET_HOME/.zprofile contains PROMPT=. It could override ~/.zshrc."
fi

# -----------------------------------------------------
# 12) Advise about reloading
# -----------------------------------------------------
if [[ -n "$ZSH_VERSION" ]]; then
    echo "Reloading new Zsh config right now..."
    # We want to source the user’s .zshrc, but ensure we run as that user if we did sudo earlier
    if [[ "$USER" == "$TARGET_USER" ]]; then
        source "$ZSHRC"
    else
        echo "NOTE: You’re in a different user shell. Run as $TARGET_USER to source $ZSHRC."
    fi
    echo "→ If your prompt didn’t immediately change, open a new terminal or run: zsh -i"
else
    echo "Not running under Zsh, so cannot auto-reload. To see your new prompt, do one of the following:"
    echo "  1) As $TARGET_USER, run:  source \"$ZSHRC\""
    echo "  2) Make Zsh your default: chsh -s \$(which zsh) (then log out/in)"
fi

echo "Kali setup complete at $(date)."
