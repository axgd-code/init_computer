#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Charger .env.local si disponible
if [ -f "${SCRIPT_DIR}/../.env.local" ]; then
    # shellcheck disable=SC1091
    source "${SCRIPT_DIR}/../.env.local"
fi

# Déterminer le chemin du fichier packages.conf
# Priorité : PACKAGES_CONF_DIR > local > example
if [ -n "${PACKAGES_CONF_DIR:-}" ] && [ -f "${PACKAGES_CONF_DIR}/packages.conf" ]; then
    PACKAGES_CONF="${PACKAGES_CONF_DIR}/packages.conf"
    echo "Using synchronized packages.conf: ${PACKAGES_CONF}"
elif [ -f "${SCRIPT_DIR}/packages.conf" ]; then
    PACKAGES_CONF="${SCRIPT_DIR}/packages.conf"
else
    PACKAGES_CONF="${SCRIPT_DIR}/packages.conf.example"
    echo "Using packages.conf.example (create .env.local to customize)"
fi

export PACKAGES_CONF

run_wifi_import() {
    if [ -z "${WIFI_KDBX_DB:-}" ]; then
        echo "Wi‑Fi: WIFI_KDBX_DB variable not set, skipping."
        return
    fi

    if [ ! -f "${WIFI_KDBX_DB}" ]; then
        echo "Wi‑Fi: kdbx file not found (${WIFI_KDBX_DB}), skipping."
        return
    fi

    if [ ! -x "${SCRIPT_DIR}/wifi_from_kdbx.sh" ]; then
        if [ -f "${SCRIPT_DIR}/wifi_from_kdbx.sh" ]; then
            chmod +x "${SCRIPT_DIR}/wifi_from_kdbx.sh" 2>/dev/null || true
        else
            echo "Wi‑Fi: wifi_from_kdbx.sh script not found, skipping."
            return
        fi
    fi

    if ! command -v keepassxc-cli >/dev/null 2>&1; then
        echo "Wi‑Fi: keepassxc-cli not available, skipping."
        return
    fi

    WIFI_ARGS=(--db "${WIFI_KDBX_DB}")
    [ -n "${WIFI_KDBX_GROUP:-}" ] && WIFI_ARGS+=(--group "${WIFI_KDBX_GROUP}")
    [ -n "${WIFI_KDBX_KEY_FILE:-}" ] && WIFI_ARGS+=(--key-file "${WIFI_KDBX_KEY_FILE}")
    [ "${WIFI_KDBX_DRY_RUN:-0}" = "1" ] && WIFI_ARGS+=(--dry-run)
    [ "${WIFI_KDBX_ASK_PASS:-0}" = "1" ] && WIFI_ARGS+=(--ask-pass)

    echo "Wi‑Fi: importing profiles from vault..."
    bash "${SCRIPT_DIR}/wifi_from_kdbx.sh" "${WIFI_ARGS[@]}"
}

echo "Starting installation"

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
    echo "Configuring for macOS..."
    
    #Vérifie si Homebrew est déjà installé
    if ! command -v brew >/dev/null 2>&1; then
        echo "Installing homebrew…"
        export HOMEBREW_BREW_GIT_REMOTE="..."  # put your Git mirror of Homebrew/brew here
        export HOMEBREW_CORE_GIT_REMOTE="..."  # put your Git mirror of Homebrew/homebrew-core here
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    brew update

    echo "Installing taps..."
    while IFS='|' read -r type mac_name win_name desc; do
        # Ignorer les commentaires et lignes vides
        [[ "$type" =~ ^#.*$ ]] && continue
        [[ -z "$type" ]] && continue
        
        if [ "$type" = "tap" ] && [ "$mac_name" != "-" ]; then
            echo "  - Adding tap: $mac_name"
            brew tap "$mac_name"
        fi
    done < "${PACKAGES_CONF}"

    echo "Installing brew packages..."
    while IFS='|' read -r type mac_name win_name desc; do
        [[ "$type" =~ ^#.*$ ]] && continue
        [[ -z "$type" ]] && continue
        
        if [ "$type" = "brew" ] && [ "$mac_name" != "-" ]; then
            echo "  - Installing: $mac_name"
            brew install "$mac_name"
        fi
    done < "${PACKAGES_CONF}"

    echo "Installing cask applications..."
    while IFS='|' read -r type mac_name win_name desc; do
        [[ "$type" =~ ^#.*$ ]] && continue
        [[ -z "$type" ]] && continue
        
        if [ "$type" = "cask" ] && [ "$mac_name" != "-" ]; then
            echo "  - Installing: $mac_name"
            brew install --cask "$mac_name"
        fi
    done < "${PACKAGES_CONF}"

    bash "${SCRIPT_DIR}/init_conf_macOs.sh"
    bash "${SCRIPT_DIR}/install_fonts.sh"

    echo "Cleaning up..."
    brew cleanup

    echo "Enabling brew autoupdate"
    brew autoupdate start --upgrade --greedy --cleanup

elif [ "${MACHINE}" = "Windows" ]; then
    echo "Configuring for Windows..."
    bash "${SCRIPT_DIR}/init_conf_windows.sh"
    
elif [ "${MACHINE}" = "Linux" ]; then
    echo "Linux detected - script not configured for Linux"
    echo "Please create an init_conf_linux.sh for Linux"
    exit 1
else
    echo "Système d'exploitation non supporté: ${MACHINE}"
    exit 1
fi

run_wifi_import

echo "Installation completed"
