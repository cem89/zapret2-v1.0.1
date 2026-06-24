$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$sourceFile = Join-Path $PSScriptRoot 'Zapret2ControlCenter.cs'
$outputExe = Join-Path $projectRoot 'zapret2_kontrol_merkezi.exe'
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

$cscPath = Get-CscPath
Remove-Item -LiteralPath $outputExe -Force -ErrorAction SilentlyContinue

$args = @(
  '/nologo',
  '/target:winexe',
  "/out:$outputExe",
  "/win32icon:$iconPath",
  '/r:System.dll',
  '/r:System.Drawing.dll',
  '/r:System.Runtime.Serialization.dll',
  '/r:System.Windows.Forms.dll',
  $sourceFile
)

& $cscPath @args
if ($LASTEXITCODE -ne 0) {
  throw "C# kontrol merkezi derlenemedi. csc exit code: $LASTEXITCODE"
}

Get-Item -LiteralPath $outputExe | Format-List FullName,Length,LastWriteTime
