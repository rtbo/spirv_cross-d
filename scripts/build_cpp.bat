@echo off

WHERE cmake >nul 2>nul
IF %ERRORLEVEL% NEQ 0 (
    ECHO cmake wasn't found
    EXIT 1
)

set PACKAGE_DIR=%1
set ARCH=%2
set VCARCH=%2
if %ARCH%==x86_64 ( set VCARCH=amd64 )
set BUILD_TYPE=Release
set CPP_DIR=%PACKAGE_DIR%\cpp
set BUILD_DIR=%PACKAGE_DIR%\build_cpp-%BUILD_TYPE%-%VCARCH%
set INSTALL_DIR=%PACKAGE_DIR%\lib\windows-%ARCH%

setlocal enableextensions
call "%~dp0msvcEnv.bat" %VCARCH%

MD %BUILD_DIR%
CD %BUILD_DIR%

cmake -G "NMake Makefiles" -DCMAKE_BUILD_TYPE=%BUILD_TYPE% %CPP_DIR%
IF %ERRORLEVEL% NEQ 0 EXIT 1

cmake --build %BUILD_DIR%
IF %ERRORLEVEL% NEQ 0 EXIT 1

MD %INSTALL_DIR%
COPY %BUILD_DIR%\spirv_cross_cpp.lib %INSTALL_DIR%
IF %ERRORLEVEL% NEQ 0 EXIT 1

endlocal
EXIT 0
