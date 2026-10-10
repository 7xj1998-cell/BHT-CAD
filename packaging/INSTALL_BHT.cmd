@echo off
rem BHT 0.6.53 installer launcher. File nay chi dung ky tu ASCII.
setlocal
chcp 65001 >nul
title Cai dat BHT 0.6.53
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0INSTALL_BHT.ps1"
set "BHT_RC=%ERRORLEVEL%"
echo.
if not "%BHT_RC%"=="0" echo [BHT] Cai dat THAT BAI (ma loi %BHT_RC%). Xem dong mau do phia tren.
pause
endlocal & exit /b %BHT_RC%
