#!/usr/bin/env bash
# Noctalia Quran Verse Widget Uninstaller
# Author: Hamza Qureshi (hamzzaqureshi)
set -euo pipefail

BOLD="\033[1m"; GREEN="\033[32m"; BLUE="\033[34m"; RESET="\033[0m"

echo -e "${BOLD}${BLUE}==> Uninstalling Noctalia Quran Verse Desktop Widget...${RESET}"

PLUGIN_ID="hamzzaqureshi/quran-verse"
PLUGIN_SLUG="quran-verse"
LOCAL_SOURCE="${HOME}/.local/share/noctalia/sources/local-plugins"

if command -v noctalia &>/dev/null; then
    noctalia msg plugins disable "${PLUGIN_ID}" >/dev/null 2>&1 || true
    echo -e "${GREEN}✓${RESET} Plugin disabled."
fi

if [[ -L "${LOCAL_SOURCE}/${PLUGIN_SLUG}" ]]; then
    rm -f "${LOCAL_SOURCE}/${PLUGIN_SLUG}"
    echo -e "${GREEN}✓${RESET} Removed catalog symlink."
fi

if [[ -d "${LOCAL_SOURCE}" ]]; then
    REMAINING=$(find "${LOCAL_SOURCE}" -mindepth 1 -maxdepth 1 ! -name "catalog.toml" | wc -l)
    if [[ "${REMAINING}" -eq 0 ]]; then
        rm -rf "${LOCAL_SOURCE}"
        command -v noctalia &>/dev/null && noctalia msg plugins source remove local-plugins >/dev/null 2>&1 || true
        echo -e "${GREEN}✓${RESET} Cleaned up empty local-plugins source."
    fi
fi

echo -e "${BOLD}${GREEN}Successfully uninstalled.${RESET}"
