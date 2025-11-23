@echo off
setlocal enabledelayedexpansion

echo ========================================
echo Построение проекта AniDev
echo ========================================
echo.

REM Проверка наличия cargo
where cargo >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ОШИБКА: Cargo не найден в PATH. Убедитесь, что Rust установлен.
    exit /b 1
)

REM Проверка, был ли передан параметр (release/debug)
set BUILD_MODE=release
if "%1"=="debug" (
    set BUILD_MODE=debug
    echo Режим сборки: Debug
) else if "%1"=="release" (
    set BUILD_MODE=release
    echo Режим сборки: Release
) else if not "%1"=="" (
    echo Неизвестный режим: %1
    echo Использование: build.bat [debug^|release]
    echo По умолчанию: release
    exit /b 1
) else (
    echo Режим сборки: Release (по умолчанию)
    echo Используйте "build.bat debug" для сборки debug версии
)

echo.
echo Начинается сборка...
echo.

REM Выполнение сборки
if "%BUILD_MODE%"=="release" (
    cargo build --release
) else (
    cargo build
)

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ========================================
    echo Сборка завершилась ошибкой! Код ошибки: %ERRORLEVEL%
    echo ========================================
    exit /b %ERRORLEVEL%
)

echo.
echo Сборка завершена успешно. Копирование плагинов...
echo.

REM Создание директории plugins если отсутствует
if not exist "plugins" (
    mkdir plugins
)

REM Автоматическое определение плагинов
set PLUGIN_COUNT=0
for /d %%P in (plugins\*) do (
    if exist "%%P\Cargo.toml" (
        set PLUGIN_LIB_NAME=
        set PLUGIN_PACKAGE_NAME=
        set IN_LIB_SECTION=0
        
        REM Чтение Cargo.toml и поиск имени библиотеки
        for /f "usebackq tokens=*" %%L in ("%%P\Cargo.toml") do (
            set "LINE=%%L"
            set "CLEAN_LINE=!LINE: =!"
            
            REM Проверка на начало секции [lib]
            echo !CLEAN_LINE! | findstr /r /c:"^\[lib\]" >nul
            if !ERRORLEVEL! EQU 0 (
                set IN_LIB_SECTION=1
            )
            
            REM Проверка на начало секции [package]
            echo !CLEAN_LINE! | findstr /r /c:"^\[package\]" >nul
            if !ERRORLEVEL! EQU 0 (
                set IN_LIB_SECTION=0
            )
            
            REM Поиск name = "..." в текущей секции
            echo !LINE! | findstr /r /c:"name = " >nul
            if !ERRORLEVEL! EQU 0 (
                if !IN_LIB_SECTION! EQU 1 (
                    REM Извлечение значения из кавычек для [lib]
                    for /f "tokens=2 delims=^"" %%N in ("!LINE!") do (
                        set PLUGIN_LIB_NAME=%%N
                    )
                ) else (
                    REM Извлечение значения из кавычек для [package]
                    for /f "tokens=2 delims=^"" %%N in ("!LINE!") do (
                        set PLUGIN_PACKAGE_NAME=%%N
                    )
                )
            )
        )
        
        REM Используем имя библиотеки, если найдено, иначе имя пакета с заменой дефисов
        if defined PLUGIN_LIB_NAME (
            set PLUGIN_NAME=!PLUGIN_LIB_NAME!
        ) else if defined PLUGIN_PACKAGE_NAME (
            REM Заменяем дефисы на подчеркивания в имени пакета
            set PLUGIN_NAME=!PLUGIN_PACKAGE_NAME!
            set PLUGIN_NAME=!PLUGIN_NAME:-=_!
            REM Если замена не сработала (batch ограничения), пробуем оба варианта при копировании
        ) else (
            REM Используем имя директории как fallback
            for %%F in ("%%P") do set PLUGIN_NAME=%%~nxF
        )
        
        REM Копирование DLL файла
        set SOURCE_FILE=target\%BUILD_MODE%\!PLUGIN_NAME!.dll
        set DEST_FILE=plugins\!PLUGIN_NAME!.dll
        
        if exist "!SOURCE_FILE!" (
            copy /Y "!SOURCE_FILE!" "!DEST_FILE!" >nul
            if !ERRORLEVEL! EQU 0 (
                echo [OK] Скопирован: !PLUGIN_NAME!.dll
                set /a PLUGIN_COUNT+=1
            ) else (
                echo [ОШИБКА] Не удалось скопировать: !PLUGIN_NAME!.dll
            )
        ) else (
            echo [ПРЕДУПРЕЖДЕНИЕ] Файл не найден: !SOURCE_FILE!
        )
    )
)

echo.
if %PLUGIN_COUNT% GTR 0 (
    echo ========================================
    echo Сборка успешно завершена!
    echo Скопировано плагинов: %PLUGIN_COUNT%
    echo ========================================
    exit /b 0
) else (
    echo ========================================
    echo Сборка завершена, но плагины не найдены!
    echo ========================================
    exit /b 0
)
