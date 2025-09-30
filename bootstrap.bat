@echo off
setlocal EnableExtensions

set "VSFLAG=0"
if /I "%~1"=="--vstudio" set "VSFLAG=1"

goto :main

:require_cmd
where %~1 >NUL 2>&1 || (set "ERRSTEP=%~2 is not installed or not in PATH" & goto :fatal)
echo [INFO] %~2 found.
exit /b 0

:main
set "ZIPFILE=v8_12.9.202.28_v1.0.zip"
set "V8_URL=https://github.com/xls/V8-libraries/releases/download/v8_12.9.202.28_v1.0/v8_12.9.202.28_v1.0.zip"

call :require_cmd git "Git"
call :require_cmd scons "scons"
call :require_cmd curl "curl"
call :require_cmd tar "tar"

set "DEVENV="
where devenv.exe 1>NUL 2>&1  && for /F "delims=" %%I in ('where devenv.exe') do set "DEVENV=%%I"
if not defined DEVENV if exist "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\devenv.exe" set "DEVENV=C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\devenv.exe"
if not defined DEVENV if exist "C:\Program Files\Microsoft Visual Studio\2022\Professional\Common7\IDE\devenv.exe" set "DEVENV=C:\Program Files\Microsoft Visual Studio\2022\Professional\Common7\IDE\devenv.exe"
if not defined DEVENV if exist "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\Common7\IDE\devenv.exe" set "DEVENV=C:\Program Files\Microsoft Visual Studio\2022\Enterprise\Common7\IDE\devenv.exe"

if defined DEVENV (
  echo [INFO] Visual Studio detected: "%DEVENV%"
) else (
  echo [INFO] Visual Studio 2022 not found. Proceeding without it.
)

set "GROOT="
set "SCRIPT_DIR=%~dp0"
if exist "%SCRIPT_DIR%SConstruct" set "GROOT=%SCRIPT_DIR%"
if not defined GROOT if exist "SConstruct" if exist "modules" set "GROOT=%CD%\"
if not defined GROOT if exist "godot\SConstruct" set "GROOT=%CD%\godot\"
if not defined GROOT if exist "godot" set "GROOT=%CD%\godot\"
if not defined GROOT (
  if exist "godot" (
    echo [INFO] godot repo already present, skipping clone.
  ) else (
    git clone -b 4.5-dev --recursive https://github.com/xls/godot || (set "ERRSTEP=git clone godot" & goto :fatal)
  )
  set "GROOT=%CD%\godot\"
)
for %%G in ("%GROOT%") do set "GROOT=%%~fG\"
echo [INFO] Repo root: %GROOT%

if not exist "%GROOT%modules" md "%GROOT%modules" || (set "ERRSTEP=mkdir modules" & goto :fatal)
pushd "%GROOT%modules" || (set "ERRSTEP=cd modules" & goto :fatal)

if exist "GodotJS" (
  echo [INFO] GodotJS repo already present, skipping clone.
) else (
  git clone -b 4.5-dev --recursive https://github.com/xls/GodotJS || (set "ERRSTEP=git clone GodotJS" & goto :fatal)
)

pushd "GodotJS" || (set "ERRSTEP=cd GodotJS" & goto :fatal)

if exist "v8" (
  echo [INFO] v8 folder already present, skipping V8 download/extract.
) else (
  curl -L -o "%ZIPFILE%" "%V8_URL%" || (set "ERRSTEP=Downloading %ZIPFILE%" & goto :fatal)
  tar -xf "%ZIPFILE%" || (set "ERRSTEP=Extracting %ZIPFILE%" & goto :fatal)
  del "%ZIPFILE%" || (set "ERRSTEP=Deleting %ZIPFILE%" & goto :fatal)
)

if exist "package.json" (
  where pnpm >NUL 2>&1 && (
    echo [INFO] GodotJS - pnpm install
    call pnpm install || (set "ERRSTEP=pnpm install" & goto :fatal)
    echo [INFO] GodotJS - pnpm build
    call pnpm build || (set "ERRSTEP=pnpm build" & goto :fatal)
  ) || (
    echo [INFO] pnpm not found, skipping pnpm install
  )
) else (
  echo [WARN] No package.json in %CD%, skipping npm/pnpm install.
)

popd
popd

set "PATHEXT=.COM;.EXE;.BAT;.CMD;.VBS;.VBE;.JS;.JSE;.WSF;.WSH;.MSC"
set "PATH=%GROOT%modules\GodotJS\node_modules\.bin;%ProgramFiles%\nodejs;%AppData%\pnpm;%PATH%"
where pnpm >NUL 2>&1 && echo [INFO] pnpm on PATH for SCons: & where pnpm

if "%VSFLAG%"=="1" goto do_vs
goto do_cli

:do_vs
echo [INFO] Generating Visual Studio project and opening solution...
pushd "%GROOT%"
scons platform=windows dev_mode=yes vsproj=yes || (set "ERRSTEP=scons vsproj generation" & popd & goto :fatal)
if not exist "godot.sln" (popd & set "ERRSTEP=godot.sln not found after vsproj generation" & goto :fatal)
if defined DEVENV (
  start "" "%DEVENV%" "godot.sln"
) else (
  start "" "godot.sln"
)
popd
goto end

:do_cli
echo [INFO] Building Godot for Windows (default CLI)...
pushd "%GROOT%"
scons platform=windows || (set "ERRSTEP=scons build" & popd & goto :fatal)
echo [DONE] Godot executables are in .\bin
if exist "bin" (
  pushd "bin"
  echo [INFO] Now in %CD%
) else (
  echo [WARN] .\bin directory not found. Staying in %CD%.
)
popd
goto end

:fatal
echo [ABORT] %ERRSTEP%
exit /b 1

:end
echo [SUCCESS] All steps completed.
exit /b 0
