@echo off
taskkill /f /im winws2.exe >nul 2>&1
if errorlevel 1 (
  echo Calisan winws2.exe bulunamadi.
) else (
  echo Roblox DPI bypass durduruldu.
)
