import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:disclosure_app_fl/utils/notification_topic_helper.dart';
import 'package:disclosure_app_fl/utils/tag_migration_helper.dart';

void main() {
  group('TagMigrationHelper.ensureTagsMigrated', () {
    test('Firestore に既に notification_tags が存在する場合は HTTP リクエストを行わずにタグ一覧を返す', () async {
      var httpCalled = false;
      final mockHttp = MockClient((request) async {
        httpCalled = true;
        return http.Response('{}', 200);
      });

      var firestoreSaved = false;
      final helper = TagMigrationHelper(
        httpClient: mockHttp,
        onSaveTags: (uid, tags) async {
          firestoreSaved = true;
        },
      );

      final result = await helper.ensureTagsMigrated(
        uid: 'test_uid_1',
        fcmToken: 'valid_token',
        userDocData: {
          'favorites': ['7203'],
          'notification_tags': ['株主優待', '決算'],
        },
      );

      expect(result, equals(['株主優待', '決算']));
      expect(httpCalled, isFalse);
      expect(firestoreSaved, isFalse);
    });

    test('notification_tags が未存在の場合、listTopicsV2 からタグを取得して Firestore に保存する', () async {
      var httpCalled = false;
      final tag1 = '株主優待';
      final tag2 = '決算短信';
      final topicTag1 = NotificationTopicHelper.fromTag(tag1);
      final topicTag2 = NotificationTopicHelper.fromTag(tag2);
      final topicCode = NotificationTopicHelper.toTopic('7203');

      final mockHttp = MockClient((request) async {
        httpCalled = true;
        expect(request.headers['Content-Type'], equals('application/json'));
        final body = json.decode(request.body);
        expect(body['IID_TOKEN'], equals('test_token_123'));

        return http.Response(
          json.encode({
            'topics': {
              topicTag1: {'addDate': '2023-01-01'},
              topicTag2: {'addDate': '2023-01-02'},
              topicCode: {'addDate': '2023-01-03'}, // 銘柄コードは除外されるべき
            }
          }),
          200,
        );
      });

      List<String>? savedTags;
      String? savedUid;
      final helper = TagMigrationHelper(
        httpClient: mockHttp,
        onSaveTags: (uid, tags) async {
          savedUid = uid;
          savedTags = tags;
        },
      );

      final result = await helper.ensureTagsMigrated(
        uid: 'user_abc',
        fcmToken: 'test_token_123',
        userDocData: {'favorites': ['7203']}, // notification_tags は存在しない
      );

      expect(httpCalled, isTrue);
      expect(result, containsAll([tag1, tag2]));
      expect(result.length, equals(2));
      expect(savedUid, equals('user_abc'));
      expect(savedTags, containsAll([tag1, tag2]));
    });

    test('listTopicsV2 が HTTP エラーを返した場合、クラッシュせず空リストを Firestore に保存する', () async {
      final mockHttp = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      List<String>? savedTags;
      final helper = TagMigrationHelper(
        httpClient: mockHttp,
        onSaveTags: (uid, tags) async {
          savedTags = tags;
        },
      );

      final result = await helper.ensureTagsMigrated(
        uid: 'user_error',
        fcmToken: 'token_err',
        userDocData: null,
        // onGetUserDoc を指定し、ドキュメントに notification_tags がない状態を再現
      );

      expect(result, isEmpty);
      expect(savedTags, isEmpty);
    });

    test('fcmToken が null の場合、listTopicsV2 を呼ばず空リストを Firestore に保存する', () async {
      var httpCalled = false;
      final mockHttp = MockClient((request) async {
        httpCalled = true;
        return http.Response('{}', 200);
      });

      List<String>? savedTags;
      final helper = TagMigrationHelper(
        httpClient: mockHttp,
        onGetUserDoc: (uid) async => <String, dynamic>{},
        onSaveTags: (uid, tags) async {
          savedTags = tags;
        },
      );

      final result = await helper.ensureTagsMigrated(
        uid: 'user_no_token',
        fcmToken: null,
      );

      expect(result, isEmpty);
      expect(httpCalled, isFalse);
      expect(savedTags, isEmpty);
    });
  });
}
