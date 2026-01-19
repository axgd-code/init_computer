#!/bin/bash

echo "=== Mise à jour automatique des packages - $(date) ==="

# Détection du système d'exploitation
OS="$(uname -s)"
case "${OS}" in
    Linux*)     MACHINE=Linux;;
    Darwin*)    MACHINE=Mac;;
    CYGWIN*)    MACHINE=Windows;;
    MINGW*)     MACHINE=Windows;;
    MSYS*)      MACHINE=Windows;;
    *)          MACHINE="UNKNOWN:${OS}"
esac

echo "Système détecté: ${MACHINE}"

if [ "${MACHINE}" = "Mac" ]; then
    echo "Mise à jour via Homebrew..."
    
    # Vérifier si Homebrew est installé
    if command -v brew &> /dev/null; then
        echo "  - Mise à jour de Homebrew..."
        brew update
        
        echo "  - Mise à jour des packages..."
        brew upgrade
        
        echo "  - Mise à jour des casks..."
        brew upgrade --cask --greedy
        
        echo "  - Nettoyage..."
        brew cleanup
        
        echo "  - Vérification de l'état du système..."
        brew doctor || true
        
        echo "✓ Mise à jour macOS terminée"
    else
        echo "✗ Homebrew n'est pas installé"
        exit 1
    fi

elif [ "${MACHINE}" = "Windows" ]; then
    echo "Mise à jour via Chocolatey..."
    
    # Vérifier si Chocolatey est installé
    if command -v choco &> /dev/null; then
        echo "  - Mise à jour de tous les packages..."
        choco upgrade all -y
        
        echo "✓ Mise à jour Windows terminée"
    else
        echo "✗ Chocolatey n'est pas installé"
        exit 1
    fi

elif [ "${MACHINE}" = "Linux" ]; then
    echo "Mise à jour Linux..."
    
    # Détecter le gestionnaire de packages
    if command -v apt-get &> /dev/null; then
        echo "  - Mise à jour via apt..."
        sudo apt-get update
        sudo apt-get upgrade -y
        sudo apt-get autoremove -y
        sudo apt-get autoclean
        echo "✓ Mise à jour Linux (apt) terminée"
        
    elif command -v dnf &> /dev/null; then
        echo "  - Mise à jour via dnf..."
        sudo dnf upgrade -y
        sudo dnf autoremove -y
        echo "✓ Mise à jour Linux (dnf) terminée"
        
    elif command -v yum &> /dev/null; then
        echo "  - Mise à jour via yum..."
        sudo yum update -y
        sudo yum autoremove -y
        echo "✓ Mise à jour Linux (yum) terminée"
        
    else
        echo "✗ Aucun gestionnaire de packages reconnu"
        exit 1
    fi
else
    echo "✗ Système d'exploitation non supporté: ${MACHINE}"
    exit 1
fi

echo "=== Mise à jour terminée à $(date) ==="
