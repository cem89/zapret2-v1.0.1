@echo off
net session >nul 2>&1
if errorlevel 1 (
  echo Yonetici izni gerekiyor. Yukseltme penceresi aciliyor...
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd.exe -ArgumentList '/c cd /d ""%~dp0"" ^&^& ""%~f0"" elevated' -Verb RunAs"
  exit /b
)

if /i "%~1"=="elevated" shift

taskkill /f /im winws2.exe >nul 2>&1
if errorlevel 1 (
  echo Calisan winws2.exe bulunamadi.
) else (
  echo Roblox DPI bypass durduruldu.
)

pause
exit /b
