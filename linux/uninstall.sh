#!/bin/bash
# uninstall.sh
# Désinstallation de DigiKam Switch installé via install.sh (voie manuelle,
# hors dpkg). Retire exactement les fichiers posés par install.sh.
# Usage : sudo bash uninstall.sh
#
# Note : si tu as installé le paquet .deb au lieu de install.sh, n'utilise PAS
# ce script. Désinstalle avec : sudo apt remove digikam-switch

# Ce script utilise des fonctionnalités propres à bash (tableaux, [[ ]],
# pipefail). Lancé avec « sh script.sh », il tournerait sous dash et
# échouerait : on se relance alors sous bash.
if [ -z "${BASH_VERSION:-}" ]; then
    exec bash "$0" "$@"
fi

set -e

INSTALL_BIN="/usr/local/bin/digikam_switch_linux.sh"
INSTALL_DATA="/usr/local/share/digikam-switch"
ICON_APP="/usr/share/icons/hicolor/scalable/apps/digikam-switch.svg"
ICON_MIME="/usr/share/icons/hicolor/scalable/mimetypes/application-x-digikam-library.svg"
MIME_XML="/usr/share/mime/packages/org.digikam.library.xml"
METAINFO="/usr/share/metainfo/io.github.m_rick.digikam-switch.metainfo.xml"

# Vérifier les droits root
if [ "$EUID" -ne 0 ]; then
    echo "Ce script doit être lancé avec sudo."
    exit 1
fi

echo "Désinstallation de DigiKam Switch..."

# ── Script principal ───────────────────────────────────────────────────────────
if [ -f "$INSTALL_BIN" ]; then
    rm -f "$INSTALL_BIN"
    echo "  Script retiré de $INSTALL_BIN"
fi

# ── Données (template) ─────────────────────────────────────────────────────────
if [ -d "$INSTALL_DATA" ]; then
    rm -rf "$INSTALL_DATA"
    echo "  Données retirées de $INSTALL_DATA"
fi

# ── Icônes ─────────────────────────────────────────────────────────────────────
rm -f "$ICON_APP" "$ICON_MIME"
if command -v gtk-update-icon-cache &>/dev/null; then
    gtk-update-icon-cache -f /usr/share/icons/hicolor/ 2>/dev/null || true
fi
echo "  Icônes retirées"

# ── Type MIME ──────────────────────────────────────────────────────────────────
if [ -f "$MIME_XML" ]; then
    rm -f "$MIME_XML"
    if command -v update-mime-database &>/dev/null; then
        update-mime-database /usr/share/mime/ 2>/dev/null || true
    fi
    echo "  Type MIME retiré"
fi

# ── Entrée .desktop (dans le HOME de l'utilisateur réel, comme install.sh) ──────
# ── AppStream metainfo ─────────────────────────────────────────────────────────
if [ -f "$METAINFO" ]; then
    rm -f "$METAINFO"
    echo "  Metainfo AppStream retiré"
fi

REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(eval echo "~$REAL_USER")
DESKTOP_FILE="$REAL_HOME/.local/share/applications/digikam-switch.desktop"
if [ -f "$DESKTOP_FILE" ]; then
    rm -f "$DESKTOP_FILE"
    if command -v update-desktop-database &>/dev/null; then
        update-desktop-database "$REAL_HOME/.local/share/applications" 2>/dev/null || true
    fi
    echo "  Entrée .desktop retirée"
fi

echo ""
echo "Désinstallation terminée."
