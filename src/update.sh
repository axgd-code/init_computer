#!/bin/bash

echo "=== Auto update packages - $(date) ==="

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

echo "Detected system: ${MACHINE}"

if [ "${MACHINE}" = "Mac" ]; then
    echo "Updating via Homebrew..."
    
    # Vérifier si Homebrew est installé
    if command -v brew &> /dev/null; then
        echo "  - Updating Homebrew..."
        brew update
        
        echo "  - Upgrading packages..."
        brew upgrade
        
        echo "  - Upgrading casks..."
        brew upgrade --cask --greedy
        
        echo "  - Cleaning..."
        brew cleanup
        
        echo "  - Checking system status..."
        brew doctor || true
        
        echo "✓ macOS update completed"
    else
        echo "✗ Homebrew is not installed"
        exit 1
    fi

elif [ "${MACHINE}" = "Windows" ]; then
    echo "Updating via Chocolatey..."
    
    # Vérifier si Chocolatey est installé
    if command -v choco &> /dev/null; then
        echo "  - Upgrading all packages..."
        choco upgrade all -y
        
        echo "✓ Windows update completed"
    else
        echo "✗ Chocolatey is not installed"
        exit 1
    fi

elif [ "${MACHINE}" = "Linux" ]; then
    echo "Updating Linux..."
    
    # Détecter le gestionnaire de packages
    if command -v apt-get &> /dev/null; then
        echo "  - Updating via apt..."
        sudo apt-get update
        sudo apt-get upgrade -y
        sudo apt-get autoremove -y
        sudo apt-get autoclean
        echo "✓ Linux update (apt) completed"
        
    elif command -v dnf &> /dev/null; then
        echo "  - Updating via dnf..."
        sudo dnf upgrade -y
        sudo dnf autoremove -y
        echo "✓ Linux update (dnf) completed"
        
    elif command -v yum &> /dev/null; then
        echo "  - Updating via yum..."
        sudo yum update -y
        sudo yum autoremove -y
        echo "✓ Linux update (yum) completed"
        
    else
        echo "✗ No recognized package manager"
        exit 1
    fi
else
    echo "✗ Unsupported operating system: ${MACHINE}"
    exit 1
fi

echo "=== Update finished at $(date) ==="
