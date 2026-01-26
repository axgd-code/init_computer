#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load .env.local if available
if [ -f "${SCRIPT_DIR}/../.env.local" ]; then
    # shellcheck disable=SC1091
    source "${SCRIPT_DIR}/../.env.local"
fi

# Determine path to packages.conf file
if [ -n "${PACKAGES_CONF_DIR:-}" ] && [ -f "${PACKAGES_CONF_DIR}/packages.conf" ]; then
    PACKAGES_CONF="${PACKAGES_CONF_DIR}/packages.conf"
elif [ -f "${SCRIPT_DIR}/packages.conf" ]; then
    PACKAGES_CONF="${SCRIPT_DIR}/packages.conf"
else
    PACKAGES_CONF="${SCRIPT_DIR}/packages.conf.example"
fi

# Detect operating system
OS="$(uname -s)"
case "${OS}" in
    Darwin*)    MACHINE=Mac;;
    CYGWIN*|MINGW*|MSYS*)    MACHINE=Windows;;
    *)          MACHINE=Linux;;
esac

# Help display
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

# Check arguments
if [ $# -lt 1 ]; then
    show_help
    exit 1
fi

COMMAND=$1
APP=$2
TYPE=${3:-auto}

# Function to install an application
install_app() {
    local app=$1
    local type=$2
    
    echo -e "${BLUE}Installing ${GREEN}${app}${NC}...\n"

    # Check availability before installing
    echo -e "${BLUE}Checking availability...${NC}"
    if ! check_homebrew_api "${app}" "${type}" && ! check_chocolatey_api "${app}"; then
        echo -e "${YELLOW}⚠ Warning: ${app} was not found in public repositories${NC}"
        echo -e "${YELLOW}Installation may fail. Continue? (y/n)${NC}"
        read -r response
        if [ "${response}" != "y" ] && [ "${response}" != "Y" ]; then
            echo -e "${RED}Installation cancelled${NC}"
            return 1
        fi
    else
        echo -e "${GREEN}✓ Package verified${NC}\n"
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
            echo -e "${GREEN}✓ Installed successfully${NC}"
        else
            echo -e "${RED}✗ Homebrew is not installed${NC}"
            exit 1
        fi
    elif [ "${MACHINE}" = "Windows" ]; then
        if command -v choco &> /dev/null; then
            echo "  → Installation via Chocolatey..."
            choco install -y "${app}"
            echo -e "${GREEN}✓ Installed successfully${NC}"
        else
            echo -e "${RED}✗ Chocolatey is not installed${NC}"
            exit 1
        fi
    elif [ "${MACHINE}" = "Linux" ]; then
        if command -v apt-get &> /dev/null; then
            echo "  → Installation via apt..."
            sudo apt-get update
            sudo apt-get install -y "${app}"
            echo -e "${GREEN}✓ Installed successfully${NC}"
        elif command -v dnf &> /dev/null; then
            echo "  → Installation via dnf..."
            sudo dnf install -y "${app}"
            echo -e "${GREEN}✓ Installed successfully${NC}"
        else
            echo -e "${RED}✗ Package manager not found${NC}"
            exit 1
        fi
    fi
}

# Function to check if an app is a cask
is_cask_app() {
    local app=$1
    # Check via Homebrew API
    curl -s "https://formulae.brew.sh/api/cask/${app}.json" 2>/dev/null | grep -q '"token"' && return 0
    return 1
}

# Function to uninstall an application
uninstall_app() {
    local app=$1
    
    echo -e "${BLUE}Uninstalling ${GREEN}${app}${NC}..."
    
    if [ "${MACHINE}" = "Mac" ]; then
        if command -v brew &> /dev/null; then
            # Check if it's a cask or a brew
            if brew list --cask "${app}" &> /dev/null; then
                echo "  → Uninstall via Homebrew cask..."
                brew uninstall --cask "${app}"
            elif brew list "${app}" &> /dev/null; then
                echo "  → Uninstall via Homebrew..."
                brew uninstall "${app}"
            else
                echo -e "${YELLOW}⚠ Application ${app} not found${NC}"
                return 1
            fi
            echo -e "${GREEN}✓ Uninstalled successfully${NC}"
        fi
    elif [ "${MACHINE}" = "Windows" ]; then
        if command -v choco &> /dev/null; then
            echo "  → Uninstall via Chocolatey..."
            choco uninstall -y "${app}"
            echo -e "${GREEN}✓ Uninstalled successfully${NC}"
        fi
    elif [ "${MACHINE}" = "Linux" ]; then
        if command -v apt-get &> /dev/null; then
            echo "  → Uninstall via apt..."
            sudo apt-get remove -y "${app}"
            echo -e "${GREEN}✓ Uninstalled successfully${NC}"
        elif command -v dnf &> /dev/null; then
            echo "  → Uninstall via dnf..."
            sudo dnf remove -y "${app}"
            echo -e "${GREEN}✓ Uninstalled successfully${NC}"
        fi
    fi
}

# Function to check an application's availability
check_availability() {
    local app=$1
    local type=$2
    
    echo -e "${BLUE}Checking availability of ${GREEN}${app}${NC}...\n"
    
    local mac_available=false
    local win_available=false
    local linux_available=false
    
    # Check on macOS via Homebrew API
    echo "  → Checking on macOS..."
    if check_homebrew_api "${app}" "${type}"; then
        echo -e "    ${GREEN}✓ Available via Homebrew${NC}"
        mac_available=true
    else
        echo -e "    ${RED}✗ Not found on Homebrew${NC}"
    fi
    
    # Check on Windows via Chocolatey API
    echo "  → Checking on Windows..."
    if check_chocolatey_api "${app}"; then
        echo -e "    ${GREEN}✓ Available via Chocolatey${NC}"
        win_available=true
    else
        echo -e "    ${RED}✗ Not found on Chocolatey${NC}"
    fi
    
    # Check on Linux
    echo "  → Checking on Linux..."
    if check_linux_availability "${app}"; then
        echo -e "    ${GREEN}✓ Available on Linux${NC}"
        linux_available=true
    else
        echo -e "    ${RED}✗ Not found on Linux${NC}"
    fi
    
    # Résumé
    echo ""
    echo "Availability summary:"
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

# Function to check Homebrew via API
check_homebrew_api() {
    local app=$1
    local type=$2
    
    # Check in formulas (brew install)
    if curl -s "https://formulae.brew.sh/api/formula/${app}.json" 2>/dev/null | grep -q '"name"'; then
        return 0
    fi
    
    # Check in casks (brew install --cask)
    if [ "${type}" = "cask" ] || [ "${type}" = "auto" ]; then
        if curl -s "https://formulae.brew.sh/api/cask/${app}.json" 2>/dev/null | grep -q '"token"'; then
            return 0
        fi
    fi
    
    return 1
}

# Function to check Chocolatey via API
check_chocolatey_api() {
    local app=$1
    
    # API Chocolatey: rechercher le package
    if curl -s "https://community.chocolatey.org/api/v2/Packages()?%24filter=tolower(Id)%20eq%20tolower(%27${app}%27)&%24select=Id" 2>/dev/null | grep -qi "\"${app}\""; then
        return 0
    fi
    
    return 1
}

# Function to check availability on Linux
check_linux_availability() {
    local app=$1
    
    # Check on the local system if we're on Linux
    if [ "${MACHINE}" = "Linux" ]; then
        if command -v apt-cache &> /dev/null; then
            apt-cache search "^${app}$" 2>/dev/null | grep -q "^${app} " && return 0
        elif command -v dnf &> /dev/null; then
            dnf search "${app}" 2>/dev/null | grep -q "^${app}\..*" && return 0
        elif command -v yum &> /dev/null; then
            yum search "${app}" 2>/dev/null | grep -q "^${app}\..*" && return 0
        fi
    else
        # If we're not on Linux, we can make a simple query
            # Debian Packages API
        if curl -s "https://packages.debian.org/search?keywords=${app}&searchon=names&suite=stable&section=all" 2>/dev/null | grep -q "Exact hits"; then
            return 0
        fi
    fi
    
    return 1
}


# Function to add an application to packages.conf
add_to_conf() {
    local app=$1
    local type=$2
    
    # Check if the app already exists
    if grep -q "^[^#]*|${app}|" "${PACKAGES_CONF}"; then
        echo -e "${YELLOW}⚠ ${app} already exists in packages.conf${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Checking availability to update packages.conf...${NC}"
    
    # Check availability on each platform
    local mac_available=false
    local win_available=false
    
    # Check macOS
    if check_homebrew_api "${app}" "${type}"; then
        mac_available=true
        echo -e "  ${GREEN}✓${NC} Available on macOS"
    else
        echo -e "  ${RED}✗${NC} Not available on macOS"
    fi
    
    # Check Windows
    if check_chocolatey_api "${app}"; then
        win_available=true
        echo -e "  ${GREEN}✓${NC} Available on Windows"
    else
        echo -e "  ${RED}✗${NC} Not available on Windows"
    fi
    
    # Determine type if set to auto
    if [ "${type}" = "auto" ]; then
        if [ "${mac_available}" = true ]; then
            type="cask"  # By default, use cask for macOS if available
            # Check if it's a formula rather than a cask
            if ! curl -s "https://formulae.brew.sh/api/cask/${app}.json" 2>/dev/null | grep -q '"token"'; then
                type="brew"
            fi
        else
            type="brew"
        fi
    fi
    
    # Set names according to availability
    local mac_name="-"
    local win_name="-"
    
    if [ "${mac_available}" = true ]; then
        mac_name="${app}"
    fi
    
    if [ "${win_available}" = true ]; then
        win_name="${app}"
    fi
    
    # If no platform has it, display a warning
    if [ "${mac_name}" = "-" ] && [ "${win_name}" = "-" ]; then
        echo -e "${YELLOW}⚠ ${app} was not found on any platform${NC}"
        echo -e "${YELLOW}Do you still want to add it? (y/n)${NC}"
        read -r response
        if [ "${response}" != "y" ] && [ "${response}" != "Y" ]; then
            echo -e "${RED}Add cancelled${NC}"
            return 1
        fi
    fi
    
    # Add to packages.conf
    local entry="${type}|${mac_name}|${win_name}|${app}"
    echo "${entry}" >> "${PACKAGES_CONF}"
    
    echo -e "${GREEN}✓ ${app} added to packages.conf${NC}"
    echo -e "  Entry: ${entry}"
}

# Function to remove an application from packages.conf
remove_from_conf() {
    local app=$1
    
    # Check if the app exists
    if ! grep -q "^[^#]*|${app}|" "${PACKAGES_CONF}"; then
        echo -e "${YELLOW}⚠ ${app} does not exist in packages.conf${NC}"
        return 1
    fi
    
    # Créer un fichier temporaire sans la ligne
    grep -v "^[^#]*|${app}|" "${PACKAGES_CONF}" > "${PACKAGES_CONF}.tmp"
    mv "${PACKAGES_CONF}.tmp" "${PACKAGES_CONF}"
    
    echo -e "${GREEN}✓ ${app} removed from packages.conf${NC}"
}

# Function to list applications
list_apps() {
    echo -e "${BLUE}Applications in packages.conf:${NC}\n"
    
    awk -F'|' '
    BEGIN { count = 0 }
    !/^#/ && NF >= 4 {
        type = $1
        mac = $2
        win = $3
        desc = $4
        
        # Display type with color
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

# Execute the command
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
