#!/bin/bash

# Скрипт для сборки проекта AniDev
# Использование: ./build.sh [debug|release]
# По умолчанию: release

set -e

# Определение режима сборки
BUILD_MODE="${1:-release}"

# Валидация режима сборки
if [ "$BUILD_MODE" != "debug" ] && [ "$BUILD_MODE" != "release" ]; then
    echo "Неизвестный режим: $BUILD_MODE"
    echo "Использование: ./build.sh [debug|release]"
    echo "По умолчанию: release"
    exit 1
fi

# Проверка наличия cargo
if ! command -v cargo &> /dev/null; then
    echo "ОШИБКА: Cargo не найден в PATH. Убедитесь, что Rust установлен."
    exit 1
fi

# Определение ОС и расширения файлов
OS="$(uname -s)"
case "$OS" in
    Linux*)
        LIB_EXT="so"
        ;;
    Darwin*)
        LIB_EXT="dylib"
        ;;
    *)
        echo "Предупреждение: Неизвестная ОС: $OS. Используется расширение .so"
        LIB_EXT="so"
        ;;
esac

echo "========================================"
echo "Построение проекта AniDev"
echo "========================================"
echo ""
echo "ОС: $OS"
echo "Режим сборки: $(echo $BUILD_MODE | tr '[:lower:]' '[:upper:]')"
if [ "$BUILD_MODE" = "release" ]; then
    echo "(Используйте './build.sh debug' для сборки debug версии)"
fi
echo ""
echo "Начинается сборка..."
echo ""

# Выполнение сборки
if [ "$BUILD_MODE" = "release" ]; then
    cargo build --release
else
    cargo build
fi

if [ $? -ne 0 ]; then
    echo ""
    echo "========================================"
    echo "Сборка завершилась ошибкой!"
    echo "========================================"
    exit 1
fi

echo ""
echo "Сборка завершена успешно. Копирование плагинов..."
echo ""

# Создание директории plugins если отсутствует
mkdir -p plugins

# Автоматическое определение плагинов
PLUGIN_COUNT=0

for PLUGIN_DIR in plugins/*/; do
    # Пропускаем если нет директорий
    [ -d "$PLUGIN_DIR" ] || continue
    
    CARGO_TOML="${PLUGIN_DIR}Cargo.toml"
    
    if [ -f "$CARGO_TOML" ]; then
        PLUGIN_LIB_NAME=""
        PLUGIN_PACKAGE_NAME=""
        IN_LIB_SECTION=0
        
        # Чтение и парсинг Cargo.toml
        while IFS= read -r line || [ -n "$line" ]; do
            # Удаляем пробелы в начале и конце
            trimmed_line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            
            # Проверка на начало секции [lib]
            if [ "$trimmed_line" = "[lib]" ]; then
                IN_LIB_SECTION=1
                continue
            fi
            
            # Проверка на начало секции [package]
            if [ "$trimmed_line" = "[package]" ]; then
                IN_LIB_SECTION=0
                continue
            fi
            
            # Поиск name = "..."
            if echo "$trimmed_line" | grep -qE '^name\s*=\s*"'; then
                # Извлечение значения из кавычек
                name_value=$(echo "$trimmed_line" | sed -n 's/^name\s*=\s*"\([^"]*\)".*/\1/p')
                
                if [ -n "$name_value" ]; then
                    if [ $IN_LIB_SECTION -eq 1 ]; then
                        PLUGIN_LIB_NAME="$name_value"
                    else
                        PLUGIN_PACKAGE_NAME="$name_value"
                    fi
                fi
            fi
        done < "$CARGO_TOML"
        
        # Определение имени плагина
        if [ -n "$PLUGIN_LIB_NAME" ]; then
            PLUGIN_NAME="$PLUGIN_LIB_NAME"
        elif [ -n "$PLUGIN_PACKAGE_NAME" ]; then
            # Заменяем дефисы на подчеркивания
            PLUGIN_NAME=$(echo "$PLUGIN_PACKAGE_NAME" | tr '-' '_')
        else
            # Используем имя директории как fallback
            PLUGIN_NAME=$(basename "$PLUGIN_DIR")
        fi
        
        # Определение имени файла библиотеки
        # На Linux/macOS Rust создает файлы с префиксом lib
        SOURCE_FILE="target/$BUILD_MODE/lib${PLUGIN_NAME}.${LIB_EXT}"
        
        # Проверяем оба варианта (с префиксом lib и без)
        if [ ! -f "$SOURCE_FILE" ]; then
            SOURCE_FILE="target/$BUILD_MODE/${PLUGIN_NAME}.${LIB_EXT}"
        fi
        
        DEST_FILE="plugins/${PLUGIN_NAME}.${LIB_EXT}"
        
        if [ -f "$SOURCE_FILE" ]; then
            cp -f "$SOURCE_FILE" "$DEST_FILE"
            echo "[OK] Скопирован: ${PLUGIN_NAME}.${LIB_EXT}"
            PLUGIN_COUNT=$((PLUGIN_COUNT + 1))
        else
            echo "[ПРЕДУПРЕЖДЕНИЕ] Файл не найден: $SOURCE_FILE"
        fi
    fi
done

echo ""
if [ $PLUGIN_COUNT -gt 0 ]; then
    echo "========================================"
    echo "Сборка успешно завершена!"
    echo "Скопировано плагинов: $PLUGIN_COUNT"
    echo "========================================"
    exit 0
else
    echo "========================================"
    echo "Сборка завершена, но плагины не найдены!"
    echo "========================================"
    exit 0
fi
