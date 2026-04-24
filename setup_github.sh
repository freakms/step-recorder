#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# setup_github.sh – Repo erstellen, pushen und GitHub Release anlegen
# Einmalig ausführen aus dem step-recorder Projektordner
# ─────────────────────────────────────────────────────────────────────────────

set -e

# ── Konfiguration ─────────────────────────────────────────────────────────────
REPO_NAME="step-recorder"
REPO_DESC="Desktop-App für Schritt-für-Schritt Anleitungen mit automatischen Screenshots"
REPO_PRIVATE=false          # true = privates Repo
VERSION="v1.0.0"
RELEASE_TITLE="Step Recorder v1.0.0"
RELEASE_NOTES="## Step Recorder v1.0.0

### Features
- 🎬 Bildschirm, Fenster oder Browser-Tab als Quelle wählen
- ✋ Manueller Modus: Screenshot per F9 oder Schaltfläche
- 🖱 Klick-Modus: Automatischer Screenshot bei jedem Mausklick
- 🎯 Smart-Modus: Klicks auf Step Recorder selbst werden ignoriert
- 📝 Bemerkungsfelder pro Screenshot
- 💾 Export als HTML und Markdown
- 🔍 Lightbox-Vorschau für Screenshots
- 🌙 Automatischer Dunkel-/Hellmodus

### Installation
\`\`\`bash
npm install
npm start
\`\`\`"

# ── GitHub Token abfragen ─────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║           Step Recorder – GitHub Setup                  ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "Du brauchst ein GitHub Personal Access Token (classic):"
echo "  → https://github.com/settings/tokens/new"
echo "  → Scopes: repo (alles unter repo anhaken)"
echo ""
read -rp "GitHub Token (ghp_...): " GITHUB_TOKEN
echo ""
read -rp "GitHub Benutzername: " GITHUB_USER
echo ""

if [ -z "$GITHUB_TOKEN" ] || [ -z "$GITHUB_USER" ]; then
  echo "❌ Token und Benutzername dürfen nicht leer sein."
  exit 1
fi

# ── Git initialisieren ────────────────────────────────────────────────────────
echo "▶ Git initialisieren..."
if [ ! -d ".git" ]; then
  git init
  echo "  ✓ Git repo initialisiert"
else
  echo "  ℹ .git existiert bereits – überspringe git init"
fi

# ── .gitignore erstellen ──────────────────────────────────────────────────────
if [ ! -f ".gitignore" ]; then
cat > .gitignore << 'GITIGNORE'
node_modules/
dist/
build/
*.log
.DS_Store
Thumbs.db
GITIGNORE
  echo "  ✓ .gitignore erstellt"
fi

# ── Ersten Commit machen ──────────────────────────────────────────────────────
echo ""
echo "▶ Dateien committen..."
git add -A
git commit -m "Initial commit: Step Recorder v1.0.0" 2>/dev/null || echo "  ℹ Nichts zu committen (bereits committed)"

# ── GitHub Repo erstellen via API ─────────────────────────────────────────────
echo ""
echo "▶ GitHub Repository erstellen..."
CREATE_RESPONSE=$(curl -s -w "\n%{http_code}" \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/user/repos \
  -d "{
    \"name\": \"$REPO_NAME\",
    \"description\": \"$REPO_DESC\",
    \"private\": $REPO_PRIVATE,
    \"auto_init\": false,
    \"has_issues\": true,
    \"has_wiki\": false
  }")

HTTP_CODE=$(echo "$CREATE_RESPONSE" | tail -n1)
BODY=$(echo "$CREATE_RESPONSE" | head -n -1)

if [ "$HTTP_CODE" = "201" ]; then
  REPO_URL="https://github.com/$GITHUB_USER/$REPO_NAME"
  echo "  ✓ Repository erstellt: $REPO_URL"
elif [ "$HTTP_CODE" = "422" ]; then
  echo "  ℹ Repository existiert bereits – verwende vorhandenes"
  REPO_URL="https://github.com/$GITHUB_USER/$REPO_NAME"
else
  echo "  ❌ Fehler beim Erstellen des Repos (HTTP $HTTP_CODE):"
  echo "$BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); print('  ', d.get('message','Unbekannter Fehler'))" 2>/dev/null || echo "$BODY"
  exit 1
fi

# ── Remote setzen und pushen ──────────────────────────────────────────────────
echo ""
echo "▶ Remote setzen und pushen..."
REMOTE_URL="https://$GITHUB_TOKEN@github.com/$GITHUB_USER/$REPO_NAME.git"

git remote remove origin 2>/dev/null || true
git remote add origin "$REMOTE_URL"

# Branch auf main setzen
git branch -M main

git push -u origin main
echo "  ✓ Code gepusht"

# ── Tag für Release erstellen ─────────────────────────────────────────────────
echo ""
echo "▶ Git-Tag $VERSION erstellen..."
git tag -a "$VERSION" -m "$RELEASE_TITLE" 2>/dev/null || echo "  ℹ Tag $VERSION existiert bereits"
git push origin "$VERSION" 2>/dev/null || echo "  ℹ Tag bereits auf Remote"
echo "  ✓ Tag $VERSION gepusht"

# ── GitHub Release erstellen ──────────────────────────────────────────────────
echo ""
echo "▶ GitHub Release erstellen..."

# Release Notes als JSON-sicheren String enkodieren
NOTES_JSON=$(echo "$RELEASE_NOTES" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))")

RELEASE_RESPONSE=$(curl -s -w "\n%{http_code}" \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/$GITHUB_USER/$REPO_NAME/releases" \
  -d "{
    \"tag_name\": \"$VERSION\",
    \"name\": \"$RELEASE_TITLE\",
    \"body\": $NOTES_JSON,
    \"draft\": false,
    \"prerelease\": false
  }")

RELEASE_HTTP=$(echo "$RELEASE_RESPONSE" | tail -n1)
RELEASE_BODY=$(echo "$RELEASE_RESPONSE" | head -n -1)

if [ "$RELEASE_HTTP" = "201" ]; then
  RELEASE_URL=$(echo "$RELEASE_BODY" | python3 -c "import sys,json; print(json.load(sys.stdin)['html_url'])" 2>/dev/null || echo "URL nicht parsbar")
  echo "  ✓ Release erstellt: $RELEASE_URL"
else
  echo "  ⚠ Release konnte nicht erstellt werden (HTTP $RELEASE_HTTP)"
  echo "$RELEASE_BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); print('  ', d.get('message',''))" 2>/dev/null || true
fi

# ── Fertig ────────────────────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  ✅ Fertig!                                              ║"
echo "╠══════════════════════════════════════════════════════════╣"
printf "║  Repo:    %-47s║\n" "$REPO_URL"
printf "║  Release: %-47s║\n" "$REPO_URL/releases"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "Remote-URL (ohne Token) für spätere Nutzung:"
echo "  https://github.com/$GITHUB_USER/$REPO_NAME.git"
echo ""
