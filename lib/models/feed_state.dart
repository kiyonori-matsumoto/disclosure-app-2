/// ハイブリッド型（最上部なら自動更新、スクロール中なら新着バッジでズレ防止）フィードの状態
class FeedState<T> {
  /// 画面に現在表示中のリスト
  final List<T> displayedItems;

  /// バックグラウンドで受信した最新の全リスト
  final List<T> latestItems;

  /// スクロール中に蓄積された未反映の新着件数
  final int newCount;

  /// スクロールが最上部（先頭）にあるかどうかのフラグ
  final bool isAtTop;

  /// データ読み込み中フラグ
  final bool isLoading;

  /// エラー発生フラグ
  final bool hasError;

  /// エラーオブジェクト
  final Object? error;

  const FeedState({
    this.displayedItems = const [],
    this.latestItems = const [],
    this.newCount = 0,
    this.isAtTop = true,
    this.isLoading = false,
    this.hasError = false,
    this.error,
  });

  /// 既存の DisclosuresFeedState との後方互換ゲッター
  List<T> get displayedDocs => displayedItems;
  List<T> get latestDocs => latestItems;

  FeedState<T> copyWith({
    List<T>? displayedItems,
    List<T>? latestItems,
    int? newCount,
    bool? isAtTop,
    bool? isLoading,
    bool? hasError,
    Object? error,
    // 互換性のための引数
    List<T>? displayedDocs,
    List<T>? latestDocs,
  }) {
    return FeedState<T>(
      displayedItems: displayedDocs ?? displayedItems ?? this.displayedItems,
      latestItems: latestDocs ?? latestItems ?? this.latestItems,
      newCount: newCount ?? this.newCount,
      isAtTop: isAtTop ?? this.isAtTop,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      error: error ?? this.error,
    );
  }

  /// 新着リストの処理ロジック
  ///
  /// - 最上部にいる場合: 即座に最新リストを画面に反映
  /// - スクロール中の場合: 画面表示は維持し、新着件数（newCount）のみ加算
  static FeedState<T> processNewItems<T>({
    required FeedState<T>? previousState,
    required List<T> newItems,
    required String Function(T item) idGetter,
    required bool isLoading,
    required bool hasError,
    required Object? error,
  }) {
    final prev = previousState;

    if (prev == null || prev.isAtTop) {
      // 初回、日付変更、または最上部にいる場合は即座に最新を画面へ反映
      return FeedState<T>(
        displayedItems: newItems,
        latestItems: newItems,
        newCount: 0,
        isAtTop: prev?.isAtTop ?? true,
        isLoading: isLoading && newItems.isEmpty,
        hasError: hasError,
        error: error,
      );
    } else {
      // スクロール中の場合は読書中のズレを防ぐため、画面表示は維持し新着件数を加算
      final currentDisplayedIds = prev.displayedItems.map(idGetter).toSet();
      final newItemsCount = newItems
          .where((item) => !currentDisplayedIds.contains(idGetter(item)))
          .length;

      return prev.copyWith(
        latestItems: newItems,
        newCount: newItemsCount,
        isLoading: isLoading && prev.displayedItems.isEmpty,
        hasError: hasError,
        error: error,
      );
    }
  }

  /// スクロール位置（最上部かどうか）の変化に応じた状態更新
  FeedState<T> onScrollPositionChanged({required bool isAtTop}) {
    if (this.isAtTop == isAtTop) return this;

    if (isAtTop && newCount > 0) {
      // 最上部に戻った場合は蓄積された新着を自然にリストへ反映
      return copyWith(
        displayedItems: latestItems,
        newCount: 0,
        isAtTop: true,
      );
    } else {
      return copyWith(isAtTop: isAtTop);
    }
  }

  /// 新着 FAB タップ等で最新のリストを明示的に反映する
  FeedState<T> refreshToLatest() {
    return copyWith(
      displayedItems: latestItems,
      newCount: 0,
    );
  }
}
