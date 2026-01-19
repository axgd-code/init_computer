#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_CONF="${SCRIPT_DIR}/packages.conf"

run_wifi_import() {
    if [ -z "${WIFI_KDBX_DB:-}" ]; then
        echo "Wi-Fi: variable WIFI_KDBX_DB non définie, étape sautée."
        return
    fi

    if [ ! -f "${WIFI_KDBX_DB}" ]; then
        echo "Wi-Fi: fichier kdbx introuvable (${WIFI_KDBX_DB}), étape sautée."
        return
    fi

    if [ ! -x "${SCRIPT_DIR}/wifi_from_kdbx.sh" ]; then
        if [ -f "${SCRIPT_DIR}/wifi_from_kdbx.sh" ]; then
            chmod +x "${SCRIPT_DIR}/wifi_from_kdbx.sh" 2>/dev/null || true
        else
            echo "Wi-Fi: script wifi_from_kdbx.sh non trouvé, étape sautée."
            return
        fi
    fi

    if ! command -v keepassxc-cli >/dev/null 2>&1; then
        echo "Wi-Fi: keepassxc-cli non disponible, étape sautée."
        return
    fi

    WIFI_ARGS=(--db "${WIFI_KDBX_DB}")
    [ -n "${WIFI_KDBX_GROUP:-}" ] && WIFI_ARGS+=(--group "${WIFI_KDBX_GROUP}")
    [ -n "${WIFI_KDBX_KEY_FILE:-}" ] && WIFI_ARGS+=(--key-file "${WIFI_KDBX_KEY_FILE}")
    [ "${WIFI_KDBX_DRY_RUN:-0}" = "1" ] && WIFI_ARGS+=(--dry-run)
    [ "${WIFI_KDBX_ASK_PASS:-0}" = "1" ] && WIFI_ARGS+=(--ask-pass)

    echo "Wi-Fi: import des profils depuis le vault..."
    bash "${SCRIPT_DIR}/wifi_from_kdbx.sh" "${WIFI_ARGS[@]}"
}

echo "Début de l'installation"

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
    echo "Configuration pour macOS..."
    
    #Vérifie si Homebrew est déjà installé
    if ! command -v brew >/dev/null 2>&1; then
        echo "Installing homebrew…"
        export HOMEBREW_BREW_GIT_REMOTE="..."  # put your Git mirror of Homebrew/brew here
        export HOMEBREW_CORE_GIT_REMOTE="..."  # put your Git mirror of Homebrew/homebrew-core here
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    brew update

    echo "Installation des taps…"
    while IFS='|' read -r type mac_name win_name desc; do
        # Ignorer les commentaires et lignes vides
        [[ "$type" =~ ^#.*$ ]] && continue
        [[ -z "$type" ]] && continue
        
        if [ "$type" = "tap" ] && [ "$mac_name" != "-" ]; then
            echo "  - Ajout du tap: $mac_name"
            brew tap "$mac_name"
        fi
    done < "${PACKAGES_CONF}"

    echo "Installation des packages brew…"
    while IFS='|' read -r type mac_name win_name desc; do
        [[ "$type" =~ ^#.*$ ]] && continue
        [[ -z "$type" ]] && continue
        
        if [ "$type" = "brew" ] && [ "$mac_name" != "-" ]; then
            echo "  - Installation: $mac_name"
            brew install "$mac_name"
        fi
    done < "${PACKAGES_CONF}"

    echo "Installation des applications (cask)…"
    while IFS='|' read -r type mac_name win_name desc; do
        [[ "$type" =~ ^#.*$ ]] && continue
        [[ -z "$type" ]] && continue
        
        if [ "$type" = "cask" ] && [ "$mac_name" != "-" ]; then
            echo "  - Installation: $mac_name"
            brew install --cask "$mac_name"
        fi
    done < "${PACKAGES_CONF}"

    bash "${SCRIPT_DIR}/init_conf_macOs.sh"
    bash "${SCRIPT_DIR}/install_fonts.sh"

    echo "Nettoyage…"
    brew cleanup

    echo "Mise à jour automatique des brews"
    brew autoupdate start --upgrade --greedy --cleanup

elif [ "${MACHINE}" = "Windows" ]; then
    echo "Configuration pour Windows..."
    bash "${SCRIPT_DIR}/init_conf_windows.sh"
    
elif [ "${MACHINE}" = "Linux" ]; then
    echo "Linux détecté - script non configuré pour Linux"
    echo "Veuillez créer un init_conf_linux.sh pour Linux"
    exit 1
else
    echo "Système d'exploitation non supporté: ${MACHINE}"
    exit 1
fi

run_wifi_import

echo "Installation terminée"
