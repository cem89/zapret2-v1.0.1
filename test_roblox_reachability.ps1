$urls = @(
  'https://www.roblox.com/',
  'https://auth.roblox.com/v2/login',
  'https://gamejoin.roblox.com/v1/join-game',
  'https://presence.roblox.com/v1/presence/users',
  'https://assetdelivery.roblox.com/v1/asset/?id=1'
)

foreach ($url in $urls) {
  Write-Host "== $url"
  $output = & curl.exe --ssl-no-revoke -I -L --max-time 12 $url 2>&1
  $code = $LASTEXITCODE
  $status = $output | Select-String -Pattern '^HTTP/' | Select-Object -Last 1
  if ($code -eq 0 -and $status) {
    Write-Host "OK $status"
  } else {
    Write-Host "FAIL curl_exit=$code"
    $output | Select-Object -Last 8
  }
}
