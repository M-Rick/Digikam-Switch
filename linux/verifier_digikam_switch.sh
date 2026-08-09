#!/bin/bash
# verifier_digikam_switch.sh
# Prépare, installe et vérifie DigiKam Switch, puis diagnostique les
# bibliothèques existantes (collection racine comprise).
#
# Usage :
#   bash verifier_digikam_switch.sh              → diagnostic seul, ne modifie rien
#   sudo bash verifier_digikam_switch.sh --install ./digikam-switch_1.0.0_all.deb
#
# Le mode --install purge l'ancienne version : il demande confirmation et
# sauvegarde digikamrc avant toute opération.

# Ce script utilise des fonctionnalités propres à bash (tableaux, [[ ]],
# pipefail). Lancé avec « sh script.sh », il tournerait sous dash et
# échouerait : on se relance alors sous bash.
if [ -z "${BASH_VERSION:-}" ]; then
    exec bash "$0" "$@"
fi

set -uo pipefail

DEB=""
DO_INSTALL=0
OK=0
KO=0

while [ $# -gt 0 ]; do
    case "$1" in
        --install) DO_INSTALL=1; DEB="${2:-}"; shift 2 || shift ;;
        -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
        *) echo "Option inconnue : $1"; exit 1 ;;
    esac
done

titre()  { printf '\n\033[1m== %s ==\033[0m\n' "$1"; }
bon()    { printf '  \033[32mOK\033[0m   %s\n' "$1"; OK=$((OK+1)); }
mauvais(){ printf '  \033[31mKO\033[0m   %s\n' "$1"; KO=$((KO+1)); }
info()   { printf '       %s\n' "$1"; }

# L'utilisateur réel, même sous sudo.
REAL_USER="${SUDO_USER:-${USER:-$(id -un)}}"
REAL_HOME=$(eval echo "~$REAL_USER")
DIGIKAMRC="$REAL_HOME/.config/digikamrc"

# Dossier images localisé (~/Images en français, ~/Bilder en allemand...).
pictures_dir() {
    local d=""
    command -v xdg-user-dir &>/dev/null && d=$(sudo -u "$REAL_USER" xdg-user-dir PICTURES 2>/dev/null)
    if [ -z "$d" ] || [ "$d" = "$REAL_HOME" ]; then
        [ -f "$REAL_HOME/.config/user-dirs.dirs" ] && \
            d=$(grep -m1 '^XDG_PICTURES_DIR=' "$REAL_HOME/.config/user-dirs.dirs" \
                | sed -e 's/^XDG_PICTURES_DIR=//' -e 's/^"//' -e 's/"$//' -e "s|^\$HOME|$REAL_HOME|")
    fi
    [ -n "$d" ] && [ -d "$d" ] && { echo "$d"; return; }
    echo "$REAL_HOME/Pictures"
}

# Lecture SQL, via sqlite3 ou python3.
sql() {
    local db="$1" q="$2"
    if command -v sqlite3 &>/dev/null; then
        sqlite3 "$db" "$q" 2>/dev/null
    elif command -v python3 &>/dev/null; then
        python3 -c "
import sqlite3,sys
try:
    c=sqlite3.connect(sys.argv[1])
    for r in c.execute(sys.argv[2]): print('|'.join('' if x is None else str(x) for x in r))
except Exception: pass" "$db" "$q"
    fi
}

# ── 1. État avant toute chose ─────────────────────────────────────────────────
titre "1. État actuel"

# Détection prudente : pgrep -f matcherait ce script lui-même (son nom contient
# « digikam »). On se limite au nom de processus exact et à l'AppImage, en
# excluant notre propre PID.
DK_PIDS=$( { pgrep -x digikam; pgrep -f 'digikam[^ ]*\.AppImage'; } 2>/dev/null \
           | grep -v "^$$\$" | sort -u | tr '\n' ' ' )
DK_PIDS="${DK_PIDS% }"
if [ -n "$DK_PIDS" ]; then
    mauvais "DigiKam est en cours d'exécution (PID $DK_PIDS)."
    info "Ferme-le avant de basculer : DigiKam réécrit digikamrc en quittant,"
    info "ce qui annulerait la bascule. Commande : pkill digikam"
else
    bon "DigiKam n'est pas en cours d'exécution."
fi

if [ -f "$DIGIKAMRC" ]; then
    bon "digikamrc présent : $DIGIKAMRC"
    ACTIVE=$(grep -m1 '^Database Name=' "$DIGIKAMRC" | sed 's/^Database Name=//')
    info "Bibliothèque active : ${ACTIVE:-(aucune)}"
else
    info "Aucun digikamrc : DigiKam n'a jamais été lancé, ce n'est pas bloquant."
fi

PICS=$(pictures_dir)
bon "Dossier images détecté : $PICS"

for outil in unzip; do
    command -v "$outil" &>/dev/null && bon "$outil disponible" || mauvais "$outil manquant (requis)"
done
if command -v sqlite3 &>/dev/null; then bon "sqlite3 disponible"
elif command -v python3 &>/dev/null; then bon "python3 disponible (repli pour sqlite3)"
else mauvais "ni sqlite3 ni python3 : la collection ne pourra pas être créée"; fi
command -v notify-send &>/dev/null && bon "notify-send disponible" \
    || info "notify-send absent : repli sur kdialog ou zenity"

# ── 2. Installation (optionnelle) ─────────────────────────────────────────────
if [ "$DO_INSTALL" = 1 ]; then
    titre "2. Installation"
    if [ "$(id -u)" -ne 0 ]; then
        echo "  Le mode --install doit être lancé avec sudo."; exit 1
    fi
    if [ ! -f "$DEB" ]; then
        echo "  Paquet introuvable : $DEB"; exit 1
    fi

    if [ -f "$DIGIKAMRC" ]; then
        cp -a "$DIGIKAMRC" "$DIGIKAMRC.bak.$(date +%Y%m%d-%H%M%S)"
        bon "Sauvegarde de digikamrc effectuée"
    fi

    if dpkg -l digikam-switch 2>/dev/null | grep -q '^[a-z][a-zA-Z]'; then
        echo ""
        echo "  Une version de digikam-switch est déjà installée."
        echo "  Elle va être PURGÉE (dpkg -P) avant réinstallation."
        echo "  Cela ne touche NI tes bibliothèques NI tes photos."
        read -rp "  Continuer ? [o/N] " rep
        case "$rep" in
            [oOyY]*) dpkg -P digikam-switch >/dev/null 2>&1 && bon "Ancienne version purgée" ;;
            *) echo "  Interrompu."; exit 0 ;;
        esac
    fi

    if apt install -y "$DEB" >/tmp/dks-install.log 2>&1; then
        bon "Paquet installé"
    else
        mauvais "Échec de l'installation, voir /tmp/dks-install.log"
        tail -5 /tmp/dks-install.log | sed 's/^/       /'
    fi
fi

# ── 3. Vérification de l'installation ─────────────────────────────────────────
titre "3. Installation en place ?"

if dpkg -l digikam-switch 2>/dev/null | grep -q '^ii'; then
    bon "Paquet enregistré dans dpkg (donc désinstallable)"
    info "Version : $(dpkg-query -W -f='${Version}' digikam-switch 2>/dev/null)"
else
    mauvais "Paquet non enregistré ou mal configuré dans dpkg"
    dpkg -l digikam-switch 2>/dev/null | tail -2 | sed 's/^/       /'
fi

for f in /usr/bin/digikam_switch_linux.sh \
         /usr/share/digikam-switch/digikam_template.zip \
         /usr/share/applications/digikam-switch.desktop \
         /usr/share/metainfo/io.github.m_rick.digikam-switch.metainfo.xml \
         /usr/share/icons/hicolor/scalable/apps/digikam-switch.svg; do
    [ -f "$f" ] && bon "présent : $f" || mauvais "MANQUANT : $f"
done

[ -x /usr/bin/digikam_switch_linux.sh ] && bon "Script exécutable" \
    || mauvais "Script non exécutable"

if [ -f /usr/share/metainfo/io.github.m_rick.digikam-switch.metainfo.xml ]; then
    if command -v appstreamcli &>/dev/null; then
        AS_OUT=$(appstreamcli validate --no-net \
            /usr/share/metainfo/io.github.m_rick.digikam-switch.metainfo.xml 2>&1)
        if [ $? -eq 0 ]; then
            bon "Metainfo AppStream valide (visible dans Logiciels)"
        else
            mauvais "Metainfo AppStream refusé par appstreamcli"
            # On affiche la raison plutôt qu'une commande à relancer.
            echo "$AS_OUT" | grep -E '^[WEI]:' | sed 's/^/       /'
        fi
    else
        info "appstreamcli absent : validation du metainfo non effectuée"
    fi
fi

# ── 4. Diagnostic des bibliothèques ───────────────────────────────────────────
titre "4. Bibliothèques et collections"

mapfile -t LIBS < <(
    for d in "$REAL_HOME/.local/share/digikam" "$PICS"; do
        [ -d "$d" ] || continue
        find "$d" -maxdepth 2 -name '*.digikamlibrary' 2>/dev/null
    done | sort -u
)

if [ "${#LIBS[@]}" -eq 0 ]; then
    info "Aucune bibliothèque trouvée dans $REAL_HOME/.local/share/digikam ni $PICS"
    info "C'est normal si tu n'en as pas encore créé."
else
    for lib in "${LIBS[@]}"; do
        echo ""
        echo "  --- $(basename "$lib") ---"
        info "$lib"
        if [ -f "$lib/digikam4.db" ]; then
            bon "base digikam4.db présente"
        else
            mauvais "digikam4.db absent : ce dossier n'est pas une bibliothèque valide"
            continue
        fi
        roots=$(sql "$lib/digikam4.db" "SELECT id||' | '||COALESCE(label,'')||' | '||COALESCE(identifier,'')||' | '||COALESCE(specificPath,'') FROM AlbumRoots;")
        if [ -z "$roots" ]; then
            mauvais "AUCUNE collection racine : album et import impossibles"
            info "C'est le bug corrigé ; une bibliothèque créée avant la correction reste affectée."
            info "Corrige-la depuis DigiKam : Configurer DigiKam, Collections, Ajouter."
        else
            bon "collection racine définie"
            echo "$roots" | sed 's/^/       /'
        fi
        nb=$(sql "$lib/digikam4.db" "SELECT COUNT(*) FROM Albums;")
        info "albums : ${nb:-?}"
    done
fi

# ── Bilan ─────────────────────────────────────────────────────────────────────
titre "Bilan"
echo "  $OK contrôle(s) OK, $KO problème(s)"
if [ "$KO" -eq 0 ]; then
    echo "  Tout est en place. Lance DigiKam Switch depuis ton menu."
else
    echo "  Corrige les points KO ci-dessus avant de tester."
fi
exit 0
