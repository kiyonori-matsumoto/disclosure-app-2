import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:disclosure_app_fl/models/company.dart';
import 'package:disclosure_app_fl/providers/company_provider.dart';
import 'package:disclosure_app_fl/providers/user_settings_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'favorites_provider.g.dart';

const String _prefKeyFavoriteSortOrder = 'favorite_sort_order';

/// お気に入り一覧の並び順
enum FavoriteSortOrder {
  codeAsc('証券コード順（昇順）'),
  codeDesc('証券コード順（降順）'),
  nameAsc('企業名順'),
  registered('登録順');

  final String label;
  const FavoriteSortOrder(this.label);
}

/// お気に入り一覧の並び順を管理・永続化する Notifier
@riverpod
class FavoriteSortOrderNotifier extends _$FavoriteSortOrderNotifier {
  Future<void>? _initFuture;

  @visibleForTesting
  Future<void>? get initFuture => _initFuture;

  @override
  FavoriteSortOrder build() {
    _initFuture = _loadSavedSortOrder();
    return FavoriteSortOrder.codeAsc;
  }

  Future<void> _loadSavedSortOrder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKeyFavoriteSortOrder);
      if (saved == null) return;
      for (final order in FavoriteSortOrder.values) {
        if (order.name == saved) {
          state = order;
          return;
        }
      }
    } catch (e) {
      debugPrint('Failed to load favorite sort order: $e');
    }
  }

  Future<void> setSortOrder(FavoriteSortOrder order) async {
    state = order;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyFavoriteSortOrder, order.name);
    } catch (e) {
      debugPrint('Failed to save favorite sort order: $e');
    }
  }
}

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
  final sortOrder = ref.watch(favoriteSortOrderProvider);

  final companies = favCodes
      .map((code) => codeMap[code] ?? Company(code, name: '???'))
      .toList();

  switch (sortOrder) {
    case FavoriteSortOrder.codeAsc:
      companies.sort((a, b) => (a.code ?? '').compareTo(b.code ?? ''));
    case FavoriteSortOrder.codeDesc:
      companies.sort((a, b) => (b.code ?? '').compareTo(a.code ?? ''));
    case FavoriteSortOrder.nameAsc:
      companies.sort(_compareCompanyByName);
    case FavoriteSortOrder.registered:
      break;
  }

  return companies;
}

int _compareCompanyByName(Company a, Company b) {
  String sortKey(Company c) {
    final kana = c.nameKana?.trim() ?? '';
    if (kana.isNotEmpty) return kana;
    return c.name?.trim() ?? '';
  }

  final cmp = sortKey(a).compareTo(sortKey(b));
  return cmp != 0 ? cmp : (a.code ?? '').compareTo(b.code ?? '');
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
