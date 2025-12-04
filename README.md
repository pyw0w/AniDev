# AniDev - Модульная система Discord бота на Rust

## Компоненты

### AniRuntime
Стандартный launcher для запуска бота. Используется для разработки и тестирования.

### AniSystemd
Systemd-версия runtime с автоматическим перезапуском при изменении плагинов.

**Особенности:**
- Автоматический перезапуск при добавлении/обновлении/удалении плагинов
- Интеграция с systemd (notify, watchdog)
- Graceful shutdown при обнаружении изменений
- Мониторинг директории `./plugins` в реальном времени

**Установка и настройка:**

1. Соберите проект:
```bash
cargo build --release --package anisystemd
```

2. Установите бинарник:
```bash
sudo cp target/release/anisystemd /usr/local/bin/anisystemd
sudo chmod +x /usr/local/bin/anisystemd
```

3. Настройте systemd unit файл:
```bash
sudo cp anisystemd.service /etc/systemd/system/
sudo nano /etc/systemd/system/anisystemd.service
```

4. Настройте переменные окружения:
```bash
sudo mkdir -p /etc/anicore
sudo nano /etc/anicore/env
# Добавьте: DISCORD_TOKEN=your_token_here
```

5. Создайте пользователя и директории:
```bash
sudo useradd -r -s /bin/false anicore
sudo mkdir -p /var/lib/anicore/plugins
sudo mkdir -p /var/lib/anicore/config
sudo chown -R anicore:anicore /var/lib/anicore
```

6. Активируйте и запустите сервис:
```bash
sudo systemctl daemon-reload
sudo systemctl enable anisystemd.service
sudo systemctl start anisystemd.service
```

7. Проверьте статус:
```bash
sudo systemctl status anisystemd.service
sudo journalctl -u anisystemd.service -f
```

**Автоматический перезапуск при изменении плагинов:**

AniSystemd автоматически отслеживает изменения в директории `./plugins` и перезапускает сервис при:
- Добавлении нового плагина (`*_plugin.so`)
- Обновлении существующего плагина
- Добавлении/обновлении сервиса (`*_service.so`)
- Удалении плагина или сервиса

При обнаружении изменений выполняется graceful shutdown, и systemd автоматически перезапускает сервис благодаря `Restart=always`.

## Документация

- [Руководство по разработке плагинов](./docs/PLUGIN_GUIDE.md)
- [Справочник API](./docs/API_REFERENCE.md)
- [Примеры](./docs/EXAMPLES.md)