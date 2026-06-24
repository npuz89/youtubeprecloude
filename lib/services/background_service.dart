import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_background/flutter_background.dart';

class BackgroundService {
  static bool _initialized = false;

  static Future<bool> enableBackground() async {
    if (!Platform.isAndroid) {
      // На iOS фоновый звук работает через audio_session автоматически
      return true;
    }

    try {
      if (!_initialized) {
        const androidConfig = FlutterBackgroundAndroidConfig(
          notificationTitle: 'YT Background Player',
          notificationText: 'Аудио воспроизводится в фоне',
          notificationImportance: AndroidNotificationImportance.high,
          notificationIcon: AndroidResource(
            name: 'ic_launcher',
            defType: 'mipmap',
          ),
        );

        final hasPermissions =
            await FlutterBackground.initialize(androidConfig: androidConfig);

        if (!hasPermissions) {
          debugPrint('Background permissions not granted');
          return false;
        }

        _initialized = true;
      }

      final success = await FlutterBackground.enableBackgroundExecution();
      debugPrint('Background execution enabled: $success');
      return success;
    } catch (e) {
      debugPrint('Background service error: $e');
      return false;
    }
  }

  static Future<void> disableBackground() async {
    if (!Platform.isAndroid) return;

    try {
      if (FlutterBackground.isBackgroundExecutionEnabled) {
        await FlutterBackground.disableBackgroundExecution();
      }
    } catch (e) {
      debugPrint('Disable background error: $e');
    }
  }

  static bool get isEnabled {
    if (!Platform.isAndroid) return false;
    try {
      return FlutterBackground.isBackgroundExecutionEnabled;
    } catch (e) {
      return false;
    }
  }
}
