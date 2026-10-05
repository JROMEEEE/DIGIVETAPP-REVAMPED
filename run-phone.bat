@echo off
title DIGIVET Mobile - run on phone
REM Double-click to start the backend, connect your phone over Wi-Fi and run the app.
REM Add -Check after the script name to test the laptop side only (no phone).
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run-phone.ps1" %*
echo.
pause
