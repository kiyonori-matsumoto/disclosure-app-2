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

/// EDINET 選択日付 Notifier (デフォルト: 当日)
@riverpod
class EdinetSelectedDate extends _$EdinetSelectedDate {
  @override
  DateTime build() => DateTime.now();

  void setDate(DateTime date) {
    state = date;
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

/// EDINET Firestore 生ストリーム Provider (日付別)
@riverpod
Stream<List<Edinet>> edinetsRawStream(Ref ref, DateTime date) {
  final firestore = ref.watch(edinetFirestoreProvider);
  final start = edinetDateFormatter.format(date);
  final end = edinetDateFormatter.format(date.add(const Duration(days: 1)));

  return firestore
      .collection('edinets')
      .where('seq', isGreaterThanOrEqualTo: start)
      .where('seq', isLessThan: end)
      .orderBy('seq', descending: true)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => Edinet.fromDocumentSnapshot(doc)).toList());
}

/// EDINET フィード状態の型エイリアス
typedef EdinetFeedState = FeedState<Edinet>;

/// EDINET ハイブリッド型開示フィード Notifier (最上部なら自動更新、スクロール中は画面ズレ防止＆新着バッジ)
@riverpod
class EdinetFeed extends _$EdinetFeed {
  DateTime? _lastDate;
  EdinetFeedState? _previousState;

  @override
  EdinetFeedState build() {
    final date = ref.watch(edinetSelectedDateProvider);
    final rawAsync = ref.watch(edinetsRawStreamProvider(date));
    final rawDocs = rawAsync.value ?? const [];

    final dateChanged = _lastDate != date;
    _lastDate = date;

    if (dateChanged) {
      _previousState = null;
    }

    final newState = FeedState.processNewItems<Edinet>(
      previousState: _previousState,
      newItems: rawDocs,
      idGetter: (e) => e.docId ?? '',
      isLoading: rawAsync.isLoading,
      hasError: rawAsync.hasError,
      error: rawAsync.error,
    );

    _previousState = newState;
    return newState;
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

  /// 【デバッグ用】仮想の新着 EDINET 開示を注入する（kDebugMode限定）
  void injectDebugNewEdinet({
    String? title,
    String? filerName,
  }) {
    if (!kDebugMode) return;
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    final dummyDocId = 'debug_edinet_${now.millisecondsSinceEpoch}';

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
