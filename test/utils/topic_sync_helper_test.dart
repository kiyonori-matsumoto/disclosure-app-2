import 'package:disclosure_app_fl/utils/topic_sync_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TopicSyncHelper.syncTopics (差分同期と結果整合性)', () {
    test('初期状態（空）から全トピックを初回購読する', () async {
      final subscribed = <String>[];
      final unsubscribed = <String>[];

      final helper = TopicSyncHelper(
        onSubscribe: (topic) async => subscribed.add(topic),
        onUnsubscribe: (topic) async => unsubscribed.add(topic),
      );

      final desired = {'code_7203', 'code_6758', 'tags_kessan'};
      final result = await helper.syncTopics(desiredTopics: desired);

      expect(subscribed, containsAll(desired));
      expect(subscribed.length, equals(3));
      expect(unsubscribed, isEmpty);
      expect(result.added, equals(desired));
      expect(result.removed, isEmpty);
      expect(result.currentLocalTopics, equals(desired));

      // SharedPreferences にも永続化されていることを確認
      final local = await helper.getLocalSubscribedTopics();
      expect(local, equals(desired));
    });

    test('既存トピックがある場合、差分（新規追加分）のみを購読する', () async {
      SharedPreferences.setMockInitialValues({
        TopicSyncHelper.keySubscribedTopics: ['code_7203'],
      });

      final subscribed = <String>[];
      final unsubscribed = <String>[];

      final helper = TopicSyncHelper(
        onSubscribe: (topic) async => subscribed.add(topic),
        onUnsubscribe: (topic) async => unsubscribed.add(topic),
      );

      final desired = {'code_7203', 'code_6758'};
      final result = await helper.syncTopics(desiredTopics: desired);

      expect(subscribed, equals(['code_6758']));
      expect(unsubscribed, isEmpty);
      expect(result.added, equals({'code_6758'}));
      expect(result.removed, isEmpty);
      expect(result.currentLocalTopics, equals(desired));
    });

    test('お気に入り解除時、差分（削除分）のみを確実に unsubscribe する', () async {
      SharedPreferences.setMockInitialValues({
        TopicSyncHelper.keySubscribedTopics: ['code_7203', 'code_6758', 'code_9984'],
      });

      final subscribed = <String>[];
      final unsubscribed = <String>[];

      final helper = TopicSyncHelper(
        onSubscribe: (topic) async => subscribed.add(topic),
        onUnsubscribe: (topic) async => unsubscribed.add(topic),
      );

      // code_6758 と code_9984 を解除し、code_7203 のみを残す
      final desired = {'code_7203'};
      final result = await helper.syncTopics(desiredTopics: desired);

      expect(subscribed, isEmpty);
      expect(unsubscribed, containsAll(['code_6758', 'code_9984']));
      expect(unsubscribed.length, equals(2));
      expect(result.removed, equals({'code_6758', 'code_9984'}));
      expect(result.currentLocalTopics, equals({'code_7203'}));

      final local = await helper.getLocalSubscribedTopics();
      expect(local, equals({'code_7203'}));
    });

    test('追加と削除が同時に発生した場合、両方の差分が正しく処理される', () async {
      SharedPreferences.setMockInitialValues({
        TopicSyncHelper.keySubscribedTopics: ['code_7203', 'code_old'],
      });

      final subscribed = <String>[];
      final unsubscribed = <String>[];

      final helper = TopicSyncHelper(
        onSubscribe: (topic) async => subscribed.add(topic),
        onUnsubscribe: (topic) async => unsubscribed.add(topic),
      );

      final desired = {'code_7203', 'code_new'};
      final result = await helper.syncTopics(desiredTopics: desired);

      expect(subscribed, equals(['code_new']));
      expect(unsubscribed, equals(['code_old']));
      expect(result.added, equals({'code_new'}));
      expect(result.removed, equals({'code_old'}));
      expect(result.currentLocalTopics, equals(desired));
    });

    test('unsubscribe が失敗した場合、ローカルから削除されず次回リトライ対象として残る', () async {
      SharedPreferences.setMockInitialValues({
        TopicSyncHelper.keySubscribedTopics: ['code_7203', 'code_fail'],
      });

      final helper = TopicSyncHelper(
        onUnsubscribe: (topic) async {
          if (topic == 'code_fail') {
            throw Exception('Network error during unsubscribe');
          }
        },
      );

      final desired = {'code_7203'};
      final result = await helper.syncTopics(desiredTopics: desired);

      expect(result.hasErrors, isTrue);
      expect(result.errors.containsKey('code_fail'), isTrue);
      expect(result.removed, isEmpty);
      // code_fail は解除失敗のためローカルに残る
      expect(result.currentLocalTopics, equals({'code_7203', 'code_fail'}));

      // 2回目の実行で unsubscribe が成功すれば、ローカルからも消える（自己修復）
      final successfulUnsubscribes = <String>[];
      final retryHelper = TopicSyncHelper(
        onUnsubscribe: (topic) async => successfulUnsubscribes.add(topic),
      );

      final retryResult = await retryHelper.syncTopics(desiredTopics: desired);
      expect(retryResult.hasErrors, isFalse);
      expect(retryResult.removed, equals({'code_fail'}));
      expect(retryResult.currentLocalTopics, equals({'code_7203'}));
    });

    test('subscribe が失敗した場合、ローカルに追加されず次回リトライ対象として残る', () async {
      SharedPreferences.setMockInitialValues({
        TopicSyncHelper.keySubscribedTopics: ['code_7203'],
      });

      final helper = TopicSyncHelper(
        onSubscribe: (topic) async {
          if (topic == 'code_new_fail') {
            throw Exception('Network error during subscribe');
          }
        },
      );

      final desired = {'code_7203', 'code_new_fail'};
      final result = await helper.syncTopics(desiredTopics: desired);

      expect(result.hasErrors, isTrue);
      expect(result.errors.containsKey('code_new_fail'), isTrue);
      expect(result.added, isEmpty);
      expect(result.currentLocalTopics, equals({'code_7203'}));

      // 2回目の実行で subscribe が成功すれば、ローカルにも追加される（自己修復）
      final successfulSubscribes = <String>[];
      final retryHelper = TopicSyncHelper(
        onSubscribe: (topic) async => successfulSubscribes.add(topic),
      );

      final retryResult = await retryHelper.syncTopics(desiredTopics: desired);
      expect(retryResult.hasErrors, isFalse);
      expect(retryResult.added, equals({'code_new_fail'}));
      expect(retryResult.currentLocalTopics, equals(desired));
    });
  });

  group('TopicSyncHelper.handleTokenChange (再インストール・データ消去ガード)', () {
    test('初回トークン設定時は true を返し、トークンを保存する', () async {
      final helper = TopicSyncHelper();
      final changed = await helper.handleTokenChange('token_first');

      expect(changed, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(TopicSyncHelper.keyLastSyncedToken), equals('token_first'));
    });

    test('同じトークンが渡された場合は false を返し、状態を維持する', () async {
      SharedPreferences.setMockInitialValues({
        TopicSyncHelper.keyLastSyncedToken: 'token_existing',
        TopicSyncHelper.keySubscribedTopics: ['code_7203'],
      });

      final helper = TopicSyncHelper();
      final changed = await helper.handleTokenChange('token_existing');

      expect(changed, isFalse);
      final local = await helper.getLocalSubscribedTopics();
      expect(local, equals({'code_7203'}));
    });

    test('トークン変更時（再インストール・データ消去など）はローカルキャッシュをリセットし、新トークンを保存する',
        () async {
      SharedPreferences.setMockInitialValues({
        TopicSyncHelper.keyLastSyncedToken: 'token_old',
        TopicSyncHelper.keySubscribedTopics: ['code_7203', 'code_6758'],
      });

      final helper = TopicSyncHelper();
      final changed = await helper.handleTokenChange('token_new');

      expect(changed, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(TopicSyncHelper.keyLastSyncedToken), equals('token_new'));

      // ローカルの購読履歴がクリアされていることを確認
      final local = await helper.getLocalSubscribedTopics();
      expect(local, isEmpty);

      // この直後に syncTopics を実行すると、全件が新規登録として subscribe される
      final subscribed = <String>[];
      final syncHelper = TopicSyncHelper(
        onSubscribe: (topic) async => subscribed.add(topic),
      );

      final result = await syncHelper.syncTopics(desiredTopics: {'code_7203', 'code_6758'});
      expect(subscribed, containsAll(['code_7203', 'code_6758']));
      expect(result.added.length, equals(2));
    });
  });
}
