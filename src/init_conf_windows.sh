#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_CONF="${SCRIPT_DIR}/packages.conf"

echo "Configuration de Windows..."

# Installation et configuration de Chocolatey si nécessaire
if ! command -v choco &> /dev/null; then
    echo "Installation de Chocolatey..."
    # Pour Git Bash/WSL, on doit utiliser PowerShell pour installer Chocolatey
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
    
    # Recharger le PATH
    export PATH="$PATH:/c/ProgramData/chocolatey/bin"
fi

echo "Installation des applications via Chocolatey..."

# Lecture du fichier packages.conf et installation des packages Windows
while IFS='|' read -r type mac_name win_name desc; do
    # Ignorer les commentaires et lignes vides
    [[ "$type" =~ ^#.*$ ]] && continue
    [[ -z "$type" ]] && continue
    
    # Installer si le package existe pour Windows
    if [ "$win_name" != "-" ] && [ -n "$win_name" ]; then
        echo "  - Installation: $win_name ($desc)"
        choco install -y "$win_name"
    fi
done < "${PACKAGES_CONF}"

echo "Configuration des paramètres Windows..."

# Configuration Git (si besoin)
# git config --global user.name "Votre Nom"
# git config --global user.email "votre.email@example.com"

echo "Configuration terminée!"
echo "Note: Certaines applications peuvent nécessiter un redémarrage de Windows pour fonctionner correctement."
