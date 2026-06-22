@echo off
setlocal
fltmc >nul 2>&1
if errorlevel 1 (
    powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Initialize-WindowsPC.ps1" -Apply -ShowFileExtensions
set "RC=%ERRORLEVEL%"
echo.
echo Windows PC Provisioning finished with exit code %RC%.
echo Review the logs before applying optional computer-name or package settings.
pause
exit /b %RC%
