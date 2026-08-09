#!/bin/bash
# nettoyer_digikam_switch.sh
# Retire toute trace de DigiKam Switch : paquet .deb (purge complète) ET
# installation manuelle via install.sh.
#
# Usage : sudo bash nettoyer_digikam_switch.sh
#
# CE SCRIPT NE TOUCHE NI TES BIBLIOTHÈQUES NI TES PHOTOS.
# Il ne modifie pas digikamrc non plus : la bibliothèque active reste celle
# en cours. Seuls les fichiers du programme sont retirés.

# Ce script utilise des fonctionnalités propres à bash (tableaux, [[ ]],
# pipefail). Lancé avec « sh script.sh », il tournerait sous dash et
# échouerait : on se relance alors sous bash.
if [ -z "${BASH_VERSION:-}" ]; then
    exec bash "$0" "$@"
fi

set -uo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "Ce script doit être lancé avec sudo."
    exit 1
fi

REAL_USER="${SUDO_USER:-${USER:-$(id -un)}}"
REAL_HOME=$(eval echo "~$REAL_USER")

bon()  { printf '  \033[32m✓\033[0m %s\n' "$1"; }
info() { printf '    %s\n' "$1"; }

printf '\n\033[1m== Ce qui va être retiré ==\033[0m\n'
echo "  - le paquet digikam-switch (purge complète)"
echo "  - les fichiers d'une éventuelle installation manuelle"
echo ""
echo "  Tes bibliothèques .digikamlibrary, tes photos et digikamrc"
echo "  ne sont PAS touchés."
echo ""
read -rp "Continuer ? [o/N] " rep
case "$rep" in
    [oOyY]*) ;;
    *) echo "Interrompu."; exit 0 ;;
esac

# ── 1. Paquet .deb ────────────────────────────────────────────────────────────
printf '\n\033[1m== 1. Paquet Debian ==\033[0m\n'
ETAT=$(dpkg-query -W -f='${Status}' digikam-switch 2>/dev/null)
if [ -n "$ETAT" ]; then
    info "état actuel : $ETAT"
    # purge : retire les fichiers ET l'enregistrement résiduel (statut « rc »)
    if dpkg -P digikam-switch >/dev/null 2>&1; then
        bon "paquet purgé"
    else
        info "dpkg -P a échoué, seconde tentative après réparation"
        dpkg --configure -a >/dev/null 2>&1
        apt-get -f install -y >/dev/null 2>&1
        dpkg -P digikam-switch >/dev/null 2>&1 && bon "paquet purgé" \
            || echo "  ÉCHEC : lance « sudo dpkg -P --force-all digikam-switch »"
    fi
else
    bon "aucun paquet digikam-switch enregistré"
fi

# ── 2. Installation manuelle (install.sh) ─────────────────────────────────────
printf '\n\033[1m== 2. Installation manuelle ==\033[0m\n'
RESTES=0
for f in /usr/local/bin/digikam_switch_linux.sh \
         /usr/bin/digikam_switch_linux.sh \
         /usr/share/metainfo/io.github.m_rick.digikam-switch.metainfo.xml \
         /usr/share/applications/digikam-switch.desktop \
         /usr/share/mime/packages/org.digikam.library.xml \
         /usr/share/icons/hicolor/scalable/apps/digikam-switch.svg \
         /usr/share/icons/hicolor/scalable/mimetypes/application-x-digikam-library.svg \
         "$REAL_HOME/.local/share/applications/digikam-switch.desktop"; do
    if [ -e "$f" ]; then
        rm -f "$f" && { bon "retiré : $f"; RESTES=$((RESTES+1)); }
    fi
done
for d in /usr/local/share/digikam-switch /usr/share/digikam-switch; do
    if [ -d "$d" ]; then
        rm -rf "$d" && { bon "retiré : $d"; RESTES=$((RESTES+1)); }
    fi
done
[ "$RESTES" -eq 0 ] && bon "aucun fichier résiduel"

# ── 3. Bases système ──────────────────────────────────────────────────────────
printf '\n\033[1m== 3. Bases système ==\033[0m\n'
command -v update-mime-database   &>/dev/null && update-mime-database /usr/share/mime/ 2>/dev/null
command -v gtk-update-icon-cache  &>/dev/null && gtk-update-icon-cache -f /usr/share/icons/hicolor/ 2>/dev/null
command -v update-desktop-database &>/dev/null && update-desktop-database /usr/share/applications/ 2>/dev/null
bon "bases MIME, icônes et applications régénérées"

# ── 4. Contrôle final ─────────────────────────────────────────────────────────
printf '\n\033[1m== 4. Contrôle final ==\033[0m\n'
RESTE=0
dpkg-query -W -f='${Status}' digikam-switch >/dev/null 2>&1 \
    && { echo "  ✗ le paquet est encore enregistré"; RESTE=1; } \
    || bon "plus aucun paquet enregistré"
for f in /usr/bin/digikam_switch_linux.sh /usr/local/bin/digikam_switch_linux.sh \
         /usr/share/digikam-switch /usr/local/share/digikam-switch \
         /usr/share/metainfo/io.github.m_rick.digikam-switch.metainfo.xml; do
    [ -e "$f" ] && { echo "  ✗ reste : $f"; RESTE=1; }
done
[ "$RESTE" -eq 0 ] && bon "aucun fichier du programme ne subsiste"

printf '\n'
if [ "$RESTE" -eq 0 ]; then
    echo "Nettoyage terminé. Tu peux réinstaller proprement :"
    echo "  sudo apt install ./digikam-switch_1.0.0_all.deb"
else
    echo "Nettoyage incomplet, voir les lignes ✗ ci-dessus."
fi

# Rappel : les bibliothèques ne sont jamais touchées.
echo ""
echo "Tes bibliothèques et tes photos sont intactes."
exit 0
