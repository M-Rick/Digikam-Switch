#!/bin/bash
# build_app.sh
# Post-traitement après génération de l'app par Platypus
# 1. Remplace Info.plist par la version avec UTI .digikamlibrary
# 2. Copie DigiKamLibrary.icns dans le bundle
# 3. Recharge le Finder pour activer le nouveau type
#
# Usage : bash macos/build_app.sh "chemin/vers/Digikam Switch.app"

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
APP="${1:-$REPO_ROOT/macos/Digikam Switch.app}"

if [ ! -d "$APP" ]; then
    echo "Erreur : application introuvable : $APP"
    echo "Usage : bash macos/build_app.sh \"chemin/vers/Digikam Switch.app\""
    exit 1
fi

ICNS="$REPO_ROOT/icons/DigiKamLibrary.icns"
if [ ! -f "$ICNS" ]; then
    echo "Erreur : DigiKamLibrary.icns introuvable."
    echo "Lancez d'abord : bash macos/make_icns.sh"
    exit 1
fi

echo "Post-traitement de $APP..."

# Remplacer Info.plist
cp "$SCRIPT_DIR/Info.plist" "$APP/Contents/Info.plist"
echo "  Info.plist mis à jour"

# Copier l'icône de bibliothèque
cp "$ICNS" "$APP/Contents/Resources/DigiKamLibrary.icns"
echo "  DigiKamLibrary.icns copié dans Resources/"

# Recharger le Finder
killall Finder 2>/dev/null && echo "  Finder rechargé" || echo "  Finder non rechargé (pas grave)"

echo ""
echo "Terminé. Testez en créant un dossier .digikamlibrary dans le Finder."
