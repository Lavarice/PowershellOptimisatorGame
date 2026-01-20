<#
 Script d'optimisation CPU / GPU pour un jeu
 - Force un mode d'alimentation haute performance
 - Désactive le Core Parking
 - Peut associer le GPU haute performance à un exécutable
 - Ne lance PAS le jeu, mais restaure les paramètres après ta session
#>

#requires -RunAsAdministrator

param(
	[string]$GamePath
)

Write-Host "=== Optimisation CPU / GPU pour le jeu ===" -ForegroundColor Cyan

# Récupérer le GUID du plan d'alimentation actif
$activeSchemeRaw = powercfg -getactivescheme 2>$null
if (-not $activeSchemeRaw) {
	Write-Warning "Impossible de récupérer le plan d'alimentation actif. Certaines optimisations seront ignorées."
}

$activeScheme = $null
if ($activeSchemeRaw) {
	$activeScheme = ([regex]::Match($activeSchemeRaw, 'GUID:\s*([a-f0-9-]+)', 'IgnoreCase')).Groups[1].Value
}

# Tenter d'activer un plan "Ultimate Performance" ou "High performance" si disponible
$targetScheme = $activeScheme
$powercfgList = powercfg -list 2>$null
if ($powercfgList) {
	$ultimateLine = $powercfgList | Select-String -Pattern 'Ultimate Performance' -SimpleMatch
	$highPerfLine = $powercfgList | Select-String -Pattern 'High performance' -SimpleMatch

	if ($ultimateLine) {
		$targetScheme = ([regex]::Match($ultimateLine.ToString(), 'GUID:\s*([a-f0-9-]+)', 'IgnoreCase')).Groups[1].Value
	} elseif ($highPerfLine) {
		$targetScheme = ([regex]::Match($highPerfLine.ToString(), 'GUID:\s*([a-f0-9-]+)', 'IgnoreCase')).Groups[1].Value
	}
}

$schemeChanged = $false
if ($activeScheme -and $targetScheme -and ($targetScheme -ne $activeScheme)) {
	powercfg -setactive $targetScheme 2>$null
	if ($LASTEXITCODE -eq 0) {
		$schemeChanged = $true
		Write-Host "Plan d'alimentation haute performance activé." -ForegroundColor Green
	} else {
		Write-Warning "Échec de l'activation du plan d'alimentation haute performance."
	}
} else {
	Write-Host "Plan d'alimentation actuel conservé (aucun meilleur plan détecté)."
}

# Désactiver le Core Parking pour tous les cœurs (paramètre global)
try {
	$coreParkingKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\be337238-0d82-4146-a960-4f3749d470c7"
	if (Test-Path -LiteralPath $coreParkingKey) {
		Set-ItemProperty -Path $coreParkingKey -Name "ACSettingIndex" -Value 0 -ErrorAction Stop
		Set-ItemProperty -Path $coreParkingKey -Name "DCSettingIndex" -Value 0 -ErrorAction Stop
		Write-Host "Core Parking désactivé pour tous les cœurs (AC/DC)." -ForegroundColor Green
	} else {
		Write-Warning "Clé de Core Parking introuvable, impossible de modifier ce paramètre sur ce système."
	}
} catch {
	Write-Warning "Erreur lors de la désactivation du Core Parking : $($_.Exception.Message)"
}

# Forcer le GPU haute performance pour l'exécutable du jeu (optionnel)
if ($GamePath) {
	try {
		if (Test-Path -LiteralPath $GamePath) {
			$gpuPrefKey = "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences"
			if (-not (Test-Path -LiteralPath $gpuPrefKey)) {
				New-Item -Path $gpuPrefKey -Force | Out-Null
			}

			New-ItemProperty -Path $gpuPrefKey -Name $GamePath -PropertyType String -Value "GpuPreference=2" -Force | Out-Null
			Write-Host "Préférence GPU haute performance définie pour : $GamePath" -ForegroundColor Green
		} else {
			Write-Warning "Chemin de jeu introuvable, la configuration GPU est ignorée : $GamePath"
		}
	} catch {
		Write-Warning "Erreur lors de la configuration de la préférence GPU : $($_.Exception.Message)"
	}
} else {
	Write-Host "Aucun chemin de jeu fourni, configuration GPU non modifiée." -ForegroundColor Yellow
}

# Sauvegarder certains réglages visuels pour les restaurer ensuite
$personalizeKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
$desktopKey    = "HKCU:\Control Panel\Desktop"

$originalTransparency = $null
$originalUPM          = $null

try {
	if (Test-Path -LiteralPath $personalizeKey) {
		$origPerso = Get-ItemProperty -Path $personalizeKey -Name "EnableTransparency" -ErrorAction SilentlyContinue
		$originalTransparency = $origPerso.EnableTransparency
	}

	if (Test-Path -LiteralPath $desktopKey) {
		$origDesk = Get-ItemProperty -Path $desktopKey -Name "UserPreferencesMask" -ErrorAction SilentlyContinue
		$originalUPM = $origDesk.UserPreferencesMask
	}
} catch {
	Write-Warning "Impossible de lire les paramètres visuels d'origine : $($_.Exception.Message)"
}

try {
	if (Test-Path -LiteralPath $personalizeKey) {
		Set-ItemProperty -Path $personalizeKey -Name "EnableTransparency" -Value 0 -ErrorAction SilentlyContinue
	}

	if (Test-Path -LiteralPath $desktopKey) {
		# Valeur courante typique pour réduire certains effets visuels
		Set-ItemProperty -Path $desktopKey -Name "UserPreferencesMask" -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) -ErrorAction SilentlyContinue
	}

	Write-Host "Effets visuels réduits pour améliorer les performances." -ForegroundColor Green
} catch {
	Write-Warning "Erreur lors de la modification des effets visuels : $($_.Exception.Message)"
}

# Vider la mémoire managée (utile seulement pour les processus .NET, impact limité)
[void][System.GC]::Collect()
[void][System.GC]::WaitForPendingFinalizers()

Write-Host "Paramètres d'optimisation appliqués." -ForegroundColor Cyan

if ($GamePath) {
	Write-Host "Vous pouvez maintenant lancer votre jeu associé à ce chemin :" -ForegroundColor Gray
	Write-Host "  $GamePath" -ForegroundColor Gray
} else {
	Write-Host "Vous pouvez maintenant lancer votre jeu (aucun chemin spécifique fourni)." -ForegroundColor Gray
}

[void](Read-Host "Appuyez sur Entrée après votre session de jeu pour restaurer les paramètres")

Write-Host "Restauration des paramètres d'origine..." -ForegroundColor Cyan

# Restaurer le plan d'alimentation d'origine
if ($schemeChanged -and $activeScheme) {
	try {
		powercfg -setactive $activeScheme 2>$null
		if ($LASTEXITCODE -eq 0) {
			Write-Host "Plan d'alimentation d'origine restauré." -ForegroundColor Green
		} else {
			Write-Warning "Impossible de restaurer le plan d'alimentation d'origine."
		}
	} catch {
		Write-Warning "Erreur lors de la restauration du plan d'alimentation : $($_.Exception.Message)"
	}
}

# Restaurer les paramètres visuels
try {
	if ($null -ne $originalTransparency -and (Test-Path -LiteralPath $personalizeKey)) {
		Set-ItemProperty -Path $personalizeKey -Name "EnableTransparency" -Value $originalTransparency -ErrorAction SilentlyContinue
	}

	if ($null -ne $originalUPM -and (Test-Path -LiteralPath $desktopKey)) {
		Set-ItemProperty -Path $desktopKey -Name "UserPreferencesMask" -Value $originalUPM -ErrorAction SilentlyContinue
	}
} catch {
	Write-Warning "Erreur lors de la restauration des paramètres visuels : $($_.Exception.Message)"
}

Write-Host "Optimisation terminée. Bon jeu !" -ForegroundColor Cyan




