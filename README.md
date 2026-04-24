# Step Recorder

> by freakms – ich schwöre feierlich ich bin ein tunichtgut

Schritt-für-Schritt Anleitungen mit automatischen Screenshots erstellen.
Wie der Windows Steps Recorder – aber mit Bemerkungsfeldern, Quellauswahl und HTML/Markdown-Export.

---

## Features

- **Quelle wählen**: Einzelnes Fenster, Browser-Tab oder bestimmter Monitor – kein Zwang zum Vollbildschirm
- **F9 Global Shortcut**: Screenshot jederzeit, auch wenn Step Recorder im Hintergrund läuft
- **Bemerkungsfelder**: Pro Screenshot ein editierbares Textfeld für Beschreibungen
- **Schritttitel editieren**: Klicke direkt auf den Schrittnamen und bearbeite ihn
- **Reihung per Drag**: Schritte nachträglich neu sortieren
- **Export als HTML**: Professionelle Anleitung mit eingebetteten Screenshots
- **Export als Markdown**: Für Wikis, Notion, GitHub etc.
- **Lightbox**: Screenshots per Klick vergrößern
- **Dunkelmodus**: Folgt automatisch dem System

---

## Installation & Start (Entwicklung)

### Voraussetzungen
- [Node.js](https://nodejs.org) ab Version 18
- npm (kommt mit Node.js)

### Schritte

```bash
# 1. In den Projektordner wechseln
cd step-recorder

# 2. Abhängigkeiten installieren
npm install

# 3. App starten
npm start
```

---

## App als .exe / .dmg bauen (Distribution)

```bash
# Windows (.exe Installer)
npm run build:win

# macOS (.dmg)
npm run build:mac

# Linux (.AppImage)
npm run build:linux
```

Die fertigen Installer landen im `dist/` Ordner.

### Windows-Hinweis
Für den Build unter Windows brauchst du zusätzlich:
```
npm install --save-dev electron-builder
```
Beim ersten Build werden Visual C++ Build Tools benötigt (automatischer Hinweis von npm).

---

## Bedienung

1. **Quelle wählen & aufnehmen** klicken
2. Fenster, Tab oder Monitor aus der Übersicht auswählen
3. In das aufgezeichnete Fenster wechseln und arbeiten
4. **F9** drücken (oder Button) für einen Screenshot-Schritt
5. **Aufnahme beenden** klicken
6. Für jeden Schritt eine Bemerkung eingeben
7. Als **HTML** oder **Markdown** exportieren

---

## Projektstruktur

```
step-recorder/
├── src/
│   ├── main.js        – Electron Hauptprozess
│   ├── preload.js     – Sicherer IPC-Bridge
│   ├── index.html     – Haupt-UI (Renderer)
│   └── overlay.html   – Transparenter Aufnahme-Indikator
├── assets/
│   ├── icon.png       – App-Icon (512x512 PNG)
│   ├── icon.ico       – Windows Icon
│   └── icon.icns      – macOS Icon
├── package.json
└── README.md
```

---

## Icon erstellen (optional)

Lege eine `assets/icon.png` (512×512 px) ab.
Für Windows: `icon.ico` (kann aus PNG konvertiert werden mit https://convertio.co)
Für macOS: `icon.icns` (mit `sips` oder `iconutil` auf macOS)

Ohne Icons funktioniert die App trotzdem – Electron nutzt dann ein Standard-Icon.

---

## Lizenz

MIT
