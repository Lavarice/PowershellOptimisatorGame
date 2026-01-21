# ---------------------------
# SCRIPT MODE JEU WINDOWS 11
# Désactive temporairement certains services Windows pendant que tu joues,
# puis les remet dans leur état d'origine à la fin.
# ---------------------------

param(
    [switch]$SansConfirmation  # Si présent, ne demande pas de confirmation avant d'arrêter les services
)

function Test-Admin {
    try {
        $id = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($id)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {
        return $false
    }
}

if (-not (Test-Admin)) {
    Write-Host "Ce script doit être lancé en tant qu'administrateur." -ForegroundColor Red
    Write-Host "Clique droit sur PowerShell puis 'Exécuter en tant qu'administrateur'." -ForegroundColor Yellow
    return
}

Write-Host "`n=== MODE JEU WINDOWS 11 ===" -ForegroundColor Cyan

# Liste des services à désactiver temporairement
$servicesToStop = @(
    # Windows Update et installation
    "wuauserv","msiserver","UsoSvc","BITS",
    # Télémétrie et collecte de données
    "DiagTrack","WerSvc","DPS",
    # Xbox (si pas utilisé)
    "XboxGipSvc","XblAuthManager","XblGameSave","XboxNetApiSvc",
    # Indexation et recherche
    "WSearch",
    # Imprimante et périphériques
    "Spooler","StiSvc","Fax","bthserv",
    # Cloud / OneDrive
    "OneSyncSvc",
    # Services UI / expérience utilisateur
    "WebClient","lfsvc","MapsBroker","WbioSrvc",
    # Machines virtuelles
    "vmcompute","vmms","HvHost"
)

# Vérifier et sauvegarder l'état actuel des services
$serviceStates = @{}
$foundServices = @()

foreach ($s in $servicesToStop) {
    $service = Get-Service -Name $s -ErrorAction SilentlyContinue
    if ($service) {
        $serviceStates[$s] = $service.Status
        $foundServices += $service
    }
}

if (-not $foundServices) {
    Write-Host "Aucun des services listés n'a été trouvé sur ce système." -ForegroundColor Yellow
    return
}

$runningServices = $foundServices | Where-Object { $_.Status -ne 'Stopped' }

Write-Host "Services détectés :" -ForegroundColor White
foreach ($svc in $foundServices) {
    $color = if ($svc.Status -eq 'Running') { 'Green' } else { 'DarkGray' }
    Write-Host " - $($svc.Name) : $($svc.Status)" -ForegroundColor $color
}

Write-Host "`nServices qui seront arrêtés (actuellement en cours d'exécution) : $($runningServices.Count)" -ForegroundColor Yellow

if ($runningServices.Count -eq 0) {
    Write-Host "Aucun service de la liste n'est actuellement en cours d'exécution. Rien à arrêter." -ForegroundColor Yellow
} else {
    if (-not $SansConfirmation) {
        $answer = Read-Host "Continuer et arrêter ces services ? (O/N)"
        if ($answer.ToUpper() -ne 'O') {
            Write-Host "Opération annulée par l'utilisateur." -ForegroundColor Yellow
            return
        }
    }

    # Désactivation des services
    Write-Host "`nDésactivation des services inutiles pour le jeu..." -ForegroundColor Cyan
    foreach ($svc in $runningServices) {
        try {
            Stop-Service -Name $svc.Name -Force -ErrorAction Stop
            Write-Host "$($svc.Name) arrêté" -ForegroundColor Green
        } catch {
            Write-Host "Impossible d'arrêter $($svc.Name) : $_" -ForegroundColor Red
        }
    }
}

Write-Host "`nMode jeu activé : services inutiles désactivés (autant que possible)." -ForegroundColor Green
Write-Host "Lance ton jeu, puis reviens ici une fois terminé." -ForegroundColor White
Read-Host "Appuie sur Entrée pour réactiver les services après le jeu..." | Out-Null

# Réactivation des services
Write-Host "`nRéactivation des services..." -ForegroundColor Cyan

foreach ($s in $serviceStates.Keys) {
    $statusAvant = $serviceStates[$s]
    if ($statusAvant -eq "Running") {
        try {
            Start-Service -Name $s -ErrorAction Stop
            Write-Host "$s réactivé" -ForegroundColor Green
        } catch {
            Write-Host "Impossible de réactiver $s : $_" -ForegroundColor Red
        }
    }
}

Write-Host "`nTous les services qui étaient actifs ont été réactivés. Bon jeu !" -ForegroundColor Magenta
