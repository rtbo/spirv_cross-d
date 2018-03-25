@echo off

WHERE cmake >nul 2>nul
IF %ERRORLEVEL% NEQ 0 (
    ECHO cmake wasn't found
    EXIT 1
)

set PACKAGE_DIR=%1
set VCARCH=%2
set BUILD_TYPE=Release
set CPP_DIR=%PACKAGE_DIR%\cpp
set BUILD_DIR=%PACKAGE_DIR%\.dub\build\sc_cpp_%VCARCH%_%BUILD_TYPE%

setlocal enableextensions
call "%~dp0msvcEnv.bat" %VCARCH%

MD %BUILD_DIR%
CD %BUILD_DIR%

cmake -G "NMake Makefiles" -DCMAKE_BUILD_TYPE=%BUILD_TYPE% %CPP_DIR%
IF %ERRORLEVEL% NEQ 0 EXIT 1

cmake --build %BUILD_DIR%
IF %ERRORLEVEL% NEQ 0 EXIT 1

COPY %BUILD_DIR%\spirv_cross_cpp.lib %PACKAGE_DIR%
IF %ERRORLEVEL% NEQ 0 EXIT 1

endlocal
EXIT 0
