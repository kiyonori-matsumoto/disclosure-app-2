import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:disclosure_app_fl/models/company_settlement.dart';
import 'package:disclosure_app_fl/models/edinet.dart';
import 'package:disclosure_app_fl/providers/company_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'company_disclosures_provider.g.dart';

/// 開示情報のページネーション状態を表すデータクラス
class PaginatedDisclosuresState {
  final List<DocumentSnapshot<Map<String, dynamic>>> docs;
  final bool hasMore;
  final bool isLoadingMore;

  const PaginatedDisclosuresState({
    required this.docs,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  PaginatedDisclosuresState copyWith({
    List<DocumentSnapshot<Map<String, dynamic>>>? docs,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return PaginatedDisclosuresState(
      docs: docs ?? this.docs,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// EDINET 開示情報のページネーション状態を表すデータクラス
class PaginatedEdinetsState {
  final List<Edinet> items;
  final DocumentSnapshot? lastDoc;
  final bool hasMore;
  final bool isLoadingMore;

  const PaginatedEdinetsState({
    required this.items,
    this.lastDoc,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  PaginatedEdinetsState copyWith({
    List<Edinet>? items,
    DocumentSnapshot? lastDoc,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return PaginatedEdinetsState(
      items: items ?? this.items,
      lastDoc: lastDoc ?? this.lastDoc,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// 個別企業の決算発表予定を提供する Provider
@riverpod
Future<CompanySettlement?> companySettlement(Ref ref, String code) async {
  final trimmed = code.trim().toUpperCase();
  if (trimmed.isEmpty) return null;

  try {
    final doc = await FirebaseFirestore.instance
        .collection('settlements')
        .doc(trimmed)
        .get();
    if (doc.exists) {
      return CompanySettlement.fromDocumentSnapshot(doc);
    }
    return null;
  } catch (error, stack) {
    debugPrint("Failed to fetch settlement for $trimmed: $error");
    if (Firebase.apps.isNotEmpty) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: false);
    }
    return null;
  }
}

/// 個別企業の開示情報（TDNET）のページネーション取得・リフレッシュを管理する Notifier
@riverpod
class CompanyDisclosures extends _$CompanyDisclosures {
  static const int pageSize = 20;

  @override
  Future<PaginatedDisclosuresState> build(String code) async {
    final trimmed = code.trim().toUpperCase();
    if (trimmed.isEmpty) {
      return const PaginatedDisclosuresState(docs: [], hasMore: false);
    }

    final query = FirebaseFirestore.instance
        .collection('disclosures')
        .where('code', isEqualTo: trimmed)
        .orderBy('time', descending: true)
        .limit(pageSize);

    final snapshot = await query.get();
    final docs = snapshot.docs;
    return PaginatedDisclosuresState(
      docs: docs,
      hasMore: docs.length >= pageSize,
    );
  }

  /// 次のページを取得して蓄積する
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    if (current.docs.isEmpty) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final trimmed = code.trim().toUpperCase();
      final lastDoc = current.docs.last;
      final query = FirebaseFirestore.instance
          .collection('disclosures')
          .where('code', isEqualTo: trimmed)
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
      debugPrint("Failed to load more disclosures for $code: $error");
      if (Firebase.apps.isNotEmpty) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: false);
      }
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  /// 先頭から再取得（リフレッシュ）する
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

/// 個別企業の EDINET 開示情報のページネーション取得・リフレッシュを管理する Notifier
@riverpod
class CompanyEdinets extends _$CompanyEdinets {
  static const int pageSize = 20;

  @override
  Future<PaginatedEdinetsState> build(String edinetCode) async {
    final trimmed = edinetCode.trim();
    if (trimmed.isEmpty) {
      return const PaginatedEdinetsState(items: [], hasMore: false);
    }

    final query = FirebaseFirestore.instance
        .collection('edinets')
        .where('map.$trimmed', isGreaterThan: 0)
        .orderBy('map.$trimmed', descending: true)
        .limit(pageSize);

    final snapshot = await query.get();
    final docs = snapshot.docs;
    final items = docs.map((d) => Edinet.fromDocumentSnapshot(d)).toList();
    final companyEdinetMap = ref.watch(companyEdinetMapProvider);
    for (final item in items) {
      item.fillCompanyName(companyEdinetMap);
    }

    return PaginatedEdinetsState(
      items: items,
      lastDoc: docs.isNotEmpty ? docs.last : null,
      hasMore: docs.length >= pageSize,
    );
  }

  /// 次のページを取得して蓄積する
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    if (current.lastDoc == null) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final trimmed = edinetCode.trim();
      final query = FirebaseFirestore.instance
          .collection('edinets')
          .where('map.$trimmed', isGreaterThan: 0)
          .orderBy('map.$trimmed', descending: true)
          .startAfterDocument(current.lastDoc!)
          .limit(pageSize);

      final snapshot = await query.get();
      final docs = snapshot.docs;
      final newItems = docs.map((d) => Edinet.fromDocumentSnapshot(d)).toList();
      final companyEdinetMap = ref.read(companyEdinetMapProvider);
      for (final item in newItems) {
        item.fillCompanyName(companyEdinetMap);
      }

      state = AsyncData(current.copyWith(
        items: [...current.items, ...newItems],
        lastDoc: docs.isNotEmpty ? docs.last : current.lastDoc,
        hasMore: docs.length >= pageSize,
        isLoadingMore: false,
      ));
    } catch (error, stack) {
      debugPrint("Failed to load more edinets for $edinetCode: $error");
      if (Firebase.apps.isNotEmpty) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: false);
      }
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  /// 先頭から再取得（リフレッシュ）する
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
