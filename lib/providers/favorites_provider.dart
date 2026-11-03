import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:disclosure_app_fl/models/company.dart';
import 'package:disclosure_app_fl/providers/company_provider.dart';
import 'package:disclosure_app_fl/providers/user_settings_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'favorites_provider.g.dart';

/// ログインユーザーのお気に入り企業コード一覧を提供する Provider
@riverpod
List<String> favorites(Ref ref) {
  final userDoc = ref.watch(userDocStreamProvider).value;
  if (userDoc == null) return [];
  return (userDoc['favorites'] as List?)?.cast<String>() ?? [];
}

/// 企業情報付きのお気に入り企業リストを提供する Provider
@riverpod
List<Company> favoritesWithCompany(Ref ref) {
  final favCodes = ref.watch(favoritesProvider);
  final codeMap = ref.watch(companyCodeMapProvider);
  return favCodes
      .map((code) => codeMap[code] ?? Company(code, name: '???'))
      .toList();
}

/// 指定した企業コードがお気に入りに登録されているかを判定する Provider
@riverpod
bool isFavorite(Ref ref, String code) {
  final favCodes = ref.watch(favoritesProvider);
  return favCodes.contains(code);
}

/// お気に入りの追加・削除・トグル操作を担当するアクションクラス
@riverpod
class FavoritesAction extends _$FavoritesAction {
  @override
  void build() {
    // 状態を持たないアクション用クラス
  }

  /// お気に入りに企業コードを追加する
  Future<void> add(String uid, String code) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({
          'favorites': FieldValue.arrayUnion([code])
        }, SetOptions(merge: true));
  }

  /// お気に入りから企業コードを削除する
  Future<void> remove(String uid, String code) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({
          'favorites': FieldValue.arrayRemove([code])
        }, SetOptions(merge: true));
  }

  /// お気に入りの登録・解除を切り替える
  Future<void> toggle(String uid, String code, {required bool isFavorite}) async {
    if (isFavorite) {
      await remove(uid, code);
    } else {
      await add(uid, code);
    }
  }
}
