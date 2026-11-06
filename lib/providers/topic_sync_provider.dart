import 'dart:async';

import 'package:disclosure_app_fl/providers/auth_provider.dart';
import 'package:disclosure_app_fl/providers/favorites_provider.dart';
import 'package:disclosure_app_fl/providers/notification_tags_provider.dart';
import 'package:disclosure_app_fl/providers/user_settings_provider.dart';
import 'package:disclosure_app_fl/utils/notification_topic_helper.dart';
import 'package:disclosure_app_fl/utils/tag_migration_helper.dart';
import 'package:disclosure_app_fl/utils/topic_sync_helper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'topic_sync_provider.g.dart';

/// TopicSyncHelper を提供する Provider (テスト時に override 可能)
@Riverpod(keepAlive: true)
TopicSyncHelper topicSyncHelper(Ref ref) => TopicSyncHelper();

/// TagMigrationHelper を提供する Provider (テスト時に override 可能)
@Riverpod(keepAlive: true)
TagMigrationHelper tagMigrationHelper(Ref ref) => TagMigrationHelper();

/// 購読すべきトピック集合を計算する Provider
@riverpod
Set<String> desiredNotificationTopics(Ref ref) {
  final favs = ref.watch(favoritesProvider);
  final tags = ref.watch(notificationTagsProvider);
  return {
    ...favs.map(NotificationTopicHelper.toTopic),
    ...tags.map(NotificationTopicHelper.fromTag),
  };
}

/// FCM トピック同期およびタグマイグレーションを統括する Notifier
@Riverpod(keepAlive: true)
class TopicSync extends _$TopicSync {
  StreamSubscription<String>? _tokenRefreshSub;
  bool _migrationAttempted = false;

  @override
  void build() {
    if (Firebase.apps.isEmpty) {
      return;
    }

    final helper = ref.watch(topicSyncHelperProvider);
    final migrationHelper = ref.watch(tagMigrationHelperProvider);
    final messaging = FirebaseMessaging.instance;

    // 1. desiredNotificationTopics の変化を監視して差分同期
    ref.listen<Set<String>>(
      desiredNotificationTopicsProvider,
      (previous, current) {
        if (previous == null || !setEquals(previous, current)) {
          debugPrint(
            "[TopicSync] Desired topics updated: ${current.length} topics",
          );
          helper.syncTopics(desiredTopics: current);
        }
      },
      fireImmediately: false,
    );

    // 2. 初回タグ通知マイグレーション（未移行ユーザーがアプリを起動したときに1度だけ実行）
    ref.listen<AsyncValue<Map<String, dynamic>>>(
      userDocStreamProvider,
      (previous, next) {
        final setting = next.value;
        final user = ref.read(currentUserProvider);
        if (!_migrationAttempted &&
            user != null &&
            setting != null &&
            !setting.containsKey('notification_tags')) {
          _migrationAttempted = true;
          // ignore: deprecated_member_use
          messaging.getToken().then((token) {
            migrationHelper.ensureTagsMigrated(
              uid: user.uid,
              fcmToken: token,
              userDocData: setting,
            );
          }).catchError((dynamic e) {
            debugPrint("getToken for tag migration failed: $e");
          });
        }
      },
    );

    // 3. トークン変更（再インストール、端末データ消去、リフレッシュ）検知と同期
    void triggerTopicSync() {
      final desired = ref.read(desiredNotificationTopicsProvider);
      helper.syncTopics(desiredTopics: desired);
    }

    // ignore: deprecated_member_use
    _tokenRefreshSub = messaging.onTokenRefresh.listen((newToken) async {
      final changed = await helper.handleTokenChange(newToken);
      if (changed) {
        triggerTopicSync();
      }
    });

    // ignore: deprecated_member_use
    messaging.getToken().then((token) async {
      final changed = await helper.handleTokenChange(token);
      if (changed) {
        triggerTopicSync();
      }
    }).catchError((dynamic e) {
      debugPrint("Initial getToken check failed: $e");
    });

    ref.onDispose(() {
      _tokenRefreshSub?.cancel();
    });
  }
}
