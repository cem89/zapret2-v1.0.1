@echo off
setlocal
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0start_roblox_dpi_bypass.ps1"
exit /b %ERRORLEVEL%
