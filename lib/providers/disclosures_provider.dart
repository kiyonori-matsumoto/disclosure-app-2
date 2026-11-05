import 'package:cloud_firestore/cloud_firestore.dart' hide Filter;
import 'package:disclosure_app_fl/models/filter.dart';
import 'package:disclosure_app_fl/providers/custom_tags_provider.dart';
import 'package:disclosure_app_fl/providers/favorites_provider.dart';
import 'package:disclosure_app_fl/providers/user_settings_provider.dart';
import 'package:disclosure_app_fl/utils/disclosure_filter_helper.dart';
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

/// 開示フィードの状態モデル
class DisclosuresFeedState {
  /// 現在画面に表示中のドキュメント一覧
  final List<DocumentSnapshot<Map<String, dynamic>>> displayedDocs;

  /// Firestore から受信した最新のドキュメント一覧
  final List<DocumentSnapshot<Map<String, dynamic>>> latestDocs;

  /// スクロール中に蓄積された未反映の新着開示件数
  final int newCount;

  /// ユーザーがリスト最上部（またはその近傍）にいるかどうか
  final bool isAtTop;

  /// データ読み込み中フラグ
  final bool isLoading;

  /// エラー発生フラグ
  final bool hasError;

  /// エラーオブジェクト
  final Object? error;

  const DisclosuresFeedState({
    this.displayedDocs = const [],
    this.latestDocs = const [],
    this.newCount = 0,
    this.isAtTop = true,
    this.isLoading = false,
    this.hasError = false,
    this.error,
  });

  DisclosuresFeedState copyWith({
    List<DocumentSnapshot<Map<String, dynamic>>>? displayedDocs,
    List<DocumentSnapshot<Map<String, dynamic>>>? latestDocs,
    int? newCount,
    bool? isAtTop,
    bool? isLoading,
    bool? hasError,
    Object? error,
  }) {
    return DisclosuresFeedState(
      displayedDocs: displayedDocs ?? this.displayedDocs,
      latestDocs: latestDocs ?? this.latestDocs,
      newCount: newCount ?? this.newCount,
      isAtTop: isAtTop ?? this.isAtTop,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      error: error ?? this.error,
    );
  }
}

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

    final prev = _previousState;
    final dateChanged = _lastDate != date;
    _lastDate = date;

    DisclosuresFeedState newState;

    if (prev == null || dateChanged || prev.isAtTop) {
      // 初回、日付変更、または最上部にいる場合は即座に最新を画面へ反映
      newState = DisclosuresFeedState(
        displayedDocs: rawDocs,
        latestDocs: rawDocs,
        newCount: 0,
        isAtTop: prev?.isAtTop ?? true,
        isLoading: rawAsync.isLoading && rawDocs.isEmpty,
        hasError: rawAsync.hasError,
        error: rawAsync.error,
      );
    } else {
      // スクロール中の場合は読書中のズレを防ぐため、画面表示は維持し新着件数を加算
      final currentDisplayedIds = prev.displayedDocs.map((d) => d.id).toSet();
      final newItemsCount =
          rawDocs.where((d) => !currentDisplayedIds.contains(d.id)).length;

      newState = prev.copyWith(
        latestDocs: rawDocs,
        newCount: newItemsCount,
        isLoading: rawAsync.isLoading && prev.displayedDocs.isEmpty,
        hasError: rawAsync.hasError,
        error: rawAsync.error,
      );
    }

    _previousState = newState;
    return newState;
  }

  /// スクロール位置（最上部かどうか）の更新
  void updateScrollPosition({required bool isAtTop}) {
    if (state.isAtTop == isAtTop) return;

    if (isAtTop && state.newCount > 0) {
      // 最上部に戻った場合は、蓄積された新着を自然にリストへ反映
      final updated = state.copyWith(
        displayedDocs: state.latestDocs,
        newCount: 0,
        isAtTop: true,
      );
      _previousState = updated;
      state = updated;
    } else {
      final updated = state.copyWith(isAtTop: isAtTop);
      _previousState = updated;
      state = updated;
    }
  }

  /// 新着 FAB タップ等で最新の開示を明示的に反映する
  void refreshToLatest() {
    final updated = state.copyWith(
      displayedDocs: state.latestDocs,
      newCount: 0,
    );
    _previousState = updated;
    state = updated;
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

  final filtered = feed.displayedDocs.where((doc) {
    final data = doc.data() ?? {};
    return DisclosureFilterHelper.matchesFilter(
      data: data,
      selectedFilterTitles: selectedFilters,
      hideDailyDisclosure: hideDaily,
      favoriteCompanyCodes: favorites,
    );
  }).toList();

  if (order == '閲覧回数') {
    filtered.sort(
      (a, b) => DisclosureFilterHelper.compareByViewCount(a.data(), b.data()),
    );
  }

  return AsyncData(filtered);
}
