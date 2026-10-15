#!/usr/bin/env bash
# Noctalia Quran Verse Widget Installer
# Author: Hamza Qureshi (hamzzaqureshi)
set -euo pipefail

BOLD="\033[1m"; GREEN="\033[32m"; BLUE="\033[34m"; CYAN="\033[36m"; RED="\033[31m"; RESET="\033[0m"

AUTO_YES=false
[[ "${1:-}" =~ ^(-y|--yes)$ ]] && AUTO_YES=true

echo -e "${BOLD}${BLUE}==> Installing Noctalia Quran Verse Desktop Widget...${RESET}"

if ! command -v noctalia &>/dev/null; then
    echo -e "${RED}[ERROR] 'noctalia' command not found in PATH.${RESET}" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_SLUG="quran-verse"
PLUGIN_ID="hamzzaqureshi/quran-verse"
LOCAL_SOURCE="${HOME}/.local/share/noctalia/sources/local-plugins"

# 1. Setup local catalog directory
mkdir -p "${LOCAL_SOURCE}"
cat << 'EOF' > "${LOCAL_SOURCE}/catalog.toml"
[[plugin]]
id = "hamzzaqureshi/quran-verse"
name = "Quran Verse"
version = "1.0.0"
author = "hamzzaqureshi"
license = "MIT"
icon = "book"
description = "Daily Quran verse desktop widget with English Hilali-Khan translation and random verse exploration for Noctalia."
plugin_api = 24
tags = ["desktop", "language", "time", "utility"]
EOF

# 2. Symlink plugin repository
ln -sfn "${SCRIPT_DIR}" "${LOCAL_SOURCE}/${PLUGIN_SLUG}"
echo -e "${GREEN}✓${RESET} Linked plugin into catalog: ${CYAN}${LOCAL_SOURCE}/${PLUGIN_SLUG}${RESET}"

# 3. Register source in Noctalia if missing
if ! noctalia msg plugins source list 2>/dev/null | grep -q "local-plugins"; then
    noctalia msg plugins source add local-plugins path "${LOCAL_SOURCE}" >/dev/null 2>&1 || true
    echo -e "${GREEN}✓${RESET} Registered 'local-plugins' source."
fi

# 4. Enable plugin
STATUS="$(noctalia msg plugins enable "${PLUGIN_ID}" 2>&1 || true)"
echo -e "${GREEN}✓${RESET} Plugin enabled: ${CYAN}${STATUS}${RESET}"

echo -e "\n${BOLD}${GREEN}Installation Complete!${RESET}"
echo -e "Open the widget layout editor anytime to place or reposition it:"
echo -e "  ${CYAN}noctalia msg desktop-widgets-toggle-edit${RESET}\n"

if [ "${AUTO_YES}" = true ]; then
    noctalia msg desktop-widgets-toggle-edit || true
elif [ -t 0 ]; then
    read -p "Open widget layout editor now? [y/N] " -n 1 -r
    echo ""
    [[ $REPLY =~ ^[Yy]$ ]] && noctalia msg desktop-widgets-toggle-edit || true
fi
