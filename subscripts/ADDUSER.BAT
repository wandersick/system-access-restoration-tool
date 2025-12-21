@echo off

:: ************************
:: Script: ADDUSER.BAT (SART Sub-module)
::         Creates recovery account and refreshes logon screen.
:: ************************

if not "%OS%"=="Windows_NT" echo "Windows version not supported" && goto :EOF

SETLOCAL ENABLEDELAYEDEXPANSION

cd /d "%windir%\system32"
SET PATH=%PATH%;%cd%\Sart
SET PATHEXT=.COM;.EXE;.BAT;.CMD;.VBS;.VBE;.JS;.JSE;.WSF;.WSH;.MSC

:: Unattended check
if /i "%~1" NEQ "/auto" goto start
net user temp_admin Password12! /add
net localgroup administrators temp_admin /add
for /f "usebackq tokens=3" %%i in (`reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentVersion`) do set winver=%%i
if %winver% GEQ 6 set NewOS=1
taskkill /F /im logonUI.exe >nul 2>&1
if defined NewOS logonUI.exe
goto :EOF

:start
echo.
echo #  SART Account Creation Utility
echo.
echo #  This will add a temporary administrator account to the system.
echo.
echo         - Username: temp_admin
echo         - Password: Password12^!
echo         - (Case sensitive)
echo.
pause
echo.

net user temp_admin Password12! /add
net localgroup administrators temp_admin /add

if %errorlevel% NEQ 0 (
	echo _____________________________________________________________________________
	echo  
	echo #  WARNING: Account creation failed.
	echo.
	echo #  Account may already exist. Launching User Manager (lusrmgr.msc)...
	echo.
	mmc /b lusrmgr.msc
	pause
)

echo _____________________________________________________________________________
echo  
echo #  Refresh Logon Screen? (Default: Y)
echo.
call _choiceYN.bat "Select your choice: [Y,N]" Y 60
if %errorlevel% NEQ 0 goto finish

echo.
echo #  Refreshing interface...
echo.
taskkill /F /im logonUI.exe >nul 2>&1
:: WinVer check repeated here for brevity, usually required to know if we need to relaunch logonUI manually
for /f "usebackq tokens=3" %%i in (`reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentVersion`) do set winver=%%i
if %winver% GEQ 6 (
    logonUI.exe
)

:finish
echo.
echo #  Temporary administrative account configured.
:end
ENDLOCAL
echo.
echo #  Exiting...
echo.
pause