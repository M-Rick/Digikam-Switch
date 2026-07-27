#!/bin/bash
# install.sh
# Installation de DigiKam Switch pour Linux
# Usage : sudo bash install.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_BIN="/usr/local/bin/digikam_switch_linux.sh"
INSTALL_DATA="/usr/local/share/digikam-switch"
INSTALL_DESKTOP="$HOME/.local/share/applications/digikam-switch.desktop"

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

echo "Installation de DigiKam Switch..."

# Installer le script
cp "$SCRIPT_DIR/digikam_switch_linux.sh" "$INSTALL_BIN"
chmod +x "$INSTALL_BIN"
echo "  Script installé dans $INSTALL_BIN"

# Installer le zip template
mkdir -p "$INSTALL_DATA"
cp "$TEMPLATE_ZIP" "$INSTALL_DATA/digikam_template.zip"
echo "  Template installé dans $INSTALL_DATA"

# Installer le .desktop pour l'utilisateur courant
# SUDO_USER contient l'utilisateur réel quand on passe par sudo
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(eval echo "~$REAL_USER")
DESKTOP_DIR="$REAL_HOME/.local/share/applications"
mkdir -p "$DESKTOP_DIR"
cp "$SCRIPT_DIR/digikam-switch.desktop" "$DESKTOP_DIR/digikam-switch.desktop"
chown "$REAL_USER:$REAL_USER" "$DESKTOP_DIR/digikam-switch.desktop"
echo "  Entrée .desktop installée dans $DESKTOP_DIR"

echo ""
echo "Installation terminée. DigiKam Switch est disponible dans votre menu d'applications."
