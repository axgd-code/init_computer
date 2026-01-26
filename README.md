# ok_computer

A set of scripts to quickly configure a new computer (macOS, Windows, Linux).

## Quick Install

### From releases (recommended)

Download the latest release and extract:
```bash
curl -fsSL -o init-computer.tar.gz \
  https://github.com/axgd-code/ok_computer/releases/download/$(curl -s https://api.github.com/repos/axgd-code/ok_computer/releases/latest | grep tag_name | cut -d'"' -f4)/init-mac-scripts.tar.gz
tar -xzf init-computer.tar.gz
```

Run the installer using the included `okc` helper:
```bash
chmod +x okc
./okc init
```

Or install `okc` system-wide first and then run:
```bash
chmod +x okc install_okc.sh
sudo ./install_okc.sh
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

## Repository layout

- `src/`: main scripts and helpers
  - `src/init.sh`: OS detection and orchestrator
  - `src/init_conf_macOs.sh`, `src/init_conf_windows.sh`: platform-specific steps
  - `src/packages.conf`: package list used by installers
  - `src/app.sh`: app management helper (install/add/remove/list)
  - `src/dotfiles.sh`: dotfiles sync and symlink management
  - `src/wifi_from_kdbx.sh`: import Wi‑Fi profiles from KeePassXC vaults
  - `src/update.sh`: update packages and tools
  - `src/setup_auto_update.sh`: configure automated updates
- `test/`: local checks and scripts

## Configuration

Copy `.env.example` to `.env.local` and edit the values to match your setup.

Important variables:
- `SYNC_DIR`: path to your synchronized folder (OneDrive, Synology Drive, Dropbox, ...)
- `PACKAGES_CONF_DIR`: optional remote folder to keep a shared `packages.conf`
- `OBSIDIAN_VAULT`, `VSCODE_CONFIG`: optional paths for Obsidian or VS Code sync

Automatic update schedule (optional):
- `AUTO_UPDATE_HOUR` (0-23, default: 21)
- `AUTO_UPDATE_MINUTE` (0-59, default: 0)

Example `.env.local`:
```dotenv
AUTO_UPDATE_HOUR=21
AUTO_UPDATE_MINUTE=0
```

`src/setup_auto_update.sh` will read `.env.local` and configure:
- macOS: a `launchd` agent
- Windows: a scheduled task via `schtasks`
- Linux: a cron job

## Usage (`okc` helper)

The `okc` script dispatches to `src/<command>.sh`. Examples:

Dotfiles:
```bash
okc dotfiles init    # initialize dotfiles sync
okc dotfiles setup   # create symlinks
okc dotfiles sync    # push changes to sync folder
okc dotfiles restore # restore from sync folder
okc dotfiles status  # show status
```

App manager:
```bash
okc app install firefox
okc app uninstall firefox
okc app list
okc app add some-app
okc app remove some-app
```

Automatic updates:
```bash
okc setup_auto_update
# or
bash src/setup_auto_update.sh
```

Wi‑Fi import from KeePassXC:
```bash
okc wifi_from_kdbx --db /path/to/vault.kdbx --group "Wi-Fi"
# or
bash src/wifi_from_kdbx.sh --db /path/to/vault.kdbx --group "Wi-Fi"
```

## Packages management

`src/packages.conf` lists packages and the cross-platform mappings used by the installers. You can keep a personal copy of this list in a synced folder and point `PACKAGES_CONF_DIR` at it.

App manager helpers (`src/app.sh`) can add or remove entries from `packages.conf`, install/uninstall apps, and check availability across platforms.

## Dotfiles synchronization

Keep your dotfiles in a synced directory (OneDrive, Synology Drive, Dropbox...) and use `src/dotfiles.sh` to manage symlinks and restore files.

Common commands:
```bash
bash src/dotfiles.sh init
bash src/dotfiles.sh setup
bash src/dotfiles.sh sync
bash src/dotfiles.sh restore
bash src/dotfiles.sh status
```

You can also sync specific targets (packages, Obsidian vault, VS Code) using subcommands.

## Tests

Run local checks:
```bash
bash test/test.sh
```

## License

See [LICENSE](LICENSE)

---

If you want, I can also:
- prepare a short `CONTRIBUTING.md` with how to test and add packages, or
- update `ui/README.md` to match this style.

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
