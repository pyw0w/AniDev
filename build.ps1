# Скрипт для сборки проекта AniDev
# Использование: ./build.ps1 [debug|release]
# По умолчанию: release

param(
    [string]$Mode = "release"
)

# Проверка наличия cargo
$cargoPath = Get-Command cargo -ErrorAction SilentlyContinue
if (-not $cargoPath) {
    Write-Host "ОШИБКА: Cargo не найден в PATH. Убедитесь, что Rust установлен." -ForegroundColor Red
    exit 1
}

# Валидация режима сборки
if ($Mode -ne "debug" -and $Mode -ne "release") {
    Write-Host "Неизвестный режим: $Mode" -ForegroundColor Red
    Write-Host "Использование: ./build.ps1 [debug|release]"
    Write-Host "По умолчанию: release"
    exit 1
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Построение проекта AniDev" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Режим сборки: $($Mode.ToUpper())" -ForegroundColor Yellow
if ($Mode -eq "release") {
    Write-Host "(Используйте './build.ps1 debug' для сборки debug версии)" -ForegroundColor Gray
}
Write-Host ""
Write-Host "Начинается сборка..." -ForegroundColor Green
Write-Host ""

# Выполнение сборки
if ($Mode -eq "release") {
    cargo build --release
} else {
    cargo build
}

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "Сборка завершилась ошибкой! Код ошибки: $LASTEXITCODE" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "Сборка завершена успешно. Копирование плагинов и сервисов..." -ForegroundColor Green
Write-Host ""

# Создание директории plugins если отсутствует
if (-not (Test-Path "plugins")) {
    New-Item -ItemType Directory -Path "plugins" | Out-Null
}

# Функция для копирования модулей (плагинов или сервисов)
function Copy-Module {
    param(
        [string]$ModuleType,  # "plugin" or "service"
        [string]$Suffix        # "_plugin" or "_service"
    )
    
    $moduleCount = 0
    $moduleDirs = Get-ChildItem -Path "plugins" -Directory -ErrorAction SilentlyContinue

    foreach ($moduleDir in $moduleDirs) {
        # Проверяем что директория содержит нужный суффикс
        if (-not $moduleDir.Name.Contains($Suffix)) {
            continue
        }
        
        $cargoToml = Join-Path $moduleDir.FullName "Cargo.toml"
        
        if (Test-Path $cargoToml) {
            $moduleLibName = $null
            $modulePackageName = $null
            $inLibSection = $false
            
            # Чтение и парсинг Cargo.toml
            $lines = Get-Content $cargoToml
            
            foreach ($line in $lines) {
                $trimmedLine = $line.Trim()
                
                # Проверка на начало секции [lib]
                if ($trimmedLine -eq "[lib]") {
                    $inLibSection = $true
                    continue
                }
                
                # Проверка на начало секции [package]
                if ($trimmedLine -eq "[package]") {
                    $inLibSection = $false
                    continue
                }
                
                # Поиск name = "..."
                if ($trimmedLine -match '^\s*name\s*=\s*"([^"]+)"') {
                    if ($inLibSection) {
                        $moduleLibName = $matches[1]
                    } else {
                        $modulePackageName = $matches[1]
                    }
                }
            }
            
            # Определение имени модуля
            if ($moduleLibName) {
                $moduleName = $moduleLibName
            } elseif ($modulePackageName) {
                # Заменяем дефисы на подчеркивания
                $moduleName = $modulePackageName -replace '-', '_'
            } else {
                # Используем имя директории как fallback
                $moduleName = $moduleDir.Name
            }
            
            # Проверка, что имя модуля содержит правильный суффикс
            if (-not $moduleName.EndsWith($Suffix)) {
                Write-Host "[ПРЕДУПРЕЖДЕНИЕ] Имя модуля '$moduleName' не содержит суффикс '$Suffix'. Пропускаем." -ForegroundColor Yellow
                continue
            }
            
            # Копирование DLL файла
            $sourceFile = Join-Path (Join-Path "target" $Mode) "$moduleName.dll"
            $destFile = Join-Path "plugins" "$moduleName.dll"
            
            if (Test-Path $sourceFile) {
                Copy-Item -Path $sourceFile -Destination $destFile -Force
                Write-Host "[OK] Скопирован $ModuleType : $moduleName.dll" -ForegroundColor Green
                $moduleCount++
            } else {
                Write-Host "[ПРЕДУПРЕЖДЕНИЕ] Файл не найден: $sourceFile" -ForegroundColor Yellow
                Write-Host "       Ожидаемое имя файла должно содержать суффикс '$Suffix'" -ForegroundColor Gray
            }
        }
    }
    
    return $moduleCount
}

# Копирование сервисов
$serviceCount = Copy-Module -ModuleType "сервис" -Suffix "_service"

# Копирование плагинов
$pluginCount = Copy-Module -ModuleType "плагин" -Suffix "_plugin"

Write-Host ""
if ($pluginCount -gt 0 -or $serviceCount -gt 0) {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Сборка успешно завершена!" -ForegroundColor Green
    if ($pluginCount -gt 0) {
        Write-Host "Скопировано плагинов: $pluginCount" -ForegroundColor Green
    }
    if ($serviceCount -gt 0) {
        Write-Host "Скопировано сервисов: $serviceCount" -ForegroundColor Green
    }
    Write-Host "========================================" -ForegroundColor Cyan
    exit 0
} else {
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "Сборка завершена, но плагины и сервисы не найдены!" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    exit 0
}
