import 'dart:async';
import 'dart:io';

import 'package:disclosure_app_fl/utils/crashlytics_helper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isFatalError', () {
    test('サイレントな FlutterErrorDetails は非致命的と判定される', () {
      final details = FlutterErrorDetails(
        exception: StateError('silent error'),
        silent: true,
      );
      expect(isFatalError(details.exception, details: details), isFalse);
    });

    test('ネットワーク・タイムアウト系の例外は非致命的と判定される', () {
      expect(
        isFatalError(const SocketException('Software caused connection abort')),
        isFalse,
      );
      expect(
        isFatalError(const HttpException('Software caused connection abort')),
        isFalse,
      );
      expect(
        isFatalError(const HandshakeException('Connection terminated')),
        isFalse,
      );
      expect(
        isFatalError(TimeoutException('timed out')),
        isFalse,
      );
      expect(
        isFatalError(
          NetworkImageLoadException(
            statusCode: 500,
            uri: Uri.parse('https://example.com/avatar.png'),
          ),
        ),
        isFalse,
      );
    });

    test('一時的な FirebaseException コードは非致命的と判定される', () {
      expect(
        isFatalError(
          FirebaseException(plugin: 'cloud_firestore', code: 'deadline-exceeded'),
        ),
        isFalse,
      );
      expect(
        isFatalError(
          FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
        ),
        isFalse,
      );
      expect(
        isFatalError(
          FirebaseException(
            plugin: 'firebase_auth',
            code: 'network-request-failed',
          ),
        ),
        isFalse,
      );
    });

    test('バグに起因する一般的な例外や非一時的な FirebaseException は致命的と判定される', () {
      expect(isFatalError(StateError('unexpected state')), isTrue);
      expect(isFatalError(ArgumentError('bad argument')), isTrue);
      expect(
        isFatalError(
          FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
        ),
        isTrue,
      );
    });
  });
}
