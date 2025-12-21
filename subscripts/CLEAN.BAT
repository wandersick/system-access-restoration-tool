@echo off

:: ************************
:: Script: CLEAN.BAT (SART Sub-module)
::         Restores system state and removes temporary files.
:: ************************

if not "%OS%"=="Windows_NT" echo "Windows version not supported" && goto :EOF

SETLOCAL ENABLEDELAYEDEXPANSION

set userwindir=%windir%
cd /d "%userwindir%\system32"
set PATH=%PATH%;%cd%\Sart
set PATHEXT=.COM;.EXE;.BAT;.CMD;.VBS;.VBE;.JS;.JSE;.WSF;.WSH;.MSC

:start
cls
echo.
echo                          =================
echo                             SART Cleanup
echo                          =================
echo.
echo :: This script will revert changes made by the System Access Restoration Tool.
echo.
echo    - Do NOT run this via the accessibility shortcut (SHIFT x5).
echo      Run via a standard Administrator Command Prompt.
echo.
echo    - ONLINE mode: Deletes temp account and profile (Run from within target OS).
echo    - OFFLINE mode: Restores files only (Run from external OS/WinPE).
echo _____________________________________________________________________
echo.
echo :: Current Target: %userwindir%
echo.
echo    1. Change Target
echo    2. Start Cleanup
echo.
_choiceMulti.bat /msg "Please select: [1,2] " /errorlevel
if %errorlevel%==1 goto start2
if %errorlevel%==0 goto _menuChooseWin

:start2
echo.
echo #  Verifying target...
echo.
if /i "%windir:\=%" EQU "%userwindir:\=%" (
	set online=1
	echo #  Mode: ONLINE (Active System)
) else (
	set offline=1
	echo #  Mode: OFFLINE (External System)
)

if exist "%userwindir%\Sart\typeI" set typeI=1
if exist "%userwindir%\Sart\typeII" set typeII=1

echo.
call _choiceYN ":: Ready to cleanup? [Y,N] " N 60
if %errorlevel% NEQ 0 goto start

cd /d "%userwindir%\system32"

echo.
echo #  Checking privileges...
echo.
attrib %windir%\system32 -h | find /i "system32"
if %errorlevel% EQU 0 (
	echo #  FATAL ERROR: Administrator privileges required.
	goto end
)

echo.
echo #  Locating backup files...
echo.
dir /tc /od sethc.backup.* >nul 2>&1
if %errorlevel% NEQ 0 (
	echo #  INFO: sethc.backup not found. Verification failed?
) else (
	@for /f "usebackq" %%i in (`dir /b /tc /od sethc.ba*`) do (ren "%%i" sethc.backup >nul 2>&1)
)

dir /tc /od utilman.backup.* >nul 2>&1
if %errorlevel% EQU 0 (
	set utilman=1
	@for /f "usebackq" %%i in (`dir /b /tc /od utilman.ba*`) do (ren "%%i" utilman.backup >nul 2>&1)
)

echo.
echo #  Terminating replaced processes...
echo.
taskkill /F /im sethc.exe >nul 2>&1
if defined utilman taskkill /F /im utilman.exe >nul 2>&1

goto restore

:restore

echo.
echo #  Restoring original binaries...
echo.
del "%userwindir%\System32\sethc.exe" /q /f
if defined utilman del "%userwindir%\System32\utilman.exe" /q /f

echo.
echo #  Attempting restoration from Backup...
echo.
if exist "%userwindir%\System32\sethc.backup" ren "%userwindir%\System32\sethc.backup" "sethc.exe"
if defined utilman if exist "%userwindir%\System32\utilman.backup" ren "%userwindir%\System32\utilman.backup" "utilman.exe"

:delet

:: Cleanup backups
del sethc.bac* /f /q > nul 2>&1
if defined utilman del utilman.bac* /f /q > nul 2>&1

if defined offline goto offlineSkip

echo.
echo #  Removing temporary account (temp_admin)...
echo.
net user temp_admin /del

echo.
echo #  Scheduling profile cleanup...
echo.
reg add "HKCU\Software\Sysinternals\Movefile" /v "EulaAccepted" /t REG_DWORD /d 0x1 /f

pushd "%userprofile%" >nul 2>&1
cd.. >nul 2>&1
cd temp_admin >nul 2>&1
for /f "usebackq tokens=* delims=" %%i in (`dir /a /b /s`) do movefile "%%i" "" >nul 2>&1
popd

echo.
echo #  Configuring RunOnce for final cleanup...
echo.
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" /v "SartCleanup" /t REG_SZ /d "\"%userwindir%\System32\startx.exe\" \"\" /b \"%userwindir%\System32\clean_next_boot.bat\"" /f

echo.
echo #  Removing SART scripts...
echo.
if exist "%userwindir%\system32\adduser.bat" del "%userwindir%\system32\adduser.bat" /f /q
rd "%userwindir%\Sart" /q /s

echo.
echo                          ==============================
echo                             CLEANUP INITIATED
echo                          ==============================
echo.
echo #  Primary cleanup complete.
echo #  Remaining artifacts (profile folders) will be removed automatically
echo    upon the next system logon.
echo.
pause
(del clean.bat /f /q >nul 2>&1)
goto end

:offlineSkip
if exist "%userwindir%\system32\startx.exe" del "%userwindir%\system32\startx.exe" /f /q
if exist "%userwindir%\system32\clean_next_boot.bat" del "%userwindir%\system32\clean_next_boot.bat" /f /q
if exist "%userwindir%\system32\adduser.bat" del "%userwindir%\system32\adduser.bat" /f /q
if exist "%userwindir%\system32\clean.bat" del "%userwindir%\system32\clean.bat" /f /q
rd "%userwindir%\Sart" /q /s

:end
ENDLOCAL
goto :EOF