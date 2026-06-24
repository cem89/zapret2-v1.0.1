@echo off
setlocal
cd /d "%~dp0"

net session >nul 2>&1
if errorlevel 1 (
  echo Yonetici izni gerekiyor. Yukseltme penceresi aciliyor...
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd.exe -ArgumentList '/c cd /d ""%~dp0"" ^&^& ""%~f0"" elevated' -Verb RunAs"
  exit /b
)

if /i "%~1"=="elevated" shift

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0start_roblox_dpi_bypass.ps1"
exit /b %ERRORLEVEL%
