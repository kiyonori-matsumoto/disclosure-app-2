import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:disclosure_app_fl/providers/user_settings_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'custom_tags_provider.g.dart';

/// ログインユーザーのカスタムタグ一覧（List<String>）を提供する Provider
@riverpod
List<String> customTags(Ref ref) {
  final userDoc = ref.watch(userDocStreamProvider).value;
  if (userDoc == null) return [];
  final tags = (userDoc['tags'] as List?)?.cast<String>() ?? [];
  return tags;
}

/// カスタムタグの追加・削除操作を担当するアクションクラス
@riverpod
class CustomTagsAction extends _$CustomTagsAction {
  @override
  void build() {
    // 状態を持たないアクション用クラス
  }

  /// カスタムタグを追加する
  Future<void> add(String uid, String tag) async {
    final trimmed = tag.trim();
    if (trimmed.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({
          'tags': FieldValue.arrayUnion([trimmed])
        }, SetOptions(merge: true));
  }

  /// カスタムタグを削除する
  Future<void> remove(String uid, String tag) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({
          'tags': FieldValue.arrayRemove([tag])
        }, SetOptions(merge: true));
  }
}
