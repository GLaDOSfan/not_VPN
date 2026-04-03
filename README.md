# notVPN

Простое VPN-приложение на базе WireGuard с динамической конфигурацией.

## Возможности

- Подключение/отключение VPN одной кнопкой
- Автоматическое получение уникальной конфигурации с сервера
- Отображение статуса подключения
- Счётчик трафика (получено/отправлено)
- Анимация процесса подключения
- Каждое устройство получает свой ключ и IP-адрес

## Установка

### Windows

1. Скачайте `not_vpn_windows.exe` из раздела [Releases](https://github.com/GLaDOSfan/not_VPN/releases)
2. Запустите установщик
3. Следуйте инструкциям на экране

### Android

1. Скачайте `not_vpn_android.apk` из раздела [Releases](https://github.com/GLaDOSfan/not_VPN/releases)
2. Разрешите установку из неизвестных источников
3. Установите приложение

## Требования

### Windows
- Windows 10 / Windows 11 (64-bit)
- Права администратора (требуются для работы WireGuard)

### Android
- Android 5.0 (API 21) или выше
- Разрешение на создание VPN-подключения

## Сборка из исходников

git clone https://github.com/GLaDOSfan/not_VPN.git
cd not_VPN
flutter pub get

# Windows
flutter build windows --release

# Android
flutter build apk --release