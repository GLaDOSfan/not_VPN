```markdown
# notVPN

Простое VPN-приложение для Windows.

## Возможности

- Подключение/отключение VPN одной кнопкой
- Отображение статуса подключения
- Счётчик трафика (получено/отправлено)

## Установка

### Из установщика

1. Скачайте файл `notVPN_Setup.exe` из раздела [Releases](https://github.com/gladosfan/notVPN/releases)
2. Запустите установщик
3. Следуйте инструкциям на экране

### Из исходников

```bash
git clone https://github.com/gladosfan/notVPN.git
cd notVPN
flutter pub get
flutter run -d windows
```

## Системные требования

- Windows 10 / Windows 11 (64-bit)
- Права администратора (требуются для работы WireGuard)

## Сборка приложения

```bash
# Сборка Debug версии
flutter run -d windows

# Сборка Release версии
flutter build windows --release

# Путь к собранному EXE
# build\notvpn_setup.exe
```

## Создание установщика

Для создания установщика используется Inno Setup:

1. Установите [Inno Setup](https://jrsoftware.org/isdl.php)
2. Откройте файл `installer.iss`
3. Нажмите `Ctrl+F9` для компиляции

## Структура проекта

```
notVPN/
├── lib/
│   └── main.dart          # Основной код приложения
├── assets/
│   └── wireguard_config.conf  # Конфигурация WireGuard (локально)
├── windows/               # Windows-специфичный код
└── pubspec.yaml           # Зависимости проекта
```

## Технологии

- [Flutter](https://flutter.dev) — фреймворк для кроссплатформенной разработки
- [wireguard_flutter_plus](https://pub.dev/packages/wireguard_flutter_plus) — плагин для WireGuard
- [Inno Setup](https://jrsoftware.org/isdl.php) — создание установщика

## Лицензия

MIT License

## Контакты

Разработчик: Aleksandr Romanov
Email: gladosfan@outlook.com
```
