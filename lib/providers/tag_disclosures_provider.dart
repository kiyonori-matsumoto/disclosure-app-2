import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:disclosure_app_fl/providers/company_disclosures_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tag_disclosures_provider.g.dart';

/// タグ別開示用 Firestore インスタンス Provider (テスト時にモックに差し替え可能)
@riverpod
FirebaseFirestore tagDisclosuresFirestore(Ref ref) {
  return FirebaseFirestore.instance;
}

/// 指定したタグに合致する開示情報のページネーション取得・リフレッシュを管理する Notifier
@riverpod
class TagDisclosures extends _$TagDisclosures {
  static const int pageSize = 20;

  @override
  Future<PaginatedDisclosuresState> build(String tag) async {
    final trimmedTag = tag.trim();
    if (trimmedTag.isEmpty) {
      return const PaginatedDisclosuresState(docs: [], hasMore: false);
    }

    final firestore = ref.watch(tagDisclosuresFirestoreProvider);
    final query = firestore
        .collection('disclosures')
        .where('tags2', arrayContains: trimmedTag)
        .orderBy('time', descending: true)
        .limit(pageSize);

    try {
      final snapshot = await query.get();
      final docs = snapshot.docs;
      return PaginatedDisclosuresState(
        docs: docs,
        hasMore: docs.length >= pageSize,
      );
    } catch (error, stack) {
      debugPrint("Failed to fetch disclosures for tag $trimmedTag: $error");
      if (Firebase.apps.isNotEmpty) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: false);
      }
      rethrow;
    }
  }

  /// 次のページを取得して蓄積する
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    if (current.docs.isEmpty) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final trimmedTag = tag.trim();
      final lastDoc = current.docs.last;
      final firestore = ref.read(tagDisclosuresFirestoreProvider);
      final query = firestore
          .collection('disclosures')
          .where('tags2', arrayContains: trimmedTag)
          .orderBy('time', descending: true)
          .startAfterDocument(lastDoc)
          .limit(pageSize);

      final snapshot = await query.get();
      final newDocs = snapshot.docs;

      state = AsyncData(current.copyWith(
        docs: [...current.docs, ...newDocs],
        hasMore: newDocs.length >= pageSize,
        isLoadingMore: false,
      ));
    } catch (error, stack) {
      debugPrint("Failed to load more disclosures for tag $tag: $error");
      if (Firebase.apps.isNotEmpty) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: false);
      }
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  /// 一覧を再取得してリフレッシュする
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
