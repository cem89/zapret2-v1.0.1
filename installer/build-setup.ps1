$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$outputRoot = 'C:\outputs\zapret2-installer'
$payloadRoot = Join-Path $outputRoot 'payload'
$payloadFolder = Join-Path $payloadRoot 'zapret2-v1.0.1'
$packageRoot = Join-Path $outputRoot 'package'
$payloadZip = Join-Path $packageRoot 'payload.zip'
$setupExe = Join-Path 'C:\outputs' 'zapret2-roblox-setup.exe'
$bootstrapCs = Join-Path $PSScriptRoot 'SetupBootstrap.cs'
$iconPath = Join-Path $projectRoot 'nfq2\windows\res\winws.ico'

function Get-CscPath {
  $candidates = @(
    'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe',
    'C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe'
  )

  foreach ($candidate in $candidates) {
    if (Test-Path -LiteralPath $candidate) {
      return $candidate
    }
  }

  throw 'csc.exe bulunamadi.'
}

New-Item -ItemType Directory -Force -Path $outputRoot, $payloadRoot, $packageRoot | Out-Null
Remove-Item -LiteralPath $payloadFolder -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $payloadFolder | Out-Null

robocopy $projectRoot $payloadFolder /E /XD .git installer /XF *.log *.err *.bak > $null
if ($LASTEXITCODE -gt 7) {
  throw "Payload kopyalama hatasi. Robocopy exit code: $LASTEXITCODE"
}

Remove-Item -LiteralPath $payloadZip -Force -ErrorAction SilentlyContinue
Compress-Archive -Path $payloadFolder -DestinationPath $payloadZip -Force

$cscPath = Get-CscPath
Remove-Item -LiteralPath $setupExe -Force -ErrorAction SilentlyContinue

$compileArgs = @(
  '/nologo',
  '/target:winexe',
  "/out:$setupExe",
  "/win32icon:$iconPath",
  '/r:System.dll',
  '/r:System.Drawing.dll',
  '/r:System.Windows.Forms.dll',
  '/r:System.IO.Compression.dll',
  '/r:System.IO.Compression.FileSystem.dll',
  "/resource:$payloadZip,payload.zip",
  $bootstrapCs
)

& $cscPath @compileArgs
if ($LASTEXITCODE -ne 0) {
  throw "Setup.exe derlenemedi. csc exit code: $LASTEXITCODE"
}

if (-not (Test-Path -LiteralPath $setupExe)) {
  throw "Setup.exe olusmadi: $setupExe"
}

Get-Item -LiteralPath $setupExe | Format-List FullName,Length,LastWriteTime
