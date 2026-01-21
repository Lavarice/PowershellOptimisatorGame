Write-Host "=== Utilisation CPU ===" -ForegroundColor Cyan

while ($true) {

    $cpu = (Get-CimInstance Win32_Processor |
            Measure-Object LoadPercentage -Average).Average

    $gpu = (Get-CimInstance Win32_VideoController |
            Measure-Object CurrentUsage -Average).Average


    if ($cpu -lt 50 -and $gpu -lt 50) {
        Write-Host "Utilisation CPU actuelle : $cpu %" -ForegroundColor Green
        Write-Host "Utilisation GPU actuelle : $gpu %" -ForegroundColor Green
    }
    else {
        Write-Host "Utilisation CPU actuelle : $cpu %" -ForegroundColor Red
        Write-Host "Utilisation GPU actuelle : $gpu %" -ForegroundColor Red
    }

    Start-Sleep -Seconds 1
}

