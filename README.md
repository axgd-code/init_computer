# init_computer

Simple repo pour ré-installer plus vite un ordinateur neuf (macOS, Windows, Linux).

## Installation rapide

### Via les releases (recommandé)

Télécharger la dernière release :
```bash
curl -fsSL -o init-computer.tar.gz \
  https://github.com/axgd-code/init_computer/releases/download/$(curl -s https://api.github.com/repos/axgd-code/init_computer/releases/latest | grep tag_name | cut -d'"' -f4)/init-mac-scripts.tar.gz
tar -xzf init-computer.tar.gz
bash init.sh
```

Ou télécharger manuellement depuis [releases](https://github.com/axgd-code/init_computer/releases), puis :
```bash
tar -xzf init-mac-scripts.tar.gz
bash init.sh
```

### Depuis le code source

Cloner et exécuter depuis les sources :
```bash
git clone https://github.com/axgd-code/init_computer.git
cd init_computer
bash src/init.sh
```

## Structure

- [src](src) : scripts et configuration principale
  - [src/init.sh](src/init.sh) : orchestrateur qui détecte l'OS et déclenche l'installation
  - [src/init_conf_macOs.sh](src/init_conf_macOs.sh) / [src/init_conf_windows.sh](src/init_conf_windows.sh) : réglages spécifiques macOS ou Windows
  - [src/packages.conf](src/packages.conf) : catalogue des packages installés
  - [src/app.sh](src/app.sh) : gestionnaire d'applications (ajout/suppression/list)
  - [src/dotfiles.sh](src/dotfiles.sh) : gestion et synchro des dotfiles
  - [src/wifi_from_kdbx.sh](src/wifi_from_kdbx.sh) : import Wi-Fi depuis KeePassXC
  - [src/install_fonts.sh](src/install_fonts.sh), [src/setup_auto_update.sh](src/setup_auto_update.sh), [src/update.sh](src/update.sh)
- [test](test) : vérifications locales
  - [test/test.sh](test/test.sh) : `bash -n` + `shellcheck` (si présent)

## Fichiers du projet

### 📋 Configuration
- [src/packages.conf](src/packages.conf) : fichier de configuration unifié listant tous les packages à installer pour macOS et Windows
  - Format : `TYPE|NOM_MAC|NOM_WINDOWS|DESCRIPTION`
  - Les packages s'installent automatiquement lors de l'exécution de [src/init.sh](src/init.sh)

### 🔧 Scripts d'installation
- [src/init.sh](src/init.sh) : script principal qui détecte le système d'exploitation et lance la configuration appropriée
- [src/init_conf_macOs.sh](src/init_conf_macOs.sh) : configuration spécifique à macOS (préférences système, Dock, Finder, etc.)
- [src/init_conf_windows.sh](src/init_conf_windows.sh) : installation des packages via Chocolatey pour Windows
- [src/install_fonts.sh](src/install_fonts.sh) : installation des polices de caractères (macOS)
- [src/app.sh](src/app.sh) : gestionnaire d'applications simple pour installer/désinstaller des apps et mettre à jour [src/packages.conf](src/packages.conf)
- [src/dotfiles.sh](src/dotfiles.sh) : gestionnaire des dotfiles synchronisés via OneDrive, Synology Drive, etc.
- [src/wifi_from_kdbx.sh](src/wifi_from_kdbx.sh) : import de profils Wi-Fi depuis un vault KeePassXC

### 🔄 Mise à jour automatique
- [src/update.sh](src/update.sh) : script de mise à jour des packages
  - Exécutable manuellement : `bash src/update.sh`
  - Met à jour automatiquement tous les packages selon le système :
    - macOS : Homebrew, casks
    - Windows : Chocolatey
    - Linux : apt/dnf/yum

- [src/setup_auto_update.sh](src/setup_auto_update.sh) : configure la mise à jour automatique quotidienne à 21h00
  - Utilise launchd sur macOS
  - Utilise Task Scheduler sur Windows
  - Utilise cron sur Linux
  - Commande : `bash src/setup_auto_update.sh`

## Systèmes supportés

### 🍎 macOS
- Installation via Homebrew
- Configuration automatique des préférences système
- Installation de polices personnalisées
- Mise à jour automatique des packages

### 🪟 Windows
- Installation via Chocolatey (installation automatique si absent)
- Support de Git Bash, WSL, CYGWIN et MINGW
- Mise à jour automatique via Task Scheduler

### 🐧 Linux
- Détection automatique du gestionnaire de packages (apt, dnf, yum)
- Mise à jour automatique via cron

## Packages inclus

Les packages installés incluent :
- Outils de développement : Git, Node.js, Docker, VS Code, OpenJDK, etc.
- Navigateurs : Firefox, Tor Browser
- Communication : Thunderbird, Signal
- Sécurité : KeePassXC, Cryptomator, VeraCrypt
- Productivité : Notion, Obsidian, Postman, Bruno
- Multimédia : VLC, FFmpeg
- Utilitaires : 7-Zip, TeamViewer, Transmission
- Et bien d'autres...

## Configuration de la mise à jour automatique

Pour activer la mise à jour automatique quotidienne à 21h00 :
```bash
bash src/setup_auto_update.sh
```

### Commandes de gestion

**macOS** :
```bash
# Désactiver
launchctl unload ~/Library/LaunchAgents/com.user.packages.update.plist

# Réactiver
launchctl load ~/Library/LaunchAgents/com.user.packages.update.plist
```

**Windows** :
```cmd
# Désactiver
schtasks //Change //TN "PackagesAutoUpdate" //DISABLE

# Réactiver
schtasks //Change //TN "PackagesAutoUpdate" //ENABLE

# Supprimer
schtasks //Delete //TN "PackagesAutoUpdate" //F
```

**Linux** :
```bash
# Voir les tâches cron
crontab -l

# Éditer les tâches cron
crontab -e
```

## Logs

Les logs de mise à jour sont sauvegardés dans :
- `update.log` : sortie standard
- `update_error.log` : erreurs (macOS uniquement)

## Ajouter ou modifier des packages

### Méthode 1 : Édition manuelle

Éditez le fichier [src/packages.conf](src/packages.conf) en respectant le format :
```
TYPE|NOM_MAC|NOM_WINDOWS|DESCRIPTION
```

Exemples :
- `brew|git|git|Version control system` (disponible sur les deux)
- `cask|firefox|firefox|Web browser` (disponible sur les deux)
- `cask|appcleaner|-|App cleaner for macOS` (macOS uniquement)
- `brew|wget|-|GNU wget` (macOS uniquement)

### Méthode 2 : Utiliser le gestionnaire d'applications ([src/app.sh](src/app.sh))

Installer une application et l'ajouter automatiquement à [src/packages.conf](src/packages.conf) :
```bash
bash src/app.sh install firefox
bash src/app.sh install vlc
bash src/app.sh install git
```

Le processus `install` effectue automatiquement :
1. ✓ Vérification de la disponibilité via les API (Homebrew, Chocolatey)
2. ✓ Installation sur la plateforme actuelle
3. ✓ Détection automatique de la disponibilité sur les autres plateformes
4. ✓ Remplissage complet de [src/packages.conf](src/packages.conf) avec les infos correctes

Désinstaller une application et la supprimer de [src/packages.conf](src/packages.conf) :
```bash
bash src/app.sh uninstall firefox
bash src/app.sh uninstall vlc
```

Ajouter une application à [src/packages.conf](src/packages.conf) sans l'installer :
```bash
bash src/app.sh add firefox
```

Supprimer une application de [src/packages.conf](src/packages.conf) sans la désinstaller :
```bash
bash src/app.sh remove firefox
```

Lister toutes les applications :
```bash
bash src/app.sh list
```

Vérifier la disponibilité d'une application sur toutes les plateformes :
```bash
bash src/app.sh check firefox
bash src/app.sh check git
```

La commande `check` utilise les API publiques pour vérifier la disponibilité sur :
- macOS : formulae.brew.sh (API Homebrew)
- Windows : community.chocolatey.org (API Chocolatey)
- Linux : packages.debian.org ou gestionnaire local (apt/dnf/yum)

## Synchronisation des dotfiles

Synchronisez vos fichiers de configuration (dotfiles) via OneDrive, Synology Drive, Dropbox, etc.

### Configuration

1. Créer le fichier de configuration local :
```bash
cp .env.example .env.local
```

2. Éditer `.env.local` et spécifier les chemins :
```bash
# Dotfiles
SYNC_DIR="$HOME/OneDrive/dotfiles"

# Obsidian (optionnel)
OBSIDIAN_VAULT="$HOME/OneDrive/Obsidian"

# VS Code (optionnel)
VSCODE_CONFIG="$HOME/OneDrive/VSCode"
```

### Utilisation

Initialiser la synchronisation (première utilisation) :
```bash
bash src/dotfiles.sh init
```

Configurer les symlinks :
```bash
bash src/dotfiles.sh setup
```

Synchroniser les modifications vers le dossier synchronisé :
```bash
bash src/dotfiles.sh sync
```

Restaurer les dotfiles depuis le dossier synchronisé :
```bash
bash src/dotfiles.sh restore
```

Afficher le statut :
```bash
bash src/dotfiles.sh status
```

Lister les dotfiles suivis :
```bash
bash src/dotfiles.sh list
```

### Gestion d'Obsidian

Synchroniser votre vault Obsidian :
```bash
bash src/dotfiles.sh obsidian sync
```

Restaurer votre vault Obsidian :
```bash
bash src/dotfiles.sh obsidian restore
```

Voir le statut du vault :
```bash
bash src/dotfiles.sh obsidian status
```

### Gestion de VS Code

Synchroniser vos paramètres et extensions VS Code :
```bash
bash src/dotfiles.sh vscode sync
```

Restaurer vos paramètres VS Code :
```bash
bash src/dotfiles.sh vscode restore
```

Voir le statut de VS Code :
```bash
bash src/dotfiles.sh vscode status
```

### Dotfiles suivis

Les fichiers suivants sont synchronisés :
- `.bashrc`, `.zshrc` (configurations shell)
- `.gitconfig`, `.git-credentials` (configuration Git)
- `.vimrc`, `.config/nvim` (configuration éditeurs)
- `.config/helix`, `.config/starship.toml` (outils CLI)
- `.config/alacritty`, `.config/kitty` (terminaux)
- `.ssh/config`, `.ssh/authorized_keys` (SSH)

### Applications synchronisées

#### Obsidian

Synchronisez votre vault Obsidian pour avoir les mêmes notes sur tous vos appareils :
- Utilise rsync pour synchroniser les changements
- Commandes : `obsidian sync`, `obsidian restore`, `obsidian status`
- Configuration : `OBSIDIAN_VAULT` dans `.env.local`

#### VS Code

Synchronisez vos paramètres, thème et extensions VS Code :
- Synchronise le dossier `User` (settings.json, keybindings.json, extensions)
- Exclut les fichiers volumineux (workspaceStorage, CachedData)
- Fonctionne sur macOS (~/Library/Application Support/Code) et Linux (~/.config/Code)
- Commandes : `vscode sync`, `vscode restore`, `vscode status`
- Configuration : `VSCODE_CONFIG` dans `.env.local`

### Avantages

✅ Mutualisation : les mêmes dotfiles sur tous vos ordinateurs
✅ Synchronisation : automatique via OneDrive/Synology Drive
✅ Flexible : supporte n'importe quel service de stockage cloud
✅ Non commité : le chemin personnel n'est pas dans le repo
✅ Symlinks : les fichiers sont liés, pas copiés

## Wi-Fi depuis KeePassXC

Importez vos mots de passe Wi-Fi depuis un vault KeePassXC pour macOS, Windows ou Linux.

Pré-requis : keepassxc-cli installé, vault kdbx avec un groupe (par défaut "Wi-Fi") où le Title = SSID et le Password = clé Wi-Fi. Attributs optionnels : "security" (WPA2/WPA3/OPEN) et "hidden" (true/false).

Exemple d'exécution :
```bash
bash src/wifi_from_kdbx.sh --db /chemin/vers/vault.kdbx --group "Wi-Fi"
```

Variables dans `.env.local` (optionnel, utilisées par [src/init.sh](src/init.sh) pour lancer l'import automatiquement en fin de run) :
- `WIFI_KDBX_DB="/chemin/vers/vault.kdbx"`
- `WIFI_KDBX_GROUP="Wi-Fi"` (par défaut)
- `WIFI_KDBX_KEY_FILE="/chemin/vers/clef.key"` (si besoin)
- `WIFI_KDBX_ASK_PASS=1` pour forcer la saisie interactive (pas de mot de passe dans un fichier/env)
- `WIFI_KDBX_DRY_RUN=1` pour simuler

Options utiles :
- `--key-file <fichier>` : si le vault utilise un keyfile
- `--dry-run` : affiche les actions sans modifier le système
- Authentification : laissez keepassxc-cli demander le mot de passe, ou exportez `KEEPASSXC_CLI_PASSWORD` avant d'exécuter le script
- Voir le script : [src/wifi_from_kdbx.sh](src/wifi_from_kdbx.sh)

## Tests des scripts

Exécuter les vérifications locales :
```bash
bash test/test.sh
```

Le script vérifie :
- **Syntaxe bash** : `bash -n` sur tous les scripts
- **Lint** : `shellcheck` si disponible
- **Structure** : présence de répertoires et fichiers requis
- **Format packages.conf** : colonnes avec séparateurs `|` valides
- **VERSION** : format sémantique `X.Y.Z`
- **Permissions** : scripts marqués comme exécutables

## Build / CI / Releases

### Build local

Créer une archive locale des scripts :
```bash
tar -czf init-mac-scripts.tar.gz -C src .
```

### GitHub Actions CI

- [.github/workflows/ci.yml](.github/workflows/ci.yml) : à chaque push, compile et publie les scripts comme artefact
- [.github/workflows/release.yml](.github/workflows/release.yml) : à chaque tag `v*`, crée une release GitHub avec les scripts

### Créer une release

1. Mettre à jour [VERSION](VERSION)
2. Commiter
3. Créer un tag et pousser :
```bash
git tag v1.0.1
git push origin v1.0.1
```

GitHub Actions crée la release automatiquement.

## License

Voir le fichier [LICENSE](LICENSE)
