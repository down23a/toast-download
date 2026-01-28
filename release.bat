@echo off
setlocal enabledelayedexpansion

REM ===== KONFIGURACE =====
set "PUBSPEC_PATH=D:\Dev\Apps\toastAuto\code\pubspec.yaml"
if not exist "%PUBSPEC_PATH%" (
  echo Soubor %PUBSPEC_PATH% nenalezen.
  exit /b 1
)
set "VERSION="
for /f "tokens=1,* delims=:" %%A in ('findstr /b /c:"version:" "%PUBSPEC_PATH%"') do set "VERSION=%%B"
for /f "tokens=* delims= " %%A in ("%VERSION%") do set "VERSION=%%A"
if "%VERSION%"=="" (
  echo Verze v pubspec.yaml nenalezena.
  exit /b 1
)
set TAG=v%VERSION%
set TITLE=Toastmasters %VERSION%
set REMOTE=origin
set BRANCH=master

echo Pouzivam verzi z: %PUBSPEC_PATH%

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
