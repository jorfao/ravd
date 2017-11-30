@echo off

SET spath=%~dp0
SET sdk=%1
SET avd=%2
SET port=9898
SET emulatorname=emulator-%port%

IF /I "%1"=="" echo Error: SDK not passed. Usage: ravd [SDK] [AVD] &&EXIT /B
IF /I "%2"=="" echo Error: AVD not passed. Usage: ravd [SDK] [AVD] &&EXIT /B

cd %sdk%
.\platform-tools\adb version >nul 2>&1||echo Error: SDK not found &&EXIT /B
.\tools\emulator -list-avds >nul 2>&1|| findstr /I %2

if %errorlevel% == 0 (
    start "" /D ".\tools\" emulator -avd %avd% -no-snapshot-load -verbose -writable-system -port 9898
    echo Wait for avd to boot...
    .\platform-tools\adb -s %emulatorname% wait-for-device
    echo Getting root access...
    .\platform-tools\adb -s %emulatorname% root
    echo Remount...
    .\platform-tools\adb -s %emulatorname% remount
    echo Pushing su.pie...
    .\platform-tools\adb -s %emulatorname% push %spath%su.pie /system/bin/su
    echo Changing su permissions...
    .\platform-tools\adb -s %emulatorname% shell chmod 06755 /system/bin/su
    echo Running daemon...
    .\platform-tools\adb -s %emulatorname% shell su --install
    .\platform-tools\adb -s %emulatorname% shell "su --daemon&"
    .\platform-tools\adb -s %emulatorname% shell setenforce 0
    echo Success
    cd %spath%
) else (
    echo Error: Emulator %2 not found &&EXIT /B
)

