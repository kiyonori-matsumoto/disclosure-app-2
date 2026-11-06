import 'package:cloud_firestore/cloud_firestore.dart' hide Filter;
import 'package:disclosure_app_fl/models/feed_state.dart';
import 'package:disclosure_app_fl/models/filter.dart';
import 'package:disclosure_app_fl/providers/custom_tags_provider.dart';
import 'package:disclosure_app_fl/providers/favorites_provider.dart';
import 'package:disclosure_app_fl/providers/user_settings_provider.dart';
import 'package:disclosure_app_fl/utils/disclosure_filter_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'disclosures_provider.g.dart';

/// 開示一覧の日付管理 Notifier
@riverpod
class SelectedDate extends _$SelectedDate {
  @override
  DateTime build() => DateTime.now();

  void setDate(DateTime date) => state = date;
}

/// 開示一覧のソート順管理 Notifier（"最新" または "閲覧回数"）
@riverpod
class DisclosureOrder extends _$DisclosureOrder {
  @override
  String build() => '最新';

  void toggle() {
    state = state == '最新' ? '閲覧回数' : '最新';
  }

  void setOrder(String order) {
    state = order;
  }
}

/// お気に入りのみ表示するトグル Notifier
@riverpod
class ShowOnlyFavorites extends _$ShowOnlyFavorites {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void set(bool value) => state = value;
}

/// 選択中フィルタタグ管理 Notifier
@riverpod
class SelectedFilters extends _$SelectedFilters {
  @override
  Set<String> build() => <String>{};

  void toggle(String tag) {
    final next = Set<String>.from(state);
    if (next.contains(tag)) {
      next.remove(tag);
    } else {
      next.add(tag);
    }
    state = next;
  }

  void clear() => state = <String>{};
}

/// 利用可能な全フィルタタグ（プリセット＋ユーザー登録カスタムタグ）一覧
@riverpod
List<Filter> availableFilters(Ref ref) {
  final selected = ref.watch(selectedFiltersProvider);
  final customTags = ref.watch(customTagsProvider);
  final allTags = [
    ...DisclosureFilterHelper.defaultFilterStrings,
    ...customTags.where(
      (t) => !DisclosureFilterHelper.defaultFilterStrings.contains(t),
    ),
  ];
  return allTags
      .map((t) => Filter(t, isSelected: selected.contains(t)))
      .toList();
}

/// 選択されているフィルタの件数
@riverpod
int selectedFilterCount(Ref ref) {
  return ref.watch(selectedFiltersProvider).length;
}

/// Firestore から対象日の開示ドキュメント一覧をリアルタイム購読する StreamProvider
@riverpod
Stream<List<DocumentSnapshot<Map<String, dynamic>>>> disclosuresRawStream(
  Ref ref,
  DateTime date,
) {
  final day = DateTime(date.year, date.month, date.day);
  final start = day.millisecondsSinceEpoch;
  final end = day.add(const Duration(days: 1)).millisecondsSinceEpoch;

  return FirebaseFirestore.instance
      .collection('disclosures')
      .where('time', isGreaterThanOrEqualTo: start)
      .where('time', isLessThan: end)
      .orderBy('time', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs);
}

/// 開示フィードの状態モデル（共通 FeedState のエイリアス）
typedef DisclosuresFeedState = FeedState<DocumentSnapshot<Map<String, dynamic>>>;

/// ハイブリッド型（最上部なら自動更新、スクロール中なら新着バッジでズレ防止）開示フィード Notifier
@riverpod
class DisclosuresFeed extends _$DisclosuresFeed {
  DateTime? _lastDate;
  DisclosuresFeedState? _previousState;

  @override
  DisclosuresFeedState build() {
    final date = ref.watch(selectedDateProvider);
    final rawAsync = ref.watch(disclosuresRawStreamProvider(date));
    final rawDocs = rawAsync.value ?? const [];

    final dateChanged = _lastDate != date;
    _lastDate = date;

    if (dateChanged) {
      _previousState = null;
    }

    final newState = FeedState.processNewItems<DocumentSnapshot<Map<String, dynamic>>>(
      previousState: _previousState,
      newItems: rawDocs,
      idGetter: (d) => d.id,
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

  /// 【デバッグ用】仮想の新着開示ドキュメントを1件注入する（kDebugMode限定）
  void injectDebugNewDisclosure({
    String? title,
    String? company,
    String? code,
  }) {
    if (!kDebugMode) return;
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    final dummyId = 'debug_${now.millisecondsSinceEpoch}';
    final dummyDoc = DebugDummyDocumentSnapshot(dummyId, {
      'title': title ?? '【新着テスト】業績予想の修正に関するお知らせ ($timeStr)',
      'company': company ?? 'テスト株式会社',
      'code': code ?? '9999',
      'time': now.millisecondsSinceEpoch,
      'view_count': 1,
      'tags': {'決算': true, '業績予想': true},
    });

    final currentDocs = state.latestDocs;
    final newState = FeedState.processNewItems<DocumentSnapshot<Map<String, dynamic>>>(
      previousState: _previousState,
      newItems: [dummyDoc, ...currentDocs],
      idGetter: (d) => d.id,
      isLoading: state.isLoading,
      hasError: state.hasError,
      error: state.error,
    );
    _previousState = newState;
    state = newState;
  }
}

/// 未反映の新着開示件数を提供する Provider
@riverpod
int pendingNewDisclosureCount(Ref ref) {
  return ref.watch(disclosuresFeedProvider).newCount;
}

/// フィルタおよびソートが適用された最終表示用開示ドキュメント一覧を提供する Provider
@riverpod
AsyncValue<List<DocumentSnapshot<Map<String, dynamic>>>> filteredDisclosures(
  Ref ref,
) {
  final feed = ref.watch(disclosuresFeedProvider);
  if (feed.hasError) {
    return AsyncError(
      feed.error ?? Exception('Unknown error'),
      StackTrace.current,
    );
  }
  if (feed.isLoading && feed.displayedDocs.isEmpty) {
    return const AsyncLoading();
  }

  final hideDaily = ref.watch(hideDailyDisclosureProvider);
  final showOnlyFavs = ref.watch(showOnlyFavoritesProvider);
  final favorites =
      showOnlyFavs ? ref.watch(favoritesProvider) : const <String>[];
  final selectedFilters = ref.watch(selectedFiltersProvider);
  final order = ref.watch(disclosureOrderProvider);

  // お気に入りのみ表示がONなのに、お気に入りが0件の場合は開示なし（0件）
  if (showOnlyFavs && favorites.isEmpty) {
    return const AsyncData([]);
  }

  final favoritesSet = favorites.toSet(); // ⚡ Bolt: Pre-compute Set outside the loop for O(1) membership checks

  final filtered = feed.displayedDocs.where((doc) {
    final data = doc.data() ?? {};
    return DisclosureFilterHelper.matchesFilter(
      data: data,
      selectedFilterTitles: selectedFilters,
      hideDailyDisclosure: hideDaily,
      favoriteCompanyCodes: favoritesSet,
    );
  }).toList();

  if (order == '閲覧回数') {
    filtered.sort(
      (a, b) => DisclosureFilterHelper.compareByViewCount(a.data(), b.data()),
    );
  }

  return AsyncData(filtered);
}

// ignore: subtype_of_sealed_class
class DebugDummyDocumentSnapshot
    implements DocumentSnapshot<Map<String, dynamic>> {
  final String _id;
  final Map<String, dynamic> _data;

  DebugDummyDocumentSnapshot(this._id, this._data);

  @override
  String get id => _id;

  @override
  Map<String, dynamic> data() => _data;

  @override
  dynamic operator [](Object? key) => _data[key];

  @override
  bool get exists => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
