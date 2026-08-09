#!/bin/bash
# Ce script utilise des fonctionnalités propres à bash (tableaux, [[ ]],
# pipefail). Lancé avec « sh script.sh », il tournerait sous dash et
# échouerait : on se relance alors sous bash.
if [ -z "${BASH_VERSION:-}" ]; then
    exec bash "$0" "$@"
fi

set -e

VERSION="1.0.0"
PACKAGE="digikam-switch"
DEB_NAME="${PACKAGE}_${VERSION}_all.deb"
BUILD_DIR="/tmp/digikam-switch-build"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ICONS_DIR="$REPO_ROOT/icons"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/DEBIAN"
mkdir -p "$BUILD_DIR/usr/bin"
mkdir -p "$BUILD_DIR/usr/share/digikam-switch"
mkdir -p "$BUILD_DIR/usr/share/applications"
mkdir -p "$BUILD_DIR/usr/share/metainfo"
mkdir -p "$BUILD_DIR/usr/share/mime/packages"
mkdir -p "$BUILD_DIR/usr/share/icons/hicolor/scalable/apps"
mkdir -p "$BUILD_DIR/usr/share/icons/hicolor/scalable/mimetypes"
mkdir -p "$BUILD_DIR/usr/share/doc/digikam-switch"

# ── DEBIAN/control ─────────────────────────────────────────────────────────────
cat > "$BUILD_DIR/DEBIAN/control" << CONTROL
Package: $PACKAGE
Version: $VERSION
Section: graphics
Priority: optional
Architecture: all
Depends: bash, unzip, kdialog | zenity
Recommends: kdialog | zenity, sqlite3 | python3
Maintainer: Aymeric Gillaizeau <aymeric@openstreetmap.org>
Description: DigiKam multiple library manager
 DigiKam Switch allows managing multiple DigiKam photo libraries
 with a simple graphical interface. Switch between libraries, create
 new ones, or locate existing ones — then launch DigiKam directly.
 .
 Supports KDE (kdialog) and GNOME/GTK (zenity) desktops, with a
 text fallback for other environments.
 .
 Interface available in 14 languages: French, English, Spanish,
 Italian, German, Portuguese, Dutch, Polish, Ukrainian, Russian,
 Japanese, Simplified Chinese, Korean.
CONTROL

# ── DEBIAN/postinst ────────────────────────────────────────────────────────────
cat > "$BUILD_DIR/DEBIAN/postinst" << 'POSTINST'
#!/bin/bash
set -e
chmod +x /usr/bin/digikam_switch_linux.sh
if command -v update-mime-database &>/dev/null; then
    update-mime-database /usr/share/mime/ 2>/dev/null || true
fi
if command -v gtk-update-icon-cache &>/dev/null; then
    gtk-update-icon-cache -f /usr/share/icons/hicolor/ 2>/dev/null || true
fi
if command -v update-desktop-database &>/dev/null; then
    update-desktop-database /usr/share/applications/ 2>/dev/null || true
fi
echo "DigiKam Switch installed successfully."
echo "Launch it from your application menu or via: digikam_switch_linux.sh"
POSTINST

# ── DEBIAN/prerm ───────────────────────────────────────────────────────────────
cat > "$BUILD_DIR/DEBIAN/prerm" << 'PRERM'
#!/bin/bash
set -e
echo "Removing DigiKam Switch..."
PRERM

# ── DEBIAN/postrm ──────────────────────────────────────────────────────────────
cat > "$BUILD_DIR/DEBIAN/postrm" << 'POSTRM'
#!/bin/bash
set -e
if command -v update-mime-database &>/dev/null; then
    update-mime-database /usr/share/mime/ 2>/dev/null || true
fi
if command -v gtk-update-icon-cache &>/dev/null; then
    gtk-update-icon-cache -f /usr/share/icons/hicolor/ 2>/dev/null || true
fi
POSTRM

chmod 755 "$BUILD_DIR/DEBIAN/postinst"
chmod 755 "$BUILD_DIR/DEBIAN/prerm"
chmod 755 "$BUILD_DIR/DEBIAN/postrm"

# ── Copyright ──────────────────────────────────────────────────────────────────
cat > "$BUILD_DIR/usr/share/doc/digikam-switch/copyright" << 'COPYRIGHT'
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: digikam-switch
Upstream-Contact: Aymeric Gillaizeau
Source: https://github.com/M-Rick/digikam-switch

Files: *
Copyright: 2026 Aymeric Gillaizeau
License: GPL-3.0+

License: GPL-3.0+
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 .
 On Debian systems, the complete text of the GNU General Public
 License version 3 can be found in /usr/share/common-licenses/GPL-3.
COPYRIGHT

# ── Fichiers principaux ────────────────────────────────────────────────────────
cp "$SCRIPT_DIR/digikam_switch_linux.sh" "$BUILD_DIR/usr/bin/"
chmod +x "$BUILD_DIR/usr/bin/digikam_switch_linux.sh"

cp "$SCRIPT_DIR/digikam-switch.desktop" "$BUILD_DIR/usr/share/applications/"
cp "$SCRIPT_DIR/io.github.m_rick.digikam-switch.metainfo.xml" "$BUILD_DIR/usr/share/metainfo/"
cp "$SCRIPT_DIR/org.digikam.library.xml" "$BUILD_DIR/usr/share/mime/packages/"

# Template zip
if [ -f "$REPO_ROOT/digikam_template.zip" ]; then
    cp "$REPO_ROOT/digikam_template.zip" "$BUILD_DIR/usr/share/digikam-switch/"
else
    echo "Erreur : digikam_template.zip introuvable à la racine du repo."
    exit 1
fi

# Icône application
if [ -f "$ICONS_DIR/DigikamSwitch.svg" ]; then
    cp "$ICONS_DIR/DigikamSwitch.svg" "$BUILD_DIR/usr/share/icons/hicolor/scalable/apps/digikam-switch.svg"
else
    echo "Attention : DigikamSwitch.svg introuvable dans icons/"
fi

# Icône type MIME .digikamlibrary
if [ -f "$ICONS_DIR/DigikamLibrary.svg" ]; then
    cp "$ICONS_DIR/DigikamLibrary.svg" "$BUILD_DIR/usr/share/icons/hicolor/scalable/mimetypes/application-x-digikam-library.svg"
else
    echo "Attention : DigikamLibrary.svg introuvable dans icons/"
fi

# ── Construction ───────────────────────────────────────────────────────────────
OUTPUT="$SCRIPT_DIR/$DEB_NAME"
dpkg-deb --build "$BUILD_DIR" "$OUTPUT"
rm -rf "$BUILD_DIR"

echo ""
echo "Package created: $OUTPUT"
echo "Size: $(du -sh "$OUTPUT" | cut -f1)"
echo ""
echo "To install: sudo dpkg -i $DEB_NAME"
