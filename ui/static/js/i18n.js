const translations = {
    en: {
        dashboard: "Dashboard",
        packages: "Packages",
        search: "Search & Install",
        settings: "Settings",
        maintenance: "Maintenance",
        maintenance_desc: "Run system updates (brew upgrade, update packages.conf, etc.)",
        run_update: "Run Update Now",
        quick_actions: "Quick Actions",
        import_installed: "Import Installed Packages",
        import_desc: "Scans system and adds to configuration",
        export_wifi: "Export Wi-Fi to KeePassXC",
        export_desc: "Imports local Wi-Fi passwords into a .kdbx file",
        configured_packages: "Configured Packages",
        search_package: "Search Package",
        search_placeholder: "e.g. firefox, git...",
        search_btn: "Search",
        all_stores: "All Stores",
        env_variables: "Environment Variables (.env.local)",
        save_changes: "Save Changes",
        running: "Running...",
        starting_update: "Starting update... please wait.",
        settings_saved: "Settings saved!",
        install_confirm: "Install {name}?",
        installing: "Installing {name}... (Check terminal/output for progress)",
        enter_db_path: "Enter path to KeePassXC database (.kdbx):",
        enter_db_pass: "Enter database password:",
        exporting: "Exporting...",
        loading: "Loading...",
        check: "Check"
    },
    fr: {
        dashboard: "Tableau de bord",
        packages: "Paquets",
        search: "Recherche & Install",
        settings: "Paramètres",
        maintenance: "Maintenance",
        maintenance_desc: "Lancer les mises à jour système (brew upgrade, etc.)",
        run_update: "Mettre à jour maintenant",
        quick_actions: "Actions rapides",
        import_installed: "Importer les paquets installés",
        import_desc: "Scan le système et ajoute à la configuration",
        export_wifi: "Exporter Wi-Fi vers KeePassXC",
        export_desc: "Importe les mots de passe Wi-Fi locaux dans un fichier .kdbx",
        configured_packages: "Paquets configurés",
        search_package: "Rechercher un paquet",
        search_placeholder: "ex: firefox, git...",
        search_btn: "Rechercher",
        all_stores: "Tous les stores",
        env_variables: "Variables d'environnement (.env.local)",
        save_changes: "Enregistrer",
        running: "En cours...",
        starting_update: "Mise à jour lancée... veuillez patienter.",
        settings_saved: "Paramètres enregistrés !",
        install_confirm: "Installer {name} ?",
        installing: "Installation de {name}... (Vérifiez le terminal)",
        enter_db_path: "Chemin vers la base KeePassXC (.kdbx) :",
        enter_db_pass: "Mot de passe de la base :",
        exporting: "Export en cours...",
        loading: "Chargement...",
        check: "Vérifier"
    }
};

let currentLang = 'en';

function setLanguage(lang) {
    if (translations[lang]) {
        currentLang = lang;
        updateUI();
    }
}

function t(key, params = {}) {
    let str = translations[currentLang][key] || key;
    for (const [k, v] of Object.entries(params)) {
        str = str.replace(`{${k}}`, v);
    }
    return str;
}

function updateUI() {
    document.querySelectorAll('[data-i18n]').forEach(el => {
        const key = el.getAttribute('data-i18n');
        if (key) {
           if(el.placeholder) {
               el.placeholder = t(key);
           } else {
               el.innerText = t(key);
           }
        }
    });
}
