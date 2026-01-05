@echo off
setlocal enabledelayedexpansion

REM ===== KONFIGURACE =====
set VERSION=0.0.3
set TAG=v%VERSION%
set TITLE=Toastmasters %VERSION%
set REMOTE=origin
set BRANCH=main

REM ===== KONTROLA =====
git status
IF ERRORLEVEL 1 (
  echo Git repo neni OK
  exit /b 1
)

REM ===== COMMIT =====
git add .
git commit -m "Release %VERSION%"

REM ===== PUSH BRANCH =====
git push %REMOTE% %BRANCH%

REM ===== TAG =====
git tag %TAG%
git push %REMOTE% %TAG%

REM ===== GITHUB RELEASE =====
gh release create %TAG% ^
  app-release.apk ^
  update.yaml ^
  config.yaml ^
  --title "%TITLE%" ^
  --notes "Release %VERSION%" ^
  --latest

echo.
echo HOTOVO:
echo - commit + push
echo - tag %TAG%
echo - GitHub Release vytvoren