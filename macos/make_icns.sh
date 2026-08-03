#!/bin/bash
# make_icns.sh
# Génère DigiKamLibrary.icns depuis icons/DigikamLibrary.svg
# Usage : bash macos/make_icns.sh
# Prérequis : ImageMagick (magick), sips, iconutil

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ICONS_DIR="$REPO_ROOT/icons"
ICONSET="$ICONS_DIR/DigiKamLibrary.iconset"
SVG="$ICONS_DIR/DigikamLibrary.svg"
PNG_1024="$ICONS_DIR/DigikamLibrary_1024.png"
ICNS="$ICONS_DIR/DigiKamLibrary.icns"

# Vérifier les outils
for tool in magick sips iconutil; do
    if ! command -v "$tool" &>/dev/null; then
        echo "Erreur : $tool introuvable."
        [ "$tool" = "magick" ] && echo "Installez ImageMagick via MacPorts : sudo port install ImageMagick"
        exit 1
    fi
done

echo "Conversion SVG → PNG 1024px..."
magick -background none -size 1024x1024 "$SVG" "$PNG_1024"

echo "Génération des tailles pour l'iconset..."
mkdir -p "$ICONSET"
sips -z 16   16   "$PNG_1024" --out "$ICONSET/icon_16x16.png"
sips -z 32   32   "$PNG_1024" --out "$ICONSET/icon_16x16@2x.png"
sips -z 32   32   "$PNG_1024" --out "$ICONSET/icon_32x32.png"
sips -z 64   64   "$PNG_1024" --out "$ICONSET/icon_32x32@2x.png"
sips -z 128  128  "$PNG_1024" --out "$ICONSET/icon_128x128.png"
sips -z 256  256  "$PNG_1024" --out "$ICONSET/icon_128x128@2x.png"
sips -z 256  256  "$PNG_1024" --out "$ICONSET/icon_256x256.png"
sips -z 512  512  "$PNG_1024" --out "$ICONSET/icon_256x256@2x.png"
sips -z 512  512  "$PNG_1024" --out "$ICONSET/icon_512x512.png"
sips -z 1024 1024 "$PNG_1024" --out "$ICONSET/icon_512x512@2x.png"

echo "Génération du .icns..."
iconutil -c icns "$ICONSET" -o "$ICNS"

echo ""
echo "Terminé : $ICNS"
echo "Copiez DigiKamLibrary.icns dans macos/ puis lancez build_app.sh"
