# ─────────────────────────────────────────────────────────────────────────────
# setup_github.ps1 – Repo erstellen, pushen und ersten Release anlegen
# Einmalig ausführen aus dem step-recorder Projektordner
# ─────────────────────────────────────────────────────────────────────────────

$ErrorActionPreference = "Stop"

$RepoName    = "step-recorder"
$RepoDesc    = "Desktop-App fuer Schritt-fuer-Schritt Anleitungen mit automatischen Screenshots"
$RepoPrivate = "false"
$Version     = "v1.0.0"

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║           Step Recorder – GitHub Setup                  ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "Du brauchst ein GitHub Personal Access Token (classic):"
Write-Host "  → https://github.com/settings/tokens/new"
Write-Host "  → Scopes: repo (alles unter repo anhaken)"
Write-Host ""

$GitHubToken = Read-Host "GitHub Token (ghp_...)"
$GitHubUser  = Read-Host "GitHub Benutzername"

if (-not $GitHubToken -or -not $GitHubUser) {
    Write-Host "❌ Token und Benutzername dürfen nicht leer sein." -ForegroundColor Red
    exit 1
}

$Headers = @{
    "Authorization" = "token $GitHubToken"
    "Accept"        = "application/vnd.github.v3+json"
    "User-Agent"    = "step-recorder-setup"
}

# ── .gitignore ────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "▶ .gitignore erstellen..." -ForegroundColor Cyan
if (-not (Test-Path ".gitignore")) {
@"
node_modules/
dist/
build/
*.log
.DS_Store
Thumbs.db
"@ | Set-Content ".gitignore" -Encoding UTF8
    Write-Host "  ✓ .gitignore erstellt" -ForegroundColor Green
} else {
    Write-Host "  ℹ .gitignore existiert bereits" -ForegroundColor Gray
}

# ── Git init ──────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "▶ Git initialisieren..." -ForegroundColor Cyan
if (-not (Test-Path ".git")) {
    git init
    Write-Host "  ✓ Git repo initialisiert" -ForegroundColor Green
} else {
    Write-Host "  ℹ .git existiert bereits" -ForegroundColor Gray
}

git add -A
try {
    git commit -m "Initial commit: Step Recorder $Version"
    Write-Host "  ✓ Initial commit" -ForegroundColor Green
} catch {
    Write-Host "  ℹ Nichts zu committen" -ForegroundColor Gray
}

# ── GitHub Repo erstellen ─────────────────────────────────────────────────────
Write-Host ""
Write-Host "▶ GitHub Repository erstellen..." -ForegroundColor Cyan

$Body = @{
    name        = $RepoName
    description = $RepoDesc
    private     = ($RepoPrivate -eq "true")
    auto_init   = $false
    has_issues  = $true
    has_wiki    = $false
} | ConvertTo-Json

try {
    $Response = Invoke-RestMethod -Uri "https://api.github.com/user/repos" `
        -Method Post -Headers $Headers -Body $Body -ContentType "application/json"
    Write-Host "  ✓ Repository erstellt: https://github.com/$GitHubUser/$RepoName" -ForegroundColor Green
} catch {
    $StatusCode = $_.Exception.Response.StatusCode.value__
    if ($StatusCode -eq 422) {
        Write-Host "  ℹ Repository existiert bereits – verwende vorhandenes" -ForegroundColor Yellow
    } else {
        Write-Host "  ❌ Fehler: $_" -ForegroundColor Red
        exit 1
    }
}

# ── Remote setzen und pushen ──────────────────────────────────────────────────
Write-Host ""
Write-Host "▶ Remote setzen und pushen..." -ForegroundColor Cyan

$RemoteUrl = "https://$GitHubToken@github.com/$GitHubUser/$RepoName.git"
try { git remote remove origin 2>$null } catch {}
git remote add origin $RemoteUrl
git branch -M main
git push -u origin main
Write-Host "  ✓ Code gepusht" -ForegroundColor Green

# ── Tag pushen → GitHub Actions startet ──────────────────────────────────────
Write-Host ""
Write-Host "▶ Tag $Version setzen → startet GitHub Actions Build..." -ForegroundColor Cyan
try {
    git tag -a $Version -m "Initial release $Version"
} catch {
    Write-Host "  ℹ Tag existiert bereits" -ForegroundColor Gray
}
git push origin $Version
Write-Host "  ✓ Tag gepusht – GitHub Actions baut jetzt .exe/.dmg/.AppImage" -ForegroundColor Green

# ── Fertig ────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  ✅ Fertig!                                              ║" -ForegroundColor Green
Write-Host "╠══════════════════════════════════════════════════════════╣" -ForegroundColor Green
Write-Host "║  Repo:    https://github.com/$GitHubUser/$RepoName" -ForegroundColor Green
Write-Host "║  Actions: https://github.com/$GitHubUser/$RepoName/actions" -ForegroundColor Green
Write-Host "║  Release: https://github.com/$GitHubUser/$RepoName/releases" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "In ~5-10 Minuten sind .exe, .dmg und .AppImage fertig gebaut." -ForegroundColor Cyan
Write-Host ""
