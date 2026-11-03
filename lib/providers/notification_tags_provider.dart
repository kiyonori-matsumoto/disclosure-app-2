import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:disclosure_app_fl/providers/favorites_provider.dart';
import 'package:disclosure_app_fl/providers/user_settings_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_tags_provider.g.dart';

/// ログインユーザーの通知タグ設定一覧（List<String>）を提供する Provider
@riverpod
List<String> notificationTags(Ref ref) {
  final userDoc = ref.watch(userDocStreamProvider).value;
  if (userDoc == null) return [];
  final tags = (userDoc['notification_tags'] as List?)?.cast<String>() ?? [];
  return tags;
}

/// テスト・デバッグ用: 現在の全通知（お気に入り企業 + 通知タグ）をコンソールログに出力する Provider
@riverpod
void logCurrentNotifications(Ref ref) {
  final favs = ref.watch(favoritesProvider);
  final tags = ref.watch(notificationTagsProvider);
  debugPrint('🔔 [Notification Status] 🔔');
  debugPrint('  - Favorite Companies (${favs.length}): $favs');
  debugPrint('  - Notification Tags (${tags.length}): $tags');
}

/// タグ通知の追加・削除・トグル操作を担当するアクションクラス
@riverpod
class NotificationTagsAction extends _$NotificationTagsAction {
  @override
  void build() {
    // 状態を持たないアクション用クラス
  }

  /// 通知タグを追加する
  Future<void> add(String uid, String tag) async {
    debugPrint('[NotificationTags] Adding tag: "$tag" for user: $uid');
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({
          'notification_tags': FieldValue.arrayUnion([tag])
        }, SetOptions(merge: true));
  }

  /// 通知タグを削除する
  Future<void> remove(String uid, String tag) async {
    debugPrint('[NotificationTags] Removing tag: "$tag" for user: $uid');
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({
          'notification_tags': FieldValue.arrayRemove([tag])
        }, SetOptions(merge: true));
  }

  /// 通知タグの有効/無効を切り替える
  Future<void> toggle(String uid, String tag, {required bool isSelected}) async {
    if (isSelected) {
      await remove(uid, tag);
    } else {
      await add(uid, tag);
    }
  }
}
