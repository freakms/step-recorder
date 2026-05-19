# apply_and_release.ps1
# Nutzung: .\apply_and_release.ps1 -Version v1.1.0 -Message "Was hat sich geändert"

param(
    [Parameter(Mandatory=$true)]
    [string]$Version,

    [Parameter(Mandatory=$false)]
    [string]$Message = "Update"
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host ">>> Dateien aus _fixes\ anwenden (falls vorhanden)..." -ForegroundColor Cyan

if (Test-Path "_fixes") {
    $fixes = Get-ChildItem "_fixes" -File
    if ($fixes.Count -gt 0) {
        foreach ($f in $fixes) {
            switch ($f.Name) {
                { $_ -in "main.js","preload.js","index.html","overlay.html" } {
                    Copy-Item $f.FullName "src\$($f.Name)" -Force
                    Write-Host "  OK src\$($f.Name)" -ForegroundColor Green
                }
                { $_ -in "package.json","README.md" } {
                    Copy-Item $f.FullName $f.Name -Force
                    Write-Host "  OK $($f.Name)" -ForegroundColor Green
                }
                default {
                    Write-Host "  -- $($f.Name) ueberspringe" -ForegroundColor Gray
                }
            }
        }
    } else {
        Write-Host "  _fixes\ ist leer" -ForegroundColor Gray
    }
} else {
    Write-Host "  Kein _fixes\ Ordner" -ForegroundColor Gray
}

Write-Host ""
Write-Host ">>> git add und commit..." -ForegroundColor Cyan
git add -A
try {
    git commit -m $Message
} catch {
    Write-Host "  Nichts zu committen" -ForegroundColor Gray
}

Write-Host ""
Write-Host ">>> pushen..." -ForegroundColor Cyan
git push origin main

Write-Host ""
Write-Host ">>> Tag $Version setzen und pushen..." -ForegroundColor Cyan
git tag -a $Version -m "${Version}: $Message"
git push origin $Version

$remoteUrl = git remote get-url origin
$repoPath = $remoteUrl -replace ".*github\.com[:/]([^/]+/[^.]+)(\.git)?.*", '$1'

Write-Host ""
Write-Host "======================================" -ForegroundColor Green
Write-Host "  OK - Tag $Version gepusht!" -ForegroundColor Green
Write-Host "  GitHub baut jetzt automatisch:" -ForegroundColor Green
Write-Host "    Windows  -> .exe (portable)" -ForegroundColor Green
Write-Host "    macOS    -> .dmg" -ForegroundColor Green
Write-Host "    Linux    -> .AppImage" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host ""
Write-Host "Actions:  https://github.com/$repoPath/actions" -ForegroundColor Cyan
Write-Host "Release:  https://github.com/$repoPath/releases/tag/$Version" -ForegroundColor Cyan
Write-Host ""
