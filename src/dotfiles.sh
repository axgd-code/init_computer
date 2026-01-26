#!/bin/bash

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Obtenir le répertoire du script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env.local"
ENV_EXAMPLE="${SCRIPT_DIR}/.env.example"

# Charger la configuration
load_config() {
    if [ ! -f "${ENV_FILE}" ]; then
        echo -e "${YELLOW}⚠ Le fichier ${ENV_FILE} n'existe pas${NC}"
        echo -e "${BLUE}Création depuis le template...${NC}"
        cp "${ENV_EXAMPLE}" "${ENV_FILE}"
        echo -e "${GREEN}✓ Fichier créé${NC}"
        echo -e "${YELLOW}⚠ Veuillez éditer ${ENV_FILE} et configurér SYNC_DIR${NC}"
        return 1
    fi
    
    # Charger les variables
    source "${ENV_FILE}"
}

# Afficher l'aide
show_help() {
    cat << EOF
${BLUE}Usage:${NC} bash dotfiles.sh [COMMAND]

${BLUE}Commands:${NC}
  ${GREEN}init${NC}              Initialize dotfiles synchronization
  ${GREEN}setup${NC}              Setup dotfiles symlinks
  ${GREEN}sync${NC}               Sync changes from home to sync folder
  ${GREEN}restore${NC}            Restore from sync folder to home
  ${GREEN}status${NC}             Show dotfiles status
  ${GREEN}list${NC}               List tracked dotfiles
  ${GREEN}config${NC}             Show current configuration
  ${GREEN}packages${NC}           Manage packages.conf synchronization
  ${GREEN}obsidian${NC}           Manage Obsidian vault synchronization
  ${GREEN}vscode${NC}             Manage VS Code settings synchronization
  ${GREEN}--help${NC}             Show this help

${BLUE}Configuration:${NC}
  Edit ${ENV_FILE} to set SYNC_DIR, PACKAGES_CONF_DIR, OBSIDIAN_VAULT, VSCODE_CONFIG

${BLUE}Dotfiles tracked:${NC}
  - .bashrc / .zshrc
  - .gitconfig
  - .ssh/config
  - .vimrc / .config/nvim
  - packages.conf
  - Obsidian vault
  - VS Code settings
EOF
}

# Lister les dotfiles à synchroniser
get_dotfiles() {
    cat << 'EOF'
.bashrc
.zshrc
.gitconfig
.git-credentials
.vimrc
.ssh/config
.ssh/authorized_keys
.config/nvim
.config/helix
.config/starship.toml
.config/alacritty
.config/kitty
EOF
}

# Initialiser la synchronisation
init_sync() {
    if [ ! -d "${SYNC_DIR}" ]; then
        echo -e "${RED}✗ Erreur: SYNC_DIR n'existe pas: ${SYNC_DIR}${NC}"
        echo -e "${YELLOW}Assurez-vous que votre dossier synchronisé est configuré et accessible${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Initialisation de la synchronisation des dotfiles...${NC}"
    echo -e "Destination: ${GREEN}${SYNC_DIR}${NC}\n"
    
    # Créer le dossier dotfiles s'il n'existe pas
    local DOTFILES_DIR="${SYNC_DIR}/dotfiles"
    mkdir -p "${DOTFILES_DIR}"
    
    echo -e "${BLUE}Copie des dotfiles existants...${NC}"
    
    local count=0
    while IFS= read -r dotfile; do
        [ -z "$dotfile" ] && continue
        
        local home_path="${HOME}/${dotfile}"
        local sync_path="${DOTFILES_DIR}/${dotfile##*/}"  # Nom du fichier seulement
        
        if [ -e "${home_path}" ]; then
            cp -r "${home_path}" "${sync_path}"
            echo -e "  ${GREEN}✓${NC} ${dotfile}"
            ((count++))
        fi
    done < <(get_dotfiles)
    
    echo -e "\n${GREEN}✓ Initialisation terminée (${count} fichiers)${NC}"
    echo -e "Prochaine étape: ${BLUE}bash dotfiles.sh setup${NC}"
}

# Créer les symlinks
setup_symlinks() {
    if [ ! -d "${SYNC_DIR}" ]; then
        echo -e "${RED}✗ Erreur: SYNC_DIR n'existe pas${NC}"
        return 1
    fi
    
    local DOTFILES_DIR="${SYNC_DIR}/dotfiles"
    
    if [ ! -d "${DOTFILES_DIR}" ]; then
        echo -e "${RED}✗ Erreur: ${DOTFILES_DIR} n'existe pas${NC}"
        echo -e "${YELLOW}Exécutez d'abord: ${BLUE}bash dotfiles.sh init${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Configuration des symlinks...${NC}\n"
    
    local count=0
    while IFS= read -r dotfile; do
        [ -z "$dotfile" ] && continue
        
        local home_path="${HOME}/${dotfile}"
        local filename="${dotfile##*/}"
        local sync_path="${DOTFILES_DIR}/${filename}"
        
        if [ ! -e "${sync_path}" ]; then
            continue
        fi
        
        # Créer les répertoires parent s'il faut
        mkdir -p "$(dirname "${home_path}")"
        
        # Supprimer l'original s'il existe et n'est pas un symlink
        if [ -e "${home_path}" ] && [ ! -L "${home_path}" ]; then
            echo -e "  ${YELLOW}⚠${NC} Sauvegarde: ${dotfile} → ${dotfile}.backup"
            mv "${home_path}" "${home_path}.backup"
        fi
        
        # Créer le symlink
        if [ ! -L "${home_path}" ]; then
            ln -s "${sync_path}" "${home_path}"
            echo -e "  ${GREEN}✓${NC} Symlink: ${dotfile} → ${filename}"
            ((count++))
        else
            echo -e "  ${BLUE}→${NC} Déjà lié: ${dotfile}"
        fi
    done < <(get_dotfiles)
    
    echo -e "\n${GREEN}✓ Configuration terminée (${count} symlinks créés)${NC}"
}

# Synchroniser depuis la maison vers le dossier sync
sync_to_remote() {
    if [ ! -d "${SYNC_DIR}" ]; then
        echo -e "${RED}✗ Erreur: SYNC_DIR n'existe pas${NC}"
        return 1
    fi
    
    local DOTFILES_DIR="${SYNC_DIR}/dotfiles"
    mkdir -p "${DOTFILES_DIR}"
    
    echo -e "${BLUE}Synchronisation vers le dossier synchronisé...${NC}\n"
    
    local count=0
    while IFS= read -r dotfile; do
        [ -z "$dotfile" ] && continue
        
        local home_path="${HOME}/${dotfile}"
        local filename="${dotfile##*/}"
        local sync_path="${DOTFILES_DIR}/${filename}"
        
        if [ -e "${home_path}" ]; then
            if [ -L "${home_path}" ]; then
                # C'est un symlink, pas besoin de copier
                echo -e "  ${BLUE}→${NC} Lié: ${dotfile}"
            else
                cp -r "${home_path}" "${sync_path}"
                echo -e "  ${GREEN}✓${NC} Copié: ${dotfile}"
                ((count++))
            fi
        fi
    done < <(get_dotfiles)
    
    echo -e "\n${GREEN}✓ Synchronisation terminée (${count} fichiers)${NC}"
}

# Restaurer depuis le dossier sync vers la maison
restore_from_remote() {
    if [ ! -d "${SYNC_DIR}" ]; then
        echo -e "${RED}✗ Erreur: SYNC_DIR n'existe pas${NC}"
        return 1
    fi
    
    local DOTFILES_DIR="${SYNC_DIR}/dotfiles"
    
    if [ ! -d "${DOTFILES_DIR}" ]; then
        echo -e "${RED}✗ Erreur: ${DOTFILES_DIR} n'existe pas${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Restauration depuis le dossier synchronisé...${NC}\n"
    
    local count=0
    while IFS= read -r dotfile; do
        [ -z "$dotfile" ] && continue
        
        local home_path="${HOME}/${dotfile}"
        local filename="${dotfile##*/}"
        local sync_path="${DOTFILES_DIR}/${filename}"
        
        if [ -e "${sync_path}" ]; then
            mkdir -p "$(dirname "${home_path}")"
            
            if [ ! -L "${home_path}" ]; then
                if [ -e "${home_path}" ]; then
                    mv "${home_path}" "${home_path}.backup"
                    echo -e "  ${YELLOW}⚠${NC} Sauvegarde: ${dotfile}"
                fi
                cp -r "${sync_path}" "${home_path}"
                echo -e "  ${GREEN}✓${NC} Restauré: ${dotfile}"
                ((count++))
            fi
        fi
    done < <(get_dotfiles)
    
    echo -e "\n${GREEN}✓ Restauration terminée (${count} fichiers)${NC}"
}

# Afficher le statut
show_status() {
    echo -e "${BLUE}Statut de la synchronisation des dotfiles:${NC}\n"
    
    if [ -z "${SYNC_DIR}" ]; then
        echo -e "  ${RED}✗ SYNC_DIR non configuré${NC}"
        return 1
    fi
    
    if [ ! -d "${SYNC_DIR}" ]; then
        echo -e "  ${RED}✗ SYNC_DIR inexistant: ${SYNC_DIR}${NC}"
        return 1
    fi
    
    echo -e "  ${GREEN}✓ SYNC_DIR: ${SYNC_DIR}${NC}"
    
    local DOTFILES_DIR="${SYNC_DIR}/dotfiles"
    if [ -d "${DOTFILES_DIR}" ]; then
        echo -e "  ${GREEN}✓ Dossier dotfiles trouvé${NC}"
        
        local linked=0
        local files=0
        
        while IFS= read -r dotfile; do
            [ -z "$dotfile" ] && continue
            local home_path="${HOME}/${dotfile}"
            if [ -L "${home_path}" ]; then
                ((linked++))
            fi
            ((files++))
        done < <(get_dotfiles)
        
        echo -e "  ${GREEN}✓ ${linked}/${files} dotfiles liés${NC}"
    else
        echo -e "  ${YELLOW}⚠ Dossier dotfiles non trouvé${NC}"
    fi
}

# Lister les dotfiles
list_dotfiles() {
    echo -e "${BLUE}Dotfiles suivis:${NC}\n"
    
    get_dotfiles | while read -r dotfile; do
        [ -z "$dotfile" ] && continue
        
        local home_path="${HOME}/${dotfile}"
        local filename="${dotfile##*/}"
        
        if [ -L "${home_path}" ]; then
            echo -e "  ${GREEN}✓${NC} ${dotfile} → $(readlink "${home_path}")"
        elif [ -e "${home_path}" ]; then
            echo -e "  ${YELLOW}✗${NC} ${dotfile} (non lié)"
        else
            echo -e "  ${BLUE}○${NC} ${dotfile} (absent)"
        fi
    done
}

# Afficher la configuration
show_config() {
    echo -e "${BLUE}Configuration:${NC}\n"
    echo -e "  Fichier config: ${ENV_FILE}"
    
    if [ -f "${ENV_FILE}" ]; then
        echo -e "  ${GREEN}✓ Configuration trouvée${NC}\n"
        echo -e "${BLUE}Contenu:${NC}"
        grep -v "^#" "${ENV_FILE}" | grep -v "^$" | sed 's/^/    /'
    else
        echo -e "  ${RED}✗ Configuration non trouvée${NC}"
    fi
}

# Exécuter la commande
if [ -z "$1" ] || [ "$1" = "--help" ] || [ "$1" = "-h" ] || [ "$1" = "help" ]; then
    show_help
    exit 0
fi

# Charger la configuration
if ! load_config; then
    if [ "$1" != "config" ] && [ "$1" != "init" ]; then
        echo -e "${RED}✗ Configuration requise${NC}"
        exit 1
    fi
fi

# Exécuter la commande
if [ -z "$1" ] || [ "$1" = "--help" ] || [ "$1" = "-h" ] || [ "$1" = "help" ]; then
    show_help
    exit 0
fi

# Charger la configuration
if ! load_config; then
    if [ "$1" != "config" ] && [ "$1" != "init" ]; then
        echo -e "${RED}✗ Configuration requise${NC}"
        exit 1
    fi
fi

# Fonction pour gérer Obsidian
manage_obsidian() {
    local cmd=$1
    
    if [ -z "${OBSIDIAN_VAULT}" ]; then
        echo -e "${YELLOW}⚠ OBSIDIAN_VAULT non configuré${NC}"
        return 1
    fi
    
    if [ ! -d "${OBSIDIAN_VAULT}" ]; then
        echo -e "${YELLOW}⚠ Dossier Obsidian n'existe pas: ${OBSIDIAN_VAULT}${NC}"
        return 1
    fi
    
    # Chemin vers la vault Obsidian locale
    local OBSIDIAN_LOCAL="${HOME}/Obsidian"
    
    case "${cmd}" in
        sync)
            echo -e "${BLUE}Synchronisation d'Obsidian vers ${OBSIDIAN_VAULT}...${NC}"
            if [ -d "${OBSIDIAN_LOCAL}" ]; then
                rsync -av "${OBSIDIAN_LOCAL}/" "${OBSIDIAN_VAULT}/"
                echo -e "${GREEN}✓ Synchronisation Obsidian terminée${NC}"
            else
                echo -e "${YELLOW}⚠ Vault locale non trouvée${NC}"
            fi
            ;;
        restore)
            echo -e "${BLUE}Restauration d'Obsidian depuis ${OBSIDIAN_VAULT}...${NC}"
            mkdir -p "${OBSIDIAN_LOCAL}"
            rsync -av "${OBSIDIAN_VAULT}/" "${OBSIDIAN_LOCAL}/"
            echo -e "${GREEN}✓ Restauration Obsidian terminée${NC}"
            ;;
        status)
            echo -e "${BLUE}Statut Obsidian:${NC}"
            echo -e "  Vault distante: ${GREEN}${OBSIDIAN_VAULT}${NC}"
            if [ -d "${OBSIDIAN_LOCAL}" ]; then
                local local_size=$(du -sh "${OBSIDIAN_LOCAL}" 2>/dev/null | cut -f1)
                echo -e "  Vault locale: ${GREEN}${OBSIDIAN_LOCAL}${NC} (${local_size})"
            else
                echo -e "  Vault locale: ${YELLOW}non trouvée${NC}"
            fi
            ;;
    esac
}

# Fonction pour gérer VS Code
manage_vscode() {
    local cmd=$1
    
    if [ -z "${VSCODE_CONFIG}" ]; then
        echo -e "${YELLOW}⚠ VSCODE_CONFIG non configuré${NC}"
        return 1
    fi
    
    if [ ! -d "${VSCODE_CONFIG}" ]; then
        echo -e "${YELLOW}⚠ Dossier VS Code n'existe pas: ${VSCODE_CONFIG}${NC}"
        return 1
    fi
    
    # Déterminer le chemin VS Code selon le système
    local VSCODE_LOCAL
    if [ "$(uname -s)" = "Darwin" ]; then
        VSCODE_LOCAL="${HOME}/Library/Application Support/Code"
    else
        VSCODE_LOCAL="${HOME}/.config/Code"
    fi
    
    case "${cmd}" in
        sync)
            echo -e "${BLUE}Synchronisation de VS Code vers ${VSCODE_CONFIG}...${NC}"
            if [ -d "${VSCODE_LOCAL}" ]; then
                rsync -av --exclude=workspaceStorage --exclude=CachedData "${VSCODE_LOCAL}/User/" "${VSCODE_CONFIG}/"
                echo -e "${GREEN}✓ Synchronisation VS Code terminée${NC}"
            else
                echo -e "${YELLOW}⚠ Configuration VS Code locale non trouvée${NC}"
            fi
            ;;
        restore)
            echo -e "${BLUE}Restauration de VS Code depuis ${VSCODE_CONFIG}...${NC}"
            mkdir -p "${VSCODE_LOCAL}/User"
            rsync -av "${VSCODE_CONFIG}/" "${VSCODE_LOCAL}/User/"
            echo -e "${GREEN}✓ Restauration VS Code terminée${NC}"
            ;;
        status)
            echo -e "${BLUE}Statut VS Code:${NC}"
            echo -e "  Config distante: ${GREEN}${VSCODE_CONFIG}${NC}"
            if [ -d "${VSCODE_LOCAL}" ]; then
                local local_size=$(du -sh "${VSCODE_LOCAL}" 2>/dev/null | cut -f1)
                echo -e "  Config locale: ${GREEN}${VSCODE_LOCAL}${NC} (${local_size})"
            else
                echo -e "  Config locale: ${YELLOW}non trouvée${NC}"
            fi
            ;;
    esac
}

# Gérer packages.conf
manage_packages() {
    local cmd="${1:-status}"
    
    if [ -z "${PACKAGES_CONF_DIR}" ]; then
        echo -e "${YELLOW}⚠ PACKAGES_CONF_DIR n'est pas défini dans ${ENV_FILE}${NC}"
        echo -e "${BLUE}Exemple: PACKAGES_CONF_DIR=\"\$HOME/OneDrive/ok_computer\"${NC}"
        return 1
    fi
    
    if [ ! -d "${PACKAGES_CONF_DIR}" ]; then
        echo -e "${YELLOW}⚠ Dossier n'existe pas: ${PACKAGES_CONF_DIR}${NC}"
        echo -e "${BLUE}Création du dossier...${NC}"
        mkdir -p "${PACKAGES_CONF_DIR}"
    fi
    
    local SOURCE_CONF="${SCRIPT_DIR}/packages.conf"
    local EXAMPLE_CONF="${SCRIPT_DIR}/packages.conf.example"
    local REMOTE_CONF="${PACKAGES_CONF_DIR}/packages.conf"
    
    case "${cmd}" in
        sync)
            echo -e "${BLUE}Synchronisation de packages.conf vers ${PACKAGES_CONF_DIR}...${NC}"
            if [ -f "${SOURCE_CONF}" ]; then
                cp "${SOURCE_CONF}" "${REMOTE_CONF}"
                echo -e "${GREEN}✓ packages.conf synchronisé${NC}"
            elif [ -f "${EXAMPLE_CONF}" ]; then
                cp "${EXAMPLE_CONF}" "${REMOTE_CONF}"
                echo -e "${GREEN}✓ packages.conf.example copié comme base${NC}"
            else
                echo -e "${RED}✗ Aucun fichier packages.conf trouvé${NC}"
                return 1
            fi
            ;;
        restore)
            echo -e "${BLUE}Restauration de packages.conf depuis ${PACKAGES_CONF_DIR}...${NC}"
            if [ -f "${REMOTE_CONF}" ]; then
                cp "${REMOTE_CONF}" "${SOURCE_CONF}"
                echo -e "${GREEN}✓ packages.conf restauré${NC}"
            else
                echo -e "${YELLOW}⚠ Aucun packages.conf distant trouvé${NC}"
                if [ -f "${EXAMPLE_CONF}" ]; then
                    echo -e "${BLUE}Copie de l'exemple...${NC}"
                    cp "${EXAMPLE_CONF}" "${SOURCE_CONF}"
                    echo -e "${GREEN}✓ packages.conf créé depuis l'exemple${NC}"
                fi
            fi
            ;;
        status)
            echo -e "${BLUE}Statut packages.conf:${NC}"
            echo -e "  Dossier synchronisé: ${GREEN}${PACKAGES_CONF_DIR}${NC}"
            if [ -f "${REMOTE_CONF}" ]; then
                local line_count=$(wc -l < "${REMOTE_CONF}" 2>/dev/null | tr -d ' ')
                echo -e "  Fichier distant: ${GREEN}${REMOTE_CONF}${NC} (${line_count} lignes)"
            else
                echo -e "  Fichier distant: ${YELLOW}non trouvé${NC}"
            fi
            if [ -f "${SOURCE_CONF}" ]; then
                local line_count=$(wc -l < "${SOURCE_CONF}" 2>/dev/null | tr -d ' ')
                echo -e "  Fichier local: ${GREEN}${SOURCE_CONF}${NC} (${line_count} lignes)"
            else
                echo -e "  Fichier local: ${YELLOW}utilise packages.conf.example${NC}"
            fi
            ;;
    esac
}

case "$1" in
    init)
        init_sync
        ;;
    setup)
        setup_symlinks
        ;;
    sync)
        sync_to_remote
        manage_obsidian sync 2>/dev/null || true
        manage_vscode sync 2>/dev/null || true
        ;;
    restore)
        restore_from_remote
        manage_obsidian restore 2>/dev/null || true
        manage_vscode restore 2>/dev/null || true
        ;;
    status)
        show_status
        echo ""
        manage_obsidian status 2>/dev/null || true
        echo ""
        manage_vscode status 2>/dev/null || true
        ;;
    list)
        list_dotfiles
        ;;
    config)
        show_config
        ;;
    obsidian)
        manage_obsidian "${2:-status}"
        ;;
    vscode)
        manage_vscode "${2:-status}"
        ;;
    packages)
        manage_packages "${2:-status}"
        ;;
    *)
        echo -e "${RED}✗ Commande inconnue: $1${NC}"
        show_help
        exit 1
        ;;
esac
