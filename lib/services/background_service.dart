import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class BackgroundService {
  static bool _initialized = false;

  /// Инициализация — вызвать один раз при старте приложения
  static void init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'yt_bg_player_channel',
        channelName: 'YT Background Player',
        channelDescription: 'Аудио воспроизводится в фоне',
        channelImportance: NotificationChannelImportance.HIGH,
        priority: NotificationPriority.HIGH,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
    _initialized = true;
  }

  /// Запросить разрешения и включить фоновый режим
  static Future<bool> enableBackground() async {
    if (!Platform.isAndroid) {
      // iOS: audio_session уже настраивает фоновое воспроизведение
      return true;
    }

    if (!_initialized) init();

    try {
      // Запрашиваем разрешение на показ уведомлений (Android 13+)
      final notifPermission =
          await FlutterForegroundTask.checkNotificationPermission();
      if (notifPermission != NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
      }

      // Запускаем foreground service
      final result = await FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: 'YT Background Player',
        notificationText: 'Аудио воспроизводится в фоне',
        callback: startCallback,
      );

      debugPrint('Foreground service start result: $result');
      return result == ServiceRequestResult.success;
    } catch (e) {
      debugPrint('BackgroundService.enableBackground error: $e');
      return false;
    }
  }

  /// Выключить фоновый режим
  static Future<void> disableBackground() async {
    if (!Platform.isAndroid) return;
    try {
      await FlutterForegroundTask.stopService();
    } catch (e) {
      debugPrint('BackgroundService.disableBackground error: $e');
    }
  }

  static bool get isEnabled {
    if (!Platform.isAndroid) return false;
    return FlutterForegroundTask.isRunningService;
  }
}

/// Top-level callback — обязательно должна быть вне класса
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(_AudioTaskHandler());
}

class _AudioTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('Foreground task started at $timestamp');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Просто держим сервис живым — аудио идёт через WebView плеера
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    debugPrint('Foreground task destroyed at $timestamp');
  }
}
