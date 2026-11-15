import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// 非致命的なエラーをデバッグ出力し、Firebase 初期化済みの場合は Crashlytics へ報告する
void reportNonFatalError(
  Object error,
  StackTrace stack, {
  String? reason,
}) {
  debugPrint(reason != null ? '$reason: $error' : '$error');
  if (Firebase.apps.isNotEmpty) {
    FirebaseCrashlytics.instance.recordError(
      error,
      stack,
      reason: reason,
      fatal: false,
    );
  }
}
