// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'disclosures_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 開示一覧の日付管理 Notifier

@ProviderFor(SelectedDate)
final selectedDateProvider = SelectedDateProvider._();

/// 開示一覧の日付管理 Notifier
final class SelectedDateProvider
    extends $NotifierProvider<SelectedDate, DateTime> {
  /// 開示一覧の日付管理 Notifier
  SelectedDateProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'selectedDateProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$selectedDateHash();

  @$internal
  @override
  SelectedDate create() => SelectedDate();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime>(value),
    );
  }
}

String _$selectedDateHash() => r'3982fe7971ba889f3becfd78002706fd37d2d77c';

/// 開示一覧の日付管理 Notifier

abstract class _$SelectedDate extends $Notifier<DateTime> {
  DateTime build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DateTime, DateTime>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<DateTime, DateTime>, DateTime, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}

/// 開示一覧のソート順管理 Notifier（"最新" または "閲覧回数"）

@ProviderFor(DisclosureOrder)
final disclosureOrderProvider = DisclosureOrderProvider._();

/// 開示一覧のソート順管理 Notifier（"最新" または "閲覧回数"）
final class DisclosureOrderProvider
    extends $NotifierProvider<DisclosureOrder, String> {
  /// 開示一覧のソート順管理 Notifier（"最新" または "閲覧回数"）
  DisclosureOrderProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'disclosureOrderProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$disclosureOrderHash();

  @$internal
  @override
  DisclosureOrder create() => DisclosureOrder();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$disclosureOrderHash() => r'f5e9aca1d090538318f733bd6a7d64e55e1772c3';

/// 開示一覧のソート順管理 Notifier（"最新" または "閲覧回数"）

abstract class _$DisclosureOrder extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<String, String>, String, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}

/// お気に入りのみ表示するトグル Notifier

@ProviderFor(ShowOnlyFavorites)
final showOnlyFavoritesProvider = ShowOnlyFavoritesProvider._();

/// お気に入りのみ表示するトグル Notifier
final class ShowOnlyFavoritesProvider
    extends $NotifierProvider<ShowOnlyFavorites, bool> {
  /// お気に入りのみ表示するトグル Notifier
  ShowOnlyFavoritesProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'showOnlyFavoritesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$showOnlyFavoritesHash();

  @$internal
  @override
  ShowOnlyFavorites create() => ShowOnlyFavorites();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$showOnlyFavoritesHash() => r'2ea6640e717c3d21876a05040c530c5901b47d46';

/// お気に入りのみ表示するトグル Notifier

abstract class _$ShowOnlyFavorites extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<bool, bool>, bool, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}

/// 選択中フィルタタグ管理 Notifier

@ProviderFor(SelectedFilters)
final selectedFiltersProvider = SelectedFiltersProvider._();

/// 選択中フィルタタグ管理 Notifier
final class SelectedFiltersProvider
    extends $NotifierProvider<SelectedFilters, Set<String>> {
  /// 選択中フィルタタグ管理 Notifier
  SelectedFiltersProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'selectedFiltersProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$selectedFiltersHash();

  @$internal
  @override
  SelectedFilters create() => SelectedFilters();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$selectedFiltersHash() => r'3a7d6504aa29acc866f8995021611248d3215fde';

/// 選択中フィルタタグ管理 Notifier

abstract class _$SelectedFilters extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<Set<String>, Set<String>>, Set<String>, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}

/// 利用可能な全フィルタタグ（プリセット＋ユーザー登録カスタムタグ）一覧

@ProviderFor(availableFilters)
final availableFiltersProvider = AvailableFiltersProvider._();

/// 利用可能な全フィルタタグ（プリセット＋ユーザー登録カスタムタグ）一覧

final class AvailableFiltersProvider
    extends $FunctionalProvider<List<Filter>, List<Filter>, List<Filter>>
    with $Provider<List<Filter>> {
  /// 利用可能な全フィルタタグ（プリセット＋ユーザー登録カスタムタグ）一覧
  AvailableFiltersProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'availableFiltersProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$availableFiltersHash();

  @$internal
  @override
  $ProviderElement<List<Filter>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Filter> create(Ref ref) {
    return availableFilters(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Filter> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Filter>>(value),
    );
  }
}

String _$availableFiltersHash() => r'd7c5078cf52af0d849e25b1b3975d4dd091bea3b';

/// 選択されているフィルタの件数

@ProviderFor(selectedFilterCount)
final selectedFilterCountProvider = SelectedFilterCountProvider._();

/// 選択されているフィルタの件数

final class SelectedFilterCountProvider
    extends $FunctionalProvider<int, int, int> with $Provider<int> {
  /// 選択されているフィルタの件数
  SelectedFilterCountProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'selectedFilterCountProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$selectedFilterCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return selectedFilterCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$selectedFilterCountHash() =>
    r'b4518345e5b99507b3b4f70cc936d22d8193eed2';

/// Firestore から対象日の開示ドキュメント一覧をリアルタイム購読する StreamProvider

@ProviderFor(disclosuresRawStream)
final disclosuresRawStreamProvider = DisclosuresRawStreamFamily._();

/// Firestore から対象日の開示ドキュメント一覧をリアルタイム購読する StreamProvider

final class DisclosuresRawStreamProvider extends $FunctionalProvider<
        AsyncValue<List<DocumentSnapshot<Map<String, dynamic>>>>,
        List<DocumentSnapshot<Map<String, dynamic>>>,
        Stream<List<DocumentSnapshot<Map<String, dynamic>>>>>
    with
        $FutureModifier<List<DocumentSnapshot<Map<String, dynamic>>>>,
        $StreamProvider<List<DocumentSnapshot<Map<String, dynamic>>>> {
  /// Firestore から対象日の開示ドキュメント一覧をリアルタイム購読する StreamProvider
  DisclosuresRawStreamProvider._(
      {required DisclosuresRawStreamFamily super.from,
      required DateTime super.argument})
      : super(
          retry: null,
          name: r'disclosuresRawStreamProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$disclosuresRawStreamHash();

  @override
  String toString() {
    return r'disclosuresRawStreamProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<DocumentSnapshot<Map<String, dynamic>>>>
      $createElement($ProviderPointer pointer) =>
          $StreamProviderElement(pointer);

  @override
  Stream<List<DocumentSnapshot<Map<String, dynamic>>>> create(Ref ref) {
    final argument = this.argument as DateTime;
    return disclosuresRawStream(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DisclosuresRawStreamProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$disclosuresRawStreamHash() =>
    r'515a1440b5eedae8cf822a689c0b7059a1a50219';

/// Firestore から対象日の開示ドキュメント一覧をリアルタイム購読する StreamProvider

final class DisclosuresRawStreamFamily extends $Family
    with
        $FunctionalFamilyOverride<
            Stream<List<DocumentSnapshot<Map<String, dynamic>>>>, DateTime> {
  DisclosuresRawStreamFamily._()
      : super(
          retry: null,
          name: r'disclosuresRawStreamProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// Firestore から対象日の開示ドキュメント一覧をリアルタイム購読する StreamProvider

  DisclosuresRawStreamProvider call(
    DateTime date,
  ) =>
      DisclosuresRawStreamProvider._(argument: date, from: this);

  @override
  String toString() => r'disclosuresRawStreamProvider';
}

/// ハイブリッド型（最上部なら自動更新、スクロール中なら新着バッジでズレ防止）開示フィード Notifier

@ProviderFor(DisclosuresFeed)
final disclosuresFeedProvider = DisclosuresFeedProvider._();

/// ハイブリッド型（最上部なら自動更新、スクロール中なら新着バッジでズレ防止）開示フィード Notifier
final class DisclosuresFeedProvider
    extends $NotifierProvider<DisclosuresFeed, DisclosuresFeedState> {
  /// ハイブリッド型（最上部なら自動更新、スクロール中なら新着バッジでズレ防止）開示フィード Notifier
  DisclosuresFeedProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'disclosuresFeedProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$disclosuresFeedHash();

  @$internal
  @override
  DisclosuresFeed create() => DisclosuresFeed();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DisclosuresFeedState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DisclosuresFeedState>(value),
    );
  }
}

String _$disclosuresFeedHash() => r'60a0df0b8856eb8cb3a6908e982ab7f223886c5f';

/// ハイブリッド型（最上部なら自動更新、スクロール中なら新着バッジでズレ防止）開示フィード Notifier

abstract class _$DisclosuresFeed extends $Notifier<DisclosuresFeedState> {
  DisclosuresFeedState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DisclosuresFeedState, DisclosuresFeedState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<DisclosuresFeedState, DisclosuresFeedState>,
        DisclosuresFeedState,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}

/// 未反映の新着開示件数を提供する Provider

@ProviderFor(pendingNewDisclosureCount)
final pendingNewDisclosureCountProvider = PendingNewDisclosureCountProvider._();

/// 未反映の新着開示件数を提供する Provider

final class PendingNewDisclosureCountProvider
    extends $FunctionalProvider<int, int, int> with $Provider<int> {
  /// 未反映の新着開示件数を提供する Provider
  PendingNewDisclosureCountProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'pendingNewDisclosureCountProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$pendingNewDisclosureCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return pendingNewDisclosureCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$pendingNewDisclosureCountHash() =>
    r'3f6b4167d55129b6926b6ad79655a01b5dddff48';

/// フィルタおよびソートが適用された最終表示用開示ドキュメント一覧を提供する Provider

@ProviderFor(filteredDisclosures)
final filteredDisclosuresProvider = FilteredDisclosuresProvider._();

/// フィルタおよびソートが適用された最終表示用開示ドキュメント一覧を提供する Provider

final class FilteredDisclosuresProvider extends $FunctionalProvider<
        AsyncValue<List<DocumentSnapshot<Map<String, dynamic>>>>,
        AsyncValue<List<DocumentSnapshot<Map<String, dynamic>>>>,
        AsyncValue<List<DocumentSnapshot<Map<String, dynamic>>>>>
    with $Provider<AsyncValue<List<DocumentSnapshot<Map<String, dynamic>>>>> {
  /// フィルタおよびソートが適用された最終表示用開示ドキュメント一覧を提供する Provider
  FilteredDisclosuresProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'filteredDisclosuresProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$filteredDisclosuresHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<List<DocumentSnapshot<Map<String, dynamic>>>>>
      $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  AsyncValue<List<DocumentSnapshot<Map<String, dynamic>>>> create(Ref ref) {
    return filteredDisclosures(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(
      AsyncValue<List<DocumentSnapshot<Map<String, dynamic>>>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<
          AsyncValue<List<DocumentSnapshot<Map<String, dynamic>>>>>(value),
    );
  }
}

String _$filteredDisclosuresHash() =>
    r'b73c5c169a13f74ee976f98598cada5b7948022b';
