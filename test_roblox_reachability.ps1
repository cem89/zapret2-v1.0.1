$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\zapret2-roblox-common.ps1"

foreach ($result in Invoke-RobloxReachabilityTest) {
  Write-Host "== $($result.Url)"
  if ($result.Success) {
    Write-Host "OK $($result.Status)"
  } else {
    Write-Host "FAIL curl_exit=$($result.ExitCode)"
    if ($result.Details) {
      Write-Host $result.Details
    }
  }
}
