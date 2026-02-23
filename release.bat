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
for /f "tokens=1,2 delims=+" %%A in ("%VERSION%") do (
  set "VERSION_NAME=%%A"
  set "VERSION_CODE=%%B"
)
if "%VERSION_CODE%"=="" (
  echo Nepodarilo se nacist build number z verze: %VERSION%
  exit /b 1
)
set TAG=v%VERSION%
set TITLE=Toastmasters %VERSION%
set REMOTE=origin
set BRANCH=master

echo Pouzivam verzi z: %PUBSPEC_PATH%
echo Build number: %VERSION_CODE%

REM ===== AKTUALIZACE CONFIG.YAML =====
set "CONFIG_PATH=config.yaml"
if exist "%CONFIG_PATH%" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
      "$path = '%CONFIG_PATH%';" ^
      "$enc = New-Object System.Text.UTF8Encoding($false);" ^
      "$text = [System.IO.File]::ReadAllText($path, $enc);" ^
      "if ($text -match '(?m)^latest_version_code:\s*') {" ^
      "  $text = [System.Text.RegularExpressions.Regex]::Replace($text, '(?m)^latest_version_code:\s*.*$', 'latest_version_code: %VERSION_CODE%')" ^
      "} else {" ^
      "  if ($text -notmatch '(\r?\n)$') { $text += [Environment]::NewLine }" ^
      "  $text += 'latest_version_code: %VERSION_CODE%' + [Environment]::NewLine" ^
      "}" ^
      "[System.IO.File]::WriteAllText($path, $text, $enc)"
  ) else (
    echo Config file %CONFIG_PATH% nenalezen, preskakuji aktualizaci.
  )
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
  gh release upload %TAG% ^
    app-release.apk ^
    update.yaml ^
    config.yaml ^
    --clobber
)

REM ===== ZAPIS VERZE DO GOOGLE SHEETS =====
set "GS_URL=https://script.google.com/macros/s/AKfycbywBHAkl_l1RMXT2gETU50Yi_lRIlxAJuEUfgziUE5bUrr6oZ9dEq6FsiDmw_BLckDxdg/exec"

echo Zapisuji verzi do Google Sheets: %VERSION%
curl -L "%GS_URL%?version=%VERSION%"



pause
