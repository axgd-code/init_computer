#!/bin/bash

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Obtenir le répertoire du script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Charger .env.local si disponible
if [ -f "${SCRIPT_DIR}/../.env.local" ]; then
    # shellcheck disable=SC1091
    source "${SCRIPT_DIR}/../.env.local"
fi

# Déterminer le chemin du fichier packages.conf
if [ -n "${PACKAGES_CONF_DIR:-}" ] && [ -f "${PACKAGES_CONF_DIR}/packages.conf" ]; then
    PACKAGES_CONF="${PACKAGES_CONF_DIR}/packages.conf"
elif [ -f "${SCRIPT_DIR}/packages.conf" ]; then
    PACKAGES_CONF="${SCRIPT_DIR}/packages.conf"
else
    PACKAGES_CONF="${SCRIPT_DIR}/packages.conf.example"
fi

# Détection du système d'exploitation
OS="$(uname -s)"
case "${OS}" in
    Darwin*)    MACHINE=Mac;;
    CYGWIN*|MINGW*|MSYS*)    MACHINE=Windows;;
    *)          MACHINE=Linux;;
esac

# Affichage de l'aide
show_help() {
    cat << EOF
${BLUE}Usage:${NC} bash app.sh [COMMAND] [OPTIONS]

${BLUE}Commands:${NC}
  ${GREEN}install${NC} <app> [type]      Install an application and add it to packages.conf
  ${GREEN}uninstall${NC} <app>            Uninstall an application and remove it from packages.conf
  ${GREEN}add${NC} <app> [type]           Add an application to packages.conf without installing
  ${GREEN}remove${NC} <app>               Remove an application from packages.conf without uninstalling
  ${GREEN}check${NC} <app> [type]         Check availability of an application on all platforms
  ${GREEN}list${NC}                       List all applications in packages.conf

${BLUE}Options:${NC}
  type: brew, cask, choco (optional, will be detected automatically)

${BLUE}Examples:${NC}
  bash app.sh install firefox
  bash app.sh install firefox cask          (macOS only)
  bash app.sh uninstall vlc
  bash app.sh check firefox                 Check availability on all platforms
  bash app.sh add git
  bash app.sh list

${BLUE}Current system:${NC} ${MACHINE}
EOF
}

# Vérifier les arguments
if [ $# -lt 1 ]; then
    show_help
    exit 1
fi

COMMAND=$1
APP=$2
TYPE=${3:-auto}

# Fonction pour installer une application
install_app() {
    local app=$1
    local type=$2
    
    echo -e "${BLUE}Installation de ${GREEN}${app}${NC}...\n"
    
    # Vérifier la disponibilité avant d'installer
    echo -e "${BLUE}Vérification de la disponibilité...${NC}"
    if ! check_homebrew_api "${app}" "${type}" && ! check_chocolatey_api "${app}"; then
        echo -e "${YELLOW}⚠ Attention: ${app} n'a pas été trouvé dans les dépôts publics${NC}"
        echo -e "${YELLOW}L'installation pourrait échouer. Continuer? (y/n)${NC}"
        read -r response
        if [ "${response}" != "y" ] && [ "${response}" != "Y" ]; then
            echo -e "${RED}Installation annulée${NC}"
            return 1
        fi
    else
        echo -e "${GREEN}✓ Package vérifié${NC}\n"
    fi
    
    if [ "${MACHINE}" = "Mac" ]; then
        if command -v brew &> /dev/null; then
            if [ "${type}" = "cask" ] || ([ "${type}" = "auto" ] && is_cask_app "${app}" ); then
                echo "  → Installation via Homebrew cask..."
                brew install --cask "${app}"
            else
                echo "  → Installation via Homebrew..."
                brew install "${app}"
            fi
            echo -e "${GREEN}✓ Installation réussie${NC}"
        else
            echo -e "${RED}✗ Homebrew n'est pas installé${NC}"
            exit 1
        fi
    elif [ "${MACHINE}" = "Windows" ]; then
        if command -v choco &> /dev/null; then
            echo "  → Installation via Chocolatey..."
            choco install -y "${app}"
            echo -e "${GREEN}✓ Installation réussie${NC}"
        else
            echo -e "${RED}✗ Chocolatey n'est pas installé${NC}"
            exit 1
        fi
    elif [ "${MACHINE}" = "Linux" ]; then
        if command -v apt-get &> /dev/null; then
            echo "  → Installation via apt..."
            sudo apt-get update
            sudo apt-get install -y "${app}"
            echo -e "${GREEN}✓ Installation réussie${NC}"
        elif command -v dnf &> /dev/null; then
            echo "  → Installation via dnf..."
            sudo dnf install -y "${app}"
            echo -e "${GREEN}✓ Installation réussie${NC}"
        else
            echo -e "${RED}✗ Gestionnaire de packages non trouvé${NC}"
            exit 1
        fi
    fi
}

# Fonction pour vérifier si une app est un cask
is_cask_app() {
    local app=$1
    # Vérifier via l'API Homebrew
    curl -s "https://formulae.brew.sh/api/cask/${app}.json" 2>/dev/null | grep -q '"token"' && return 0
    return 1
}

# Fonction pour désinstaller une application
uninstall_app() {
    local app=$1
    
    echo -e "${BLUE}Désinstallation de ${GREEN}${app}${NC}..."
    
    if [ "${MACHINE}" = "Mac" ]; then
        if command -v brew &> /dev/null; then
            # Vérifier si c'est un cask ou un brew
            if brew list --cask "${app}" &> /dev/null; then
                echo "  → Désinstallation via Homebrew cask..."
                brew uninstall --cask "${app}"
            elif brew list "${app}" &> /dev/null; then
                echo "  → Désinstallation via Homebrew..."
                brew uninstall "${app}"
            else
                echo -e "${YELLOW}⚠ Application ${app} non trouvée${NC}"
                return 1
            fi
            echo -e "${GREEN}✓ Désinstallation réussie${NC}"
        fi
    elif [ "${MACHINE}" = "Windows" ]; then
        if command -v choco &> /dev/null; then
            echo "  → Désinstallation via Chocolatey..."
            choco uninstall -y "${app}"
            echo -e "${GREEN}✓ Désinstallation réussie${NC}"
        fi
    elif [ "${MACHINE}" = "Linux" ]; then
        if command -v apt-get &> /dev/null; then
            echo "  → Désinstallation via apt..."
            sudo apt-get remove -y "${app}"
            echo -e "${GREEN}✓ Désinstallation réussie${NC}"
        elif command -v dnf &> /dev/null; then
            echo "  → Désinstallation via dnf..."
            sudo dnf remove -y "${app}"
            echo -e "${GREEN}✓ Désinstallation réussie${NC}"
        fi
    fi
}

# Fonction pour vérifier la disponibilité d'une application
check_availability() {
    local app=$1
    local type=$2
    
    echo -e "${BLUE}Vérification de la disponibilité de ${GREEN}${app}${NC}...\n"
    
    local mac_available=false
    local win_available=false
    local linux_available=false
    
    # Vérifier sur macOS via API Homebrew
    echo "  → Vérification sur macOS..."
    if check_homebrew_api "${app}" "${type}"; then
        echo -e "    ${GREEN}✓ Disponible via Homebrew${NC}"
        mac_available=true
    else
        echo -e "    ${RED}✗ Non trouvé sur Homebrew${NC}"
    fi
    
    # Vérifier sur Windows via API Chocolatey
    echo "  → Vérification sur Windows..."
    if check_chocolatey_api "${app}"; then
        echo -e "    ${GREEN}✓ Disponible via Chocolatey${NC}"
        win_available=true
    else
        echo -e "    ${RED}✗ Non trouvé sur Chocolatey${NC}"
    fi
    
    # Vérifier sur Linux
    echo "  → Vérification sur Linux..."
    if check_linux_availability "${app}"; then
        echo -e "    ${GREEN}✓ Disponible sur Linux${NC}"
        linux_available=true
    else
        echo -e "    ${RED}✗ Non trouvé sur Linux${NC}"
    fi
    
    # Résumé
    echo ""
    echo "Résumé de disponibilité:"
    printf "  macOS:   "
    [ "${mac_available}" = true ] && echo -e "${GREEN}✓${NC}" || echo -e "${RED}✗${NC}"
    printf "  Windows: "
    [ "${win_available}" = true ] && echo -e "${GREEN}✓${NC}" || echo -e "${RED}✗${NC}"
    printf "  Linux:   "
    [ "${linux_available}" = true ] && echo -e "${GREEN}✓${NC}" || echo -e "${RED}✗${NC}"
    
    # Retourner true si au moins une plateforme l'a
    if [ "${mac_available}" = true ] || [ "${win_available}" = true ] || [ "${linux_available}" = true ]; then
        return 0
    else
        return 1
    fi
}

# Fonction pour vérifier sur Homebrew via API
check_homebrew_api() {
    local app=$1
    local type=$2
    
    # Vérifier dans les formulas (brew install)
    if curl -s "https://formulae.brew.sh/api/formula/${app}.json" 2>/dev/null | grep -q '"name"'; then
        return 0
    fi
    
    # Vérifier dans les casks (brew install --cask)
    if [ "${type}" = "cask" ] || [ "${type}" = "auto" ]; then
        if curl -s "https://formulae.brew.sh/api/cask/${app}.json" 2>/dev/null | grep -q '"token"'; then
            return 0
        fi
    fi
    
    return 1
}

# Fonction pour vérifier sur Chocolatey via API
check_chocolatey_api() {
    local app=$1
    
    # API Chocolatey: rechercher le package
    if curl -s "https://community.chocolatey.org/api/v2/Packages()?%24filter=tolower(Id)%20eq%20tolower(%27${app}%27)&%24select=Id" 2>/dev/null | grep -qi "\"${app}\""; then
        return 0
    fi
    
    return 1
}

# Fonction pour vérifier sur Linux
check_linux_availability() {
    local app=$1
    
    # Vérifier sur le système local si on est sur Linux
    if [ "${MACHINE}" = "Linux" ]; then
        if command -v apt-cache &> /dev/null; then
            apt-cache search "^${app}$" 2>/dev/null | grep -q "^${app} " && return 0
        elif command -v dnf &> /dev/null; then
            dnf search "${app}" 2>/dev/null | grep -q "^${app}\..*" && return 0
        elif command -v yum &> /dev/null; then
            yum search "${app}" 2>/dev/null | grep -q "^${app}\..*" && return 0
        fi
    else
        # Si on n'est pas sur Linux, on peut faire une requête simple
        # Debian Packages API
        if curl -s "https://packages.debian.org/search?keywords=${app}&searchon=names&suite=stable&section=all" 2>/dev/null | grep -q "Exact hits"; then
            return 0
        fi
    fi
    
    return 1
}


# Fonction pour ajouter une application à packages.conf
add_to_conf() {
    local app=$1
    local type=$2
    
    # Vérifier si l'app existe déjà
    if grep -q "^[^#]*|${app}|" "${PACKAGES_CONF}"; then
        echo -e "${YELLOW}⚠ ${app} existe déjà dans packages.conf${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Vérification de la disponibilité pour compléter packages.conf...${NC}"
    
    # Vérifier la disponibilité sur chaque plateforme
    local mac_available=false
    local win_available=false
    
    # Vérifier macOS
    if check_homebrew_api "${app}" "${type}"; then
        mac_available=true
        echo -e "  ${GREEN}✓${NC} Disponible sur macOS"
    else
        echo -e "  ${RED}✗${NC} Non disponible sur macOS"
    fi
    
    # Vérifier Windows
    if check_chocolatey_api "${app}"; then
        win_available=true
        echo -e "  ${GREEN}✓${NC} Disponible sur Windows"
    else
        echo -e "  ${RED}✗${NC} Non disponible sur Windows"
    fi
    
    # Déterminer le type si auto
    if [ "${type}" = "auto" ]; then
        if [ "${mac_available}" = true ]; then
            type="cask"  # Par défaut, utilise cask pour macOS si disponible
            # Vérifier si c'est en formula plutôt qu'en cask
            if ! curl -s "https://formulae.brew.sh/api/cask/${app}.json" 2>/dev/null | grep -q '"token"'; then
                type="brew"
            fi
        else
            type="brew"
        fi
    fi
    
    # Définir les noms selon la disponibilité
    local mac_name="-"
    local win_name="-"
    
    if [ "${mac_available}" = true ]; then
        mac_name="${app}"
    fi
    
    if [ "${win_available}" = true ]; then
        win_name="${app}"
    fi
    
    # Si aucune plateforme ne l'a, afficher un avertissement
    if [ "${mac_name}" = "-" ] && [ "${win_name}" = "-" ]; then
        echo -e "${RED}⚠ ${app} n'a été trouvé sur aucune plateforme${NC}"
        echo -e "${YELLOW}Voulez-vous quand même l'ajouter? (y/n)${NC}"
        read -r response
        if [ "${response}" != "y" ] && [ "${response}" != "Y" ]; then
            echo -e "${RED}Ajout annulé${NC}"
            return 1
        fi
    fi
    
    # Ajouter à packages.conf
    local entry="${type}|${mac_name}|${win_name}|${app}"
    echo "${entry}" >> "${PACKAGES_CONF}"
    
    echo -e "${GREEN}✓ ${app} ajouté à packages.conf${NC}"
    echo -e "  Entrée: ${entry}"
}

# Fonction pour supprimer une application de packages.conf
remove_from_conf() {
    local app=$1
    
    # Vérifier si l'app existe
    if ! grep -q "^[^#]*|${app}|" "${PACKAGES_CONF}"; then
        echo -e "${YELLOW}⚠ ${app} n'existe pas dans packages.conf${NC}"
        return 1
    fi
    
    # Créer un fichier temporaire sans la ligne
    grep -v "^[^#]*|${app}|" "${PACKAGES_CONF}" > "${PACKAGES_CONF}.tmp"
    mv "${PACKAGES_CONF}.tmp" "${PACKAGES_CONF}"
    
    echo -e "${GREEN}✓ ${app} supprimé de packages.conf${NC}"
}

# Fonction pour lister les applications
list_apps() {
    echo -e "${BLUE}Applications dans packages.conf:${NC}\n"
    
    awk -F'|' '
    BEGIN { count = 0 }
    !/^#/ && NF >= 4 {
        type = $1
        mac = $2
        win = $3
        desc = $4
        
        # Afficher le type avec couleur
        if (type == "tap") {
            type_display = "\033[36mtap\033[0m"
        } else if (type == "brew") {
            type_display = "\033[33mbrew\033[0m"
        } else if (type == "cask") {
            type_display = "\033[35mcask\033[0m"
        } else {
            type_display = type
        }
        
        printf "%-8s %-25s %-25s %s\n", type_display, (mac != "-" ? mac : "-"), (win != "-" ? win : "-"), desc
        count++
    }
    END { print "\nTotal: " count " applications" }
    ' "${PACKAGES_CONF}"
}

# Exécuter la commande
case "${COMMAND}" in
    install)
        if [ -z "${APP}" ]; then
            echo -e "${RED}✗ Erreur: nom de l'application requis${NC}"
            show_help
            exit 1
        fi
        install_app "${APP}" "${TYPE}"
        add_to_conf "${APP}" "${TYPE}"
        ;;
    uninstall)
        if [ -z "${APP}" ]; then
            echo -e "${RED}✗ Erreur: nom de l'application requis${NC}"
            show_help
            exit 1
        fi
        uninstall_app "${APP}" || true
        remove_from_conf "${APP}"
        ;;
    add)
        if [ -z "${APP}" ]; then
            echo -e "${RED}✗ Erreur: nom de l'application requis${NC}"
            show_help
            exit 1
        fi
        add_to_conf "${APP}" "${TYPE}"
        ;;
    remove)
        if [ -z "${APP}" ]; then
            echo -e "${RED}✗ Erreur: nom de l'application requis${NC}"
            show_help
            exit 1
        fi
        remove_from_conf "${APP}"
        ;;
    check)
        if [ -z "${APP}" ]; then
            echo -e "${RED}✗ Erreur: nom de l'application requis${NC}"
            show_help
            exit 1
        fi
        check_availability "${APP}" "${TYPE}"
        ;;
    list)
        list_apps
        ;;
    --help|-h|help)
        show_help
        ;;
    *)
        echo -e "${RED}✗ Commande inconnue: ${COMMAND}${NC}"
        show_help
        exit 1
        ;;
esac
