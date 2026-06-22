@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Initialize-WindowsPC.ps1"
set "RC=%ERRORLEVEL%"
echo.
echo Windows PC Provisioning inventory finished with exit code %RC%.
echo Use the README commands when applying named provisioning settings.
pause
exit /b %RC%
