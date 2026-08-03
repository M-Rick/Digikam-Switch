#!/bin/bash
# install.sh
# Installation de DigiKam Switch pour Linux
# Usage : sudo bash install.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_BIN="/usr/local/bin/digikam_switch_linux.sh"
INSTALL_DATA="/usr/local/share/digikam-switch"

# Vérifier les droits root pour l'installation système
if [ "$EUID" -ne 0 ]; then
    echo "Ce script doit être lancé avec sudo."
    exit 1
fi

# Vérifier que le zip template est présent
TEMPLATE_ZIP="$SCRIPT_DIR/../digikam_template.zip"
if [ ! -f "$TEMPLATE_ZIP" ]; then
    echo "Erreur : digikam_template.zip introuvable dans le dossier parent."
    echo "Assurez-vous que digikam_template.zip est présent à la racine du repo."
    exit 1
fi

# Vérifier que l'icône SVG est présente
ICON_SVG="$SCRIPT_DIR/../Digikam Switch.svg"
if [ ! -f "$ICON_SVG" ]; then
    echo "Attention : Digikam Switch.svg introuvable — l'icône ne sera pas installée."
    ICON_SVG=""
fi

echo "Installation de DigiKam Switch..."

# ── Script principal ───────────────────────────────────────────────────────────
cp "$SCRIPT_DIR/digikam_switch_linux.sh" "$INSTALL_BIN"
chmod +x "$INSTALL_BIN"
echo "  Script installé dans $INSTALL_BIN"

# ── Zip template ───────────────────────────────────────────────────────────────
mkdir -p "$INSTALL_DATA"
cp "$TEMPLATE_ZIP" "$INSTALL_DATA/digikam_template.zip"
echo "  Template installé dans $INSTALL_DATA"

# ── Icône SVG ──────────────────────────────────────────────────────────────────
if [ -n "$ICON_SVG" ]; then
    # Icône application
    mkdir -p /usr/share/icons/hicolor/scalable/apps
    cp "$ICON_SVG" /usr/share/icons/hicolor/scalable/apps/digikam-switch.svg

    # Icône type MIME .digikamlibrary
    mkdir -p /usr/share/icons/hicolor/scalable/mimetypes
    cp "$SCRIPT_DIR/../Digikam Library.svg" /usr/share/icons/hicolor/scalable/mimetypes/application-x-digikam-library.svg 2>/dev/null || \
    cp "$ICON_SVG" /usr/share/icons/hicolor/scalable/mimetypes/application-x-digikam-library.svg

    # Mettre à jour le cache des icônes
    if command -v gtk-update-icon-cache &>/dev/null; then
        gtk-update-icon-cache -f /usr/share/icons/hicolor/ 2>/dev/null || true
    fi
    echo "  Icônes installées dans /usr/share/icons/hicolor/scalable/"
fi

# ── Type MIME .digikamlibrary ──────────────────────────────────────────────────
if [ -f "$SCRIPT_DIR/org.digikam.library.xml" ]; then
    mkdir -p /usr/share/mime/packages
    cp "$SCRIPT_DIR/org.digikam.library.xml" /usr/share/mime/packages/
    if command -v update-mime-database &>/dev/null; then
        update-mime-database /usr/share/mime/ 2>/dev/null || true
    fi
    echo "  Type MIME .digikamlibrary enregistré"
fi

# ── Entrée .desktop ────────────────────────────────────────────────────────────
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(eval echo "~$REAL_USER")
DESKTOP_DIR="$REAL_HOME/.local/share/applications"
mkdir -p "$DESKTOP_DIR"
cp "$SCRIPT_DIR/digikam-switch.desktop" "$DESKTOP_DIR/digikam-switch.desktop"
chown "$REAL_USER:$REAL_USER" "$DESKTOP_DIR/digikam-switch.desktop"
echo "  Entrée .desktop installée dans $DESKTOP_DIR"

# ── Mettre à jour la base des applications ────────────────────────────────────
if command -v update-desktop-database &>/dev/null; then
    update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
fi

echo ""
echo "Installation terminée. DigiKam Switch est disponible dans votre menu d'applications."
