#!/usr/bin/env bash
# ============================================================
# BWL Slayer · Godot 4 Toolchain
#
#单一 Versionsquelle: GODOT_VERSION in .godot-version.
# Editor-Binary, Export-Templates und CI-Workflow verwenden
# exakt dieselbe Version.
# ============================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_VERSION="$(cat "${REPO_ROOT}/.godot-version")"
TOOLS_DIR="${REPO_ROOT}/.godot-tools"

GODOT_DIR="${TOOLS_DIR}/godot-${GODOT_VERSION}"
GODOT_BIN="${GODOT_DIR}/godot"

# Godot erwartet die Export-Templates unter einem Verzeichnis, in dem der
# Versionsstring normalisiert ist: "4.7.2-stable" wird zu
# "4.7.2.stable". Ohne diese Umbenennung findet der Exporter die
# Templates nicht.
GODOT_TEMPLATE_DIR="${GODOT_VERSION/-stable/.stable}"
TEMPLATES_DIR="${HOME}/.local/share/godot/export_templates/${GODOT_TEMPLATE_DIR}"

# --- Version ermitteln ---
godot_version() {
  "${GODOT_BIN}" --version 2>/dev/null | head -n1
}

# --- Editor-Binary installieren ---
install_editor() {
  if [[ -x "${GODOT_BIN}" ]]; then
    echo "Godot ${GODOT_VERSION} ist bereits installiert: $(godot_version)"
    return 0
  fi
  mkdir -p "${GODOT_DIR}"
  local zip="${TOOLS_DIR}/godot-${GODOT_VERSION}.zip"
  local url="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_linux.x86_64.zip"
  echo "Lade Godot ${GODOT_VERSION} herunter …"
  curl -fsSL "${url}" -o "${zip}"
  unzip -q -o "${zip}" -d "${GODOT_DIR}"
  # Zip enthaelt eine einzelne Datei namens Godot_v<version>_linux.x86_64
  local inner
  inner="$(find "${GODOT_DIR}" -maxdepth 1 -type f -name 'Godot_v*' | head -n1)"
  [[ -n "${inner}" ]] && mv "${inner}" "${GODOT_BIN}"
  chmod +x "${GODOT_BIN}"
  rm -f "${zip}"
  echo "Installiert: $(godot_version)"
}

# --- Export-Templates installieren ---
install_templates() {
  if [[ -d "${TEMPLATES_DIR}" ]] && [[ -n "$(ls -A "${TEMPLATES_DIR}" 2>/dev/null)" ]]; then
    echo "Export-Templates ${GODOT_VERSION} sind bereits vorhanden."
    return 0
  fi
  local tpz="${TOOLS_DIR}/templates-${GODOT_VERSION}.tpz"
  local url="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_export_templates.tpz"
  mkdir -p "${TOOLS_DIR}"
  echo "Lade Export-Templates ${GODOT_VERSION} herunter …"
  curl -fsSL "${url}" -o "${tpz}"
  mkdir -p "${TEMPLATES_DIR}"
  # .tpz ist ein ZIP mit einem 'templates'-Ordner
  local tmp
  tmp="$(mktemp -d)"
  unzip -q -o "${tpz}" -d "${tmp}"
  if [[ -d "${tmp}/templates" ]]; then
    cp -r "${tmp}/templates/." "${TEMPLATES_DIR}/"
  else
    cp -r "${tmp}/." "${TEMPLATES_DIR}/"
  fi
  rm -rf "${tmp}" "${tpz}"
  echo "Export-Templates installiert: ${TEMPLATES_DIR}"
}

# --- Projekt headless importieren ---
import_project() {
  echo "Importiere Projekt headless …"
  "${GODOT_BIN}" --headless --path "${REPO_ROOT}/godot" --import
}

case "${1:-help}" in
  install)
    install_editor
    install_templates
    ;;
  install-editor) install_editor ;;
  install-templates) install_templates ;;
  import) install_editor; import_project ;;
  version) install_editor; godot_version ;;
  *)
    cat <<'EOF'
BWL Slayer · Godot-Toolchain

  ./tools/godot.sh install          Editor + Export-Templates installieren
  ./tools/godot.sh install-editor   nur Editor-Binary
  ./tools/godot.sh install-templates nur Export-Templates
  ./tools/godot.sh import           Projekt headless importieren
  ./tools/godot.sh version          installierte Version anzeigen
EOF
    ;;
esac
