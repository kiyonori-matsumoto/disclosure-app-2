import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:disclosure_app_fl/providers/auth_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_settings_provider.g.dart';

/// ログインユーザーの users/{uid} ドキュメントデータをリアルタイム購読する基盤 Provider
@riverpod
Stream<Map<String, dynamic>> userDocStream(Ref ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value({});
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((snapshot) => snapshot.data() ?? {});
}

/// 日々の開示情報を非表示にする設定の Provider
@riverpod
bool hideDailyDisclosure(Ref ref) {
  final data = ref.watch(userDocStreamProvider).value;
  if (data == null) return false;
  final setting = data['setting'] as Map<String, dynamic>?;
  return setting?['hideDailyDisclosure'] as bool? ?? false;
}

/// ユーザー設定の更新を担当するアクションクラス
@riverpod
class UserSettingsAction extends _$UserSettingsAction {
  @override
  void build() {
    // 状態を持たないアクション用クラス
  }

  /// 日々の開示情報非表示設定を更新する
  Future<void> setHideDailyDisclosure(bool value) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      throw StateError('User is not authenticated');
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({
          'setting': {'hideDailyDisclosure': value}
        }, SetOptions(merge: true));
  }
}
