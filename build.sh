#!/bin/bash

# Собираем всё
cargo build

# Создаем папку plugins если нет
mkdir -p plugins

# Копируем библиотеки
# На Linux это будут .so файлы, на Mac .dylib
cp target/debug/libutils_plugin.so plugins/utils_plugin.so 2>/dev/null || cp target/debug/utils_plugin.dll plugins/ 2>/dev/null
cp target/debug/libvoicetemp_plugin.so plugins/voicetemp_plugin.so 2>/dev/null || cp target/debug/voicetemp_plugin.dll plugins/ 2>/dev/null

echo "Build complete. Plugins copied to ./plugins/"
