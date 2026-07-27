# DigiKam Switch

**DigiKam Switch** est un gestionnaire de bibliothèques multiples pour [DigiKam](https://www.digikam.org/), disponible sur macOS et Linux.

DigiKam ne propose pas nativement de gestion de bibliothèques multiples (comme le fait l'application Photos d'Apple). DigiKam Switch comble ce manque avec une interface graphique simple : choisir la bibliothèque active, en créer une nouvelle, ou en localiser une existante — puis lancer DigiKam directement.

---

## Fonctionnalités

- Liste les bibliothèques DigiKam disponibles avec indication de la bibliothèque active
- Bascule vers une bibliothèque existante en un clic
- Crée une nouvelle bibliothèque à partir d'un template
- Localise une bibliothèque non répertoriée via un sélecteur de fichiers
- Interface entièrement localisée en 14 langues : français, anglais, espagnol, italien, allemand, portugais, néerlandais, polonais, ukrainien, russe, japonais, chinois simplifié, coréen
- Compatible macOS 10.9+ et Linux (KDE, GNOME, XFCE et autres)

---

## Structure du repo

```
digikam-switch/
├── README.md
├── digikam_template.zip       ← Base SQLite DigiKam vide (commune macOS/Linux)
├── macos/
│   ├── digikam_switch.sh      ← Script principal macOS
│   ├── DigiKam Switch.platypus ← Projet Platypus (ouvrir pour packager en .app)
│   └── screenshots/
│       └── platypus_config.png ← Capture de la configuration Platypus
└── linux/
    ├── digikam_switch_linux.sh ← Script principal Linux
    ├── digikam-switch.desktop  ← Entrée menu application
    └── install.sh              ← Script d'installation
```

---

## macOS

### Prérequis

- macOS 10.9 Mavericks ou supérieur
- [DigiKam](https://www.digikam.org/download/) installé dans `/Applications/digiKam.org/digikam.app`
- [Platypus](https://sveinbjorn.org/platypus) pour packager le script en application `.app`

### Installation

1. Cloner le repo ou télécharger l'archive
2. Ouvrir `macos/DigiKam Switch.platypus` dans Platypus
3. Dans **Bundled Files**, vérifier que `digikam_template.zip` est bien présent
4. Cliquer sur **Create App** et placer l'application où vous le souhaitez (Dock, `/Applications`, etc.)

### Configuration Platypus

Si vous préférez configurer Platypus manuellement :

| Paramètre | Valeur |
|-----------|--------|
| Script Type | bash |
| Script Path | `macos/digikam_switch.sh` |
| Interface | None |
| Run in background | ✓ |
| Remain running after completion | ✗ |
| Bundled Files | `digikam_template.zip` |
| App Name | DigiKam Switch |

![Configuration Platypus](macos/screenshots/platypus_config.png)

### Bibliothèques détectées automatiquement

Le script scanne les dossiers suivants à la recherche de `.photoslibrary` contenant un `digikam4.db` :

- `~/Pictures/Digikam/`
- `~/Pictures/`

Les bibliothèques sur des volumes externes ou à d'autres emplacements sont accessibles via **Autre emplacement...**.

---

## Linux

### Prérequis

- DigiKam installé et accessible via la commande `digikam`
- `kdialog` (KDE) ou `zenity` (GNOME/GTK) pour l'interface graphique
- `unzip` pour l'extraction du template

### Installation

```bash
git clone https://github.com/VOTRE_USERNAME/digikam-switch.git
cd digikam-switch
sudo bash linux/install.sh
```

Le script installe :
- `digikam_switch_linux.sh` dans `/usr/local/bin/`
- `digikam_template.zip` dans `/usr/local/share/digikam-switch/`
- `digikam-switch.desktop` dans `~/.local/share/applications/`

DigiKam Switch apparaît ensuite dans le menu d'applications sous **Graphisme → DigiKam Switch**.

### Interface graphique

Le script détecte automatiquement l'interface disponible dans cet ordre :

1. **kdialog** si le bureau est KDE ou LXQt et que kdialog est installé
2. **zenity** si disponible
3. **kdialog** sur tout autre bureau Qt
4. **Texte** dans le terminal en fallback

### Bibliothèques détectées automatiquement

- `~/.local/share/digikam/`
- `~/Pictures/`

---

## digikam_template.zip

Ce fichier contient une bibliothèque DigiKam vide initialisée (`digikam4.db`, `recognition.db`, `similarity.db`, `thumbnails-digikam.db`) utilisée comme base lors de la création de nouvelles bibliothèques.

Il est commun aux versions macOS et Linux. Si vous souhaitez le régénérer :

```bash
mkdir -p /tmp/Digikam.photoslibrary
digikam --database-directory /tmp/Digikam.photoslibrary
# Quitter DigiKam dès qu'il est lancé
cd /tmp
zip digikam_template.zip Digikam.photoslibrary/*.db
```

---

## Licence

GPL v3 — dans l'esprit du projet DigiKam.

## Auteur

Aymeric Gillaizeau — [OpenStreetMap M-Rick](https://www.openstreetmap.org/user/M-Rick)
