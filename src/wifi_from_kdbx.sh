#!/bin/bash

set -euo pipefail

# Import Wi-Fi profiles from a KeePassXC database (kdbx) using keepassxc-cli.
# Expected: entries in a group (default "Wi-Fi") where Title = SSID and Password = Wi-Fi key.
# Optional entry attributes: security (e.g., WPA2, WPA3, OPEN) and hidden (true/false) when supported.

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DB_FILE=""
GROUP="Wi-Fi"
KEY_FILE=""
DRY_RUN=false
ASK_PASS=false

usage() {
    cat <<EOF
${BLUE}Usage:${NC} bash wifi_from_kdbx.sh --db <file.kdbx> [--group "Wi-Fi"] [--key-file path] [--dry-run] [--ask-pass]

Prerequisites:
  - keepassxc-cli installé et accessible dans le PATH
    - Le vault kdbx contient un groupe (par défaut "Wi-Fi")
    - Title = SSID
    - Password = clé Wi-Fi
    - (optionnel) attribut "security" (WPA2/WPA3/OPEN) et "hidden" (true/false)
Notes:
    - Authentification KeePassXC: par défaut keepassxc-cli demandera le mot de passe en interactif; n'exportez pas de mot de passe dans un fichier. L'option --ask-pass force cette invite même si une variable KEEPASSXC_CLI_PASSWORD est présente.
    - Sur macOS/Windows/Linux l'outil demande souvent les droits administrateur pour ajouter des profils.
EOF
}

log_info() { echo -e "${BLUE}$*${NC}"; }
log_warn() { echo -e "${YELLOW}$*${NC}"; }
log_error() { echo -e "${RED}$*${NC}"; }
log_ok() { echo -e "${GREEN}$*${NC}"; }

require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        log_error "Commande requise manquante: $1"
        exit 1
    fi
}

os_detect() {
    local os
    os=$(uname -s)
    case "$os" in
        Darwin*) echo "Mac";;
        CYGWIN*|MINGW*|MSYS*) echo "Windows";;
        *) echo "Linux";;
    esac
}

kp_attr() {
    local attr="$1" entry_path="$2" value=""
    if value=$(keepassxc-cli show -q ${KEY_FILE:+--key-file "$KEY_FILE"} -a "$attr" "$DB_FILE" "$entry_path" 2>/dev/null); then
        echo "$value"
    else
        echo ""
    fi
}

list_entries() {
    keepassxc-cli ls ${KEY_FILE:+--key-file "$KEY_FILE"} "$DB_FILE" "$GROUP" \
        | sed 's:^ *::; s:/$::' \
        | awk 'NF > 0 && $0 !~ /\/$/'
}

add_wifi_macos() {
    local ssid="$1" password="$2" security="$3" hidden="$4"
    require_cmd networksetup
    local iface
    iface=$(networksetup -listallhardwareports | awk '/Wi-Fi/{getline; print $2; exit}')
    if [ -z "$iface" ]; then
        log_warn "Interface Wi-Fi introuvable sur macOS"
        return 1
    fi
    local sec_flag="${security:-WPA2}"
    if $DRY_RUN; then
        log_info "[dry-run] macOS: ajouter ${ssid} sur ${iface} (${sec_flag})"
        return 0
    fi
    networksetup -addpreferredwirelessnetworkatindex "$iface" "$ssid" 0 "$sec_flag" "$password"
    if [ "$hidden" = "true" ]; then
        networksetup -setairportpower "$iface" on >/dev/null 2>&1 || true
    fi
    log_ok "Profil Wi-Fi ajouté (macOS): ${ssid}"
}

add_wifi_linux() {
    local ssid="$1" password="$2" security="$3" hidden="$4"
    require_cmd nmcli
    local hidden_flag=""
    [ "$hidden" = "true" ] && hidden_flag="--hidden yes"
    if $DRY_RUN; then
        log_info "[dry-run] Linux: nmcli dev wifi connect ${ssid} (hidden=${hidden})"
        return 0
    fi
    nmcli dev wifi connect "$ssid" password "$password" ${hidden_flag}
    log_ok "Profil Wi-Fi ajouté (Linux): ${ssid}"
}

add_wifi_windows() {
    local ssid="$1" password="$2" security="$3" hidden="$4"
    require_cmd netsh
    local tmp
    tmp=$(mktemp 2>/dev/null || true)
    if [ -z "$tmp" ]; then
        tmp="${TMPDIR:-/tmp}/wifi-profile-${RANDOM}.xml"
    fi
    local auth="WPA2PSK"
    [ -n "$security" ] && auth="$security"
    if $DRY_RUN; then
        log_info "[dry-run] Windows: netsh profile for ${ssid} (auth=${auth})"
        return 0
    fi
    cat > "$tmp" <<EOF
<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
    <name>${ssid}</name>
    <SSIDConfig>
        <SSID>
            <name>${ssid}</name>
        </SSID>
    </SSIDConfig>
    <connectionType>ESS</connectionType>
    <connectionMode>auto</connectionMode>
    <MSM>
        <security>
            <authEncryption>
                <authentication>${auth}</authentication>
                <encryption>AES</encryption>
                <useOneX>false</useOneX>
            </authEncryption>
            <sharedKey>
                <keyType>passPhrase</keyType>
                <protected>false</protected>
                <keyMaterial>${password}</keyMaterial>
            </sharedKey>
        </security>
    </MSM>
    <MacRandomization xmlns="http://www.microsoft.com/networking/WLAN/profile/v3">
        <enableRandomization>false</enableRandomization>
    </MacRandomization>
</WLANProfile>
EOF
    netsh wlan add profile filename="${tmp}" user=all >/dev/null
    netsh wlan connect name="${ssid}" >/dev/null 2>&1 || true
    rm -f "$tmp"
    log_ok "Profil Wi-Fi ajouté (Windows): ${ssid}"
}

main() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --db)
                DB_FILE="$2"; shift 2;;
            --group)
                GROUP="$2"; shift 2;;
            --key-file)
                KEY_FILE="$2"; shift 2;;
            --dry-run)
                DRY_RUN=true; shift;;
            --ask-pass)
                ASK_PASS=true; shift;;
            -h|--help)
                usage; exit 0;;
            *)
                log_error "Option inconnue: $1"; usage; exit 1;;
        esac
    done

    if [ -z "$DB_FILE" ]; then
        usage; exit 1
    fi
    if [ ! -f "$DB_FILE" ]; then
        log_error "Fichier kdbx introuvable: $DB_FILE"; exit 1
    fi

    if $ASK_PASS; then
        unset KEEPASSXC_CLI_PASSWORD
    fi

    require_cmd keepassxc-cli

    local os machine
    machine=$(os_detect)
    log_info "Système détecté: ${machine}"

    mapfile -t entries < <(list_entries || true)
    if [ ${#entries[@]} -eq 0 ]; then
        log_warn "Aucune entrée trouvée dans ${GROUP}"; exit 0
    fi

    for entry in "${entries[@]}"; do
        local path="${GROUP}/${entry}"
        local pw security hidden
        pw=$(kp_attr password "$path")
        if [ -z "$pw" ]; then
            log_warn "Mot de passe manquant pour ${entry}, ignoré"
            continue
        fi
        security=$(kp_attr security "$path" | tr '[:lower:]' '[:upper:]')
        hidden=$(kp_attr hidden "$path" | tr '[:upper:]' '[:lower:]')
        case "$hidden" in
            true|yes|1) hidden="true";;
            *) hidden="false";;
        esac
        log_info "Injection SSID: ${entry} (security=${security:-auto}, hidden=${hidden})"
        case "$machine" in
            Mac) add_wifi_macos "$entry" "$pw" "$security" "$hidden";;
            Linux) add_wifi_linux "$entry" "$pw" "$security" "$hidden";;
            Windows) add_wifi_windows "$entry" "$pw" "$security" "$hidden";;
            *) log_error "OS non supporté"; exit 1;;
        esac
    done
}

main "$@"
