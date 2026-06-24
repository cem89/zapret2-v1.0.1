@echo off
cd /d "%~dp0"
if exist "%~dp0zapret2_kontrol_merkezi.exe" (
  start "" "%~dp0zapret2_kontrol_merkezi.exe"
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0zapret2-roblox-ui.ps1"
)
