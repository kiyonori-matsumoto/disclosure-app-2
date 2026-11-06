import 'package:disclosure_app_fl/providers/favorites_provider.dart';
import 'package:disclosure_app_fl/providers/notification_tags_provider.dart';
import 'package:disclosure_app_fl/providers/topic_sync_provider.dart';
import 'package:disclosure_app_fl/utils/notification_topic_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('desiredNotificationTopicsProvider', () {
    test('favorites と notificationTags からトピック集合を生成する', () {
      final container = ProviderContainer(
        overrides: [
          favoritesProvider.overrideWith((ref) => ['7203', '6758']),
          notificationTagsProvider.overrideWith((ref) => ['決算', '配当']),
        ],
      );
      addTearDown(container.dispose);

      final topics = container.read(desiredNotificationTopicsProvider);
      expect(
        topics,
        equals({
          NotificationTopicHelper.toTopic('7203'),
          NotificationTopicHelper.toTopic('6758'),
          NotificationTopicHelper.fromTag('決算'),
          NotificationTopicHelper.fromTag('配当'),
        }),
      );
    });

    test('空リストの場合は空の Set を返す', () {
      final container = ProviderContainer(
        overrides: [
          favoritesProvider.overrideWith((ref) => []),
          notificationTagsProvider.overrideWith((ref) => []),
        ],
      );
      addTearDown(container.dispose);

      final topics = container.read(desiredNotificationTopicsProvider);
      expect(topics, isEmpty);
    });
  });

  group('TopicSyncHelper / TagMigrationHelper Provider', () {
    test('デフォルトインスタンスが正しく提供される', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(topicSyncHelperProvider), isNotNull);
      expect(container.read(tagMigrationHelperProvider), isNotNull);
    });
  });

  group('TopicSync Notifier ライフサイクル', () {
    test('Firebase 未初期化環境でもクラッシュせずに初期化・破棄できる', () {
      final container = ProviderContainer(
        overrides: [
          favoritesProvider.overrideWith((ref) => ['7203']),
          notificationTagsProvider.overrideWith((ref) => ['決算']),
        ],
      );
      addTearDown(container.dispose);

      expect(
        () => container.read(topicSyncProvider.notifier),
        returnsNormally,
      );
    });
  });
}
