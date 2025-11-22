#!/bin/bash

# Определение цветов
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # Без цвета

echo "========================================"
echo "Построение проекта AniDev"
echo "========================================"
echo ""

# Проверяем, был ли передан параметр (release/debug)
BUILD_MODE="debug"
if [ "$1" = "release" ]; then
    BUILD_MODE="release"
    echo "Режим сборки: Release"
else
    echo "Режим сборки: Debug (используйте './build.sh release' для сборки релизной версии)"
fi

echo ""
echo "Начинается сборка..."
echo ""

# Выполняем сборку
if [ "$BUILD_MODE" = "release" ]; then
    cargo build --release
else
    cargo build
fi

# Проверяем результат сборки
if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}========================================"
    echo "Сборка успешно завершена!"
    echo -e "========================================${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}========================================"
    echo "Сборка завершилась ошибкой!"
    echo -e "========================================${NC}"
    exit 1
fi

