# Скрипт для сборки и перемещения плагинов
# Использование: ./build.ps1

# Собираем всё
cargo build

# Создаем папку plugins если нет
New-Item -ItemType Directory -Force -Path "plugins" | Out-Null

# Копируем скомпилированные DLL плагинов из target/debug в plugins/
# Ищем все файлы .dll в target/debug, которые похожи на плагины (можно уточнить фильтр)
# В данном случае копируем конкретные известные плагины
Copy-Item "target/debug/utils_plugin.dll" -Destination "plugins/" -Force
Copy-Item "target/debug/voicetemp_plugin.dll" -Destination "plugins/" -Force

Write-Host "Build complete. Plugins copied to ./plugins/"

