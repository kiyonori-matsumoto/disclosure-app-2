import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:disclosure_app_fl/models/company.dart';
import 'package:disclosure_app_fl/providers/company_provider.dart';
import 'package:disclosure_app_fl/providers/user_settings_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'company_history_provider.g.dart';

/// ログインユーザーの検索履歴（証券コード一覧）を提供する Provider
@Riverpod(keepAlive: true)
List<String> companyHistoryCodes(Ref ref) {
  final userDoc = ref.watch(userDocStreamProvider).value;
  if (userDoc == null) return [];
  return (userDoc['cp_hist'] as List?)?.map((e) => e.toString()).toList() ?? [];
}

/// 企業情報付きの検索履歴リストを提供する Provider
@Riverpod(keepAlive: true)
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

  /// 既存の履歴リストに新規コードを先頭追加し、重複を排除して最大20件にトリミングする
  static List<String> computeUpdatedHistory(List<dynamic> current, String newCode) {
    final trimmed = newCode.trim().toUpperCase();
    final currentStrings = current.map((e) => e.toString()).toList();
    if (trimmed.isEmpty) return currentStrings;

    return [
      trimmed,
      ...currentStrings.where((c) => c != trimmed),
    ].take(20).toList();
  }

  /// 検索履歴に企業コードを追加する（最新を先頭に追加、重複排除、最大20件）
  Future<void> add(String uid, String code) => addWithWriter(uid, code);

  @visibleForTesting
  Future<void> addWithWriter(
    String uid,
    String code, {
    Future<void> Function(String uid, List<String> updated)? onWrite,
  }) async {
    final trimmed = code.trim().toUpperCase();
    if (trimmed.isEmpty) return;

    // userDocStreamProvider の初回読み込み完了前に空リストで上書きして履歴を消さないよう、
    // 未取得時はストリームの解決を待ってから現在の履歴を取得する。
    // 待機中に autoDispose されないよう keepAlive と listen で寿命を保持する。
    // runTransaction はオフラインやバックグラウンド移行時に UNAVAILABLE で失敗するため使わない。
    final link = ref.keepAlive();
    final sub = ref.listen(userDocStreamProvider, (_, __) {});
    try {
      final userDoc = ref.read(userDocStreamProvider).value ??
          await ref.read(userDocStreamProvider.future);
      if (userDoc == null) return;
      final current = (userDoc['cp_hist'] as List?) ?? const [];
      final updated = computeUpdatedHistory(current, trimmed);

      if (onWrite != null) {
        await onWrite(uid, updated);
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'cp_hist': updated}, SetOptions(merge: true));
    } finally {
      sub.close();
      link.close();
    }
  }
}
