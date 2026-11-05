@echo off
title DIGIVET Mobile - Galaxy A17
REM Double-click: runs the app on the A17 against this laptop's Online server.
REM Options (add after the script name): -Hosted   -Hosted -Release
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run-a17.ps1" %*
echo.
pause
