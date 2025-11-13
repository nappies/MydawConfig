@echo off
setlocal


rd /s /q "D:\WORK_FOLDER\TESTTT"

del /q "D:\REPERSTUFF\MyDaw_Installer\QT_I_FW\!!mydaw-installer\MyDawInstaller.exe"

mkdir "D:\WORK_FOLDER\TESTTT"

:: ===============================
:: Configuration — adjust these
:: ===============================

set IFW_BIN="D:\REPERSTUFF\MyDaw_Installer\QT_I_FW\bin\binarycreator.exe"

:: Path to your installer project directories

set PROJECT_ROOT=%~dp0
set CONFIG_DIR=%PROJECT_ROOT%config
set PACKAGES_DIR=%PROJECT_ROOT%packages

:: Output installer name
set OUTPUT_INSTALLER=%PROJECT_ROOT%MyDawInstaller.exe



:: ===============================
:: Build steps
:: ===============================

echo Building Qt Installer using IFW...

:: (Optional) Clean old installer
if exist %OUTPUT_INSTALLER% (
    echo Removing old installer %OUTPUT_INSTALLER%
    del /f /q %OUTPUT_INSTALLER%
)

:: Run binarycreator
echo Running binarycreator...
%IFW_BIN% ^
    --offline-only ^
    -c "%CONFIG_DIR%\config.xml" ^
    -p "%PACKAGES_DIR%" ^
    "%OUTPUT_INSTALLER%"

if errorlevel 1 (
    echo ERROR: binarycreator failed with exit code %errorlevel%.
    
)

echo Installer built successfully: %OUTPUT_INSTALLER%

endlocal

pause