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
    Config = Join-Path $root 'roblox-bypass.conf'
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
  Get-Process winws2 -ErrorAction SilentlyContinue | Select-Object -First 1
}

function Stop-RobloxDpiBypass {
  Assert-ZapretAdmin
  $proc = Get-WinwsProcess
  if ($null -eq $proc) {
    return $false
  }
  $proc | Stop-Process -Force
  Start-Sleep -Milliseconds 600
  return $true
}

function Start-RobloxDpiBypass {
  Assert-ZapretAdmin
  $paths = Get-ZapretPaths

  if (-not (Test-Path -LiteralPath $paths.Winws)) {
    throw "winws2.exe bulunamadi: $($paths.Winws)"
  }

  if (Test-Path -LiteralPath $paths.LogOut) {
    Remove-Item -LiteralPath $paths.LogOut -Force -ErrorAction SilentlyContinue
  }
  if (Test-Path -LiteralPath $paths.LogErr) {
    Remove-Item -LiteralPath $paths.LogErr -Force -ErrorAction SilentlyContinue
  }

  Get-WinwsProcess | Stop-Process -Force -ErrorAction SilentlyContinue

  $process = Start-Process `
    -FilePath $paths.Winws `
    -ArgumentList (Get-RobloxBypassArguments) `
    -WorkingDirectory $paths.Root `
    -WindowStyle Hidden `
    -RedirectStandardOutput $paths.LogOut `
    -RedirectStandardError $paths.LogErr `
    -PassThru

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
      throw "$exitCodeText`n$errPreview"
    }

    throw $exitCodeText
  }

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
  if (-not (Test-Path -LiteralPath $paths.LogOut)) {
    return 'Henuz log olusmadi.'
  }

  try {
    (Get-Content -LiteralPath $paths.LogOut -Tail $Tail) -join [Environment]::NewLine
  } catch {
    'Log okunamadi.'
  }
}

function Get-ZapretStatus {
  $paths = Get-ZapretPaths
  $proc = Get-WinwsProcess
  $logTime = $null

  if (Test-Path -LiteralPath $paths.LogOut) {
    $logTime = (Get-Item -LiteralPath $paths.LogOut).LastWriteTime
  }

  [pscustomobject]@{
    IsAdmin = Test-ZapretAdmin
    IsRunning = $null -ne $proc
    ProcessId = if ($proc) { $proc.Id } else { $null }
    StartedAt = if ($proc) { $proc.StartTime } else { $null }
    WinwsExists = Test-Path -LiteralPath $paths.Winws
    LogOut = $paths.LogOut
    LogErr = $paths.LogErr
    Config = $paths.Config
    LastLogUpdate = $logTime
    HostTargets = (Get-RobloxHostTargets) -join ', '
  }
}
