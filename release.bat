@echo off
setlocal enabledelayedexpansion

REM ===== KONFIGURACE =====
set VERSION=0.0.4
set TAG=v%VERSION%
set TITLE=Toastmasters %VERSION%
set REMOTE=origin
set BRANCH=master

echo === GIT STATUS ===
git status

REM ===== COMMIT (pokud je co) =====
git add .
git diff --cached --quiet
IF %ERRORLEVEL% NEQ 0 (
  git commit -m "Release %VERSION%"
) ELSE (
  echo Nic k commitnuti
)

REM ===== PUSH BRANCH =====
git push %REMOTE% %BRANCH%

REM ===== TAG (jen pokud neexistuje) =====
git tag | findstr %TAG% >nul
IF %ERRORLEVEL% NEQ 0 (
  git tag %TAG%
  git push %REMOTE% %TAG%
) ELSE (
  echo Tag %TAG% uz existuje
)

REM ===== RELEASE =====
gh release view %TAG% >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
  echo Vytvarim novy release %TAG%
  gh release create %TAG% ^
    app-release.apk ^
    update.yaml ^
    config.yaml ^
    --title "%TITLE%" ^
    --notes "Release %VERSION%" ^
    --latest
) ELSE (
  echo Release %TAG% uz existuje, updatuji assets
  gh
