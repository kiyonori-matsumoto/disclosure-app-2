import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:disclosure_app_fl/models/disclosure.dart';
import 'package:disclosure_app_fl/providers/auth_provider.dart';
import 'package:disclosure_app_fl/utils/time.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'saved_disclosures_provider.g.dart';

/// ログインユーザーの保存済み開示情報ドキュメント一覧をリアルタイム購読する Provider
@riverpod
Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> savedDisclosuresStream(
  Ref ref,
) {
  final authUser = ref.watch(authStateProvider).value;
  if (authUser == null) {
    return Stream.value([]);
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(authUser.uid)
      .collection('disclosures')
      .orderBy('add_at', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs);
}

/// 保存済み開示情報を追加日（日付文字列）ごとにグループ化した Provider
@riverpod
Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>
    groupedSavedDisclosures(Ref ref) {
  final docs = ref.watch(savedDisclosuresStreamProvider).value ?? [];
  return groupBy(docs, (doc) => toDate(doc.data()['add_at']));
}

/// 保存済み開示情報の操作（保存・削除・復元）を担当するクラス
@riverpod
class SavedDisclosuresAction extends _$SavedDisclosuresAction {
  @override
  void build() {
    // 状態を持たないアクション用クラス
  }

  /// 開示情報を保存する
  Future<void> save(Disclosure disclosure) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) {
      throw StateError('User is not authenticated');
    }

    final obj = disclosure.toObject();
    obj['add_at'] = DateTime.now().millisecondsSinceEpoch;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('disclosures')
        .doc(disclosure.document)
        .set(obj);
  }

  /// 保存済みドキュメントを削除する
  Future<void> delete(DocumentReference ref) async {
    await ref.delete();
  }

  /// 削除を取り消して復元する
  Future<void> restore(
    DocumentReference ref,
    Map<String, dynamic> data,
  ) async {
    await ref.set(data);
  }
}
