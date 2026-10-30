@echo off
setlocal
chcp 65001 >nul
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0preflight.ps1" %*
set "preflightCode=%errorlevel%"
echo.
if not defined L08_PREFLIGHT_NO_PAUSE pause
exit /b %preflightCode%
