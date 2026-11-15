import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

const _nonFatalFirebaseCodes = {
  'unavailable',
  'deadline-exceeded',
  'network-request-failed',
};

/// Crashlytics に致命的（FATAL）として報告すべきエラーかどうかを判定する。
/// サイレントエラーや通信・一時的な障害に起因するエラーは非致命的（false）として扱う。
bool isFatalError(Object error, {FlutterErrorDetails? details}) {
  if (details != null && details.silent) {
    return false;
  }
  if (error is SocketException ||
      error is HttpException ||
      error is HandshakeException ||
      error is TimeoutException ||
      error is NetworkImageLoadException) {
    return false;
  }
  if (error is FirebaseException &&
      _nonFatalFirebaseCodes.contains(error.code)) {
    return false;
  }
  return true;
}

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
