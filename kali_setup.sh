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

echo "Kali setup complete at $(date)."
