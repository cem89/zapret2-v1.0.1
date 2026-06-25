$ErrorActionPreference = 'Stop'

function Get-ZapretRoot {
  Split-Path -Parent $PSScriptRoot
}

function Get-ZapretProjectRoot {
  $PSScriptRoot
}

function Get-ZapretPaths {
  $root = Get-ZapretProjectRoot
  [pscustomobject]@{
    Root = $root
    Winws = Join-Path $root 'binaries\windows-x86_64\winws2.exe'
    LuaLib = Join-Path $root 'lua\zapret-lib.lua'
    LuaAntiDpi = Join-Path $root 'lua\zapret-antidpi.lua'
    LogOut = Join-Path $root 'winws-roblox.log'
    LogErr = Join-Path $root 'winws-roblox.err'
    ControlLog = Join-Path $root 'zapret2-control.log'
    Config = Join-Path $root 'roblox-bypass.conf'
  }
}

function Write-ZapretControlLog {
  param(
    [string]$Event,
    [string]$Message,
    [hashtable]$Data = @{}
  )

  $paths = Get-ZapretPaths
  $payload = [ordered]@{
    time = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff')
    event = $Event
    message = $Message
    admin = Test-ZapretAdmin
  }

  foreach ($key in $Data.Keys) {
    $payload[$key] = $Data[$key]
  }

  try {
    ($payload | ConvertTo-Json -Compress -Depth 5) | Add-Content -LiteralPath $paths.ControlLog -Encoding UTF8
  } catch {
  }
}

function Test-ZapretAdmin {
  $principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
  $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Assert-ZapretAdmin {
  if (-not (Test-ZapretAdmin)) {
    throw 'Bu islem Yonetici olarak calistirilmali.'
  }
}

function Get-RobloxHostTargets {
  @(
    'clientsettingscdn.roblox.com',
    'clientsettings.roblox.com',
    'client-telemetry.roblox.com',
    'setup.rbxcdn.com'
  )
}

function Resolve-RobloxIpSets {
  $ipsets = [System.Collections.Generic.List[string]]::new()
  @(
    '128.116.0.0/16',
    '18.244.87.0/24',
    '52.222.236.0/24',
    '99.84.91.0/24',
    '184.25.88.0/24'
  ) | ForEach-Object { [void]$ipsets.Add($_) }

  foreach ($hostName in Get-RobloxHostTargets) {
    try {
      [System.Net.Dns]::GetHostAddresses($hostName) |
        Where-Object AddressFamily -eq InterNetwork |
        ForEach-Object {
          $parts = $_.IPAddressToString.Split('.')
          if ($parts.Count -eq 4) {
            [void]$ipsets.Add(('{0}.{1}.{2}.0/24' -f $parts[0], $parts[1], $parts[2]))
          }
        }
    } catch {
      continue
    }
  }

  $ipsets | Sort-Object -Unique
}

function Get-RobloxBypassArguments {
  $paths = Get-ZapretPaths
  if (-not (Test-Path -LiteralPath $paths.Winws)) {
    throw "winws2.exe bulunamadi: $($paths.Winws)"
  }

  $ipsetArg = '--ipset-ip=' + ((Resolve-RobloxIpSets) -join ',')

  @(
    # winws2 resolves these from WorkingDirectory; relative paths avoid
    # Cygwin path parsing issues when installed under "Program Files".
    '--lua-init=@lua/zapret-lib.lua',
    '--lua-init=@lua/zapret-antidpi.lua',
    '--wf-tcp-out=80,443',
    $ipsetArg,
    '--payload=tls_client_hello',
    '--lua-desync=fake:blob=0x00000000:tcp_md5:repeats=1',
    '--lua-desync=fake:blob=fake_default_tls:tcp_md5:tls_mod=rnd,dupsid:repeats=1',
    '--lua-desync=multisplit:pos=2'
  )
}

function Get-WinwsProcess {
  $paths = Get-ZapretPaths
  Get-Process winws2 -ErrorAction SilentlyContinue |
    Where-Object {
      try {
        $_.Path -and ($_.Path -ieq $paths.Winws)
      } catch {
        $true
      }
    } |
    Select-Object -First 1
}

function Get-WinDivertDriverStatus {
  $driver = Get-CimInstance Win32_SystemDriver -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -ieq 'WinDivert' } |
    Select-Object -First 1

  if ($null -eq $driver) {
    return [pscustomobject]@{
      Exists = $false
      Running = $false
      State = 'NotInstalled'
      PathName = ''
    }
  }

  [pscustomobject]@{
    Exists = $true
    Running = [bool]($driver.State -eq 'Running')
    State = [string]$driver.State
    PathName = [string]$driver.PathName
  }
}

function Stop-WinDivertDriver {
  Assert-ZapretAdmin
  $before = Get-WinDivertDriverStatus
  $stopOutput = ''
  $deleteOutput = ''

  if ($before.Exists) {
    $stopOutput = (& sc.exe stop WinDivert 2>&1) -join [Environment]::NewLine
    Start-Sleep -Milliseconds 900
    $deleteOutput = (& sc.exe delete WinDivert 2>&1) -join [Environment]::NewLine
    Start-Sleep -Milliseconds 300
  }

  $after = Get-WinDivertDriverStatus
  [pscustomobject]@{
    Before = $before
    After = $after
    StopOutput = $stopOutput
    DeleteOutput = $deleteOutput
    Changed = [bool]($before.Exists -or $before.Running)
  }
}

function Stop-RobloxDpiBypass {
  Assert-ZapretAdmin
  Write-ZapretControlLog -Event 'stop.begin' -Message 'Stop requested.'
  $proc = Get-WinwsProcess
  $processStopped = $false
  $processId = $null

  if ($null -ne $proc) {
    $processId = $proc.Id
    try {
      $proc | Stop-Process -Force -ErrorAction Stop
      Start-Sleep -Milliseconds 700
      $processStopped = $true
    } catch {
      Write-ZapretControlLog -Event 'stop.process.error' -Message $_.Exception.Message -Data @{ pid = $processId }
    }
  }

  $driverResult = Stop-WinDivertDriver
  $remainingProc = Get-WinwsProcess
  $remainingDriver = Get-WinDivertDriverStatus
  $stopped = [bool]($processStopped -or $driverResult.Changed)

  Write-ZapretControlLog -Event 'stop.end' -Message 'Stop finished.' -Data @{
    requestedPid = $processId
    processStopped = $processStopped
    driverBefore = $driverResult.Before.State
    driverAfter = $driverResult.After.State
    remainingProcess = [bool]($null -ne $remainingProc)
    remainingDriverRunning = $remainingDriver.Running
  }

  [pscustomobject]@{
    Stopped = $stopped
    ProcessStopped = $processStopped
    ProcessId = $processId
    DriverBefore = $driverResult.Before
    DriverAfter = $driverResult.After
    RemainingProcess = [bool]($null -ne $remainingProc)
    RemainingDriverRunning = $remainingDriver.Running
  }
}

function Start-RobloxDpiBypass {
  Assert-ZapretAdmin
  $paths = Get-ZapretPaths
  Write-ZapretControlLog -Event 'start.begin' -Message 'Start requested.'

  if (-not (Test-Path -LiteralPath $paths.Winws)) {
    Write-ZapretControlLog -Event 'start.error' -Message 'winws2.exe missing.' -Data @{ path = $paths.Winws }
    throw "winws2.exe bulunamadi: $($paths.Winws)"
  }

  if (Test-Path -LiteralPath $paths.LogOut) {
    Remove-Item -LiteralPath $paths.LogOut -Force -ErrorAction SilentlyContinue
  }
  if (Test-Path -LiteralPath $paths.LogErr) {
    Remove-Item -LiteralPath $paths.LogErr -Force -ErrorAction SilentlyContinue
  }

  Get-WinwsProcess | Stop-Process -Force -ErrorAction SilentlyContinue
  Stop-WinDivertDriver | Out-Null

  $process = Start-Process `
    -FilePath $paths.Winws `
    -ArgumentList (Get-RobloxBypassArguments) `
    -WorkingDirectory $paths.Root `
    -WindowStyle Hidden `
    -RedirectStandardOutput $paths.LogOut `
    -RedirectStandardError $paths.LogErr `
    -PassThru

  Write-ZapretControlLog -Event 'start.spawned' -Message 'winws2 process spawned.' -Data @{ pid = $process.Id; path = $paths.Winws }

  $logDetected = $false
  $runningDetected = $false

  for ($i = 0; $i -lt 12; $i++) {
    Start-Sleep -Milliseconds 250

    if (Get-WinwsProcess) {
      $runningDetected = $true
    }

    if ((Test-Path -LiteralPath $paths.LogOut) -and ((Get-Item -LiteralPath $paths.LogOut).Length -gt 0)) {
      $logDetected = $true
      break
    }
  }

  if (-not $logDetected -and -not $runningDetected) {
    $errPreview = ''
    if (Test-Path -LiteralPath $paths.LogErr) {
      $errPreview = (Get-Content -LiteralPath $paths.LogErr -Tail 20 -ErrorAction SilentlyContinue) -join [Environment]::NewLine
    }
    if ($process.HasExited) {
      $exitCodeText = "winws2.exe hemen kapandi. ExitCode=$($process.ExitCode)"
    } else {
      $exitCodeText = 'winws2.exe durumunu dogrulama basarisiz oldu.'
    }

    if ($errPreview) {
      Write-ZapretControlLog -Event 'start.error' -Message $exitCodeText -Data @{ stderr = $errPreview }
      throw "$exitCodeText`n$errPreview"
    }

    Write-ZapretControlLog -Event 'start.error' -Message $exitCodeText
    throw $exitCodeText
  }

  $driver = Get-WinDivertDriverStatus
  Write-ZapretControlLog -Event 'start.end' -Message 'Start finished.' -Data @{ pid = $process.Id; runningDetected = $runningDetected; logDetected = $logDetected; driverState = $driver.State }
  $process
}

function Invoke-RobloxReachabilityTest {
  $urls = @(
    'https://www.roblox.com/',
    'https://auth.roblox.com/v2/login',
    'https://gamejoin.roblox.com/v1/join-game',
    'https://presence.roblox.com/v1/presence/users',
    'https://assetdelivery.roblox.com/v1/asset/?id=1'
  )

  foreach ($url in $urls) {
    $output = & curl.exe --ssl-no-revoke -I -L --max-time 12 $url 2>&1
    $code = $LASTEXITCODE
    $status = ($output | Select-String -Pattern '^HTTP/' | Select-Object -Last 1).ToString()
    [pscustomobject]@{
      Url = $url
      Success = [bool]($code -eq 0 -and $status)
      ExitCode = $code
      Status = if ($status) { $status } else { '' }
      Details = ($output | Select-Object -Last 8) -join [Environment]::NewLine
    }
  }
}

function Get-LatestLogPreview {
  param(
    [int]$Tail = 30
  )

  $paths = Get-ZapretPaths
  $sections = [System.Collections.Generic.List[string]]::new()

  foreach ($entry in @(
    @{ Title = 'Kontrol Merkezi'; Path = $paths.ControlLog },
    @{ Title = 'winws stdout'; Path = $paths.LogOut },
    @{ Title = 'winws stderr'; Path = $paths.LogErr }
  )) {
    [void]$sections.Add("[$($entry.Title)]")
    if (Test-Path -LiteralPath $entry.Path) {
      try {
        [void]$sections.Add(((Get-Content -LiteralPath $entry.Path -Tail $Tail -ErrorAction Stop) -join [Environment]::NewLine))
      } catch {
        [void]$sections.Add('Log okunamadi: ' + $_.Exception.Message)
      }
    } else {
      [void]$sections.Add('Henuz log olusmadi.')
    }
  }

  ($sections -join ([Environment]::NewLine + [Environment]::NewLine)).Trim()
}

function Get-ZapretStatus {
  $paths = Get-ZapretPaths
  $proc = Get-WinwsProcess
  $driver = Get-WinDivertDriverStatus
  $logTime = $null

  if (Test-Path -LiteralPath $paths.LogOut) {
    $logTime = (Get-Item -LiteralPath $paths.LogOut).LastWriteTime
  }

  [pscustomobject]@{
    IsAdmin = Test-ZapretAdmin
    IsRunning = $null -ne $proc
    ProcessId = if ($proc) { $proc.Id } else { $null }
    StartedAt = if ($proc) { $proc.StartTime } else { $null }
    IsDriverRunning = $driver.Running
    DriverState = $driver.State
    DriverPath = $driver.PathName
    WinwsExists = Test-Path -LiteralPath $paths.Winws
    LogOut = $paths.LogOut
    LogErr = $paths.LogErr
    ControlLog = $paths.ControlLog
    Config = $paths.Config
    LastLogUpdate = $logTime
    HostTargets = (Get-RobloxHostTargets) -join ', '
  }
}
