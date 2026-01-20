<#
 Script d'optimisation CPU / GPU pour un jeu
 - Force un mode d'alimentation haute performance
 - Désactive le Core Parking
 - Peut associer le GPU haute performance à un exécutable
 - Ne lance PAS le jeu, mais restaure les paramètres après ta session
#>

#requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess = $true)]
param(
	[string]$GamePath,
	[ValidateSet('Idle','BelowNormal','Normal','AboveNormal','High','Realtime')]
	[string]$GameProcessPriority = 'High',
	[Nullable[long]]$GameAffinityMask
)

Write-Host "=== Optimisation CPU / GPU pour le jeu ===" -ForegroundColor Cyan

# Variables pour la restauration ultérieure
$coreParkingKey        = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\be337238-0d82-4146-a960-4f3749d470c7"
$originalCoreParkingAC = $null
$originalCoreParkingDC = $null

$gpuPrefKey              = "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences"
$originalGpuPreference   = $null
$gpuPreferenceExisted    = $false

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
	if ($PSCmdlet.ShouldProcess("Plan d'alimentation $targetScheme", "Activer un plan d'alimentation haute performance")) {
		powercfg -setactive $targetScheme 2>$null
		if ($LASTEXITCODE -eq 0) {
			$schemeChanged = $true
			Write-Host "Plan d'alimentation haute performance activé." -ForegroundColor Green
		} else {
			Write-Warning "Échec de l'activation du plan d'alimentation haute performance."
		}
	}
} else {
	Write-Host "Plan d'alimentation actuel conservé (aucun meilleur plan détecté)."
}

# Désactiver le Core Parking pour tous les cœurs (paramètre global)
try {
	if (Test-Path -LiteralPath $coreParkingKey) {
		$coreParkingProps = Get-ItemProperty -Path $coreParkingKey -Name "ACSettingIndex","DCSettingIndex" -ErrorAction SilentlyContinue
		if ($coreParkingProps) {
			$originalCoreParkingAC = $coreParkingProps.ACSettingIndex
			$originalCoreParkingDC = $coreParkingProps.DCSettingIndex
		}

		if ($PSCmdlet.ShouldProcess("Core Parking (AC/DC)", "Désactiver le Core Parking")) {
			Set-ItemProperty -Path $coreParkingKey -Name "ACSettingIndex" -Value 0 -ErrorAction Stop
			Set-ItemProperty -Path $coreParkingKey -Name "DCSettingIndex" -Value 0 -ErrorAction Stop
			Write-Host "Core Parking désactivé pour tous les cœurs (AC/DC)." -ForegroundColor Green
		}
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
			if (-not (Test-Path -LiteralPath $gpuPrefKey)) {
				New-Item -Path $gpuPrefKey -Force | Out-Null
			}

			# Sauvegarder la valeur existante pour pouvoir la restaurer plus tard
			$existingGpu = Get-ItemProperty -Path $gpuPrefKey -Name $GamePath -ErrorAction SilentlyContinue
			if ($existingGpu) {
				$originalGpuPreference = $existingGpu.$GamePath
				$gpuPreferenceExisted  = $true
			}

			if ($PSCmdlet.ShouldProcess($GamePath, "Définir la préférence GPU haute performance")) {
				New-ItemProperty -Path $gpuPrefKey -Name $GamePath -PropertyType String -Value "GpuPreference=2" -Force | Out-Null
				Write-Host "Préférence GPU haute performance définie pour : $GamePath" -ForegroundColor Green
			}
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

$gameSessionHandled = $false

if ($GamePath -and (Test-Path -LiteralPath $GamePath)) {
	try {
		if ($PSCmdlet.ShouldProcess($GamePath, "Lancer le jeu et ajuster le processus")) {
			$startInfo = New-Object System.Diagnostics.ProcessStartInfo
			$startInfo.FileName = $GamePath
			$startInfo.UseShellExecute = $true

			$process = [System.Diagnostics.Process]::Start($startInfo)
			if ($process) {
				try {
					$process.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::$GameProcessPriority
					Write-Host "Priorité du processus du jeu définie sur : $GameProcessPriority" -ForegroundColor Green
				} catch {
					Write-Warning "Impossible de définir la priorité du processus : $($_.Exception.Message)"
				}

				if ($null -ne $GameAffinityMask) {
					try {
						$process.ProcessorAffinity = [Int64]$GameAffinityMask
						Write-Host "Affinité CPU du jeu définie sur le masque : $GameAffinityMask" -ForegroundColor Green
					} catch {
						Write-Warning "Impossible de définir l'affinité CPU : $($_.Exception.Message)"
					}
				}

				Write-Host "Jeu lancé. En attente de la fin du processus..." -ForegroundColor Cyan
				$process.WaitForExit()
				$gameSessionHandled = $true
			}
		}
	} catch {
		Write-Warning "Erreur lors du lancement ou du suivi du jeu : $($_.Exception.Message)"
	}
}

if (-not $gameSessionHandled) {
	if ($GamePath) {
		Write-Host "Vous pouvez maintenant lancer votre jeu associé à ce chemin :" -ForegroundColor Gray
		Write-Host "  $GamePath" -ForegroundColor Gray
	} else {
		Write-Host "Vous pouvez maintenant lancer votre jeu (aucun chemin spécifique fourni)." -ForegroundColor Gray
	}

	[void](Read-Host "Appuyez sur Entrée après votre session de jeu pour restaurer les paramètres")
}

Write-Host "Restauration des paramètres d'origine..." -ForegroundColor Cyan

# Restaurer le plan d'alimentation d'origine
if ($schemeChanged -and $activeScheme) {
	try {
		if ($PSCmdlet.ShouldProcess("Plan d'alimentation $activeScheme", "Restaurer le plan d'alimentation d'origine")) {
			powercfg -setactive $activeScheme 2>$null
			if ($LASTEXITCODE -eq 0) {
				Write-Host "Plan d'alimentation d'origine restauré." -ForegroundColor Green
			} else {
				Write-Warning "Impossible de restaurer le plan d'alimentation d'origine."
			}
		}
	} catch {
		Write-Warning "Erreur lors de la restauration du plan d'alimentation : $($_.Exception.Message)"
	}
}

# Restaurer le Core Parking si les valeurs d'origine sont connues
try {
	if ((Test-Path -LiteralPath $coreParkingKey) -and ($null -ne $originalCoreParkingAC -or $null -ne $originalCoreParkingDC)) {
		if ($PSCmdlet.ShouldProcess("Core Parking (AC/DC)", "Restaurer les paramètres d'origine")) {
			if ($null -ne $originalCoreParkingAC) {
				Set-ItemProperty -Path $coreParkingKey -Name "ACSettingIndex" -Value $originalCoreParkingAC -ErrorAction SilentlyContinue
			}
			if ($null -ne $originalCoreParkingDC) {
				Set-ItemProperty -Path $coreParkingKey -Name "DCSettingIndex" -Value $originalCoreParkingDC -ErrorAction SilentlyContinue
			}
		}
	}
} catch {
	Write-Warning "Erreur lors de la restauration du Core Parking : $($_.Exception.Message)"
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

# Restaurer la préférence GPU si elle a été modifiée
if ($GamePath -and (Test-Path -LiteralPath $gpuPrefKey)) {
	try {
		if ($gpuPreferenceExisted -and $null -ne $originalGpuPreference) {
			if ($PSCmdlet.ShouldProcess($GamePath, "Restaurer la préférence GPU d'origine")) {
				New-ItemProperty -Path $gpuPrefKey -Name $GamePath -PropertyType String -Value $originalGpuPreference -Force | Out-Null
			}
		} else {
			if ($PSCmdlet.ShouldProcess($GamePath, "Retirer la préférence GPU temporaire")) {
				Remove-ItemProperty -Path $gpuPrefKey -Name $GamePath -ErrorAction SilentlyContinue
			}
		}
	} catch {
		Write-Warning "Erreur lors de la restauration de la préférence GPU : $($_.Exception.Message)"
	}
}

Write-Host "Optimisation terminée. Bon jeu !" -ForegroundColor Cyan




