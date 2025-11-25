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
Write-Host "Сборка завершена успешно. Копирование плагинов..." -ForegroundColor Green
Write-Host ""

# Создание директории plugins если отсутствует
if (-not (Test-Path "plugins")) {
    New-Item -ItemType Directory -Path "plugins" | Out-Null
}

# Автоматическое определение плагинов
$pluginCount = 0
$pluginDirs = Get-ChildItem -Path "plugins" -Directory -ErrorAction SilentlyContinue

foreach ($pluginDir in $pluginDirs) {
    $cargoToml = Join-Path $pluginDir.FullName "Cargo.toml"
    
    if (Test-Path $cargoToml) {
        $pluginLibName = $null
        $pluginPackageName = $null
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
                    $pluginLibName = $matches[1]
                } else {
                    $pluginPackageName = $matches[1]
                }
            }
        }
        
        # Определение имени плагина
        if ($pluginLibName) {
            $pluginName = $pluginLibName
        } elseif ($pluginPackageName) {
            # Заменяем дефисы на подчеркивания
            $pluginName = $pluginPackageName -replace '-', '_'
        } else {
            # Используем имя директории как fallback
            $pluginName = $pluginDir.Name
        }
        
        # Копирование DLL файла
        $sourceFile = Join-Path (Join-Path "target" $Mode) "$pluginName.dll"
        $destFile = Join-Path "plugins" "$pluginName.dll"
        
        if (Test-Path $sourceFile) {
            Copy-Item -Path $sourceFile -Destination $destFile -Force
            Write-Host "[OK] Скопирован: $pluginName.dll" -ForegroundColor Green
            $pluginCount++
        } else {
            Write-Host "[ПРЕДУПРЕЖДЕНИЕ] Файл не найден: $sourceFile" -ForegroundColor Yellow
        }
    }
}

Write-Host ""
if ($pluginCount -gt 0) {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Сборка успешно завершена!" -ForegroundColor Green
    Write-Host "Скопировано плагинов: $pluginCount" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    exit 0
} else {
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "Сборка завершена, но плагины не найдены!" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    exit 0
}
