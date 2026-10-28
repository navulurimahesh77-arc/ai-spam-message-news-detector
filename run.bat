@echo off
setlocal
title AI Spam Shield - Windows Notification Companion

echo ========================================================
echo    AI Spam Shield - Windows Notification Companion
echo    Automatic WhatsApp ^& Windows Notification Monitor
echo ========================================================
echo.

cd /d "%~dp0"

echo [1/3] Checking if companion is already active on port 8765...
powershell -NoProfile -Command "try { $r = Invoke-WebRequest -Uri 'http://127.0.0.1:8765/api/status' -UseBasicParsing -TimeoutSec 1; exit 0 } catch { exit 1 }" >nul 2>nul

if %ERRORLEVEL% EQU 0 (
    echo [OK] Companion is already active and monitoring on port 8765!
    echo Opening live SpamShield website...
    start https://ai-spam-message-news-detector.vercel.app
    echo.
    echo Dashboard is live at: https://ai-spam-message-news-detector.vercel.app
    echo (Offline mirror available at: http://127.0.0.1:8765)
    echo.
    echo Keep this window open while monitoring notifications.
    pause
    exit /b 0
)

echo [2/3] Verifying notification listener files...
set "PS_COMPANION=%~dp0companion\WindowsNotificationCompanion.ps1"
if not exist "%PS_COMPANION%" (
    set "PS_COMPANION=%~dp0WindowsNotificationCompanion.ps1"
)
if not exist "%PS_COMPANION%" (
    set "PS_COMPANION=%~dp0Companion-Laptop2.ps1"
)

if not exist "%PS_COMPANION%" (
    echo [SETUP] First-time setup on this laptop...
    echo Downloading listener engine from SpamShield live servers...
    if not exist "%~dp0companion" mkdir "%~dp0companion" 2>nul
    set "PS_COMPANION=%~dp0companion\WindowsNotificationCompanion.ps1"
    powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { (New-Object Net.WebClient).DownloadFile('https://ai-spam-message-news-detector.vercel.app/companion/WindowsNotificationCompanion.ps1', '%~dp0companion\WindowsNotificationCompanion.ps1'); Write-Host '[OK] Companion engine ready.' -ForegroundColor Green } catch { (New-Object Net.WebClient).DownloadFile('https://raw.githubusercontent.com/navulurimahesh77-arc/ai-spam-message-news-detector/main/Companion-Laptop2.ps1', '%~dp0companion\WindowsNotificationCompanion.ps1'); Write-Host '[OK] Fallback engine ready.' -ForegroundColor Green }"
)

echo [3/3] Launching companion listener on port 8765...
echo Opening live website: https://ai-spam-message-news-detector.vercel.app
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_COMPANION%" -Port 8765
pause
