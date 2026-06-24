$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$controlCenterBuild = Join-Path $projectRoot 'csharp\build-control-center.ps1'
$issPath = Join-Path $PSScriptRoot 'zapret2-roblox.iss'

function Get-IsccPath {
  $candidates = @(
    'C:\Program Files (x86)\Inno Setup 6\ISCC.exe',
    'C:\Program Files\Inno Setup 6\ISCC.exe',
    'C:\Program Files (x86)\Inno Setup 5\ISCC.exe',
    'C:\Program Files\Inno Setup 5\ISCC.exe',
    'C:\Users\cemar\AppData\Local\Programs\Inno Setup 6\ISCC.exe'
  )

  foreach ($candidate in $candidates) {
    if (Test-Path -LiteralPath $candidate) {
      return $candidate
    }
  }

  $found = Get-ChildItem 'C:\' -Filter ISCC.exe -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
  if ($found) {
    return $found
  }

  throw 'ISCC.exe bulunamadi.'
}

function Get-Compil32Path {
  $candidates = @(
    'C:\Users\cemar\AppData\Local\Programs\Inno Setup 6\Compil32.exe',
    'C:\Program Files (x86)\Inno Setup 6\Compil32.exe',
    'C:\Program Files\Inno Setup 6\Compil32.exe'
  )

  foreach ($candidate in $candidates) {
    if (Test-Path -LiteralPath $candidate) {
      return $candidate
    }
  }

  throw 'Compil32.exe bulunamadi.'
}

& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $controlCenterBuild

$compiled = $false

try {
  $iscc = Get-IsccPath
  & $iscc $issPath
  if ($LASTEXITCODE -ne 0) {
    throw "ISCC derlemesi basarisiz oldu. exit code: $LASTEXITCODE"
  }
  $compiled = $true
} catch {
  $compil32 = Get-Compil32Path
  Start-Process -FilePath $compil32 -ArgumentList "/cc `"$issPath`"" -Wait
  $compiled = Test-Path -LiteralPath 'C:\outputs\zapret2-roblox-inno-setup.exe'
}

if (-not $compiled) {
  throw 'Inno Setup derlemesi basarisiz oldu.'
}

Get-Item -LiteralPath 'C:\outputs\zapret2-roblox-inno-setup.exe' | Format-List FullName,Length,LastWriteTime
