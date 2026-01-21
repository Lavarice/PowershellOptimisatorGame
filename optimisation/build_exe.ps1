<#
Builds UltimeOptimiser.exe from UltimeOptimiser.ps1 using ps2exe.
Run in PowerShell (user scope is enough):
  pwsh -File .\build_exe.ps1
You can override output path:
  pwsh -File .\build_exe.ps1 -OutputPath "C:\\temp\\UltimeOptimiser.exe"
#>

[CmdletBinding()]
param(
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSCommandPath
$inputFile = Join-Path $root 'UltimeOptimiser.ps1'
if (-not $OutputPath) {
    $OutputPath = Join-Path $root 'UltimeOptimiser.exe'
}

Write-Host "Packaging $inputFile -> $OutputPath" -ForegroundColor Cyan

# Ensure NuGet provider for Install-Module
if (-not (Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue)) {
    Install-PackageProvider -Name NuGet -Scope CurrentUser -Force -Confirm:$false
}

# Trust PSGallery for this session
try { Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted -ErrorAction Stop } catch {}

# Ensure ps2exe is available
if (-not (Get-Module -ListAvailable -Name ps2exe)) {
    Write-Host "Installing ps2exe..." -ForegroundColor Yellow
    Install-Module ps2exe -Scope CurrentUser -Force -AllowClobber -SkipPublisherCheck -Confirm:$false
}

Import-Module ps2exe -ErrorAction Stop

Invoke-PS2EXE -inputFile $inputFile -outputFile $OutputPath -noConsole -icon $null -title 'UltimeOptimiser' -description 'Game optimisation helper' -product 'UltimeOptimiser' -company 'Local' -version '1.0.0.0'

Write-Host "Done." -ForegroundColor Green
