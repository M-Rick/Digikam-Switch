#!/bin/bash
# install.sh
# Installation de DigiKam Switch pour Linux
# Usage : sudo bash install.sh

# Ce script utilise des fonctionnalités propres à bash (tableaux, [[ ]],
# pipefail). Lancé avec « sh script.sh », il tournerait sous dash et
# échouerait : on se relance alors sous bash.
if [ -z "${BASH_VERSION:-}" ]; then
    exec bash "$0" "$@"
fi

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
ICON_SVG="$SCRIPT_DIR/../icons/DigikamSwitch.svg"
if [ ! -f "$ICON_SVG" ]; then
    echo "Attention : icons/DigikamSwitch.svg introuvable — l'icône ne sera pas installée."
    ICON_SVG=""
fi

echo "Installation de DigiKam Switch..."

# ── Dépendances de la création de bibliothèque ────────────────────────────────
# La déclaration de la collection racine dans digikam4.db passe par sqlite3,
# avec python3 en repli. Sans l'un des deux, une bibliothèque neuve serait
# créée sans collection et n'accepterait ni album ni import.
if ! command -v sqlite3 &>/dev/null && ! command -v python3 &>/dev/null; then
    echo "  Attention : ni sqlite3 ni python3 trouvé."
    echo "  Les nouvelles bibliothèques seront créées sans collection racine."
    echo "  Installez sqlite3 : sudo apt install sqlite3"
fi

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
    cp "$SCRIPT_DIR/../icons/DigikamLibrary.svg" /usr/share/icons/hicolor/scalable/mimetypes/application-x-digikam-library.svg 2>/dev/null || \
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

# ── AppStream metainfo (pour affichage dans GNOME Software / KDE Discover) ─────
mkdir -p /usr/share/metainfo
cp "$SCRIPT_DIR/io.github.m_rick.digikam-switch.metainfo.xml" /usr/share/metainfo/ 2>/dev/null \
  && echo "  Metainfo AppStream installé" \
  || echo "Attention : metainfo AppStream introuvable."

# ── Entrée .desktop ────────────────────────────────────────────────────────────
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(eval echo "~$REAL_USER")
DESKTOP_DIR="$REAL_HOME/.local/share/applications"
mkdir -p "$DESKTOP_DIR"
cp "$SCRIPT_DIR/digikam-switch.desktop" "$DESKTOP_DIR/digikam-switch.desktop"
# Le .desktop source cible /usr/bin (paquet). En installation manuelle le
# script est dans /usr/local/bin : on ajuste l'Exec en consequence.
sed -i 's#^Exec=/usr/bin/digikam_switch_linux.sh#Exec=/usr/local/bin/digikam_switch_linux.sh#' "$DESKTOP_DIR/digikam-switch.desktop"
chown "$REAL_USER:$REAL_USER" "$DESKTOP_DIR/digikam-switch.desktop"
echo "  Entrée .desktop installée dans $DESKTOP_DIR"

# ── Mettre à jour la base des applications ────────────────────────────────────
if command -v update-desktop-database &>/dev/null; then
    update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
fi

echo ""
echo "Installation terminée. DigiKam Switch est disponible dans votre menu d'applications."

echo ""
echo "Pour desinstaller : sudo bash uninstall.sh"
