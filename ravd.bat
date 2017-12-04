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

    FOR /F "tokens=2*delims==" %%a IN ('findstr /R abi.type "%UserProfile%\.android\avd\%avd%.avd\config.ini"') do SET arch=%%a

    IF "!arch!"=="x86" (SET sufile=x86\su.pie SET sufilename=su.pie)
    IF "!arch!"=="x64" (SET sufile=x64\su SET sufilename=su)
    IF "!arch!"=="x86_64" (SET sufile=x64\su SET sufilename=su)
    IF "!arch!"=="armeabi-v7a" (SET sufile=armv7\su SET sufilename=su)
    IF "!arch!"=="mips" (SET sufile=mips\su SET sufilename=su)
    IF "!arch!"=="mips64" (SET sufile=mips64\su SET sufilename=su)
    IF "!arch!"=="arm64-v8a" (SET sufile=arm64\su SET sufilename=su)
    IF "!arch!"=="arm" (SET sufile=arm\su SET sufilename=su)
    IF "!arch!"=="armeabi" (SET sufile=arm\su SET sufilename=su)

    SET sufile=%arch%\%sufilename%

    echo Pushing %sufilename% for %arch%...
    .\platform-tools\adb -s %emulatorname% push %spath%%sufile% /system/bin/%sufilename%
    
    echo Changing su permissions...
    .\platform-tools\adb -s %emulatorname% shell chmod 06755 /system/bin/%sufilename%
    
    echo Running daemon...
    .\platform-tools\adb -s %emulatorname% shell "%sufilename% --install"
    .\platform-tools\adb -s %emulatorname% shell "%sufilename% --daemon&"
    .\platform-tools\adb -s %emulatorname% shell "setenforce 0"
    
    echo Success
    cd %spath%
) else (
    echo Error: Emulator %2 not found &&EXIT /B
)
