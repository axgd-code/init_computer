#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load .env.local if available
if [ -f "${SCRIPT_DIR}/../.env.local" ]; then
    # shellcheck disable=SC1091
    source "${SCRIPT_DIR}/../.env.local"
fi

# Determine path to packages.conf
if [ -n "${PACKAGES_CONF_DIR:-}" ] && [ -f "${PACKAGES_CONF_DIR}/packages.conf" ]; then
    PACKAGES_CONF="${PACKAGES_CONF_DIR}/packages.conf"
elif [ -f "${SCRIPT_DIR}/packages.conf" ]; then
    PACKAGES_CONF="${SCRIPT_DIR}/packages.conf"
else
    PACKAGES_CONF="${SCRIPT_DIR}/packages.conf.example"
fi

echo "Configuring Windows..."

# Install and configure Chocolatey if needed
if ! command -v choco &> /dev/null; then
    echo "Installing Chocolatey..."
    # For Git Bash/WSL, use PowerShell to install Chocolatey
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
    
    # Reload PATH
    export PATH="$PATH:/c/ProgramData/chocolatey/bin"
fi

echo "Installing applications via Chocolatey..."

# Lecture du fichier packages.conf et installation des packages Windows
while IFS='|' read -r type mac_name win_name desc; do
    # Ignore comments and empty lines
    [[ "$type" =~ ^#.*$ ]] && continue
    [[ -z "$type" ]] && continue
    
    # Install if the package exists for Windows
    if [ "$win_name" != "-" ] && [ -n "$win_name" ]; then
        echo "  - Installation: $win_name ($desc)"
        choco install -y "$win_name"
    fi
done < "${PACKAGES_CONF}"

echo "Applying Windows settings..."

# Git configuration (if needed)
# git config --global user.name "Votre Nom"
# git config --global user.email "votre.email@example.com"

echo "Configuration completed!"
echo "Note: Some applications may require a Windows restart to work correctly."
