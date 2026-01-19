#!/usr/bin/env bash

# Quick sanity checks for all repo scripts.
# - bash -n for syntax
# - shellcheck (if available) for lint
# - File structure verification
# - packages.conf format check
# - Build verification

set -euo pipefail

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
SRC_DIR="${ROOT_DIR}/src"
TEST_DIR="${SCRIPT_DIR}"
cd "${ROOT_DIR}"

SCRIPTS=(
  "${SRC_DIR}/app.sh"
  "${SRC_DIR}/dotfiles.sh"
  "${SRC_DIR}/init.sh"
  "${SRC_DIR}/init_conf_macOs.sh"
  "${SRC_DIR}/init_conf_windows.sh"
  "${SRC_DIR}/install_fonts.sh"
  "${SRC_DIR}/setup_auto_update.sh"
  "${SRC_DIR}/update.sh"
  "${SRC_DIR}/wifi_from_kdbx.sh"
)

have_shellcheck=false
if command -v shellcheck >/dev/null 2>&1; then
  have_shellcheck=true
fi

status=0

# === Syntax check ===
echo -e "${BLUE}==> Syntax check (bash -n)${NC}"
for file in "${SCRIPTS[@]}"; do
  if [ ! -f "$file" ]; then
    echo -e "${YELLOW}SKIP${NC} $file (absent)"
    continue
  fi
  if bash -n "$file"; then
    echo -e "${GREEN}OK${NC}   $file"
  else
    echo -e "${RED}FAIL${NC} $file"
    status=1
  fi
done

# === Shellcheck lint ===
if $have_shellcheck; then
  echo -e "${BLUE}==> shellcheck lint${NC}"
  for file in "${SCRIPTS[@]}"; do
    if [ ! -f "$file" ]; then
      continue
    fi
    if shellcheck -x "$file"; then
      echo -e "${GREEN}OK${NC}   $file"
    else
      echo -e "${RED}FAIL${NC} $file"
      status=1
    fi
  done
else
  echo -e "${YELLOW}shellcheck non trouvé, lint ignoré${NC}"
fi

# === File structure ===
echo -e "${BLUE}==> Vérification structure des répertoires${NC}"
required_dirs=("${SRC_DIR}" "${TEST_DIR}")
for dir in "${required_dirs[@]}"; do
  if [ -d "$dir" ]; then
    echo -e "${GREEN}OK${NC}   $dir"
  else
    echo -e "${RED}FAIL${NC} $dir manquant"
    status=1
  fi
done

# === Required files ===
echo -e "${BLUE}==> Vérification fichiers requis${NC}"
required_files=(
  "${SRC_DIR}/packages.conf"
  "${ROOT_DIR}/VERSION"
  "${ROOT_DIR}/build.sh"
  "${ROOT_DIR}/README.md"
)
for file in "${required_files[@]}"; do
  if [ -f "$file" ]; then
    echo -e "${GREEN}OK${NC}   $(basename "$file")"
  else
    echo -e "${RED}FAIL${NC} $file manquant"
    status=1
  fi
done

# === packages.conf format ===
echo -e "${BLUE}==> Vérification format packages.conf${NC}"
conf_file="${SRC_DIR}/packages.conf"
if [ -f "$conf_file" ]; then
  # Vérifier qu'il contient des lignes valides (non-vides, non-commentaires)
  total_lines=$(wc -l < "$conf_file")
  data_lines=$(grep -vc "^#\|^$" "$conf_file" || true)
  
  # Vérifier format basique avec grep
  invalid=$(grep -v "^#\|^$\|^[a-z]*|" "$conf_file" | wc -l || true)
  
  if [ "$invalid" -eq 0 ]; then
    echo -e "${GREEN}OK${NC}   $data_lines lignes valides / $total_lines total"
  else
    echo -e "${YELLOW}WARN${NC} $invalid lignes avec format suspect"
  fi
else
  echo -e "${RED}FAIL${NC} $conf_file manquant"
  status=1
fi

# === VERSION file ===
echo -e "${BLUE}==> Vérification VERSION${NC}"
if [ -f "${ROOT_DIR}/VERSION" ]; then
  version=$(cat "${ROOT_DIR}/VERSION" 2>/dev/null || echo "invalid")
  if [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${GREEN}OK${NC}   v${version}"
  else
    echo -e "${YELLOW}WARN${NC} VERSION format invalide: '$version'"
  fi
else
  echo -e "${RED}FAIL${NC} VERSION manquant"
  status=1
fi

# === Script permissions ===
echo -e "${BLUE}==> Vérification permissions des scripts${NC}"
for file in "${SCRIPTS[@]}" "${ROOT_DIR}/build.sh" "${TEST_DIR}/test.sh"; do
  if [ -f "$file" ]; then
    if [ -x "$file" ]; then
      echo -e "${GREEN}OK${NC}   executable: $(basename "$file")"
    else
      echo -e "${YELLOW}WARN${NC} non-executable: $(basename "$file")"
    fi
  fi
done

exit $status

