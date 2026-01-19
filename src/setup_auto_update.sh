#!/usr/bin/env bash

echo "Configuration de la mise à jour automatique quotidienne à 21h00"

# Obtenir le chemin absolu du répertoire du script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UPDATE_SCRIPT="${SCRIPT_DIR}/update.sh"

# Vérifier que le script de mise à jour existe
if [ ! -f "${UPDATE_SCRIPT}" ]; then
    echo "✗ Erreur: Le script ${UPDATE_SCRIPT} n'existe pas"
    exit 1
fi

# Rendre le script de mise à jour exécutable
chmod +x "${UPDATE_SCRIPT}"

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
    echo "Configuration de launchd pour macOS..."
    
    PLIST_FILE="$HOME/Library/LaunchAgents/com.user.packages.update.plist"
    
    # Créer le répertoire si nécessaire
    mkdir -p "$HOME/Library/LaunchAgents"
    
    # Créer le fichier plist
    cat > "${PLIST_FILE}" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.packages.update</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>${UPDATE_SCRIPT}</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>21</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>${SCRIPT_DIR}/update.log</string>
    <key>StandardErrorPath</key>
    <string>${SCRIPT_DIR}/update_error.log</string>
</dict>
</plist>
EOF

    # Charger le service
    launchctl unload "${PLIST_FILE}" 2>/dev/null || true
    launchctl load "${PLIST_FILE}"
    
    echo "✓ Tâche planifiée créée: ${PLIST_FILE}"
    echo "✓ Les mises à jour s'exécuteront tous les jours à 21h00"
    echo "  Logs: ${SCRIPT_DIR}/update.log"
    echo ""
    echo "Pour désactiver: launchctl unload ${PLIST_FILE}"
    echo "Pour réactiver: launchctl load ${PLIST_FILE}"

elif [ "${MACHINE}" = "Windows" ]; then
    echo "Configuration du Task Scheduler pour Windows..."
    
    # Créer une tâche planifiée avec schtasks
    TASK_NAME="PackagesAutoUpdate"
    
    # Supprimer la tâche si elle existe déjà
    schtasks.exe //Delete //TN "${TASK_NAME}" //F 2>/dev/null || true
    
    # Créer la nouvelle tâche
    schtasks.exe //Create //TN "${TASK_NAME}" \
        //TR "\"C:\\Program Files\\Git\\bin\\bash.exe\" \"${UPDATE_SCRIPT}\"" \
        //SC DAILY //ST 21:00 //F
    
    echo "✓ Tâche planifiée créée: ${TASK_NAME}"
    echo "✓ Les mises à jour s'exécuteront tous les jours à 21h00"
    echo ""
    echo "Pour désactiver: schtasks //Change //TN \"${TASK_NAME}\" //DISABLE"
    echo "Pour réactiver: schtasks //Change //TN \"${TASK_NAME}\" //ENABLE"
    echo "Pour supprimer: schtasks //Delete //TN \"${TASK_NAME}\" //F"

elif [ "${MACHINE}" = "Linux" ]; then
    echo "Configuration de cron pour Linux..."
    
    # Créer une ligne cron
    CRON_LINE="0 21 * * * ${UPDATE_SCRIPT} >> ${SCRIPT_DIR}/update.log 2>&1"
    
    # Vérifier si la ligne existe déjà
    (crontab -l 2>/dev/null | grep -v "${UPDATE_SCRIPT}"; echo "${CRON_LINE}") | crontab -
    
    echo "✓ Tâche cron créée"
    echo "✓ Les mises à jour s'exécuteront tous les jours à 21h00"
    echo "  Logs: ${SCRIPT_DIR}/update.log"
    echo ""
    echo "Pour voir les tâches cron: crontab -l"
    echo "Pour éditer: crontab -e"

else
    echo "✗ Système d'exploitation non supporté: ${MACHINE}"
    exit 1
fi

echo ""
echo "Configuration terminée avec succès!"
echo "Vous pouvez tester manuellement avec: bash ${UPDATE_SCRIPT}"
