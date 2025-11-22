@echo off
setlocal enabledelayedexpansion

echo ========================================
echo Построение проекта AniDev
echo ========================================
echo.

REM Проверка, был ли передан параметр (release/debug)
set BUILD_MODE=debug
if "%1"=="release" (
    set BUILD_MODE=release
    echo Режим сборки: Release
) else (
    echo Режим сборки: Debug (используйте "build.bat release" для сборки релизной версии)
)

echo.
echo Начинается сборка...
echo.

if "%BUILD_MODE%"=="release" (
    cargo build --release
) else (
    cargo build
)

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo Сборка успешно завершена!
    echo ========================================
    exit /b 0
) else (
    echo.
    echo ========================================
    echo Сборка завершилась ошибкой! Код ошибки: %ERRORLEVEL%
    echo ========================================
    exit /b %ERRORLEVEL%
)
