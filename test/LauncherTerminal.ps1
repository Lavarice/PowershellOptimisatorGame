Clear-Host

function Show-Header {
    Clear-Host
    $user = $env:USERNAME
    $pc   = $env:COMPUTERNAME
    $time = Get-Date -Format "HH:mm:ss"

    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host "   LANCEUR TERMINAL - POWERSHELLOPTIMISATOR  " -ForegroundColor Cyan
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host "Utilisateur : $user @ $pc" -ForegroundColor DarkCyan
    Write-Host "Heure      : $time" -ForegroundColor DarkCyan
    Write-Host "" 
}

function Pause-Enter {
    Write-Host "" 
    Read-Host "Appuie sur Entrée pour continuer" | Out-Null
}

function Launch-IfExists {
    param(
        [string]$Path,
        [string]$Name
    )

    if (Test-Path $Path) {
        Start-Process $Path
        Write-Host "Lancement de $Name ..." -ForegroundColor Green
    }
    else {
        Write-Host "Chemin introuvable pour $Name :" -ForegroundColor Red
        Write-Host "  $Path" -ForegroundColor DarkRed
    }
}

# TODO: adapte ces chemins à ton installation réelle
$Apps = @{
    "Steam"   = "C:\\Program Files (x86)\\Steam\\Steam.exe";
    "Discord" = "C:\\Users\\$env:USERNAME\\AppData\\Local\\Discord\\Update.exe";
    "Edge"    = "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe";
}

function Show-Menu {
    Show-Header
    Write-Host "1. Activer le MODE JEU (scriptJeux.ps1)" -ForegroundColor Yellow
    Write-Host "2. Lancer Steam" -ForegroundColor White
    Write-Host "3. Lancer Discord" -ForegroundColor White
    Write-Host "4. Lancer le navigateur (Edge)" -ForegroundColor White
    Write-Host "5. Lancer l'explorateur de fichiers" -ForegroundColor White
    Write-Host "6. Lancer un jeu / programme par chemin" -ForegroundColor White
    Write-Host "Q. Quitter le lanceur" -ForegroundColor Magenta
    Write-Host "" 
}

# Boucle principale
while ($true) {
    Show-Menu
    $choice = Read-Host "Choisis une option"

    switch ($choice.ToUpper()) {
        "1" {
            # Mode jeu (nécessite d'être admin)
            $scriptPath = Join-Path $PSScriptRoot "scriptJeux.ps1"
            if (Test-Path $scriptPath) {
                Write-Host "Ouverture du MODE JEU..." -ForegroundColor Yellow
                # On ouvre dans une nouvelle fenêtre pour garder le lanceur ouvert
                Start-Process powershell -ArgumentList "-NoExit -File `"$scriptPath`""
            }
            else {
                Write-Host "scriptJeux.ps1 introuvable dans le même dossier que ce lanceur." -ForegroundColor Red
            }
            Pause-Enter
        }
        "2" {
            Launch-IfExists -Path $Apps["Steam"] -Name "Steam"
            Pause-Enter
        }
        "3" {
            Launch-IfExists -Path $Apps["Discord"] -Name "Discord"
            Pause-Enter
        }
        "4" {
            Launch-IfExists -Path $Apps["Edge"] -Name "Microsoft Edge"
            Pause-Enter
        }
        "5" {
            Start-Process "explorer.exe"
            Write-Host "Explorateur Windows lancé." -ForegroundColor Green
            Pause-Enter
        }
        "6" {
            Write-Host "Entre le chemin complet du .exe (ex : C:\\Jeux\\MonJeu\\Game.exe)" -ForegroundColor White
            $exePath = Read-Host "Chemin du programme"
            if (-not [string]::IsNullOrWhiteSpace($exePath)) {
                Launch-IfExists -Path $exePath -Name $exePath
            }
            Pause-Enter
        }
        "Q" {
            Write-Host "Fermeture du lanceur. A bientôt !" -ForegroundColor Cyan
            break
        }
        default {
            Write-Host "Choix invalide." -ForegroundColor Red
            Pause-Enter
        }
    }
}
