@ECHO OFF
:: BatchGotAdmin
::-------------------------------------
REM  --> Check for permissions
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

REM --> If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    set params = %*:"="
    echo UAC.ShellExecute "cmd.exe", "/c %~s0 %params%", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    pushd "%CD%"
    CD /D "%~dp0"
::--------------------------------------
::START THE DEPLOY CODE BELOW:
::--------------------------------------

:: Change this to your service name
SET service=ws-salesforce-hub
:: Chamge the name of .zip file
SET zip_name="ws-salesforce-hub.zip"
:: seting folders
SET output_path="D:\programs\ws-salesforce-hub"
:: Get state of service ("RUNNING"?)
for /f "tokens=1,3 delims=: " %%a in ('sc query %service%') do (
  if "%%a"=="STATE" set state=%%b
)
:: Get start type of service ("AUTO_START" or "DEMAND_START")
for /f "tokens=1,3 delims=: " %%a in ('sc qc %service%') do (
  if "%%a"=="START_TYPE" set start=%%b
)
echo Service "%service%" State "%state%"  start "%start%" 
pause 
:: If start=="" assume Service was not found, ergo is disabled(?)
if "%state%"=="" (
  echo Service "%service%" could not be found, it might be disabled // start unzip files.
  CALL :CLEANFOLDER %output_path%
  CALL :UNZIP %output_path%, %zip_name%
  CALL :INSTALLSERVICE %output_path%
  CALL :STARTSERVICE %service%
  echo end script
  pause
  exit /b
)
:: If running: stop, disable and print message
if "%state%"=="RUNNING" (
  CALL :STOPSERVICE %service%
  CALL :UNISTALLSERVICE %output_path%
  CALL :CLEANFOLDER %output_path%
  CALL :UNZIP %output_path%, %zip_name%
  CALL :INSTALLSERVICE %output_path%
  CALL :STARTSERVICE %service%
  echo end script
  pause
  exit /b
)
:: If running: stop, disable and print message
if "%state%"=="STOPPED" (
  echo Service "%service%" is stopped.
  CALL :UNISTALLSERVICE %output_path%
  CALL :CLEANFOLDER %output_path%
  CALL :UNZIP %output_path%, %zip_name%
  CALL :INSTALLSERVICE %output_path%
  CALL :STARTSERVICE %service%
  echo end script
  pause
  exit /b
)
:UNZIP 
echo unzip
  powershell.exe -nologo -noprofile -command "& { Add-Type -A 'System.IO.Compression.FileSystem'; [IO.Compression.ZipFile]::ExtractToDirectory('./%~2', '%~1'); }"
echo Finished unzip files.
goto :EOF
:CLEANFOLDER
echo delete old files
cd /d %~1
for /F "delims=" %%i in ('dir /b') do (rmdir "%%i" /s/q || del "%%i" /s/q)
cd /D  %~dp0
echo end delete old files 
goto :EOF  
:STARTSERVICE
echo start service. please wait ...
sc start %~1
goto :EOF
:STOPSERVICE
echo stop service
sc stop %~1
echo Service "%~1%" was stopped.
goto :EOF  
:INSTALLSERVICE
echo install service. please wait ... 
CMD /c ""%~1\ws-salesforce-hub.exe"" install
echo end install 
goto :EOF  
:UNISTALLSERVICE
echo uninstall service 
CMD /c ""%~1\ws-salesforce-hub.exe"" uninstall
echo end unistall
goto :EOF