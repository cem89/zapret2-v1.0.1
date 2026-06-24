$ErrorActionPreference = 'Stop'
param(
  [string]$PayloadZip = (Join-Path $PSScriptRoot 'payload.zip'),
  [switch]$LaunchAfterInstall
)

Add-Type -AssemblyName PresentationFramework

function Test-IsAdmin {
  $principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
  $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Show-Message {
  param(
    [string]$Text,
    [string]$Title = 'Zapret2 Roblox Kurulum',
    [string]$Icon = 'Information'
  )

  [System.Windows.MessageBox]::Show($Text, $Title, 'OK', $Icon) | Out-Null
}

if (-not (Test-IsAdmin)) {
  $argList = @(
    '-NoProfile',
    '-ExecutionPolicy', 'Bypass',
    '-File', "`"$PSCommandPath`"",
    '-PayloadZip', "`"$PayloadZip`""
  )
  if ($LaunchAfterInstall) {
    $argList += '-LaunchAfterInstall'
  }
  Start-Process powershell.exe -ArgumentList $argList -Verb RunAs
  exit
}

if (-not (Test-Path -LiteralPath $PayloadZip)) {
  throw "Kurulum paketi bulunamadi: $PayloadZip"
}

$appName = 'Zapret2 Roblox Kontrol Merkezi'
$installDir = Join-Path ${env:ProgramFiles} $appName
$desktopShortcut = Join-Path ([Environment]::GetFolderPath('Desktop')) "$appName.lnk"
$startMenuDir = Join-Path ([Environment]::GetFolderPath('Programs')) $appName
$startMenuShortcut = Join-Path $startMenuDir "$appName.lnk"
$iconPath = Join-Path $installDir 'nfq2\windows\res\winws.ico'
$launcherCmd = Join-Path $installDir 'zapret2_kontrol_merkezi.cmd'

$tempExtract = Join-Path $env:TEMP ('zapret2-install-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $tempExtract | Out-Null

try {
  Expand-Archive -LiteralPath $PayloadZip -DestinationPath $tempExtract -Force

  $payloadRoot = Join-Path $tempExtract 'zapret2-v1.0.1'
  if (-not (Test-Path -LiteralPath $payloadRoot)) {
    throw 'Kurulum icerigi beklenen klasor yapisinda degil.'
  }

  New-Item -ItemType Directory -Force -Path $installDir | Out-Null
  robocopy $payloadRoot $installDir /E > $null
  if ($LASTEXITCODE -gt 7) {
    throw "Dosya kopyalama hatasi. Robocopy exit code: $LASTEXITCODE"
  }

  New-Item -ItemType Directory -Force -Path $startMenuDir | Out-Null

  $wsh = New-Object -ComObject WScript.Shell

  $desktop = $wsh.CreateShortcut($desktopShortcut)
  $desktop.TargetPath = $launcherCmd
  $desktop.WorkingDirectory = $installDir
  if (Test-Path -LiteralPath $iconPath) {
    $desktop.IconLocation = $iconPath
  }
  $desktop.Save()

  $startMenu = $wsh.CreateShortcut($startMenuShortcut)
  $startMenu.TargetPath = $launcherCmd
  $startMenu.WorkingDirectory = $installDir
  if (Test-Path -LiteralPath $iconPath) {
    $startMenu.IconLocation = $iconPath
  }
  $startMenu.Save()

  Show-Message "Kurulum tamamlandi.`n`nUygulama yolu:`n$installDir`n`nMasaustune kisayol eklendi."

  if ($LaunchAfterInstall -and (Test-Path -LiteralPath $launcherCmd)) {
    Start-Process $launcherCmd
  }
} finally {
  Remove-Item -LiteralPath $tempExtract -Recurse -Force -ErrorAction SilentlyContinue
}
