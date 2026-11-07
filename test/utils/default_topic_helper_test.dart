import 'dart:io';

import 'package:disclosure_app_fl/utils/default_topic_helper.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeIOException implements IOException {
  final String message;
  const _FakeIOException(this.message);

  @override
  String toString() => 'java.io.IOException: $message';
}

void main() {
  group('DefaultTopicHelper.subscribeToDefaultTopics', () {
    test('edinetNotificationTopic が正しく "edinet_notification" に設定されている', () {
      expect(
        DefaultTopicHelper.edinetNotificationTopic,
        equals('edinet_notification'),
      );
    });

    test('トピック購読成功時に onSubscribe が対象トピック名で呼ばれる', () async {
      final subscribedTopics = <String>[];
      var errorCalled = false;

      await DefaultTopicHelper.subscribeToDefaultTopics(
        onSubscribe: (topic) async {
          subscribedTopics.add(topic);
        },
        onError: (e, s) {
          errorCalled = true;
        },
      );

      expect(
        subscribedTopics,
        equals([DefaultTopicHelper.edinetNotificationTopic]),
      );
      expect(errorCalled, isFalse);
    });

    test(
      'FCM Registration failed (IOException) 発生時に例外を外部へ再スローせず安全に onError へ送る',
      () async {
        var errorCalled = false;
        Object? capturedError;
        StackTrace? capturedStack;

        // 未捕捉例外でクラッシュしないことを確認
        await expectLater(
          DefaultTopicHelper.subscribeToDefaultTopics(
            onSubscribe: (topic) async {
              throw const _FakeIOException('FCM Registration failed!');
            },
            onError: (e, s) {
              errorCalled = true;
              capturedError = e;
              capturedStack = s;
            },
          ),
          completes,
        );

        expect(errorCalled, isTrue);
        expect(capturedError, isA<IOException>());
        expect(capturedError.toString(), contains('FCM Registration failed!'));
        expect(capturedStack, isNotNull);
      },
    );

    test('一般例外（タイムアウトやネットワークエラー等）発生時も未捕捉にならず安全に完了する', () async {
      var errorCalled = false;

      await expectLater(
        DefaultTopicHelper.subscribeToDefaultTopics(
          onSubscribe: (topic) async {
            throw Exception('Network timeout');
          },
          onError: (e, s) {
            errorCalled = true;
          },
        ),
        completes,
      );

      expect(errorCalled, isTrue);
    });
  });
}
