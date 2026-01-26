# ok_computer
# ok_computer

Repository to quickly reconfigure a new computer (macOS, Windows, Linux).

## Quick Install

### From releases (recommended)

Download the latest release and extract:
```bash
curl -fsSL -o init-computer.tar.gz \
  https://github.com/axgd-code/ok_computer/releases/download/$(curl -s https://api.github.com/repos/axgd-code/ok_computer/releases/latest | grep tag_name | cut -d'"' -f4)/init-mac-scripts.tar.gz
tar -xzf init-computer.tar.gz
```

Run the installer using the `okc` helper included in the archive:
```bash
chmod +x okc
./okc init
```

If you prefer, install `okc` system-wide first and then run:
```bash
chmod +x okc install_okc.sh
./install_okc.sh    # or sudo ./install_okc.sh
okc init
```

### From source

```bash
git clone https://github.com/axgd-code/ok_computer.git
cd ok_computer
chmod +x okc install_okc.sh
./install_okc.sh    # optional: install okc into your PATH
okc init
```

## Structure

- `src/`: main scripts and configuration
  - `src/init.sh`: orchestrator that detects OS and runs setup
  - `src/init_conf_macOs.sh` / `src/init_conf_windows.sh`: platform-specific configuration
  - `src/packages.conf`: list of packages to install
  - `src/app.sh`: simple app manager (add/remove/list)
  - `src/dotfiles.sh`: dotfiles sync manager
  - `src/wifi_from_kdbx.sh`: import Wi‑Fi profiles from KeePassXC
  - `src/update.sh`: update script for packages
  - `src/setup_auto_update.sh`: configure automatic daily updates
- `test/`: local checks

## Configuration

Copy `.env.example` to `.env.local` and edit to match your paths.
Typical variables:
- `SYNC_DIR` — path to your synchronized folder (OneDrive, Synology Drive, Dropbox, ...)
- `PACKAGES_CONF_DIR` — optional remote folder to store a shared `packages.conf`
- `OBSIDIAN_VAULT`, `VSCODE_CONFIG` — optional sync targets

Automatic update schedule (optional):
- `AUTO_UPDATE_HOUR` — hour in 0-23 (default: 21)
- `AUTO_UPDATE_MINUTE` — minute in 0-59 (default: 0)

Example `.env.local` additions:
```dotenv
AUTO_UPDATE_HOUR=21
AUTO_UPDATE_MINUTE=0
```

`src/setup_auto_update.sh` reads `.env.local` (one level up) and uses these values to configure:
- macOS: a `launchd` agent (`$HOME/Library/LaunchAgents/...plist`)
- Windows: a scheduled task via `schtasks` (uses the provided time)
- Linux: a cron job (uses the provided minute/hour)

## Commands using `okc`

Use `okc` to run repository scripts without typing `bash src/...`.

Dotfiles examples:
```bash
okc dotfiles init      # initialize sync
okc dotfiles setup     # create symlinks
okc dotfiles sync      # push changes to sync folder
okc dotfiles restore   # restore from sync folder
okc dotfiles status    # show status
```

App manager examples:
```bash
okc app install firefox
okc app uninstall firefox
okc app list
okc app add some-app
okc app remove some-app
```

Automatic updates setup:
```bash
okc setup_auto_update
```

If you prefer to run the script directly:
```bash
bash src/setup_auto_update.sh
```

## Wi‑Fi import from KeePassXC

Use `okc` or run the script directly:
```bash
okc wifi_from_kdbx --db /path/to/vault.kdbx --group "Wi-Fi"
# or
bash src/wifi_from_kdbx.sh --db /path/to/vault.kdbx --group "Wi-Fi"
```

## Tests

Run local checks:
```bash
bash test/test.sh
```

## okc — quick helper

The `okc` script dispatches to `src/<command>.sh` so you can run tasks like `okc init`, `okc app`, `okc dotfiles`.

Install example (local):
```bash
chmod +x okc
./okc init
```

Install example (system):
```bash
chmod +x okc install_okc.sh
sudo ./install_okc.sh
okc init
```

## License

See [LICENSE](LICENSE)

Run local checks:
```bash
bash test/test.sh
```

## License

See [LICENSE](LICENSE)
### Configuration personnalisée (recommandé)

Pour avoir votre propre liste de packages synchronisée entre vos machines :

1. Créer le fichier `.env.local` depuis l'exemple :
```bash
cp .env.example .env.local
```

2. Éditer `.env.local` et définir le chemin de synchronisation :
```bash
PACKAGES_CONF_DIR="$HOME/OneDrive/ok_computer"
# ou
PACKAGES_CONF_DIR="$HOME/SynologyDrive/ok_computer"
```

3. Synchroniser votre fichier packages.conf personnalisé :
```bash
# Copier la liste actuelle vers le dossier synchronisé
bash src/dotfiles.sh packages sync

# Ou restaurer depuis le dossier synchronisé
bash src/dotfiles.sh packages restore

# Voir le statut
bash src/dotfiles.sh packages status
```

**Avantages** :
- ✅ Votre liste de packages est synchronisée automatiquement via OneDrive/Synology
- ✅ Même configuration sur tous vos ordinateurs
- ✅ Le fichier `packages.conf` local est ignoré par Git (personnel)
- ✅ Le repository contient seulement `packages.conf.example` comme référence

### Méthode 1 : Édition manuelle

Éditez votre fichier packages.conf (synchronisé ou local dans `src/packages.conf`) en respectant le format :
```
TYPE|NOM_MAC|NOM_WINDOWS|DESCRIPTION
```

Exemples :
- `brew|git|git|Version control system` (disponible sur les deux)
- `cask|firefox|firefox|Web browser` (disponible sur les deux)
- `cask|appcleaner|-|App cleaner for macOS` (macOS uniquement)
- `brew|wget|-|GNU wget` (macOS uniquement)

### Méthode 2 : Utiliser le gestionnaire d'applications ([src/app.sh](src/app.sh))

Installer une application et l'ajouter automatiquement à packages.conf :
```bash
bash src/app.sh install firefox
bash src/app.sh install vlc
bash src/app.sh install git
```

Le processus `install` effectue automatiquement :
1. ✓ Vérification de la disponibilité via les API (Homebrew, Chocolatey)
2. ✓ Installation sur la plateforme actuelle
3. ✓ Détection automatique de la disponibilité sur les autres plateformes
4. ✓ Remplissage complet de packages.conf avec les infos correctes

Désinstaller une application et la supprimer de packages.conf :
```bash
bash src/app.sh uninstall firefox
bash src/app.sh uninstall vlc
```

Ajouter une application à packages.conf sans l'installer :
```bash
bash src/app.sh add firefox
```

Supprimer une application de packages.conf sans la désinstaller :
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

# Packages personnalisés
PACKAGES_CONF_DIR="$HOME/OneDrive/ok_computer"

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

### Gestion de packages.conf

Synchroniser votre liste de packages personnalisée :
```bash
bash src/dotfiles.sh packages sync
```

Restaurer votre liste de packages :
```bash
bash src/dotfiles.sh packages restore
```

Voir le statut :
```bash
bash src/dotfiles.sh packages status
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
- `packages.conf` (liste personnalisée des applications)
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

## Wi-Fi from KeePassXC

Import your Wi‑Fi passwords from a KeePassXC vault for macOS, Windows, or Linux.

Prerequisites: keepassxc-cli installed and available in PATH. The kdbx vault should contain a group (default "Wi‑Fi") where Title = SSID and Password = Wi‑Fi key. Optional attributes: "security" (WPA2/WPA3/OPEN) and "hidden" (true/false).

Example:
```bash
bash src/wifi_from_kdbx.sh --db /path/to/vault.kdbx --group "Wi‑Fi"
```

Optional `.env.local` variables (used by [src/init.sh](src/init.sh) to run import automatically at the end of initialization):
- `WIFI_KDBX_DB="/path/to/vault.kdbx"`
- `WIFI_KDBX_GROUP="Wi‑Fi"` (default)
- `WIFI_KDBX_KEY_FILE="/path/to/keyfile.key"` (if needed)
- `WIFI_KDBX_ASK_PASS=1` to force interactive password prompt (do not store passwords in files/env)
- `WIFI_KDBX_DRY_RUN=1` to simulate actions

Useful options:
- `--key-file <file>` : if the vault uses a keyfile
- `--dry-run` : show actions without modifying the system
- Authentication: let keepassxc-cli prompt for the password, or export `KEEPASSXC_CLI_PASSWORD` before running the script
- See the script: [src/wifi_from_kdbx.sh](src/wifi_from_kdbx.sh)

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

## okc — utilitaire rapide

Le script `okc` permet d'appeler rapidement les scripts présents dans `src/` sans préfixer par `bash src/...`.

Exemples :

```bash
okc init                # lance src/init.sh
okc app install firefox # lance src/app.sh install firefox
okc dotfiles sync       # lance src/dotfiles.sh sync
okc packages sync       # alias géré via src/dotfiles.sh packages
```

Installation recommandée (copie/symlink dans votre PATH) :

```bash
chmod +x okc install_okc.sh
./install_okc.sh
# ou (installation système)
sudo ./install_okc.sh
```

Le script `install_okc.sh` installe `okc` dans `/usr/local/bin` si possible, sinon dans `~/.local/bin` et ajoute `~/.local/bin` à `~/.profile` si nécessaire.

Vous pouvez aussi installer manuellement :

```bash
chmod +x okc
sudo ln -sf "$PWD/okc" /usr/local/bin/okc
```

Après installation, exécutez `okc` depuis n'importe où.