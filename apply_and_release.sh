#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# apply_and_release.sh – Dateien anwenden, committen, pushen → GitHub baut .exe/.dmg/.AppImage
# Nutzung: ./apply_and_release.sh v1.1.0 "Was hat sich geändert"
# ─────────────────────────────────────────────────────────────────────────────

set -e

VERSION="${1:-}"
COMMIT_MSG="${2:-"Update"}"

if [ -z "$VERSION" ]; then
  echo "Nutzung: ./apply_and_release.sh v1.1.0 \"Was hat sich geändert\""
  exit 1
fi

echo ""
echo "▶ Dateien aus _fixes/ anwenden (falls vorhanden)..."
if [ -d "_fixes" ] && [ "$(ls -A _fixes 2>/dev/null)" ]; then
  for f in _fixes/*; do
    fname=$(basename "$f")
    case "$fname" in
      main.js|preload.js|index.html|overlay.html)
        cp "$f" "src/$fname" && echo "  ✓ src/$fname" ;;
      package.json|README.md|*.yml|*.yaml)
        cp "$f" "$fname" && echo "  ✓ $fname" ;;
      *)
        echo "  ℹ $fname – überspringe" ;;
    esac
  done
else
  echo "  ℹ Kein _fixes/-Ordner oder leer"
fi

echo ""
echo "▶ git add & commit..."
git add -A
git commit -m "$COMMIT_MSG" || echo "  ℹ Nichts zu committen"

echo ""
echo "▶ pushen..."
git push origin main

echo ""
echo "▶ Tag $VERSION setzen und pushen → startet GitHub Actions Build..."
git tag -a "$VERSION" -m "$VERSION: $COMMIT_MSG"
git push origin "$VERSION"

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  ✅ Tag $VERSION gepusht!                               ║"
echo "║                                                          ║"
echo "║  GitHub Actions baut jetzt automatisch:                  ║"
echo "║    🪟 Windows  →  .exe Installer                        ║"
echo "║    🍎 macOS    →  .dmg Disk Image                       ║"
echo "║    🐧 Linux    →  .AppImage                             ║"
echo "║                                                          ║"
echo "║  Status: https://github.com/$(git remote get-url origin | sed 's|.*github.com[:/]\([^/]*/[^.]*\).*|\1|')/actions  ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
