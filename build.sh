#!/usr/bin/env bash

set -euo pipefail

# Compile all shell scripts in src/ using shc into dist/
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="${ROOT_DIR}/src"
DIST_DIR="${ROOT_DIR}/dist"
VERSION_FILE="${ROOT_DIR}/VERSION"
VERSION="$(cat "${VERSION_FILE}" 2>/dev/null || echo 'dev')"

if ! command -v shc >/dev/null 2>&1; then
  echo "shc est requis pour compiler les scripts (sudo apt-get install -y shc)" >&2
  exit 1
fi

rm -rf "${DIST_DIR}"
mkdir -p "${DIST_DIR}"

echo "Build v${VERSION}"

compile_script() {
  local script_path="$1"
  local base
  base="$(basename "${script_path}")"
  # shc génère <base>.x et <base>.x.c; on place le binaire final dans dist/<base>
  shc -f "${script_path}" -o "${DIST_DIR}/${base}" >/dev/null
  rm -f "${DIST_DIR}/${base}.x.c" "${DIST_DIR}/${base}.x" 2>/dev/null || true
}

for script in "${SRC_DIR}"/*.sh; do
  [ -e "${script}" ] || continue
  compile_script "${script}"
  echo "Compilé: ${script} → ${DIST_DIR}/$(basename "${script}")"
done

# Inclure le fichier de configuration pour distribution
if [ -f "${SRC_DIR}/packages.conf" ]; then
  cp "${SRC_DIR}/packages.conf" "${DIST_DIR}/packages.conf"
fi

# Générer un manifest avec la version
cat > "${DIST_DIR}/MANIFEST.txt" << EOF
init_mac compiled release v${VERSION}
Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Built with: shc

Files:
EOF

ls -lh "${DIST_DIR}" | awk 'NR>1 {print $9 " (" $5 ")"}' >> "${DIST_DIR}/MANIFEST.txt" || true

echo "Build v${VERSION} terminé. Artefacts dans ${DIST_DIR}"