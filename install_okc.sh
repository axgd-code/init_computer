#!/usr/bin/env bash
set -euo pipefail

# install_okc.sh
# Installs the `okc` executable into /usr/local/bin or ~/.local/bin

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OKC_SRC="$SCRIPT_DIR/okc"

if [ ! -f "$OKC_SRC" ]; then
  echo "Fichier okc introuvable dans $SCRIPT_DIR" >&2
  exit 1
fi

install_global() {
  echo "Installation dans /usr/local/bin (nécessite sudo)..."
  sudo ln -sf "$OKC_SRC" /usr/local/bin/okc
  sudo chmod +x "$OKC_SRC"
  echo "okc installé dans /usr/local/bin/okc"
}

install_user() {
  dest="$HOME/.local/bin"
  mkdir -p "$dest"
  ln -sf "$OKC_SRC" "$dest/okc"
  chmod +x "$OKC_SRC"
  echo "okc installé dans $dest/okc"

  # Add ~/.local/bin to PATH if necessary
  case ":$PATH:" in
    *":$dest:"*)
      ;;
    *)
      echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$HOME/.profile"
      echo "Ajout de ~/.local/bin à PATH dans ~/.profile (reconnexion requise ou source ~/.profile)"
      ;;
  esac
}

echo "Choix de l'installation..."
if [ -w /usr/local/bin ]; then
  install_global
else
  echo "/usr/local/bin non accessible en écriture, installation pour l'utilisateur"
  install_user
fi

echo "Installation terminée. Testez avec : okc --help ou okc init"
