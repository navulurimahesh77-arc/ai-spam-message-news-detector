@echo off
title AI Spam & News Detector - Laptop 2 Companion Launcher
cls
echo ==========================================================
echo   AI Spam & News Detector - Second Laptop Companion
echo ==========================================================
echo.
echo [1/2] Running automated system and permission diagnostics...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Diagnose-Laptop2.ps1"
echo.
echo [2/2] Launching Companion Server...
echo Press Ctrl+C at any time to stop.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Companion-Laptop2.ps1"
pause
