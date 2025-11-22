# AniDev

AniDev - это платформа для создания Discord ботов с системой плагинов на Rust.

## Особенности

- 🚀 Современный Rust API на основе traits
- 🔌 Гибкая система плагинов с поддержкой горячей перезагрузки
- 🔄 Межплагинное взаимодействие через реестр функций
- 📝 Полная поддержка Discord Slash Commands
- 🎯 Обработка событий Discord (сообщения, взаимодействия, голосовые каналы)
- 📦 Простая разработка плагинов как отдельных проектов
- 🔧 Конфигурация плагинов через JSON
- 📊 Интеграция с systemd для Linux

## Быстрый старт

### Установка

```bash
git clone <repository-url>
cd AniDev
cargo build --release
```

### Настройка

1. Создайте файл `.env` в корне проекта:
```env
DISCORD_TOKEN=your_bot_token_here
PLUGIN_DIR=target/release
```

2. Запустите бота:
```bash
cargo run --bin anicore
```

## Разработка плагинов

AniDev использует современный Rust API для разработки плагинов. Плагины реализуют trait `Plugin` и используют `PluginContext` для взаимодействия с системой.

### Минимальный пример плагина

```rust
use aniapi::{Plugin, PluginContext};
use std::error::Error;

pub struct MyPlugin {
    name: String,
    version: String,
}

impl Plugin for MyPlugin {
    fn name(&self) -> &str {
        &self.name
    }
    
    fn version(&self) -> &str {
        &self.version
    }
    
    fn initialize(&mut self, ctx: PluginContext) -> Result<(), Box<dyn Error>> {
        aniapi::logger::PluginLogger::info("Плагин инициализирован!");
        Ok(())
    }
    
    fn shutdown(&mut self) -> Result<(), Box<dyn Error>> {
        aniapi::logger::PluginLogger::info("Плагин завершает работу");
        Ok(())
    }
}

#[no_mangle]
pub extern "C" fn init_plugin() -> *mut std::ffi::c_void {
    let plugin: Box<dyn aniapi::Plugin> = Box::new(MyPlugin::new());
    Box::into_raw(Box::new(plugin)) as *mut std::ffi::c_void
}
```

Полная документация по разработке плагинов: [docs/PLUGIN_DEVELOPMENT.md](docs/PLUGIN_DEVELOPMENT.md)

## Структура проекта

```
AniDev/
├── anicore/          # Основной бот
├── aniapi/           # API для плагинов
├── plugins/          # Примеры плагинов
│   ├── utils_plugin/     # Простой плагин с командами
│   └── voicetemp_plugin/ # Плагин для временных голосовых каналов
└── docs/            # Документация
```

## Документация

- [Разработка плагинов](docs/PLUGIN_DEVELOPMENT.md) - полное руководство по созданию плагинов
- [Система логирования](docs/LOGGER.md) - документация по логированию
- [Интеграция с systemd](docs/SYSTEMD.md) - настройка для Linux

## Примеры плагинов

- **utils_plugin** - простой плагин с командой ping
- **voicetemp_plugin** - плагин для автоматического создания временных голосовых каналов

## Требования

- Rust 1.70+
- Discord Bot Token
- (Опционально) systemd для Linux

## Лицензия

[Укажите лицензию]
