Get-ADComputer –filter * | foreach{ Invoke-GPUpdate –Computer $_.name -Force -RandomDelayInMinutes 0}
