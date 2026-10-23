@echo off
setlocal
title AI Spam, Message & News Detector

echo ========================================================
echo    AI Spam, Message & News Detector
echo    Local Privacy-First Detection Dashboard
echo ========================================================
echo.
echo Starting local Windows Companion on http://127.0.0.1:8765...
echo.

where powershell >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0companion\WindowsNotificationCompanion.ps1"
) else (
    echo [WARNING] PowerShell not detected in PATH.
    echo Opening index.html directly in your default browser...
    start "" "%~dp0index.html"
)

pause
