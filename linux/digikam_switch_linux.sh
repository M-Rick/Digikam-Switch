#!/bin/bash
# digikam_switch_linux.sh
# Gestionnaire de bibliothèques DigiKam pour Linux
# Compatible bash 3.2+
# Packager via un fichier .desktop
# Dépendances optionnelles : kdialog (KDE), zenity (GNOME/GTK)

# Ce script utilise des fonctionnalités propres à bash (tableaux, [[ ]],
# pipefail). Lancé avec « sh script.sh », il tournerait sous dash et
# échouerait : on se relance alors sous bash.
if [ -z "${BASH_VERSION:-}" ]; then
    exec bash "$0" "$@"
fi

DIGIKAMRC="$HOME/.config/digikamrc"
# La commande de lancement de DigiKam est resolue a l'execution (resolve_digikam),
# car selon l'installation (paquet, Flatpak, Snap, AppImage) il n'existe pas
# forcement de binaire « digikam » dans le PATH.
DIGIKAM_CMD=()
# Emplacement du template : override explicite, sinon a cote du script (depot),
# sinon repertoires d'installation (.deb: /usr/share, install.sh: /usr/local/share).
if [ -z "${TEMPLATE_ZIP:-}" ]; then
    for _cand in \
        "$(dirname "$0")/digikam_template.zip" \
        "/usr/share/digikam-switch/digikam_template.zip" \
        "/usr/local/share/digikam-switch/digikam_template.zip"; do
        [ -f "$_cand" ] && { TEMPLATE_ZIP="$_cand"; break; }
    done
    : "${TEMPLATE_ZIP:=$(dirname "$0")/digikam_template.zip}"
fi

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
            L_TITLE="DigiKam Switch"
            L_ACTIVE="Bibliothèque active"
            L_CHOOSE="Choisissez une bibliothèque :"
            L_OTHER="Autre emplacement..."
            L_NEW="+ Nouvelle bibliothèque..."
            L_ACTIVE_SUFFIX="(active)"
            L_NAME_PROMPT="Nom de la nouvelle bibliothèque :"
            L_NAME_TITLE="DigiKam - Nouvelle bibliothèque"
            L_FOLDER_PROMPT="Choisissez un dossier pour la bibliothèque :"
            L_FILE_PROMPT="Choisissez un .digikamlibrary DigiKam :"
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
            L_ERR_COLLECTION="Impossible de déclarer la collection dans la nouvelle bibliothèque. Ajoutez-la depuis DigiKam : Configurer DigiKam, Collections."
            L_RUNNING="DigiKam est en cours d'exécution. En se fermant, il réécrira sa configuration et annulera le changement de bibliothèque. Fermer DigiKam, puis continuer ?"
            L_ERR_EXISTS="Une bibliothèque existe déjà à cet emplacement."
            L_ERR_INVALID="Ce fichier ne contient pas de bibliothèque DigiKam valide."
            L_TEXT_SELECT="Entrez le numéro de votre choix :"
            L_TEXT_NAME="Nom de la nouvelle bibliothèque :"
            L_TEXT_PATH="Chemin complet de la bibliothèque :"
            ;;
        es)
            L_TITLE="DigiKam Switch"
            L_ACTIVE="Biblioteca activa"
            L_CHOOSE="Elija una biblioteca :"
            L_OTHER="Otra ubicación..."
            L_NEW="+ Nueva biblioteca..."
            L_ACTIVE_SUFFIX="(activa)"
            L_NAME_PROMPT="Nombre de la nueva biblioteca :"
            L_NAME_TITLE="DigiKam - Nueva biblioteca"
            L_FOLDER_PROMPT="Elija una carpeta para la biblioteca :"
            L_FILE_PROMPT="Elija un .digikamlibrary de DigiKam :"
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
            L_ERR_COLLECTION="No se pudo declarar la colección en la nueva biblioteca. Añádala desde DigiKam: Configurar DigiKam, Colecciones."
            L_RUNNING="DigiKam se está ejecutando. Al cerrarse reescribirá su configuración y anulará el cambio de biblioteca. ¿Cerrar DigiKam y continuar?"
            L_ERR_EXISTS="Ya existe una biblioteca en esta ubicación."
            L_ERR_INVALID="Este archivo no contiene una biblioteca DigiKam válida."
            L_TEXT_SELECT="Ingrese el número de su elección :"
            L_TEXT_NAME="Nombre de la nueva biblioteca :"
            L_TEXT_PATH="Ruta completa de la biblioteca :"
            ;;
        it)
            L_TITLE="DigiKam Switch"
            L_ACTIVE="Libreria attiva"
            L_CHOOSE="Scegli una libreria :"
            L_OTHER="Altra posizione..."
            L_NEW="+ Nuova libreria..."
            L_ACTIVE_SUFFIX="(attiva)"
            L_NAME_PROMPT="Nome della nuova libreria :"
            L_NAME_TITLE="DigiKam - Nuova libreria"
            L_FOLDER_PROMPT="Scegli una cartella per la libreria :"
            L_FILE_PROMPT="Scegli un .digikamlibrary DigiKam :"
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
            L_ERR_COLLECTION="Impossibile dichiarare la raccolta nella nuova libreria. Aggiungila da DigiKam: Configura DigiKam, Raccolte."
            L_RUNNING="DigiKam è in esecuzione. Alla chiusura riscriverà la configurazione annullando il cambio di libreria. Chiudere DigiKam e continuare?"
            L_ERR_EXISTS="Esiste già una libreria in questa posizione."
            L_ERR_INVALID="Questo file non contiene una libreria DigiKam valida."
            L_TEXT_SELECT="Inserisci il numero della tua scelta :"
            L_TEXT_NAME="Nome della nuova libreria :"
            L_TEXT_PATH="Percorso completo della libreria :"
            ;;
        de)
            L_TITLE="DigiKam Switch"
            L_ACTIVE="Aktive Bibliothek"
            L_CHOOSE="Wählen Sie eine Bibliothek :"
            L_OTHER="Anderer Speicherort..."
            L_NEW="+ Neue Bibliothek..."
            L_ACTIVE_SUFFIX="(aktiv)"
            L_NAME_PROMPT="Name der neuen Bibliothek :"
            L_NAME_TITLE="DigiKam - Neue Bibliothek"
            L_FOLDER_PROMPT="Wählen Sie einen Ordner für die Bibliothek :"
            L_FILE_PROMPT="Wählen Sie ein DigiKam .digikamlibrary :"
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
            L_ERR_COLLECTION="Die Sammlung konnte in der neuen Bibliothek nicht angelegt werden. Fügen Sie sie in DigiKam hinzu: DigiKam einrichten, Sammlungen."
            L_RUNNING="DigiKam läuft bereits. Beim Beenden überschreibt es seine Konfiguration und macht den Bibliothekswechsel rückgängig. DigiKam schließen und fortfahren?"
            L_ERR_EXISTS="An diesem Speicherort existiert bereits eine Bibliothek."
            L_ERR_INVALID="Diese Datei enthält keine gültige DigiKam-Bibliothek."
            L_TEXT_SELECT="Geben Sie die Nummer Ihrer Wahl ein :"
            L_TEXT_NAME="Name der neuen Bibliothek :"
            L_TEXT_PATH="Vollständiger Pfad der Bibliothek :"
            ;;
        pt)
            L_TITLE="DigiKam Switch"
            L_ACTIVE="Biblioteca ativa"
            L_CHOOSE="Escolha uma biblioteca :"
            L_OTHER="Outro local..."
            L_NEW="+ Nova biblioteca..."
            L_ACTIVE_SUFFIX="(ativa)"
            L_NAME_PROMPT="Nome da nova biblioteca :"
            L_NAME_TITLE="DigiKam - Nova biblioteca"
            L_FOLDER_PROMPT="Escolha uma pasta para a biblioteca :"
            L_FILE_PROMPT="Escolha um .digikamlibrary DigiKam :"
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
            L_ERR_COLLECTION="Não foi possível declarar a coleção na nova biblioteca. Adicione-a no DigiKam: Configurar DigiKam, Coleções."
            L_RUNNING="O DigiKam está em execução. Ao fechar, reescreverá a configuração e anulará a mudança de biblioteca. Fechar o DigiKam e continuar?"
            L_ERR_EXISTS="Já existe uma biblioteca neste local."
            L_ERR_INVALID="Este ficheiro não contém uma biblioteca DigiKam válida."
            L_TEXT_SELECT="Digite o número da sua escolha :"
            L_TEXT_NAME="Nome da nova biblioteca :"
            L_TEXT_PATH="Caminho completo da biblioteca :"
            ;;
        nl)
            L_TITLE="DigiKam Switch"
            L_ACTIVE="Actieve bibliotheek"
            L_CHOOSE="Kies een bibliotheek :"
            L_OTHER="Andere locatie..."
            L_NEW="+ Nieuwe bibliotheek..."
            L_ACTIVE_SUFFIX="(actief)"
            L_NAME_PROMPT="Naam van de nieuwe bibliotheek :"
            L_NAME_TITLE="DigiKam - Nieuwe bibliotheek"
            L_FOLDER_PROMPT="Kies een map voor de bibliotheek :"
            L_FILE_PROMPT="Kies een DigiKam .digikamlibrary :"
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
            L_ERR_COLLECTION="Kan de verzameling niet aanmaken in de nieuwe bibliotheek. Voeg deze toe in DigiKam: DigiKam instellen, Verzamelingen."
            L_RUNNING="DigiKam is actief. Bij het afsluiten overschrijft het zijn configuratie en maakt de bibliotheekwissel ongedaan. DigiKam sluiten en doorgaan?"
            L_ERR_EXISTS="Er bestaat al een bibliotheek op deze locatie."
            L_ERR_INVALID="Dit bestand bevat geen geldige DigiKam-bibliotheek."
            L_TEXT_SELECT="Voer het nummer van uw keuze in :"
            L_TEXT_NAME="Naam van de nieuwe bibliotheek :"
            L_TEXT_PATH="Volledig pad van de bibliotheek :"
            ;;
        pl)
            L_TITLE="DigiKam Switch"
            L_ACTIVE="Aktywna biblioteka"
            L_CHOOSE="Wybierz bibliotekę :"
            L_OTHER="Inna lokalizacja..."
            L_NEW="+ Nowa biblioteka..."
            L_ACTIVE_SUFFIX="(aktywna)"
            L_NAME_PROMPT="Nazwa nowej biblioteki :"
            L_NAME_TITLE="DigiKam - Nowa biblioteka"
            L_FOLDER_PROMPT="Wybierz folder dla biblioteki :"
            L_FILE_PROMPT="Wybierz plik .digikamlibrary DigiKam :"
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
            L_ERR_COLLECTION="Nie można utworzyć kolekcji w nowej bibliotece. Dodaj ją w DigiKam: Ustawienia DigiKam, Kolekcje."
            L_RUNNING="DigiKam jest uruchomiony. Przy zamykaniu nadpisze konfigurację i cofnie zmianę biblioteki. Zamknąć DigiKam i kontynuować?"
            L_ERR_EXISTS="Biblioteka już istnieje w tej lokalizacji."
            L_ERR_INVALID="Ten plik nie zawiera prawidłowej biblioteki DigiKam."
            L_TEXT_SELECT="Wpisz numer swojego wyboru :"
            L_TEXT_NAME="Nazwa nowej biblioteki :"
            L_TEXT_PATH="Pełna ścieżka biblioteki :"
            ;;
        uk)
            L_TITLE="DigiKam Switch"
            L_ACTIVE="Активна бібліотека"
            L_CHOOSE="Виберіть бібліотеку :"
            L_OTHER="Інше місце..."
            L_NEW="+ Нова бібліотека..."
            L_ACTIVE_SUFFIX="(активна)"
            L_NAME_PROMPT="Назва нової бібліотеки :"
            L_NAME_TITLE="DigiKam - Нова бібліотека"
            L_FOLDER_PROMPT="Виберіть папку для бібліотеки :"
            L_FILE_PROMPT="Виберіть .digikamlibrary DigiKam :"
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
            L_ERR_COLLECTION="Не вдалося створити колекцію в новій бібліотеці. Додайте її в DigiKam: Налаштувати DigiKam, Колекції."
            L_RUNNING="DigiKam запущено. Під час закриття він перезапише конфігурацію і скасує зміну бібліотеки. Закрити DigiKam і продовжити?"
            L_ERR_EXISTS="Бібліотека вже існує в цьому місці."
            L_ERR_INVALID="Цей файл не містить дійсної бібліотеки DigiKam."
            L_TEXT_SELECT="Введіть номер вибору :"
            L_TEXT_NAME="Назва нової бібліотеки :"
            L_TEXT_PATH="Повний шлях бібліотеки :"
            ;;
        ru)
            L_TITLE="DigiKam Switch"
            L_ACTIVE="Активная библиотека"
            L_CHOOSE="Выберите библиотеку :"
            L_OTHER="Другое расположение..."
            L_NEW="+ Новая библиотека..."
            L_ACTIVE_SUFFIX="(активная)"
            L_NAME_PROMPT="Название новой библиотеки :"
            L_NAME_TITLE="DigiKam - Новая библиотека"
            L_FOLDER_PROMPT="Выберите папку для библиотеки :"
            L_FILE_PROMPT="Выберите .digikamlibrary DigiKam :"
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
            L_ERR_COLLECTION="Не удалось создать коллекцию в новой библиотеке. Добавьте её в DigiKam: Настроить DigiKam, Коллекции."
            L_RUNNING="DigiKam запущен. При закрытии он перезапишет конфигурацию и отменит смену библиотеки. Закрыть DigiKam и продолжить?"
            L_ERR_EXISTS="Библиотека уже существует в этом месте."
            L_ERR_INVALID="Этот файл не содержит допустимой библиотеки DigiKam."
            L_TEXT_SELECT="Введите номер вашего выбора :"
            L_TEXT_NAME="Название новой библиотеки :"
            L_TEXT_PATH="Полный путь библиотеки :"
            ;;
        ja)
            L_TITLE="DigiKam Switch"
            L_ACTIVE="アクティブなライブラリ"
            L_CHOOSE="ライブラリを選択してください :"
            L_OTHER="他の場所..."
            L_NEW="+ 新しいライブラリ..."
            L_ACTIVE_SUFFIX="(アクティブ)"
            L_NAME_PROMPT="新しいライブラリの名前 :"
            L_NAME_TITLE="DigiKam - 新しいライブラリ"
            L_FOLDER_PROMPT="ライブラリ用のフォルダを選択してください :"
            L_FILE_PROMPT="DigiKam の .digikamlibrary を選択してください :"
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
            L_ERR_COLLECTION="新しいライブラリにコレクションを登録できませんでした。DigiKam の設定からコレクションを追加してください。"
            L_RUNNING="DigiKam が実行中です。終了時に設定が上書きされ、ライブラリの切り替えが取り消されます。DigiKam を閉じて続行しますか？"
            L_ERR_EXISTS="この場所にはすでにライブラリが存在します。"
            L_ERR_INVALID="このファイルには有効な DigiKam ライブラリが含まれていません。"
            L_TEXT_SELECT="選択肢の番号を入力してください :"
            L_TEXT_NAME="新しいライブラリの名前 :"
            L_TEXT_PATH="ライブラリのフルパス :"
            ;;
        zh)
            L_TITLE="DigiKam Switch"
            L_ACTIVE="当前资料库"
            L_CHOOSE="请选择一个资料库 :"
            L_OTHER="其他位置..."
            L_NEW="+ 新建资料库..."
            L_ACTIVE_SUFFIX="(当前)"
            L_NAME_PROMPT="新资料库的名称 :"
            L_NAME_TITLE="DigiKam - 新建资料库"
            L_FOLDER_PROMPT="请选择资料库文件夹 :"
            L_FILE_PROMPT="请选择 DigiKam .digikamlibrary :"
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
            L_ERR_COLLECTION="无法在新库中创建收藏集。请在 DigiKam 的设置中添加收藏集。"
            L_RUNNING="DigiKam 正在运行。关闭时它会重写配置并撤销库切换。关闭 DigiKam 后继续吗？"
            L_ERR_EXISTS="此位置已存在资料库。"
            L_ERR_INVALID="此文件不包含有效的 DigiKam 资料库。"
            L_TEXT_SELECT="请输入您的选择编号 :"
            L_TEXT_NAME="新资料库的名称 :"
            L_TEXT_PATH="资料库的完整路径 :"
            ;;
        ko)
            L_TITLE="DigiKam Switch"
            L_ACTIVE="활성 라이브러리"
            L_CHOOSE="라이브러리를 선택하세요 :"
            L_OTHER="다른 위치..."
            L_NEW="+ 새 라이브러리..."
            L_ACTIVE_SUFFIX="(활성)"
            L_NAME_PROMPT="새 라이브러리 이름 :"
            L_NAME_TITLE="DigiKam - 새 라이브러리"
            L_FOLDER_PROMPT="라이브러리 폴더를 선택하세요 :"
            L_FILE_PROMPT="DigiKam .digikamlibrary를 선택하세요 :"
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
            L_ERR_COLLECTION="새 라이브러리에 컬렉션을 등록하지 못했습니다. DigiKam 설정에서 컬렉션을 추가하세요."
            L_RUNNING="DigiKam이 실행 중입니다. 종료할 때 설정을 덮어써서 라이브러리 전환이 취소됩니다. DigiKam을 닫고 계속할까요?"
            L_ERR_EXISTS="이 위치에 이미 라이브러리가 존재합니다."
            L_ERR_INVALID="이 파일에는 유효한 DigiKam 라이브러리가 없습니다."
            L_TEXT_SELECT="선택 번호를 입력하세요 :"
            L_TEXT_NAME="새 라이브러리 이름 :"
            L_TEXT_PATH="라이브러리 전체 경로 :"
            ;;
        *)
            L_TITLE="DigiKam Switch"
            L_ACTIVE="Active library"
            L_CHOOSE="Choose a library :"
            L_OTHER="Other location..."
            L_NEW="+ New library..."
            L_ACTIVE_SUFFIX="(active)"
            L_NAME_PROMPT="Name of the new library :"
            L_NAME_TITLE="DigiKam - New library"
            L_FOLDER_PROMPT="Choose a folder for the library :"
            L_FILE_PROMPT="Choose a DigiKam .digikamlibrary :"
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
            L_ERR_COLLECTION="Could not declare the collection in the new library. Add it from DigiKam: Configure DigiKam, Collections."
            L_RUNNING="DigiKam is running. On exit it will rewrite its configuration and undo the library switch. Close DigiKam, then continue?"
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
    # Equivalent Linux de « display notification » sous macOS : la notification
    # doit rendre la main immediatement. zenity --notification reste en attente
    # jusqu a fermeture : il bloquerait le lancement de DigiKam qui suit.
    if command -v notify-send &>/dev/null; then
        notify-send -a "$L_TITLE" -i digikam-switch "$L_TITLE" "$msg" >/dev/null 2>&1 &
        return 0
    fi
    case "$UI" in
        kdialog) kdialog --passivepopup "$msg" 3 --title "$L_TITLE" >/dev/null 2>&1 & ;;
        zenity)  ( zenity --notification --text="$msg" >/dev/null 2>&1 & ) ;;
        text)    echo "$msg" ;;
    esac
    return 0
}

ui_input() {
    local prompt="$1" default="$2" title="${3:-$L_TITLE}"
    case "$UI" in
        kdialog) kdialog --inputbox "$prompt" "$default" --title "$title" ;;
        zenity)  zenity --entry --title="$title" --text="$prompt" --entry-text="$default" \
                        --ok-label="$L_BTN_CONTINUE" --cancel-label="$L_BTN_CANCEL" ;;
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
        kdialog) kdialog --getopenfilename "$HOME" "*.digikamlibrary" --title "$prompt" ;;
        zenity)  zenity --file-selection --title="$prompt" --file-filter="*.digikamlibrary" ;;
        text)    read -rp "$prompt " val; echo "$val" ;;
    esac
}

ui_confirm() {
    local msg="$1" title="${2:-$L_TITLE}" ok="${3:-}" cancel="${4:-}"
    # Libellés explicites quand ils sont fournis, comme sur macOS où les boutons
    # portent « Annuler » et « Créer et ouvrir » plutôt qu un Oui/Non générique.
    case "$UI" in
        kdialog)
            if [ -n "$ok" ]; then
                kdialog --yesno "$msg" --title "$title" \
                        --yes-label "$ok" --no-label "${cancel:-$L_BTN_CANCEL}" \
                    && echo "yes" || echo "no"
            else
                kdialog --yesno "$msg" --title "$title" && echo "yes" || echo "no"
            fi ;;
        zenity)
            if [ -n "$ok" ]; then
                zenity --question --title="$title" --text="$msg" \
                       --ok-label="$ok" --cancel-label="${cancel:-$L_BTN_CANCEL}" \
                    && echo "yes" || echo "no"
            else
                zenity --question --title="$title" --text="$msg" && echo "yes" || echo "no"
            fi ;;
        text)
            read -rp "$msg [${ok:-y}/${cancel:-N}] " val
            [[ "$val" =~ ^[yYoO] ]] && echo "yes" || echo "no" ;;
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
    basename "$1" .digikamlibrary
}

# ── Lister les bibliothèques DigiKam disponibles ──────────────────────────────
# Dossier « Images » de l utilisateur. Il est localise : ~/Images en francais,
# ~/Bilder en allemand, ~/Immagini en italien... Le coder en dur a « Pictures »
# rend invisibles les bibliotheques des systemes non anglophones.
pictures_dir() {
    local d=""
    if command -v xdg-user-dir &>/dev/null; then
        d=$(xdg-user-dir PICTURES 2>/dev/null)
    fi
    if [ -z "$d" ] || [ "$d" = "$HOME" ]; then
        # Pas de xdg-user-dir : lire directement la configuration XDG.
        if [ -f "$HOME/.config/user-dirs.dirs" ]; then
            d=$(grep -m1 '^XDG_PICTURES_DIR=' "$HOME/.config/user-dirs.dirs" \
                | sed -e 's/^XDG_PICTURES_DIR=//' -e 's/^"//' -e 's/"$//' \
                      -e "s|^\$HOME|$HOME|")
        fi
    fi
    [ -n "$d" ] && [ -d "$d" ] && { echo "$d"; return 0; }
    # Dernier recours : l emplacement anglais.
    echo "$HOME/Pictures"
}

list_libraries() {
    local dir lib
    for dir in "$HOME/.local/share/digikam" "$(pictures_dir)"; do
        [ -d "$dir" ] || continue
        while IFS= read -r -d '' lib; do
            [ -f "$lib/digikam4.db" ] && echo "$lib"
        done < <(find "$dir" -maxdepth 2 -name "*.digikamlibrary" -print0 2>/dev/null)
    done | sort -u
}

# ── Mettre à jour les 4 clés Database dans digikamrc ──────────────────────────
update_digikamrc() {
    local new_path="$1"
    [[ "$new_path" != */ ]] && new_path="$new_path/"

    # Le fichier peut ne pas exister (DigiKam jamais lance) : on le cree avec la
    # section attendue, sinon le sed echouerait en silence et la bascule serait
    # sans effet.
    if [ ! -f "$DIGIKAMRC" ]; then
        mkdir -p "$(dirname "$DIGIKAMRC")"
        printf '[Database Settings]\n' > "$DIGIKAMRC"
    fi

    # Section [Database Settings] absente : on l ajoute.
    if ! grep -q '^\[Database Settings\]' "$DIGIKAMRC"; then
        printf '\n[Database Settings]\n' >> "$DIGIKAMRC"
    fi

    local key
    for key in "Database Name" "Database Name Face" \
               "Database Name Similarity" "Database Name Thumbnails"; do
        if grep -q "^$key=" "$DIGIKAMRC"; then
            sed -i "s|^$key=.*|$key=$new_path|" "$DIGIKAMRC"
        else
            # Cle absente : on l insere juste apres l en-tete de section.
            sed -i "/^\[Database Settings\]/a $key=$new_path" "$DIGIKAMRC"
        fi
    done

    # Verification : la bascule a-t-elle vraiment ete ecrite ?
    grep -q "^Database Name=$new_path\$" "$DIGIKAMRC"
}

# ── Créer une nouvelle bibliothèque ───────────────────────────────────────────
# ── Collection racine de la bibliotheque ──────────────────────────────────────
# Une base DigiKam neuve n a aucune collection (table AlbumRoots vide) : DigiKam
# s ouvre alors sans racine d album, et il devient impossible de creer un album
# ou d importer des images. On declare donc la bibliotheque elle-meme comme
# collection, ce que DigiKam fait aussi par defaut (base et photos au meme
# endroit). L identifiant de type « path= » est prefere a « uuid= » : il ne
# depend pas du systeme de fichiers, donc la bibliotheque reste utilisable si
# elle est deplacee ou posee sur un disque externe.
register_collection_root() {
    local lib_path="${1%/}"
    local db="$lib_path/digikam4.db"
    local label
    label=$(library_name "$lib_path")
    [ -f "$db" ] || return 1

    local sql="INSERT OR IGNORE INTO AlbumRoots
        (label, status, type, identifier, specificPath, caseSensitivity)
        VALUES ('$(printf '%s' "$label" | sed "s/'/''/g")', 0, 1,
                'volumeid:?path=$(printf '%s' "$lib_path" | sed "s/'/''/g")', '/', 0);"

    if command -v sqlite3 &>/dev/null; then
        sqlite3 "$db" "$sql" 2>/dev/null && return 0
    fi
    if command -v python3 &>/dev/null; then
        python3 - "$db" "$sql" << 'PYEOF' 2>/dev/null && return 0
import sys, sqlite3
con = sqlite3.connect(sys.argv[1])
con.execute(sys.argv[2])
con.commit()
con.close()
PYEOF
    fi
    return 1
}

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

    # On ne suppose pas le nom du dossier contenu dans le template : on le
    # repère par la présence de digikam4.db, seul critère qui fasse foi.
    local extracted
    extracted=$(find "$tmp_dir" -maxdepth 2 -type f -name digikam4.db 2>/dev/null | head -1)
    [ -n "$extracted" ] && extracted=$(dirname "$extracted")

    if [ -z "$extracted" ] || [ ! -d "$extracted" ]; then
        ui_error "$L_ERR_UNZIP"
        rm -rf "$tmp_dir"
        exit 1
    fi

    mv "$extracted" "$tmp_dir/$lib_name.digikamlibrary"
    mv "$tmp_dir/$lib_name.digikamlibrary" "$lib_parent/"
    rm -rf "$tmp_dir"

    cp "$DIGIKAMRC" "$lib_path/digikamrc.template" 2>/dev/null

    # Sans collection racine, DigiKam ne permet ni album ni import.
    if ! register_collection_root "$lib_path"; then
        ui_warning "$L_ERR_COLLECTION"
    fi

    update_digikamrc "$lib_path"
}

# ── Résolution de la commande DigiKam ─────────────────────────────────────────
# DigiKam s'installe de plusieurs façons sous Linux : paquet natif, Flatpak,
# Snap, ou AppImage. Aucune ne garantit un binaire nommé « digikam » dans le
# PATH (l'AppImage est le mode par défaut du projet et n'y figure jamais). On
# résout donc la commande de lancement à l'exécution au lieu de la coder en dur.
resolve_digikam() {
    # 1. Binaire dans le PATH : paquet natif, wrapper Snap, ou lien manuel.
    if command -v digikam &>/dev/null; then
        DIGIKAM_CMD=(digikam)
        return 0
    fi

    # 2. Flatpak.
    if command -v flatpak &>/dev/null && flatpak info org.kde.digikam &>/dev/null; then
        DIGIKAM_CMD=(flatpak run org.kde.digikam)
        return 0
    fi

    # 3. Snap sans wrapper dans le PATH.
    if command -v snap &>/dev/null && snap list digikam &>/dev/null; then
        DIGIKAM_CMD=(snap run digikam)
        return 0
    fi

    # 4. Fichier .desktop : AppImage intégré au menu, ou toute autre intégration.
    #    On lit la ligne Exec= et on n'en garde que l'exécutable, pas les
    #    arguments d'intégration (digikam se lance sans). Un chemin cité peut
    #    contenir des espaces : la branche guillemets le préserve. Le cas
    #    multi-mots (flatpak run ...) n'a pas à être traité ici, Flatpak et Snap
    #    étant déjà résolus aux étapes 2 et 3.
    local dir desktop exec_line first
    for dir in "$HOME/.local/share/applications" \
               "/usr/share/applications"; do
        for desktop in "$dir/org.kde.digikam.desktop" "$dir/digikam.desktop"; do
            [ -f "$desktop" ] || continue
            exec_line=$(grep -m1 '^Exec=' "$desktop" | sed 's/^Exec=//')
            [ -z "$exec_line" ] && continue
            if [[ "$exec_line" =~ ^\"([^\"]*)\" ]]; then
                DIGIKAM_CMD=("${BASH_REMATCH[1]}")
            else
                read -r first _ <<< "$exec_line"
                DIGIKAM_CMD=("$first")
            fi
            [ -n "${DIGIKAM_CMD[0]}" ] && return 0
        done
    done

    return 1
}

# Message « DigiKam introuvable » regroupé ici plutôt que dispersé dans les
# quatorze blocs de langue.
digikam_notfound_msg() {
    case "$LANG_CODE" in
        fr) echo "DigiKam est introuvable. Installez-le (paquet, Flatpak, Snap) ou intégrez son AppImage au menu des applications." ;;
        es) echo "No se encuentra DigiKam. Instálelo (paquete, Flatpak, Snap) o integre su AppImage en el menú de aplicaciones." ;;
        it) echo "DigiKam non è stato trovato. Installalo (pacchetto, Flatpak, Snap) o integra la sua AppImage nel menu delle applicazioni." ;;
        de) echo "DigiKam wurde nicht gefunden. Installieren Sie es (Paket, Flatpak, Snap) oder integrieren Sie das AppImage ins Anwendungsmenü." ;;
        pt) echo "DigiKam não foi encontrado. Instale-o (pacote, Flatpak, Snap) ou integre a sua AppImage no menu de aplicações." ;;
        nl) echo "DigiKam is niet gevonden. Installeer het (pakket, Flatpak, Snap) of voeg de AppImage toe aan het toepassingenmenu." ;;
        pl) echo "Nie znaleziono programu DigiKam. Zainstaluj go (pakiet, Flatpak, Snap) lub dodaj jego AppImage do menu aplikacji." ;;
        uk) echo "DigiKam не знайдено. Установіть його (пакунок, Flatpak, Snap) або додайте його AppImage до меню програм." ;;
        ru) echo "DigiKam не найден. Установите его (пакет, Flatpak, Snap) или добавьте его AppImage в меню приложений." ;;
        ja) echo "DigiKam が見つかりません。インストールする（パッケージ、Flatpak、Snap）か、AppImage をアプリケーションメニューに登録してください。" ;;
        zh) echo "未找到 DigiKam。请安装（软件包、Flatpak、Snap）或将其 AppImage 集成到应用程序菜单中。" ;;
        ko) echo "DigiKam을 찾을 수 없습니다. 설치하거나(패키지, Flatpak, Snap) AppImage를 응용 프로그램 메뉴에 등록하세요." ;;
        *)  echo "DigiKam was not found. Install it (package, Flatpak, Snap) or add its AppImage to the applications menu." ;;
    esac
}

# Lance DigiKam avec la commande résolue.
launch_digikam() {
    "${DIGIKAM_CMD[@]}" &
}

# DigiKam en cours d execution ? Il reecrit digikamrc en quittant, ce qui
# annulerait la bascule. On ne compte que le nom de processus exact et
# l AppImage, jamais ce script lui-meme.
digikam_running() {
    local pids
    pids=$( { pgrep -x digikam; pgrep -f 'digikam[^ ]*\.AppImage'; } 2>/dev/null \
            | grep -v "^$$\$" | sort -u )
    [ -n "$pids" ]
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
    UI=$(detect_ui)
    LANG_CODE=$(detect_lang)
    set_strings "$LANG_CODE"

    # DigiKam doit etre joignable pour que l'application ait un sens.
    if ! resolve_digikam; then
        ui_error "$(digikam_notfound_msg)"
        exit 1
    fi

    # Avertir si DigiKam tourne deja : sa fermeture ecraserait la bascule.
    if digikam_running; then
        if [ "$(ui_confirm "$L_RUNNING" "$L_TITLE")" != "yes" ]; then
            exit 0
        fi
    fi

    # Ouverture directe d'une bibliotheque passee en argument (chemin d'un
    # dossier .digikamlibrary), pour une action de gestionnaire de fichiers.
    if [ -n "$1" ]; then
        local target="${1%/}"
        if [ -f "$target/digikam4.db" ]; then
            update_digikamrc "$target"
            ui_notify "$L_NOTIF_ACTIVATED : $(library_name "$target")"
            launch_digikam
            exit 0
        else
            ui_warning "$L_ERR_INVALID"
            exit 1
        fi
    fi

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
        other_location=$(ui_choose_folder "$L_FILE_PROMPT")
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
        launch_digikam
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
        local full_path="$lib_location/$lib_name.digikamlibrary"

        if [ -f "$full_path/digikam4.db" ]; then
            ui_warning "$L_ERR_EXISTS"
            exit 1
        fi

        local confirm
        confirm=$(ui_confirm "$L_CONFIRM_MSG\n$full_path" "$L_CONFIRM_TITLE" \
                              "$L_BTN_CREATE" "$L_BTN_CANCEL")
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
            launch_digikam
            exit 0
        fi

        update_digikamrc "$chosen_path"
        ui_notify "$L_NOTIF_ACTIVATED : $chosen_name"
    fi

    launch_digikam
}

main "$@"
