import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:disclosure_app_fl/models/edinet.dart';
import 'package:disclosure_app_fl/models/feed_state.dart';
import 'package:disclosure_app_fl/providers/company_provider.dart';
import 'package:disclosure_app_fl/providers/favorites_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'edinet_disclosures_provider.g.dart';

final edinetDateFormatter = DateFormat("yyyy-MM-dd");

/// EDINET 用 Firestore インスタンス Provider (テスト時にモックに差し替え可能)
@riverpod
FirebaseFirestore edinetFirestore(Ref ref) {
  return FirebaseFirestore.instance;
}

const int kEdinetsPageSize = 100;
const int kEdinetsDeltaLimit = 50;

/// EDINET 選択日付 Notifier (デフォルト: 当日)
@riverpod
class EdinetSelectedDate extends _$EdinetSelectedDate {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void setDate(DateTime date) {
    state = DateTime(date.year, date.month, date.day);
  }
}

/// EDINET 書類種別フィルタ Notifier (デフォルト: '' = 全件)
@riverpod
class EdinetDocTypeFilter extends _$EdinetDocTypeFilter {
  @override
  String build() => '';

  void setFilter(String filter) {
    state = filter;
  }

  void reset() {
    state = '';
  }
}

/// EDINET お気に入りのみ表示 Notifier (デフォルト: false)
@riverpod
class EdinetShowOnlyFavorites extends _$EdinetShowOnlyFavorites {
  @override
  bool build() => false;

  void toggle() {
    state = !state;
  }

  void set(bool value) {
    state = value;
  }
}

/// EDINET Firestore 取得・購読ストリームを構築する
///
/// メモリおよび Firestore Read コストを抑えるため、初回は上限付き `.get()` で取得し、
/// 当日分のみ最新 `seq` 以降の新着差分だけを `.snapshots()` で監視する。
Stream<List<Edinet>> buildEdinetsDayStream({
  required FirebaseFirestore firestore,
  required DateTime date,
  DateTime? now,
  int pageSize = kEdinetsPageSize,
  int deltaLimit = kEdinetsDeltaLimit,
}) async* {
  final currentNow = now ?? DateTime.now();
  final day = DateTime(date.year, date.month, date.day);
  final today = DateTime(currentNow.year, currentNow.month, currentNow.day);
  final start = edinetDateFormatter.format(day);
  final end = edinetDateFormatter.format(day.add(const Duration(days: 1)));

  final collection = firestore.collection('edinets');
  final initialSnapshot = await collection
      .where('seq', isGreaterThanOrEqualTo: start)
      .where('seq', isLessThan: end)
      .orderBy('seq', descending: true)
      .limit(pageSize)
      .get();

  final initialItems = initialSnapshot.docs
      .map((doc) => Edinet.fromDocumentSnapshot(doc))
      .toList();
  yield initialItems;

  if (day != today) {
    return;
  }

  final String? latestSeq =
      initialItems.isNotEmpty ? initialItems.first.seq : null;

  final deltaQuery = latestSeq != null
      ? collection
          .where('seq', isGreaterThan: latestSeq)
          .where('seq', isLessThan: end)
          .orderBy('seq', descending: true)
          .limit(deltaLimit)
      : collection
          .where('seq', isGreaterThanOrEqualTo: start)
          .where('seq', isLessThan: end)
          .orderBy('seq', descending: true)
          .limit(pageSize);

  final Map<String, Edinet> deltaById = {};
  final Set<String> initialIds =
      initialItems.map((e) => e.docId ?? '').where((id) => id.isNotEmpty).toSet();

  await for (final deltaSnap in deltaQuery.snapshots()) {
    for (final doc in deltaSnap.docs) {
      final item = Edinet.fromDocumentSnapshot(doc);
      final id = item.docId ?? doc.id;
      if (!initialIds.contains(id)) {
        deltaById[id] = item;
      }
    }
    final mergedDelta = deltaById.values.toList()
      ..sort((a, b) => (b.seq ?? '').compareTo(a.seq ?? ''));
    yield [...mergedDelta, ...initialItems];
  }
}

/// EDINET Firestore 生ストリーム Provider (日付別)
@riverpod
Stream<List<Edinet>> edinetsRawStream(Ref ref, DateTime date) {
  final firestore = ref.watch(edinetFirestoreProvider);
  return buildEdinetsDayStream(firestore: firestore, date: date);
}

/// EDINET フィード状態の型エイリアス
typedef EdinetFeedState = FeedState<Edinet>;

/// EDINET ハイブリッド型開示フィード Notifier (最上部なら自動更新、スクロール中は画面ズレ防止＆新着バッジ)
@riverpod
class EdinetFeed extends _$EdinetFeed {
  DateTime? _lastDate;
  EdinetFeedState? _previousState;
  List<Edinet> _olderItems = [];
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  EdinetFeedState build() {
    final date = ref.watch(edinetSelectedDateProvider);
    final rawAsync = ref.watch(edinetsRawStreamProvider(date));
    final rawDocs = rawAsync.value ?? const [];

    final dateChanged = _lastDate != date;
    _lastDate = date;

    if (dateChanged) {
      _previousState = null;
      _olderItems = [];
      _hasMore = true;
      _isLoadingMore = false;
    }

    if (!rawAsync.isLoading && _olderItems.isEmpty) {
      _hasMore = rawDocs.length >= kEdinetsPageSize;
    }

    final rawIds = rawDocs.map((e) => e.docId ?? '').toSet();
    final combinedItems = _olderItems.isEmpty
        ? rawDocs
        : [
            ...rawDocs,
            ..._olderItems.where((e) => !rawIds.contains(e.docId ?? '')),
          ];

    final newState = FeedState.processNewItems<Edinet>(
      previousState: _previousState,
      newItems: combinedItems,
      idGetter: (e) => e.docId ?? '',
      isLoading: rawAsync.isLoading,
      hasError: rawAsync.hasError,
      error: rawAsync.error,
    );

    _previousState = newState;
    return newState;
  }

  /// スクロール末尾到達時に過去の EDINET 開示を追加取得する
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    final currentItems = state.latestItems;
    if (currentItems.isEmpty) return;

    final lastSeq = currentItems.last.seq;
    if (lastSeq == null || lastSeq.isEmpty) return;

    final date = _lastDate;
    if (date == null) return;

    _isLoadingMore = true;
    try {
      final day = DateTime(date.year, date.month, date.day);
      final start = edinetDateFormatter.format(day);
      final end = edinetDateFormatter.format(day.add(const Duration(days: 1)));

      final firestore = ref.read(edinetFirestoreProvider);
      final snapshot = await firestore
          .collection('edinets')
          .where('seq', isGreaterThanOrEqualTo: start)
          .where('seq', isLessThan: end)
          .orderBy('seq', descending: true)
          .startAfter([lastSeq])
          .limit(kEdinetsPageSize)
          .get();

      final newItems = snapshot.docs
          .map((doc) => Edinet.fromDocumentSnapshot(doc))
          .toList();
      _hasMore = newItems.length >= kEdinetsPageSize;

      if (newItems.isNotEmpty) {
        final existingOlderIds =
            _olderItems.map((e) => e.docId ?? '').toSet();
        _olderItems = [
          ..._olderItems,
          ...newItems.where((e) => !existingOlderIds.contains(e.docId ?? '')),
        ];

        final displayedIds =
            state.displayedItems.map((e) => e.docId ?? '').toSet();
        final latestIds = state.latestItems.map((e) => e.docId ?? '').toSet();
        final updated = state.copyWith(
          displayedItems: [
            ...state.displayedItems,
            ...newItems.where((e) => !displayedIds.contains(e.docId ?? '')),
          ],
          latestItems: [
            ...state.latestItems,
            ...newItems.where((e) => !latestIds.contains(e.docId ?? '')),
          ],
        );
        _previousState = updated;
        state = updated;
      }
    } finally {
      _isLoadingMore = false;
    }
  }

  /// スクロール位置（最上部かどうか）の更新
  void updateScrollPosition({required bool isAtTop}) {
    if (state.isAtTop == isAtTop) return;
    final updated = state.onScrollPositionChanged(isAtTop: isAtTop);
    _previousState = updated;
    state = updated;
  }

  /// 新着 FAB タップ等で最新の開示を明示的に反映する
  void refreshToLatest() {
    final updated = state.refreshToLatest();
    _previousState = updated;
    state = updated;
  }

  static int _debugCounter = 0;

  /// 【デバッグ用】仮想の新着 EDINET 開示を注入する（kDebugMode限定）
  void injectDebugNewEdinet({
    String? title,
    String? filerName,
  }) {
    if (!kDebugMode) return;
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    final dummyDocId = 'debug_edinet_${now.microsecondsSinceEpoch}_${_debugCounter++}';

    final dummy = Edinet(
      docId: dummyDocId,
      docDescription: title ?? '【Debug新着】テスト書類提出 ($timeStr)',
      filerName: filerName ?? 'デバッグ株式会社',
      docTypeCode: '140', // 四半期報告書
      time: now.millisecondsSinceEpoch,
      viewCount: 0,
    );

    final newItems = [dummy, ...state.latestItems];
    final updated = FeedState.processNewItems<Edinet>(
      previousState: _previousState,
      newItems: newItems,
      idGetter: (e) => e.docId ?? '',
      isLoading: false,
      hasError: false,
      error: null,
    );
    _previousState = updated;
    state = updated;
  }
}

/// EDINET フィルタ合成済み開示一覧 Provider
@riverpod
AsyncValue<List<Edinet>> filteredEdinets(Ref ref) {
  final feed = ref.watch(edinetFeedProvider);
  final docTypeFilter = ref.watch(edinetDocTypeFilterProvider);
  final showOnlyFavs = ref.watch(edinetShowOnlyFavoritesProvider);
  final favorites = ref.watch(favoritesProvider);
  final edinetCompanyMap = ref.watch(companyEdinetMapProvider);

  if (feed.hasError) {
    return AsyncError(feed.error ?? 'Unknown error', StackTrace.current);
  }

  if (feed.isLoading && feed.displayedItems.isEmpty) {
    return const AsyncLoading();
  }

  // お気に入りフィルタがONでお気に入りが0件の場合は空リストを返す
  if (showOnlyFavs && favorites.isEmpty) {
    return const AsyncData([]);
  }

  final favSet = favorites.toSet();

  final filtered = feed.displayedItems.map((edinet) {
    // 企業名・コードの補完
    edinet.fillCompanyName(edinetCompanyMap);
    return edinet;
  }).where((edinet) {
    // 書類種別フィルタ
    if (docTypeFilter.isNotEmpty && edinet.docType != docTypeFilter) {
      return false;
    }
    // お気に入りフィルタ
    if (showOnlyFavs) {
      final hasFav = edinet.companies
          .any((c) => c?.code != null && favSet.contains(c!.code));
      if (!hasFav) return false;
    }
    return true;
  }).toList();

  return AsyncData(filtered);
}
