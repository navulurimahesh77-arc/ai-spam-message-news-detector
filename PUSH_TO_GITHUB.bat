@echo off
title Push Updates to GitHub
echo ========================================================
echo   Pushing AI Detector Updates to GitHub...
echo ========================================================
echo.

set GIT_EXE=C:\Users\Ramch\AppData\Local\github-copilot-git-2.56.0-1\cmd\git.exe
set REPO_DIR=C:\Users\Ramch\.gemini\antigravity\scratch\ai-spam-message-news-detector

echo [1/3] Adding all updated files...
"%GIT_EXE%" -C "%REPO_DIR%" add -A

echo [2/3] Checking commit...
"%GIT_EXE%" -C "%REPO_DIR%" commit -m "Update detector: fix loops, add WhatsApp Web live monitoring, and restore clean feed" >nul 2>&1

echo [3/3] Pushing to GitHub (origin main)...
"%GIT_EXE%" -C "%REPO_DIR%" push origin main

echo.
if %ERRORLEVEL% equ 0 (
    echo ========================================================
    echo   SUCCESS! Pushed to GitHub successfully!
    echo   Vercel will now deploy the update automatically!
    echo ========================================================
) else (
    echo [NOTE] If a browser sign-in window popped up, please complete the sign-in.
    echo Alternatively, you can drag and drop index.html directly into GitHub Web:
    echo https://github.com/navulurimahesh77-arc/ai-spam-message-news-detector/upload/main
)
echo.
pause
