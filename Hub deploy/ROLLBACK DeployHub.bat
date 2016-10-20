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
:: seting folders
SET output_path="C:\D\programs\ws-salesforce-hub"
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
  CALL :INSTALLSERVICE %output_path%
  echo end script
  pause
  exit /b
)
:: If running: stop, disable and print message
if "%state%"=="RUNNING" (
  CALL :STOPSERVICE %service%
  CALL :UNISTALLSERVICE %output_path%
  echo end script
  pause
  exit /b
)
:: If running: stop, disable and print message
if "%state%"=="STOPPED" (
  echo Service "%service%" is stopped.
  CALL :UNISTALLSERVICE %output_path%
  echo end script
  pause
  exit /b
)
:STOPSERVICE
echo stop service
sc stop %~1%
echo Service "%service%" was stopped.
goto :EOF  
:UNISTALLSERVICE
echo uninstall service 
CMD /c ""%~1%\ws-salesforce-hub.exe"" uninstall
echo end unistall
goto :EOF