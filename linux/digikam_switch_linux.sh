#!/bin/bash
# digikam_switch_linux.sh
# Gestionnaire de bibliothèques DigiKam pour Linux
# Compatible bash 3.2+
# Packager via un fichier .desktop
# Dépendances optionnelles : kdialog (KDE), zenity (GNOME/GTK)

DIGIKAMRC="$HOME/.config/digikamrc"
DIGIKAM_BIN="digikam"
TEMPLATE_ZIP="${TEMPLATE_ZIP:-$(dirname "$0")/digikam_template.zip}"

# ── Détection de l'interface disponible ───────────────────────────────────────
detect_ui() {
    # 1. KDE ou LXQt avec kdialog disponible
    if [[ "$XDG_CURRENT_DESKTOP" =~ ^(KDE|LXQt)$ ]] && command -v kdialog &>/dev/null; then
        echo "kdialog"
    # 2. zenity disponible
    elif command -v zenity &>/dev/null; then
        echo "zenity"
    # 3. kdialog disponible (autre bureau Qt)
    elif command -v kdialog &>/dev/null; then
        echo "kdialog"
    # 4. fallback texte
    else
        echo "text"
    fi
}

# ── Langue système ─────────────────────────────────────────────────────────────
detect_lang() {
    local lang
    lang=$(echo "${LANG:-${LANGUAGE:-en}}" | cut -c1-2)
    echo "${lang:-en}"
}

# ── Chaînes localisées ─────────────────────────────────────────────────────────
set_strings() {
    local lang="$1"
    case "$lang" in
        fr)
            L_TITLE="DigiKam"
            L_ACTIVE="Bibliothèque active"
            L_CHOOSE="Choisissez une bibliothèque :"
            L_OTHER="Autre emplacement..."
            L_NEW="+ Nouvelle bibliothèque..."
            L_ACTIVE_SUFFIX="(active)"
            L_NAME_PROMPT="Nom de la nouvelle bibliothèque :"
            L_NAME_TITLE="DigiKam - Nouvelle bibliothèque"
            L_FOLDER_PROMPT="Choisissez un dossier pour la bibliothèque :"
            L_FILE_PROMPT="Choisissez un .photoslibrary DigiKam :"
            L_CONFIRM_MSG="Créer la bibliothèque ?"
            L_CONFIRM_TITLE="DigiKam - Confirmation"
            L_BTN_CANCEL="Annuler"
            L_BTN_CONTINUE="Continuer"
            L_BTN_CREATE="Créer et ouvrir"
            L_NOTIF_CREATED="Bibliothèque créée"
            L_NOTIF_ACTIVATED="Bibliothèque activée"
            L_NOTIF_ALREADY="est déjà la bibliothèque active."
            L_ERR_TEMPLATE="Fichier template introuvable :"
            L_ERR_UNZIP="Erreur lors de la décompression du template."
            L_ERR_EXISTS="Une bibliothèque existe déjà à cet emplacement."
            L_ERR_INVALID="Ce fichier ne contient pas de bibliothèque DigiKam valide."
            L_TEXT_SELECT="Entrez le numéro de votre choix :"
            L_TEXT_NAME="Nom de la nouvelle bibliothèque :"
            L_TEXT_PATH="Chemin complet de la bibliothèque :"
            ;;
        es)
            L_TITLE="DigiKam"
            L_ACTIVE="Biblioteca activa"
            L_CHOOSE="Elija una biblioteca :"
            L_OTHER="Otra ubicación..."
            L_NEW="+ Nueva biblioteca..."
            L_ACTIVE_SUFFIX="(activa)"
            L_NAME_PROMPT="Nombre de la nueva biblioteca :"
            L_NAME_TITLE="DigiKam - Nueva biblioteca"
            L_FOLDER_PROMPT="Elija una carpeta para la biblioteca :"
            L_FILE_PROMPT="Elija un .photoslibrary de DigiKam :"
            L_CONFIRM_MSG="¿Crear la biblioteca?"
            L_CONFIRM_TITLE="DigiKam - Confirmación"
            L_BTN_CANCEL="Cancelar"
            L_BTN_CONTINUE="Continuar"
            L_BTN_CREATE="Crear y abrir"
            L_NOTIF_CREATED="Biblioteca creada"
            L_NOTIF_ACTIVATED="Biblioteca activada"
            L_NOTIF_ALREADY="ya es la biblioteca activa."
            L_ERR_TEMPLATE="Archivo de plantilla no encontrado :"
            L_ERR_UNZIP="Error al descomprimir la plantilla."
            L_ERR_EXISTS="Ya existe una biblioteca en esta ubicación."
            L_ERR_INVALID="Este archivo no contiene una biblioteca DigiKam válida."
            L_TEXT_SELECT="Ingrese el número de su elección :"
            L_TEXT_NAME="Nombre de la nueva biblioteca :"
            L_TEXT_PATH="Ruta completa de la biblioteca :"
            ;;
        it)
            L_TITLE="DigiKam"
            L_ACTIVE="Libreria attiva"
            L_CHOOSE="Scegli una libreria :"
            L_OTHER="Altra posizione..."
            L_NEW="+ Nuova libreria..."
            L_ACTIVE_SUFFIX="(attiva)"
            L_NAME_PROMPT="Nome della nuova libreria :"
            L_NAME_TITLE="DigiKam - Nuova libreria"
            L_FOLDER_PROMPT="Scegli una cartella per la libreria :"
            L_FILE_PROMPT="Scegli un .photoslibrary DigiKam :"
            L_CONFIRM_MSG="Creare la libreria?"
            L_CONFIRM_TITLE="DigiKam - Conferma"
            L_BTN_CANCEL="Annulla"
            L_BTN_CONTINUE="Continua"
            L_BTN_CREATE="Crea e apri"
            L_NOTIF_CREATED="Libreria creata"
            L_NOTIF_ACTIVATED="Libreria attivata"
            L_NOTIF_ALREADY="è già la libreria attiva."
            L_ERR_TEMPLATE="File modello non trovato :"
            L_ERR_UNZIP="Errore durante la decompressione del modello."
            L_ERR_EXISTS="Esiste già una libreria in questa posizione."
            L_ERR_INVALID="Questo file non contiene una libreria DigiKam valida."
            L_TEXT_SELECT="Inserisci il numero della tua scelta :"
            L_TEXT_NAME="Nome della nuova libreria :"
            L_TEXT_PATH="Percorso completo della libreria :"
            ;;
        de)
            L_TITLE="DigiKam"
            L_ACTIVE="Aktive Bibliothek"
            L_CHOOSE="Wählen Sie eine Bibliothek :"
            L_OTHER="Anderer Speicherort..."
            L_NEW="+ Neue Bibliothek..."
            L_ACTIVE_SUFFIX="(aktiv)"
            L_NAME_PROMPT="Name der neuen Bibliothek :"
            L_NAME_TITLE="DigiKam - Neue Bibliothek"
            L_FOLDER_PROMPT="Wählen Sie einen Ordner für die Bibliothek :"
            L_FILE_PROMPT="Wählen Sie ein DigiKam .photoslibrary :"
            L_CONFIRM_MSG="Bibliothek erstellen?"
            L_CONFIRM_TITLE="DigiKam - Bestätigung"
            L_BTN_CANCEL="Abbrechen"
            L_BTN_CONTINUE="Weiter"
            L_BTN_CREATE="Erstellen und öffnen"
            L_NOTIF_CREATED="Bibliothek erstellt"
            L_NOTIF_ACTIVATED="Bibliothek aktiviert"
            L_NOTIF_ALREADY="ist bereits die aktive Bibliothek."
            L_ERR_TEMPLATE="Vorlagendatei nicht gefunden :"
            L_ERR_UNZIP="Fehler beim Entpacken der Vorlage."
            L_ERR_EXISTS="An diesem Speicherort existiert bereits eine Bibliothek."
            L_ERR_INVALID="Diese Datei enthält keine gültige DigiKam-Bibliothek."
            L_TEXT_SELECT="Geben Sie die Nummer Ihrer Wahl ein :"
            L_TEXT_NAME="Name der neuen Bibliothek :"
            L_TEXT_PATH="Vollständiger Pfad der Bibliothek :"
            ;;
        pt)
            L_TITLE="DigiKam"
            L_ACTIVE="Biblioteca ativa"
            L_CHOOSE="Escolha uma biblioteca :"
            L_OTHER="Outro local..."
            L_NEW="+ Nova biblioteca..."
            L_ACTIVE_SUFFIX="(ativa)"
            L_NAME_PROMPT="Nome da nova biblioteca :"
            L_NAME_TITLE="DigiKam - Nova biblioteca"
            L_FOLDER_PROMPT="Escolha uma pasta para a biblioteca :"
            L_FILE_PROMPT="Escolha um .photoslibrary DigiKam :"
            L_CONFIRM_MSG="Criar a biblioteca?"
            L_CONFIRM_TITLE="DigiKam - Confirmação"
            L_BTN_CANCEL="Cancelar"
            L_BTN_CONTINUE="Continuar"
            L_BTN_CREATE="Criar e abrir"
            L_NOTIF_CREATED="Biblioteca criada"
            L_NOTIF_ACTIVATED="Biblioteca ativada"
            L_NOTIF_ALREADY="já é a biblioteca ativa."
            L_ERR_TEMPLATE="Ficheiro de modelo não encontrado :"
            L_ERR_UNZIP="Erro ao descompactar o modelo."
            L_ERR_EXISTS="Já existe uma biblioteca neste local."
            L_ERR_INVALID="Este ficheiro não contém uma biblioteca DigiKam válida."
            L_TEXT_SELECT="Digite o número da sua escolha :"
            L_TEXT_NAME="Nome da nova biblioteca :"
            L_TEXT_PATH="Caminho completo da biblioteca :"
            ;;
        nl)
            L_TITLE="DigiKam"
            L_ACTIVE="Actieve bibliotheek"
            L_CHOOSE="Kies een bibliotheek :"
            L_OTHER="Andere locatie..."
            L_NEW="+ Nieuwe bibliotheek..."
            L_ACTIVE_SUFFIX="(actief)"
            L_NAME_PROMPT="Naam van de nieuwe bibliotheek :"
            L_NAME_TITLE="DigiKam - Nieuwe bibliotheek"
            L_FOLDER_PROMPT="Kies een map voor de bibliotheek :"
            L_FILE_PROMPT="Kies een DigiKam .photoslibrary :"
            L_CONFIRM_MSG="Bibliotheek aanmaken?"
            L_CONFIRM_TITLE="DigiKam - Bevestiging"
            L_BTN_CANCEL="Annuleren"
            L_BTN_CONTINUE="Doorgaan"
            L_BTN_CREATE="Aanmaken en openen"
            L_NOTIF_CREATED="Bibliotheek aangemaakt"
            L_NOTIF_ACTIVATED="Bibliotheek geactiveerd"
            L_NOTIF_ALREADY="is al de actieve bibliotheek."
            L_ERR_TEMPLATE="Sjabloonbestand niet gevonden :"
            L_ERR_UNZIP="Fout bij het uitpakken van het sjabloon."
            L_ERR_EXISTS="Er bestaat al een bibliotheek op deze locatie."
            L_ERR_INVALID="Dit bestand bevat geen geldige DigiKam-bibliotheek."
            L_TEXT_SELECT="Voer het nummer van uw keuze in :"
            L_TEXT_NAME="Naam van de nieuwe bibliotheek :"
            L_TEXT_PATH="Volledig pad van de bibliotheek :"
            ;;
        pl)
            L_TITLE="DigiKam"
            L_ACTIVE="Aktywna biblioteka"
            L_CHOOSE="Wybierz bibliotekę :"
            L_OTHER="Inna lokalizacja..."
            L_NEW="+ Nowa biblioteka..."
            L_ACTIVE_SUFFIX="(aktywna)"
            L_NAME_PROMPT="Nazwa nowej biblioteki :"
            L_NAME_TITLE="DigiKam - Nowa biblioteka"
            L_FOLDER_PROMPT="Wybierz folder dla biblioteki :"
            L_FILE_PROMPT="Wybierz plik .photoslibrary DigiKam :"
            L_CONFIRM_MSG="Utworzyć bibliotekę?"
            L_CONFIRM_TITLE="DigiKam - Potwierdzenie"
            L_BTN_CANCEL="Anuluj"
            L_BTN_CONTINUE="Kontynuuj"
            L_BTN_CREATE="Utwórz i otwórz"
            L_NOTIF_CREATED="Biblioteka utworzona"
            L_NOTIF_ACTIVATED="Biblioteka aktywowana"
            L_NOTIF_ALREADY="jest już aktywną biblioteką."
            L_ERR_TEMPLATE="Plik szablonu nie znaleziony :"
            L_ERR_UNZIP="Błąd podczas rozpakowywania szablonu."
            L_ERR_EXISTS="Biblioteka już istnieje w tej lokalizacji."
            L_ERR_INVALID="Ten plik nie zawiera prawidłowej biblioteki DigiKam."
            L_TEXT_SELECT="Wpisz numer swojego wyboru :"
            L_TEXT_NAME="Nazwa nowej biblioteki :"
            L_TEXT_PATH="Pełna ścieżka biblioteki :"
            ;;
        uk)
            L_TITLE="DigiKam"
            L_ACTIVE="Активна бібліотека"
            L_CHOOSE="Виберіть бібліотеку :"
            L_OTHER="Інше місце..."
            L_NEW="+ Нова бібліотека..."
            L_ACTIVE_SUFFIX="(активна)"
            L_NAME_PROMPT="Назва нової бібліотеки :"
            L_NAME_TITLE="DigiKam - Нова бібліотека"
            L_FOLDER_PROMPT="Виберіть папку для бібліотеки :"
            L_FILE_PROMPT="Виберіть .photoslibrary DigiKam :"
            L_CONFIRM_MSG="Створити бібліотеку?"
            L_CONFIRM_TITLE="DigiKam - Підтвердження"
            L_BTN_CANCEL="Скасувати"
            L_BTN_CONTINUE="Продовжити"
            L_BTN_CREATE="Створити та відкрити"
            L_NOTIF_CREATED="Бібліотеку створено"
            L_NOTIF_ACTIVATED="Бібліотеку активовано"
            L_NOTIF_ALREADY="вже є активною бібліотекою."
            L_ERR_TEMPLATE="Файл шаблону не знайдено :"
            L_ERR_UNZIP="Помилка розпакування шаблону."
            L_ERR_EXISTS="Бібліотека вже існує в цьому місці."
            L_ERR_INVALID="Цей файл не містить дійсної бібліотеки DigiKam."
            L_TEXT_SELECT="Введіть номер вибору :"
            L_TEXT_NAME="Назва нової бібліотеки :"
            L_TEXT_PATH="Повний шлях бібліотеки :"
            ;;
        ru)
            L_TITLE="DigiKam"
            L_ACTIVE="Активная библиотека"
            L_CHOOSE="Выберите библиотеку :"
            L_OTHER="Другое расположение..."
            L_NEW="+ Новая библиотека..."
            L_ACTIVE_SUFFIX="(активная)"
            L_NAME_PROMPT="Название новой библиотеки :"
            L_NAME_TITLE="DigiKam - Новая библиотека"
            L_FOLDER_PROMPT="Выберите папку для библиотеки :"
            L_FILE_PROMPT="Выберите .photoslibrary DigiKam :"
            L_CONFIRM_MSG="Создать библиотеку?"
            L_CONFIRM_TITLE="DigiKam - Подтверждение"
            L_BTN_CANCEL="Отмена"
            L_BTN_CONTINUE="Продолжить"
            L_BTN_CREATE="Создать и открыть"
            L_NOTIF_CREATED="Библиотека создана"
            L_NOTIF_ACTIVATED="Библиотека активирована"
            L_NOTIF_ALREADY="уже является активной библиотекой."
            L_ERR_TEMPLATE="Файл шаблона не найден :"
            L_ERR_UNZIP="Ошибка при распаковке шаблона."
            L_ERR_EXISTS="Библиотека уже существует в этом месте."
            L_ERR_INVALID="Этот файл не содержит допустимой библиотеки DigiKam."
            L_TEXT_SELECT="Введите номер вашего выбора :"
            L_TEXT_NAME="Название новой библиотеки :"
            L_TEXT_PATH="Полный путь библиотеки :"
            ;;
        ja)
            L_TITLE="DigiKam"
            L_ACTIVE="アクティブなライブラリ"
            L_CHOOSE="ライブラリを選択してください :"
            L_OTHER="他の場所..."
            L_NEW="+ 新しいライブラリ..."
            L_ACTIVE_SUFFIX="(アクティブ)"
            L_NAME_PROMPT="新しいライブラリの名前 :"
            L_NAME_TITLE="DigiKam - 新しいライブラリ"
            L_FOLDER_PROMPT="ライブラリ用のフォルダを選択してください :"
            L_FILE_PROMPT="DigiKam の .photoslibrary を選択してください :"
            L_CONFIRM_MSG="ライブラリを作成しますか？"
            L_CONFIRM_TITLE="DigiKam - 確認"
            L_BTN_CANCEL="キャンセル"
            L_BTN_CONTINUE="続ける"
            L_BTN_CREATE="作成して開く"
            L_NOTIF_CREATED="ライブラリを作成しました"
            L_NOTIF_ACTIVATED="ライブラリを有効にしました"
            L_NOTIF_ALREADY="はすでにアクティブなライブラリです。"
            L_ERR_TEMPLATE="テンプレートファイルが見つかりません :"
            L_ERR_UNZIP="テンプレートの解凍中にエラーが発生しました。"
            L_ERR_EXISTS="この場所にはすでにライブラリが存在します。"
            L_ERR_INVALID="このファイルには有効な DigiKam ライブラリが含まれていません。"
            L_TEXT_SELECT="選択肢の番号を入力してください :"
            L_TEXT_NAME="新しいライブラリの名前 :"
            L_TEXT_PATH="ライブラリのフルパス :"
            ;;
        zh)
            L_TITLE="DigiKam"
            L_ACTIVE="当前资料库"
            L_CHOOSE="请选择一个资料库 :"
            L_OTHER="其他位置..."
            L_NEW="+ 新建资料库..."
            L_ACTIVE_SUFFIX="(当前)"
            L_NAME_PROMPT="新资料库的名称 :"
            L_NAME_TITLE="DigiKam - 新建资料库"
            L_FOLDER_PROMPT="请选择资料库文件夹 :"
            L_FILE_PROMPT="请选择 DigiKam .photoslibrary :"
            L_CONFIRM_MSG="创建资料库？"
            L_CONFIRM_TITLE="DigiKam - 确认"
            L_BTN_CANCEL="取消"
            L_BTN_CONTINUE="继续"
            L_BTN_CREATE="创建并打开"
            L_NOTIF_CREATED="资料库已创建"
            L_NOTIF_ACTIVATED="资料库已激活"
            L_NOTIF_ALREADY="已经是当前资料库。"
            L_ERR_TEMPLATE="找不到模板文件 :"
            L_ERR_UNZIP="解压模板时出错。"
            L_ERR_EXISTS="此位置已存在资料库。"
            L_ERR_INVALID="此文件不包含有效的 DigiKam 资料库。"
            L_TEXT_SELECT="请输入您的选择编号 :"
            L_TEXT_NAME="新资料库的名称 :"
            L_TEXT_PATH="资料库的完整路径 :"
            ;;
        ko)
            L_TITLE="DigiKam"
            L_ACTIVE="활성 라이브러리"
            L_CHOOSE="라이브러리를 선택하세요 :"
            L_OTHER="다른 위치..."
            L_NEW="+ 새 라이브러리..."
            L_ACTIVE_SUFFIX="(활성)"
            L_NAME_PROMPT="새 라이브러리 이름 :"
            L_NAME_TITLE="DigiKam - 새 라이브러리"
            L_FOLDER_PROMPT="라이브러리 폴더를 선택하세요 :"
            L_FILE_PROMPT="DigiKam .photoslibrary를 선택하세요 :"
            L_CONFIRM_MSG="라이브러리를 생성하시겠습니까?"
            L_CONFIRM_TITLE="DigiKam - 확인"
            L_BTN_CANCEL="취소"
            L_BTN_CONTINUE="계속"
            L_BTN_CREATE="생성 및 열기"
            L_NOTIF_CREATED="라이브러리가 생성되었습니다"
            L_NOTIF_ACTIVATED="라이브러리가 활성화되었습니다"
            L_NOTIF_ALREADY="은(는) 이미 활성 라이브러리입니다."
            L_ERR_TEMPLATE="템플릿 파일을 찾을 수 없습니다 :"
            L_ERR_UNZIP="템플릿 압축 해제 중 오류가 발생했습니다."
            L_ERR_EXISTS="이 위치에 이미 라이브러리가 존재합니다."
            L_ERR_INVALID="이 파일에는 유효한 DigiKam 라이브러리가 없습니다."
            L_TEXT_SELECT="선택 번호를 입력하세요 :"
            L_TEXT_NAME="새 라이브러리 이름 :"
            L_TEXT_PATH="라이브러리 전체 경로 :"
            ;;
        *)
            L_TITLE="DigiKam"
            L_ACTIVE="Active library"
            L_CHOOSE="Choose a library :"
            L_OTHER="Other location..."
            L_NEW="+ New library..."
            L_ACTIVE_SUFFIX="(active)"
            L_NAME_PROMPT="Name of the new library :"
            L_NAME_TITLE="DigiKam - New library"
            L_FOLDER_PROMPT="Choose a folder for the library :"
            L_FILE_PROMPT="Choose a DigiKam .photoslibrary :"
            L_CONFIRM_MSG="Create the library?"
            L_CONFIRM_TITLE="DigiKam - Confirmation"
            L_BTN_CANCEL="Cancel"
            L_BTN_CONTINUE="Continue"
            L_BTN_CREATE="Create and open"
            L_NOTIF_CREATED="Library created"
            L_NOTIF_ACTIVATED="Library activated"
            L_NOTIF_ALREADY="is already the active library."
            L_ERR_TEMPLATE="Template file not found :"
            L_ERR_UNZIP="Error while extracting template."
            L_ERR_EXISTS="A library already exists at this location."
            L_ERR_INVALID="This file does not contain a valid DigiKam library."
            L_TEXT_SELECT="Enter the number of your choice :"
            L_TEXT_NAME="Name of the new library :"
            L_TEXT_PATH="Full path of the library :"
            ;;
    esac
}

# ── Wrappers UI ────────────────────────────────────────────────────────────────

ui_error() {
    local msg="$1"
    case "$UI" in
        kdialog) kdialog --error "$msg" --title "$L_TITLE" ;;
        zenity)  zenity --error --title="$L_TITLE" --text="$msg" ;;
        text)    echo "ERROR: $msg" >&2 ;;
    esac
}

ui_warning() {
    local msg="$1"
    case "$UI" in
        kdialog) kdialog --sorry "$msg" --title "$L_TITLE" ;;
        zenity)  zenity --warning --title="$L_TITLE" --text="$msg" ;;
        text)    echo "WARNING: $msg" >&2 ;;
    esac
}

ui_notify() {
    local msg="$1"
    case "$UI" in
        kdialog) kdialog --passivepopup "$msg" 3 --title "$L_TITLE" ;;
        zenity)  zenity --notification --text="$msg" ;;
        text)    echo "$msg" ;;
    esac
}

ui_input() {
    local prompt="$1" default="$2" title="${3:-$L_TITLE}"
    case "$UI" in
        kdialog) kdialog --inputbox "$prompt" "$default" --title "$title" ;;
        zenity)  zenity --entry --title="$title" --text="$prompt" --entry-text="$default" ;;
        text)    read -rp "$prompt " val; echo "$val" ;;
    esac
}

ui_choose_folder() {
    local prompt="$1"
    case "$UI" in
        kdialog) kdialog --getexistingdirectory "$HOME" --title "$prompt" ;;
        zenity)  zenity --file-selection --directory --title="$prompt" ;;
        text)    read -rp "$prompt " val; echo "$val" ;;
    esac
}

ui_choose_file() {
    local prompt="$1"
    case "$UI" in
        kdialog) kdialog --getopenfilename "$HOME" "*.photoslibrary" --title "$prompt" ;;
        zenity)  zenity --file-selection --title="$prompt" --file-filter="*.photoslibrary" ;;
        text)    read -rp "$prompt " val; echo "$val" ;;
    esac
}

ui_confirm() {
    local msg="$1" title="${2:-$L_TITLE}"
    case "$UI" in
        kdialog) kdialog --yesno "$msg" --title "$title" && echo "yes" || echo "no" ;;
        zenity)  zenity --question --title="$title" --text="$msg" && echo "yes" || echo "no" ;;
        text)    read -rp "$msg [y/N] " val; [[ "$val" =~ ^[yY] ]] && echo "yes" || echo "no" ;;
    esac
}

ui_menu() {
    # Affiche une liste et retourne le choix
    # Arguments : titre prompt item1 item2 ...
    local title="$1" prompt="$2"
    shift 2
    local items=("$@")

    case "$UI" in
        kdialog)
            local args=()
            local idx=1
            for item in "${items[@]}"; do
                args+=("$idx" "$item")
                idx=$((idx + 1))
            done
            local choice
            choice=$(kdialog --menu "$prompt" "${args[@]}" --title "$title")
            [ -z "$choice" ] && return 1
            echo "${items[$((choice - 1))]}"
            ;;
        zenity)
            local args=()
            for item in "${items[@]}"; do
                args+=("$item")
            done
            zenity --list \
                --title="$title" \
                --text="$prompt" \
                --column="$L_TITLE" \
                --hide-header \
                "${args[@]}"
            ;;
        text)
            echo "$title"
            echo "$prompt"
            local idx=1
            for item in "${items[@]}"; do
                echo "  $idx. $item"
                idx=$((idx + 1))
            done
            read -rp "$L_TEXT_SELECT " num
            [ -z "$num" ] && return 1
            echo "${items[$((num - 1))]}"
            ;;
    esac
}

# ── Lire la bibliothèque active ────────────────────────────────────────────────
get_active_library() {
    grep -m1 "^Database Name=" "$DIGIKAMRC" 2>/dev/null \
        | sed 's/^Database Name=//' \
        | sed 's|/$||'
}

# ── Extraire le nom court ──────────────────────────────────────────────────────
library_name() {
    basename "$1" .photoslibrary
}

# ── Lister les bibliothèques DigiKam disponibles ──────────────────────────────
list_libraries() {
    local dir lib
    for dir in "$HOME/.local/share/digikam" "$HOME/Pictures"; do
        [ -d "$dir" ] || continue
        while IFS= read -r -d '' lib; do
            [ -f "$lib/digikam4.db" ] && echo "$lib"
        done < <(find "$dir" -maxdepth 2 -name "*.photoslibrary" -print0 2>/dev/null)
    done | sort -u
}

# ── Mettre à jour les 4 clés Database dans digikamrc ──────────────────────────
update_digikamrc() {
    local new_path="$1"
    [[ "$new_path" != */ ]] && new_path="$new_path/"
    sed -i \
        -e "s|^Database Name=.*|Database Name=$new_path|" \
        -e "s|^Database Name Face=.*|Database Name Face=$new_path|" \
        -e "s|^Database Name Similarity=.*|Database Name Similarity=$new_path|" \
        -e "s|^Database Name Thumbnails=.*|Database Name Thumbnails=$new_path|" \
        "$DIGIKAMRC"
}

# ── Créer une nouvelle bibliothèque ───────────────────────────────────────────
create_library() {
    local lib_path="$1"
    local lib_name
    lib_name=$(library_name "$lib_path")
    local lib_parent
    lib_parent=$(dirname "$lib_path")

    if [ ! -f "$TEMPLATE_ZIP" ]; then
        ui_error "$L_ERR_TEMPLATE\n$TEMPLATE_ZIP"
        exit 1
    fi

    local tmp_dir
    tmp_dir=$(mktemp -d)

    unzip -q "$TEMPLATE_ZIP" -d "$tmp_dir"

    if [ ! -d "$tmp_dir/Digikam.photoslibrary" ]; then
        ui_error "$L_ERR_UNZIP"
        rm -rf "$tmp_dir"
        exit 1
    fi

    mv "$tmp_dir/Digikam.photoslibrary" "$tmp_dir/$lib_name.photoslibrary"
    mv "$tmp_dir/$lib_name.photoslibrary" "$lib_parent/"
    rm -rf "$tmp_dir"

    cp "$DIGIKAMRC" "$lib_path/digikamrc.template" 2>/dev/null
    update_digikamrc "$lib_path"
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
    UI=$(detect_ui)
    local lang
    lang=$(detect_lang)
    set_strings "$lang"

    local active active_name
    active=$(get_active_library)
    active_name=$(library_name "$active")

    # Construire la liste des bibliothèques
    local i=0
    local names=()
    local paths=()

    while IFS= read -r lib; do
        local name
        name=$(library_name "$lib")
        if [ "$lib" = "$active" ] || [ "$lib/" = "$active" ]; then
            names[$i]="$name $L_ACTIVE_SUFFIX"
        else
            names[$i]="$name"
        fi
        paths[$i]="$lib"
        i=$((i + 1))
    done < <(list_libraries)

    # Ajouter les options spéciales
    local menu_items=("${names[@]}" "$L_OTHER" "$L_NEW")

    local choice
    choice=$(ui_menu "$L_TITLE" "$L_ACTIVE : $active_name\n$L_CHOOSE" "${menu_items[@]}")

    [ -z "$choice" ] && exit 0

    # ── Autre emplacement ────────────────────────────────────────────────────
    if [ "$choice" = "$L_OTHER" ]; then

        local other_location
        other_location=$(ui_choose_file "$L_FILE_PROMPT")
        [ -z "$other_location" ] && exit 0

        other_location="${other_location%/}"

        if [ ! -f "$other_location/digikam4.db" ]; then
            ui_warning "$L_ERR_INVALID"
            exit 1
        fi

        update_digikamrc "$other_location"
        local other_name
        other_name=$(library_name "$other_location")
        ui_notify "$L_NOTIF_ACTIVATED : $other_name"
        $DIGIKAM_BIN &
        exit 0

    # ── Nouvelle bibliothèque ────────────────────────────────────────────────
    elif [ "$choice" = "$L_NEW" ]; then

        local lib_name
        lib_name=$(ui_input "$L_NAME_PROMPT" "" "$L_NAME_TITLE")
        [ -z "$lib_name" ] && exit 0

        local lib_location
        lib_location=$(ui_choose_folder "$L_FOLDER_PROMPT")
        [ -z "$lib_location" ] && exit 0

        lib_location="${lib_location%/}"
        local full_path="$lib_location/$lib_name.photoslibrary"

        if [ -f "$full_path/digikam4.db" ]; then
            ui_warning "$L_ERR_EXISTS"
            exit 1
        fi

        local confirm
        confirm=$(ui_confirm "$L_CONFIRM_MSG\n$full_path" "$L_CONFIRM_TITLE")
        [ "$confirm" != "yes" ] && exit 0

        create_library "$full_path"
        ui_notify "$L_NOTIF_CREATED : $lib_name"

    else
        # ── Bibliothèque existante ───────────────────────────────────────────
        local chosen_name="${choice% $L_ACTIVE_SUFFIX}"
        local chosen_path=""

        local j
        for j in "${!names[@]}"; do
            local bare_name="${names[$j]% $L_ACTIVE_SUFFIX}"
            if [ "$bare_name" = "$chosen_name" ]; then
                chosen_path="${paths[$j]}"
                break
            fi
        done

        [ -z "$chosen_path" ] && exit 1

        if [ "$chosen_path" = "$active" ] || [ "$chosen_path/" = "$active" ]; then
            ui_notify "$chosen_name $L_NOTIF_ALREADY"
            $DIGIKAM_BIN &
            exit 0
        fi

        update_digikamrc "$chosen_path"
        ui_notify "$L_NOTIF_ACTIVATED : $chosen_name"
    fi

    $DIGIKAM_BIN &
}

main
