#!/usr/bin/env bash
set -euo pipefail

# Build standalone executable for current platform using PyInstaller
# Usage: ./build.sh [name]
NAME=${1:-ok_computer_ui}
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$HERE"

# Create venv and install
python3 -m venv .venv
. .venv/bin/activate
pip install -U pip
pip install -r requirements.txt

# Determine add-data separator (':' on Unix, ';' on Windows)
SEP=:
case "$(uname -s)" in
  MINGW*|CYGWIN*|MSYS*) SEP=';';;
  *) SEP=':';;
esac

# Run PyInstaller including templates and static folders
python -m PyInstaller --name "$NAME" --onefile \
  --add-data "templates${SEP}templates" \
  --add-data "static${SEP}static" \
  --collect-submodules flask \
  --hidden-import socket \
  app.py

echo "Built: dist/$NAME"
