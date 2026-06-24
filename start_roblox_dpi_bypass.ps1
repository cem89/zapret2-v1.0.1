$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$winws = Join-Path $root 'binaries\windows-x86_64\winws2.exe'
$luaLib = Join-Path $root 'lua\zapret-lib.lua'
$luaAntiDpi = Join-Path $root 'lua\zapret-antidpi.lua'

if (-not (Test-Path -LiteralPath $winws)) {
  throw "winws2.exe bulunamadi: $winws"
}

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
  throw 'Bu script Yonetici olarak calistirilmali.'
}

Get-Process winws2 -ErrorAction SilentlyContinue | Stop-Process -Force

$ipsets = [System.Collections.Generic.List[string]]::new()
$ipsets.Add('128.116.0.0/16')
$ipsets.Add('18.244.87.0/24')
$ipsets.Add('52.222.236.0/24')
$ipsets.Add('99.84.91.0/24')
$ipsets.Add('184.25.88.0/24')
$robloxHosts = @(
  'clientsettingscdn.roblox.com',
  'clientsettings.roblox.com',
  'client-telemetry.roblox.com',
  'setup.rbxcdn.com'
)

foreach ($hostName in $robloxHosts) {
  [System.Net.Dns]::GetHostAddresses($hostName) |
    Where-Object AddressFamily -eq InterNetwork |
    ForEach-Object {
      $parts = $_.IPAddressToString.Split('.')
      if ($parts.Count -eq 4) {
        $ipsets.Add(('{0}.{1}.{2}.0/24' -f $parts[0], $parts[1], $parts[2]))
      }
    }
}

$ipsetArg = '--ipset-ip=' + (($ipsets | Sort-Object -Unique) -join ',')

$args = @(
  "--lua-init=@$luaLib",
  "--lua-init=@$luaAntiDpi",
  '--wf-tcp-out=80,443',
  $ipsetArg,
  '--payload=tls_client_hello',
  '--lua-desync=fake:blob=0x00000000:tcp_md5:repeats=1',
  '--lua-desync=fake:blob=fake_default_tls:tcp_md5:tls_mod=rnd,dupsid:repeats=1',
  '--lua-desync=multisplit:pos=2'
)

Start-Process -FilePath $winws -ArgumentList $args -WorkingDirectory $root -WindowStyle Hidden
Start-Sleep -Seconds 1

if (-not (Get-Process winws2 -ErrorAction SilentlyContinue)) {
  throw 'winws2.exe baslatildi ama ayakta kalmadi.'
}

Write-Host 'Roblox DPI bypass baslatildi.'
