# 🎵 YouTube Background Player

Flutter-приложение для воспроизведения YouTube видео с фоновым звуком при заблокированном экране.

## Возможности

- Воспроизведение YouTube по ссылке или ID видео
- **Звук продолжает играть при блокировке экрана**
- Управление через шторку уведомлений
- Список быстрого запуска популярных стримов

## Как собрать APK

### Вариант 1 — GitHub Actions (автоматически)

1. Сделайте Fork этого репозитория
2. Перейдите в **Actions** → **Build APK**
3. Нажмите **Run workflow**
4. Скачайте APK из **Artifacts**

### Вариант 2 — локально

```bash
flutter pub get
flutter build apk --release
```

APK будет в: `build/app/outputs/flutter-apk/app-release.apk`

## Структура проекта

```
lib/
  main.dart                    # Точка входа
  screens/
    home_screen.dart           # Главный экран
  services/
    background_service.dart    # Фоновое воспроизведение
android/
  app/src/main/
    AndroidManifest.xml        # Разрешения Android
    kotlin/.../MainActivity.kt
  app/build.gradle
```

## Зависимости

| Пакет | Назначение |
|---|---|
| youtube_player_flutter | Встроенный плеер YouTube |
| wakelock_plus | Не даёт экрану гаснуть |
| audio_session | Настройка аудио-сессии Android/iOS |
| flutter_background | Foreground Service для фонового режима |

## Разрешения Android

- `FOREGROUND_SERVICE` — запуск при заблокированном экране
- `FOREGROUND_SERVICE_MEDIA_PLAYBACK` — тип медиа-сервиса
- `WAKE_LOCK` — CPU не засыпает во время воспроизведения
- `INTERNET` — загрузка видео
