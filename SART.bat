@echo off > "%temp%\clean_next_boot.bat"

:: ************************************************************************************
:: Script: System Access Restoration Tool (SART) Type I
::         SART.bat, adduser.bat, clean.bat, clean_next_boot.bat (auto generated)
:: Version: 1.0 (Professional Edition)
:: Function: To restore access to a locked Windows system for administrative recovery
::           using the accessibility tool replacement method (sethc.exe/utilman.exe).
::           This tool is intended for authorized system administration and recovery only.
:: ************************************************************************************

if not "%OS%"=="Windows_NT" echo "Windows version not supported" && goto :EOF

SETLOCAL ENABLEDELAYEDEXPANSION

:: debugging options
:: set debug=1
if defined debug echo :: Debugging mode is ON.
title "System Access Restoration Tool -- Administrative Access Recovery"

if /i "%~1" EQU /? goto _help

:: detects if working directory is wrong and corrects it if possible
set workDir1=%cd%\
if defined ECPP popd
for /f "usebackq tokens=* delims=" %%i in (`dir /a /b /s %~nx0 2^>nul`) do @set workDir2=%%~dpi
if "%workDir2%"=="" echo.&echo  ** ERROR: Working directory incorrect and cannot be corrected. &echo.&echo  "%~nx0" cannot be found in "%CD%".&echo.&goto :EOF
if defined ECPP pushd Exe
if /i "%workDir1%" NEQ "%workDir2%" (
	set pushdBit=1
	pushd "%workDir2%"
)

set PATH=%PATH%;%CD%\3rdparty;%CD%\subscripts
set PATHEXT=.COM;.EXE;.BAT;.CMD;.VBS;.VBE;.JS;.JSE;.WSF;.WSH;.MSC

:: detect winpe
reg query "hklm\software\microsoft\windows nt\currentversion" /v systemroot | find /i "x:\"
if %errorlevel% EQU 0 (set winpe=1)
reg query "hklm\software\microsoft\windows nt\currentversion" | find /i "preinstallation"
if %errorlevel% EQU 0 (set winpe=1)

:start
cls
echo.
echo                      - System Access Restoration Tool (SART) v1.0 -  
echo.
echo     :: Purpose: This script is designed to run under Windows PE or an external
echo        Windows environment to assist in regaining administrative access to a
echo        locked system by creating a temporary administrative user.
echo.
echo     :: Methodology: Replaces accessibility tools (sethc.exe/utilman.exe) with 
echo        cmd.exe temporarily. This allows an administrator to launch a command
echo        prompt at the logon screen (by pressing SHIFT 5 times) to creating 
echo        a temporary recovery account.
echo.
echo        Recovery Credentials: temp_admin / Password12!
echo.
echo        After access is restored, run "CLEAN" to revert system changes.
echo        Residual files will be cleaned up upon the next system boot.
echo.
echo     :: Dependencies: cacls, reg, taskkill/wkill, takeown/subinacl, startx
echo.
echo     :: Note: Use Type II if Sticky Keys is disabled on the target.
echo ______________________________________________________________
echo.
echo :: NOTICE: Ensure you have authorization to access the target system.
echo.
echo    - For Vista and later OS, run this script as Administrator.
echo ______________________________________________________________
echo.

echo.
pause
:menuMain
cls
echo.
echo :: SART Main Menu
echo.
echo    1. Method I -- Accessibility Tool Replacement (sethc.exe)
echo.
echo    2. Method II -- Service Creation (Alternative)
echo.
echo    3. Unattended Mode (Apply both methods w/ default options)
echo.
echo    4. System Cleanup (Revert changes)
echo.
echo    5. Display Documentation
echo.
echo    6. Check for Updates
echo.
echo    A. Exit
echo.
echo    B. Reboot System
echo.
call _choiceMulti.bat /msg ":: Please make a selection: [1,2,3,4,5,6,A,B] " /button 123456AB /errorlevel 8

if "%errorlevel%"=="8" (
	@if defined winpe (
		exit
	) else (
		shutdown -r -t 0
	)
)
if "%errorlevel%"=="7" cls&goto :EOF
if "%errorlevel%"=="6" call :_update&goto menu
if "%errorlevel%"=="5" (call :_help)&goto menu
if "%errorlevel%"=="4" (call ".\subscripts\clean.bat")&goto menu
if "%errorlevel%"=="3" set typeII=1&set typeI=1&unattended=1
if "%errorlevel%"=="2" set typeII=1&goto typeII
if "%errorlevel%"=="1" set typeI=1

goto _menuChooseWin

:start2

echo.
echo #  Verifying target Windows directory...
echo.
if /i "%windir:\=%" EQU "%userwindir:\=%" (
	echo _____________________________________________________________________________
	echo  
	echo #  Warning: You have specified the LOCAL Windows directory: %windir%
	echo.
	echo #  Caution: Ensure you are targeting the external drive/volume you wish to
	echo    restore access to, not the system you are currently running (unless intentional).
	echo.
)

if not defined typeII (
	if defined typeI (
		call _choiceYN ":: SART Type I will be applied to %userwindir%. Continue? [Y,N] " N 60
		if !errorlevel! NEQ 0 goto start
	) else (
		goto start
	)
) else (
	if defined typeI (
		call _choiceYN ":: SART Type I and II will be applied to %userwindir%. Continue? [Y,N] " N 60
		if !errorlevel! NEQ 0 goto start
	) else (
		call _choiceYN ":: SART Type II will be applied to %userwindir%. Continue? [Y,N] " N 60
		if !errorlevel! NEQ 0 (
			goto start
		) else (
			goto typeII
		)
	)
)

echo.
echo #  Validating existence of sethc.exe in target Windows...
echo.
if NOT exist %userwindir%\system32\sethc.exe (
echo.
echo #  ERROR: sethc.exe not found in %userwindir%\system32\sethc.exe. Verify path.
echo.
pause
goto start
)

echo.
echo #  Checking for previous SART installations...
echo.
if exist "%userwindir%\system32\clean.bat" (
	echo _____________________________________________________________________________
	echo.
	echo #  INFO: clean.bat found in target system32. SART may have already been
	echo          applied or not fully removed.
	echo.
	echo #  Continuing...
	echo.
	(timeout /T 6 >nul 2>&1) || (ping -n 6 -l 2 127.0.0.1 >nul 2>&1)
) else if exist "%userwindir%\system32\clean1.bat" (
	echo _____________________________________________________________________________
	echo.
	echo #  INFO: clean1.bat found. SART legacy files detected.
	echo.
	echo #  Continuing...
	echo.
	(timeout /T 6 >nul 2>&1) || (ping -n 6 -l 2 127.0.0.1 >nul 2>&1)
)

echo.
echo #  Checking for existing backup files...
echo.
dir "%userwindir%\system32\sethc.bac*" >nul 2>&1
if %errorlevel% EQU 0 (
	echo _____________________________________________________________________________
	echo.
	echo #  INFO: sethc.backup already exists. SART will attempt to restore from
	echo          system protected files first, then the oldest backup during cleanup.
	echo.
	echo #  Continuing...
	echo.
	(timeout /T 6 >nul 2>&1) || (ping -n 6 -l 2 127.0.0.1 >nul 2>&1)
)
dir "%userwindir%\system32\utilman.bac*" >nul 2>&1
if %errorlevel% EQU 0 (
	echo _____________________________________________________________________________
	echo.
	echo #  INFO: utilman.backup already exists.
	echo.
	echo #  Continuing...
	echo.
	(timeout /T 6 >nul 2>&1) || (ping -n 6 -l 2 127.0.0.1 >nul 2>&1)
)

echo.
echo #  Verifying required local executables...
echo.

reg >nul 2>&1
if %errorlevel% EQU 9009 (
	echo #  ERROR: reg.exe not in PATH.
	pause&set requiredExeMissing=1
)

cacls >nul 2>&1 
if %errorlevel% EQU 9009 (
	echo #  ERROR: cacls.exe not in PATH.
	pause&set requiredExeMissing=1
)

attrib >nul 2>&1 
if %errorlevel% EQU 9009 (
	echo #  ERROR: attrib.exe not in PATH.
	pause&set requiredExeMissing=1
	goto start
)

find >nul 2>&1 
if %errorlevel% EQU 9009 (
	echo #  ERROR: find.exe not in PATH.
	pause&set requiredExeMissing=1
	goto start
)

wkill >nul 2>&1
if %errorlevel% EQU 9009 (
	echo #  WARNING: wkill.exe not found (optional).
	pause
)

if not exist ".\3rdparty\pskill.exe"  (
	echo #  WARNING: pskill.exe not found (optional).
	pause
)

if not exist ".\3rdparty\movefile.exe"  (
	echo #  WARNING: movefile.exe not found. User profile cleanup may be incomplete.
	pause
)

if not exist ".\3rdparty\startx.exe" (
	echo #  WARNING: StartX.exe not found. Automatic background cleanup may fail.
	pause
)

sc start >nul 2>&1
if %errorlevel% EQU 9009 (
	echo #  ERROR: sc.exe not in PATH.
	pause&set requiredExeMissing=1
)

if not exist ".\3rdparty\srvany.exe" (
	echo #  ERROR: srvany.exe not found in 3rdparty folder.
	pause&set requiredExeMissing=1
)

if defined requiredExeMissing goto start

echo.
echo #  Verifying Administrator Privileges...
echo.
attrib %windir%\system32 -h | find /i "system32"
if %errorlevel% EQU 0 (
	echo _____________________________________________________________________________
	echo  
	echo #  FATAL ERROR: Insufficient privileges.
	echo                 Run this script as Administrator.
	echo.
	goto end
)

:: typeI begins

echo.
echo #  Loading target registry hives...
echo.
reg load HKLM\sartHKLM %userwindir%\system32\config\software
if %errorlevel% NEQ 0 (
	echo #  FATAL ERROR: Can't load registry: %userwindir%\system32\config\software
	goto end
)

reg load HKLM\sartDefaultUser %userwindir%\system32\config\default
if %errorlevel% NEQ 0 (
	echo #  WARNING: Can't load registry: %userwindir%\system32\config\default
	pause
	goto skipSticky
)

for /f "usebackq tokens=3 skip=2" %%i in (`reg query "HKLM\sartDefaultUser\Control Panel\Accessibility\StickyKeys" /v Flags`) do (
	@if "%%i" EQU "506" (
		echo.
		echo #  INFO: Sticky Keys is DISABLED on target system.
		echo.
	) else if "%%i" EQU "510" (
		echo.
		echo #  INFO: Sticky Keys is ENABLED on target system.
		echo.
		goto skipSticky
	) else (
		echo.
		echo #  INFO: Sticky Keys state unknown.
		echo.	
	)
)

echo.
echo #  Enabling Sticky Keys for target system account...
echo.
reg add "HKLM\sartDefaultUser\Control Panel\Accessibility\StickyKeys" /v Flags /t REG_SZ /d 510 /f

:skipSticky

echo.
echo #  Preparing boot cleanup script...
echo.   
echo @echo off   >> "%temp%\clean_next_boot.bat"
echo set typeI=1
echo. >> "%temp%\clean_next_boot.bat"
echo rem #  SART Cleanup Routine Part 2   >> "%temp%\clean_next_boot.bat"
echo. >> "%temp%\clean_next_boot.bat"
echo rem #  Remove temporary user profile     >> "%temp%\clean_next_boot.bat"
echo cd /d "%%userprofile%%" ^>nul 2^>^&1     >> "%temp%\clean_next_boot.bat"
echo cd.. ^>nul 2^>^&1     >> "%temp%\clean_next_boot.bat"
echo. >> "%temp%\clean_next_boot.bat"
echo rd /s /q "temp_admin" ^>nul 2^>^&1     >> "%temp%\clean_next_boot.bat"
echo.     >> "%temp%\clean_next_boot.bat"

echo.
echo #  Detecting target Windows version...
echo.
for /f "usebackq tokens=3 skip=2" %%i in (`reg query "HKLM\sartHKLM\Microsoft\Windows NT\CurrentVersion" /v CurrentVersion`) do set winver=%%i
if %errorlevel% NEQ 0 (
	echo #  FATAL ERROR: Cannot query registry for Windows version.
	goto end
)

echo.
echo #  Windows version %winver% detected.
echo.

if /i NOT %winver% geq 6 (
	echo rem #  remove StartX     >> "%temp%\clean_next_boot.bat"
	echo del "%%systemroot%%\system32\startx.exe" /f /q ^>nul 2^>^&1     >> "%temp%\clean_next_boot.bat"
	echo.     >> "%temp%\clean_next_boot.bat"
	echo rem #  remove itself     >> "%temp%\clean_next_boot.bat"
	echo del "%%systemroot%%\system32\clean_next_boot.bat" /f /q ^>nul 2^>^&1     >> "%temp%\clean_next_boot.bat"
	goto oldwin
)

echo _____________________________________________________________________________
echo   
echo :: Vista or later detected.
echo.
echo :: Replace utilman.exe (Ease of Access) as well? (Default: Y)
echo.
echo    Utilman.exe controls accessibility tools at the logon screen (Win+U).
echo    Replacing both sethc.exe and utilman.exe increases success rate.
echo.
call _choiceYN ":: Input your answer [Y,N]: " Y 60
if "%errorlevel%" EQU "0" set utilman=1
goto skipUtilman


:skipUtilman
for /f "usebackq tokens=3 skip=2" %%i in (`reg query HKLM\sartHKLM\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA`) do set uacBit=%%i
if "%uacbit%"=="0x0" (
	echo.
	echo #  Target UAC is already disabled.
	echo.
	echo rem #  remove StartX     >> "%temp%\clean_next_boot.bat"
	echo del "%%systemroot%%\system32\startx.exe" /f /q ^>nul 2^>^&1     >> "%temp%\clean_next_boot.bat"
	echo.     >> "%temp%\clean_next_boot.bat"
	echo rem #  remove itself     >> "%temp%\clean_next_boot.bat"
	echo del "%%systemroot%%\system32\clean_next_boot.bat" /f /q ^>nul 2^>^&1     >> "%temp%\clean_next_boot.bat"
	goto skipUAC
)

echo _____________________________________________________________________________
echo   
echo :: UAC (User Account Control) is enabled on target.
echo    Temporarily disable for smoother operation? (Default: Y)
echo.
echo    UAC will be automatically re-enabled by the cleanup script.
echo.
call _choiceYN ":: Input your answer [Y,N]: " Y 60
if "%errorlevel%" NEQ "0" goto skipUAC

reg.exe ADD HKLM\sartHKLM\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA /t REG_DWORD /d 0 /f

echo rem #  Enable UAC    >> "%temp%\clean_next_boot.bat"
echo reg.exe ADD HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA /t REG_DWORD /d 1 /f    >> "%temp%\clean_next_boot.bat"
echo. >> "%temp%\clean_next_boot.bat"
echo rem #  remove StartX     >> "%temp%\clean_next_boot.bat"
echo del "%%systemroot%%\system32\startx.exe" /f /q ^>nul 2^>^&1     >> "%temp%\clean_next_boot.bat"
echo. >> "%temp%\clean_next_boot.bat"
echo rem #  remove itself     >> "%temp%\clean_next_boot.bat"
echo del "%%systemroot%%\system32\clean_next_boot.bat" /f /q ^>nul 2^>^&1     >> "%temp%\clean_next_boot.bat"


:skipUAC

echo.
echo #  Checking for takeown.exe or subinacl.exe...
echo.
takeown >nul 2>&1
if %errorlevel% EQU 9009 (
	echo #  INFO: takeown.exe not found. Attempting subinacl.
	goto subinacl
)
echo.
echo #  Taking ownership of sethc.exe...
echo.
takeown /F "%userwindir%\system32\sethc.exe" /A
if %errorlevel% NEQ 0 (
	echo #  FATAL ERROR: Cannot take ownership.
	goto end
)

if defined utilman (
	echo.
	echo #  Taking ownership of utilman.exe...
	echo.
	takeown /F "%userwindir%\system32\utilman.exe" /A
	@if !errorlevel! NEQ 0 (
		echo #  FATAL ERROR: Cannot take ownership.
		goto end
	)	
)
goto cacls

:subinacl
subinacl >nul 2>&1
if %errorlevel% EQU 9009 (
	echo #  FATAL ERROR: Neither takeown.exe nor subinacl.exe found in PATH.
	goto end
)
echo.
echo #  Taking ownership using subinacl.exe...
echo.
subinacl /noverbose /file "%userwindir%\system32\sethc.exe" /setowner="Administrators"

if defined utilman (
	echo.
	echo #  Taking ownership of utilman.exe using subinacl.exe
	echo.
	subinacl /noverbose /file "%userwindir%\system32\utilman.exe" /setowner="Administrators"
)

:cacls

echo.
echo #  Granting administrative rights on sethc.exe...
echo.
cacls "%userwindir%\system32\sethc.exe" /grant administrators:F /E
if %errorlevel% NEQ 0 (
	echo #  FATAL ERROR: Can't grant rights using cacls.
	goto end
)

if defined utilman (
	echo.
	echo #  Granting administrative rights on utilman.exe...
	echo.
	cacls "%userwindir%\system32\utilman.exe" /grant administrators:F /E
	@if !errorlevel! NEQ 0 (
		echo #  FATAL ERROR: Can't grant rights using cacls.
		goto end
	)
)

:oldwin

echo.
echo #  Unloading target registry hive...
echo.
reg unload HKLM\sartHKLM
if %errorlevel% NEQ 0 (
	echo #  WARNING: Cannot unload registry hive.
	pause
)

reg unload HKLM\sartDefaultUser
if %errorlevel% NEQ 0 (
	echo #  WARNING: Cannot unload registry hive.
	pause
)

echo.
echo #  Backing up sethc.exe...
echo.
rename "%userwindir%\system32\sethc.exe" sethc.backup.%random%
if %errorlevel% NEQ 0 (
	echo #  FATAL ERROR: File rename failed.
	goto end
)

if defined utilman (
	echo.
	echo #  Backing up utilman.exe...
	echo.
	rename "%userwindir%\system32\utilman.exe" utilman.backup.%random%
	@if !errorlevel! NEQ 0 (
		echo #  FATAL ERROR: File rename failed.
		goto end
	)
)

echo.
echo #  Replacing sethc.exe with cmd.exe...
echo.
copy "%userwindir%\system32\cmd.exe" "%userwindir%\system32\sethc.exe" /y
if %errorlevel% NEQ 0 (
	echo #  FATAL ERROR: Replacement failed.
	goto end
)

if defined utilman (
	echo.
	echo #  Replacing utilman.exe with cmd.exe...
	echo.
	copy "%userwindir%\system32\cmd.exe" "%userwindir%\system32\utilman.exe" /y
	@if !errorlevel! NEQ 0 (
		echo #  FATAL ERROR: Replacement failed.
		goto end
	)
)

:: Copy required utilities to target

echo.
echo #  Copying support tools to "%userwindir%\system32\Sart"
echo.
copy ".\3rdparty\choice.exe" "%userwindir%\system32\Sart\choice.exe" /y
copy ".\3rdparty\pskill.exe" "%userwindir%\system32\Sart\pskill.exe" /y
copy ".\3rdparty\wkill.exe" "%userwindir%\system32\Sart\wkill.exe" /y
copy ".\3rdparty\movefile.exe" "%userwindir%\system32\Sart\movefile.exe" /y

echo.
echo #  Copying StartX.exe to "%userwindir%\system32"
echo.
copy ".\3rdparty\startx.exe" "%userwindir%\system32\startx.exe" /y
if %errorlevel% NEQ 0 (
	echo #  ERROR: Failed to copy StartX.exe. Background cleanup may fail.
	pause
)

:: Copy scripts

echo.
echo #  Copying scripts to target...
echo.
copy ".\subscripts\_choiceYN.bat" "%userwindir%\system32\Sart\_choiceYN.bat" /y
copy ".\subscripts\_choiceMulti.bat" "%userwindir%\system32\Sart\_choiceMulti.bat" /y

copy ".\subscripts\adduser.bat" "%userwindir%\system32\adduser.bat" /y
if %errorlevel% NEQ 0 (
	echo #  FATAL ERROR: Failed to copy adduser.bat.
	goto end
)

copy ".\subscripts\clean.bat" "%userwindir%\system32\clean.bat" /y
if %errorlevel% NEQ 0 (
	echo #  WARNING: Failed to copy clean.bat. Manual cleanup required.
	pause
)
copy "%temp%\clean_next_boot.bat" "%userwindir%\system32\clean_next_boot.bat" /y

echo _____________________________________________________________________________
echo.
echo :: SART Type I Setup Complete.
echo.
(timeout /T 6 >nul 2>&1) || (ping -n 6 -l 2 127.0.0.1 >nul 2>&1)

:typeII
if not defined typeII goto finish

:finish

if defined typeI type nul > "%userwindir%\system32\Sart\typeI"
if defined typeII type nul > "%userwindir%\system32\Sart\typeII"

echo.
echo.
echo.
echo. 
echo                    - Setup Phase Complete !!
echo.
echo     :: Phase 2: Reboot the target system. At the logon screen, press the
echo        SHIFT key 5 times to launch the Administrative Command Prompt.
echo        Type "ADDUSER" to create the recovery account.
echo.
echo        Credentials to note:
echo         - Username: temp_admin
echo         - Password: Password12^!
echo         - (Case sensitive)
echo.
echo     :: Phase 3: After completing maintenance, run "CLEAN" from the
echo        command prompt to restore system state.
echo.
:end
echo.
echo #  SART Setup Exiting.
echo.
pause
if defined pushdBit popd&set pushdBit=
ENDLOCAL
goto :EOF

:_update
:: Update functionality placeholder
goto :EOF

:_menuChooseWin
if not defined debug cls
echo.
echo :: Select Target Windows Location:
echo.
echo    1. Auto-Search
echo.
echo    2. Manual Path Entry
echo.
echo    A. Back
echo.
call _choiceMulti.bat /msg ":: Selection: [1,2,A] " /button 12A /errorlevel 3
if "%errorlevel%"=="3" goto menuMain
if "%errorlevel%"=="2" echo ______________________________________________________________&goto manual
if "%errorlevel%"=="1" goto auto

:manual
echo.
echo :: Enter target Windows directory (e.g., E:\Windows):
echo.
set /p userwindir=:: Path: 
for %%i in (%userwindir%) do set userwindir=%%~i
if /i "%userwindir%"=="back" goto _menuChooseWin
if /i "%userwindir%"=="a" goto _menuChooseWin
echo %userwindir% | find /i ":\" >nul 2>&1
if %errorlevel% NEQ 0 cls&goto manual
goto start2

:auto
if not defined debug cls
set count=0
for %%i in (B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
if exist %%i:\Windows.old/Windows\nul (set /a count+=1 && set SWI!count!=!count!=%%i:\Windows.old\Windows)
if exist %%i:\WinNT\nul (set /a count+=1 && set SWI!count!=!count!=%%i:\WinNT)
if exist %%i:\Windows\nul (set /a count+=1 && set SWI!count!=!count!=%%i:\Windows)
)
if not defined debug cls
set num=0
for /f "usebackq" %%i in (`set SWI`) do set /a num+=1
if not "%num%"=="0" goto foundWin
echo  
echo ** ERROR: No Windows installations found. Please specify manually.
echo.
pause
goto start

:foundWin
echo.
echo :: Windows installations found:
echo.
for /f "usebackq delims== tokens=1-3" %%i in (`set SWI`) do echo    %%j. %%k&echo.
set /a numPlus=%num%+1
echo    A. Back
echo.
for /l %%i in (1,1,%num%) do set butMinus=!butMinus!%%i
call _choiceMulti /msg ":: Selection: " /button %butMinus%A /errorlevel %numPlus%
if "%errorlevel%" EQU "%numPlus%" goto _menuChooseWin
set chosenwin=%errorlevel%
for /f "usebackq delims== tokens=1-3" %%i in (`set SWI%chosenwin%`) do set userwindir=%%k
goto start2

:_help
:: Help text placeholder
goto :EOF