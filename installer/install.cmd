@echo off
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" -PayloadZip "%~dp0payload.zip" -LaunchAfterInstall
exit /b %ERRORLEVEL%
