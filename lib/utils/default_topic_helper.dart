import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// アプリ起動時にデフォルトで購読すべき固定トピックを安全に購読するヘルパー
class DefaultTopicHelper {
  static const String edinetNotificationTopic = 'edinet_notification';

  /// [edinetNotificationTopic] を安全に購読する。
  /// エラー発生時（FCM Registration failed等）は例外をキャッチし、
  /// [onError] または Crashlytics へ非致命的エラーとして記録する。
  static Future<void> subscribeToDefaultTopics({
    FirebaseMessaging? messaging,
    Future<void> Function(String topic)? onSubscribe,
    void Function(Object error, StackTrace stack)? onError,
  }) async {
    try {
      if (onSubscribe != null) {
        await onSubscribe(edinetNotificationTopic);
      } else {
        await (messaging ?? FirebaseMessaging.instance).subscribeToTopic(
          edinetNotificationTopic,
        );
      }
    } catch (e, stack) {
      debugPrint("Failed to subscribe to $edinetNotificationTopic topic: $e");
      if (onError != null) {
        onError(e, stack);
      } else {
        FirebaseCrashlytics.instance.recordError(e, stack, fatal: false);
      }
    }
  }
}
