@ECHO OFF

IF DEFINED ProgramW6432 (
SET SPDDIR="%ProgramW6432%\SP Devices"
) ELSE (
SET SPDDIR="%ProgramFiles%\SP Devices"
)

REM Remove previous adqapi.h to make sure tthere will not be mixing between old adqapi.h and new adqapi.dll
IF EXIST adqapi.h del adqapi.h

IF EXIST %SPDDIR%\ADQAPI_x64\adqapi.dll (GOTO COPY_INSTALLED_FILES) ELSE (GOTO COPY_DEV_FILES)
GOTO ERROR

:COPY_DEV_FILES
ECHO Copying development ADQAPI...
REM No need to copy .dll and .lib if ADQAPI project is already included in the solution file
copy ..\..\..\..\..\..\Software\ADQAPI\Release\adqapi.h .\Debug
copy ..\..\..\..\..\..\Software\ADQAPI\Release\adqapi.h .
IF NOT ERRORLEVEL 0 GOTO ERROR
GOTO END

:COPY_INSTALLED_FILES
ECHO Copying installed ADQAPI...
copy %SPDDIR%\ADQAPI\adqapi.dll .\Debug\
IF NOT ERRORLEVEL 0 GOTO ERROR
copy %SPDDIR%\ADQAPI\adqapi.lib .\Debug\
IF NOT ERRORLEVEL 0 GOTO ERROR
copy %SPDDIR%\ADQAPI\adqapi.h .
IF NOT ERRORLEVEL 0 GOTO ERROR
GOTO END

:ERROR
ECHO Error, missing ADQAPI files!
EXIT /B 1

:END
ECHO ...done!
EXIT /B 0
