$ErrorActionPreference = 'Stop'

$BackendCommand = if ($args.Count -ge 1) { [string]$args[0] } else { '' }
$Tail = if ($args.Count -ge 2) { [int]$args[1] } else { 30 }

if ($BackendCommand -notin @('status', 'start', 'stop', 'test', 'log')) {
  throw "Gecersiz komut: '$BackendCommand'"
}

. "$PSScriptRoot\zapret2-roblox-common.ps1"

switch ($BackendCommand) {
  'status' {
    Get-ZapretStatus | ConvertTo-Json -Compress -Depth 4
  }
  'start' {
    Start-RobloxDpiBypass | Out-Null
    [pscustomobject]@{
      success = $true
      message = 'Bypass baslatildi.'
    } | ConvertTo-Json -Compress
  }
  'stop' {
    $result = Stop-RobloxDpiBypass
    [pscustomobject]@{
      success = $true
      stopped = $result.Stopped
      processStopped = $result.ProcessStopped
      driverStopped = -not $result.RemainingDriverRunning
      remainingProcess = $result.RemainingProcess
      remainingDriverRunning = $result.RemainingDriverRunning
      message = if (-not $result.RemainingProcess -and -not $result.RemainingDriverRunning) {
        'Bypass tamamen durduruldu.'
      } elseif ($result.RemainingDriverRunning) {
        'winws2 kapandi fakat WinDivert surucusu hala calisiyor.'
      } else {
        'Durdurma denendi, calisan winws2.exe bulunamadi.'
      }
    } | ConvertTo-Json -Compress
  }
  'test' {
    Invoke-RobloxReachabilityTest | ConvertTo-Json -Compress -Depth 5
  }
  'log' {
    Get-LatestLogPreview -Tail $Tail
  }
}
