#!/bin/bash
# diagnostic_digikam_macos.sh
# Diagnostique le problème « bibliothèque ouvrable mais rien ne peut y être
# ajouté » sur macOS, en comparant les bibliothèques créées par DigiKam Switch
# avec celles créées par DigiKam lui-même.
#
# Usage : bash diagnostic_digikam_macos.sh
#
# Ce script NE MODIFIE RIEN. Il lit et affiche, c'est tout.
# La seule écriture éventuelle se fait dans un dossier temporaire, sur une COPIE.

if [ -z "${BASH_VERSION:-}" ]; then
    exec bash "$0" "$@"
fi

DIGIKAMRC="$HOME/Library/Preferences/digikamrc"
SQLITE=/usr/bin/sqlite3

titre() { printf '\n\033[1m== %s ==\033[0m\n' "$1"; }
info()  { printf '  %s\n' "$1"; }

# ── 1. Outils ─────────────────────────────────────────────────────────────────
titre "1. Outils disponibles"
if [ -x "$SQLITE" ]; then
    info "sqlite3 présent : $SQLITE ($("$SQLITE" -version 2>/dev/null | cut -d' ' -f1))"
else
    info "PROBLÈME : $SQLITE absent ou non exécutable."
    info "C'est probablement la cause : la collection n'a jamais pu être écrite."
    if command -v sqlite3 &>/dev/null; then
        info "Mais un sqlite3 existe ailleurs : $(command -v sqlite3)"
    fi
fi
command -v python3 &>/dev/null && info "python3 présent : $(command -v python3)" \
                               || info "python3 absent"

# ── 2. Configuration DigiKam ──────────────────────────────────────────────────
titre "2. Configuration DigiKam"
if [ -f "$DIGIKAMRC" ]; then
    info "digikamrc : $DIGIKAMRC"
    grep -E '^Database (Name|Type)' "$DIGIKAMRC" 2>/dev/null | sed 's/^/    /'
else
    info "Aucun digikamrc à $DIGIKAMRC"
    info "Autres emplacements possibles :"
    for p in "$HOME/.config/digikamrc" "$HOME/Library/Application Support/digikam/digikamrc"; do
        [ -f "$p" ] && info "    TROUVÉ : $p"
    done
fi

# ── 3. Bibliothèques trouvées ─────────────────────────────────────────────────
titre "3. Bibliothèques .digikamlibrary"

# Recherche dans les emplacements courants, sans parcourir tout le disque.
LIBS=()
while IFS= read -r d; do
    [ -n "$d" ] && LIBS+=("$d")
done < <(find "$HOME/Pictures" "$HOME/Images" "$HOME/Documents" "$HOME/Desktop" \
              -maxdepth 3 -type d -name '*.digikamlibrary' 2>/dev/null | sort)

if [ "${#LIBS[@]}" -eq 0 ]; then
    info "Aucune bibliothèque .digikamlibrary trouvée dans Pictures, Documents, Desktop."
else
    info "${#LIBS[@]} bibliothèque(s) trouvée(s)."
fi

dump_albumroots() {
    local db="$1"
    [ -x "$SQLITE" ] || { echo "        (sqlite3 indisponible)"; return; }
    local n
    n=$("$SQLITE" "$db" "SELECT count(*) FROM AlbumRoots;" 2>/dev/null)
    if [ -z "$n" ]; then
        echo "        LECTURE IMPOSSIBLE (base absente, verrouillée ou schéma inattendu)"
        return
    fi
    echo "        AlbumRoots : $n ligne(s)"
    if [ "$n" -gt 0 ]; then
        "$SQLITE" -header -column "$db" \
            "SELECT id, label, status, type, identifier, specificPath FROM AlbumRoots;" \
            2>/dev/null | sed 's/^/        /'
    else
        echo "        >>> VIDE : c'est la cause du blocage, aucune racine d'album."
    fi
    local albums images
    albums=$("$SQLITE" "$db" "SELECT count(*) FROM Albums;" 2>/dev/null)
    images=$("$SQLITE" "$db" "SELECT count(*) FROM Images;" 2>/dev/null)
    echo "        Albums : ${albums:-?}   Images : ${images:-?}"
}

for lib in "${LIBS[@]}"; do
    echo ""
    info "── $lib"
    db="$lib/digikam4.db"
    if [ ! -f "$db" ]; then
        echo "        PAS de digikam4.db dans ce dossier"
        continue
    fi
    echo "        taille digikam4.db : $(stat -f%z "$db" 2>/dev/null || stat -c%s "$db" 2>/dev/null) octets"
    dump_albumroots "$db"
done

# ── 4. Bibliothèque de référence créée par DigiKam lui-même ────────────────────
titre "4. Référence : bases gérées directement par DigiKam"
info "Si tu as une collection DigiKam qui fonctionne (créée par DigiKam, hors"
info "DigiKam Switch), sa base montre le format que DigiKam macOS attend."
REF_DBS=()
while IFS= read -r d; do
    [ -n "$d" ] && REF_DBS+=("$d")
done < <(find "$HOME/Pictures" "$HOME/Library/Application Support/digikam" \
              "$HOME/Documents" -maxdepth 4 -name 'digikam4.db' 2>/dev/null \
         | grep -v '\.digikamlibrary/' | sort)

if [ "${#REF_DBS[@]}" -eq 0 ]; then
    info "Aucune base DigiKam hors .digikamlibrary trouvée."
    info "Si ta collection habituelle est ailleurs, indique son chemin."
else
    for db in "${REF_DBS[@]}"; do
        echo ""
        info "── $db"
        dump_albumroots "$db"
    done
fi

# ── 5. Test d'écriture réel sur une COPIE ─────────────────────────────────────
titre "5. L'écriture de la collection fonctionne-t-elle ?"
if [ "${#LIBS[@]}" -eq 0 ]; then
    info "Pas de bibliothèque à tester."
elif [ ! -x "$SQLITE" ]; then
    info "sqlite3 indisponible : test impossible, et cause probable du problème."
else
    TMP=$(mktemp -d)
    SRC="${LIBS[0]}"
    cp "$SRC/digikam4.db" "$TMP/digikam4.db" 2>/dev/null
    info "Test sur une copie de : $SRC"
    label="TestDiag"
    path="/tmp/TestDiag.digikamlibrary"
    "$SQLITE" "$TMP/digikam4.db" "INSERT OR IGNORE INTO AlbumRoots
        (label, status, type, identifier, specificPath, caseSensitivity)
        VALUES ('$label', 0, 1, 'volumeid:?path=$path', '/', 0);"
    rc=$?
    if [ "$rc" -eq 0 ]; then
        info "L'INSERT réussit (code $rc). L'écriture n'est donc PAS le problème."
        "$SQLITE" -header -column "$TMP/digikam4.db" \
            "SELECT label, status, type, identifier, specificPath FROM AlbumRoots WHERE label='$label';" \
            2>/dev/null | sed 's/^/    /'
    else
        info "L'INSERT ÉCHOUE (code $rc). Message d'erreur sans masquage :"
        "$SQLITE" "$TMP/digikam4.db" "INSERT INTO AlbumRoots
            (label, status, type, identifier, specificPath, caseSensitivity)
            VALUES ('$label', 0, 1, 'volumeid:?path=$path', '/', 0);" 2>&1 | sed 's/^/    /'
    fi
    echo ""
    info "Schéma réel de la table AlbumRoots :"
    "$SQLITE" "$TMP/digikam4.db" ".schema AlbumRoots" 2>/dev/null | sed 's/^/    /'
    rm -rf "$TMP"
fi

# ── 6. Volume et système de fichiers ──────────────────────────────────────────
titre "6. Volume contenant les bibliothèques"
if [ "${#LIBS[@]}" -gt 0 ]; then
    info "Point de montage de ${LIBS[0]} :"
    df -h "${LIBS[0]}" 2>/dev/null | sed 's/^/    /'
    info "Système de fichiers :"
    diskutil info "$(df "${LIBS[0]}" 2>/dev/null | tail -1 | awk '{print $1}')" 2>/dev/null \
        | grep -E 'File System|Volume Name|Mount Point|Case-sensitive' | sed 's/^/    /'
fi

titre "Fin"
echo "  Copie-colle toute cette sortie dans la conversation."
exit 0
