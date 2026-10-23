@echo off
title Push AI Detector to GitHub
echo ========================================================
echo    Pushing AI Spam & News Detector to GitHub
echo ========================================================
echo.
echo Target: https://github.com/navulurimahesh77-arc/ai-spam-message-news-detector.git
echo.

"C:\Users\Ramch\.gemini\antigravity\scratch\MinGit\cmd\git.exe" remote remove origin 2>nul
"C:\Users\Ramch\.gemini\antigravity\scratch\MinGit\cmd\git.exe" remote add origin https://github.com/navulurimahesh77-arc/ai-spam-message-news-detector.git
"C:\Users\Ramch\.gemini\antigravity\scratch\MinGit\cmd\git.exe" branch -M main

echo Starting Git Push...
"C:\Users\Ramch\.gemini\antigravity\scratch\MinGit\cmd\git.exe" push -u origin main

echo.
if %ERRORLEVEL% EQU 0 (
    echo [SUCCESS] Your repository was pushed to GitHub successfully!
    echo Visit: https://github.com/navulurimahesh77-arc/ai-spam-message-news-detector
) else (
    echo [NOTICE] If GitHub asked for a password or token, please ensure the repo exists and you are signed in.
)

pause
