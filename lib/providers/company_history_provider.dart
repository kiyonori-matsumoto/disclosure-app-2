import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:disclosure_app_fl/models/company.dart';
import 'package:disclosure_app_fl/providers/company_provider.dart';
import 'package:disclosure_app_fl/providers/user_settings_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'company_history_provider.g.dart';

/// ログインユーザーの検索履歴（証券コード一覧）を提供する Provider
@riverpod
List<String> companyHistoryCodes(Ref ref) {
  final userDoc = ref.watch(userDocStreamProvider).value;
  if (userDoc == null) return [];
  return (userDoc['cp_hist'] as List?)?.cast<String>() ?? [];
}

/// 企業情報付きの検索履歴リストを提供する Provider
@riverpod
List<Company> companyHistory(Ref ref) {
  final histCodes = ref.watch(companyHistoryCodesProvider);
  final codeMap = ref.watch(companyCodeMapProvider);
  return histCodes
      .map((code) => codeMap[code] ?? Company(code, name: '???'))
      .toList();
}

/// 検索履歴の追加操作を担当するアクションクラス
@riverpod
class CompanyHistoryAction extends _$CompanyHistoryAction {
  @override
  void build() {
    // 状態を持たないアクション用クラス
  }

  /// 検索履歴に企業コードを追加する（最新を先頭に追加、重複排除、最大20件）
  Future<void> add(
    String uid,
    String code, {
    List<String>? currentHistory,
  }) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return;

    List<String> current = currentHistory ?? [];
    if (currentHistory == null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      current = (doc.data()?['cp_hist'] as List?)?.cast<String>() ?? [];
    }

    final updated = [
      trimmed,
      ...current.where((c) => c != trimmed),
    ].take(20).toList();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({'cp_hist': updated}, SetOptions(merge: true));
  }
}
