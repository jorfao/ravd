@echo off

SET spath=%~dp0
SET sdk=%1
SET avd=%2

cd %sdk%

start "" /D ".\tools\" emulator -avd %avd% -partition-size 2047 -no-snapshot-load -verbose -writable-system

echo wait for avd to boot
.\platform-tools\adb wait-for-device

.\platform-tools\adb root
.\platform-tools\adb remount
.\platform-tools\adb push %spath%su.pie /system/bin/su
.\platform-tools\adb shell chmod 06755 /system/bin/su
.\platform-tools\adb shell su --install
.\platform-tools\adb shell "su --daemon&"
.\platform-tools\adb shell setenforce 0

