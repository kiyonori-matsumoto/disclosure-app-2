// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'edinet_disclosures_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// EDINET 用 Firestore インスタンス Provider (テスト時にモックに差し替え可能)

@ProviderFor(edinetFirestore)
final edinetFirestoreProvider = EdinetFirestoreProvider._();

/// EDINET 用 Firestore インスタンス Provider (テスト時にモックに差し替え可能)

final class EdinetFirestoreProvider extends $FunctionalProvider<
    FirebaseFirestore,
    FirebaseFirestore,
    FirebaseFirestore> with $Provider<FirebaseFirestore> {
  /// EDINET 用 Firestore インスタンス Provider (テスト時にモックに差し替え可能)
  EdinetFirestoreProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'edinetFirestoreProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$edinetFirestoreHash();

  @$internal
  @override
  $ProviderElement<FirebaseFirestore> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FirebaseFirestore create(Ref ref) {
    return edinetFirestore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseFirestore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseFirestore>(value),
    );
  }
}

String _$edinetFirestoreHash() => r'856e4d6208933da77f457dbdb9a7f1f63e3483bc';

/// EDINET 選択日付 Notifier (デフォルト: 当日)

@ProviderFor(EdinetSelectedDate)
final edinetSelectedDateProvider = EdinetSelectedDateProvider._();

/// EDINET 選択日付 Notifier (デフォルト: 当日)
final class EdinetSelectedDateProvider
    extends $NotifierProvider<EdinetSelectedDate, DateTime> {
  /// EDINET 選択日付 Notifier (デフォルト: 当日)
  EdinetSelectedDateProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'edinetSelectedDateProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$edinetSelectedDateHash();

  @$internal
  @override
  EdinetSelectedDate create() => EdinetSelectedDate();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime>(value),
    );
  }
}

String _$edinetSelectedDateHash() =>
    r'81c01115d0fcf4a938fa2b3f6e59d018cf55a680';

/// EDINET 選択日付 Notifier (デフォルト: 当日)

abstract class _$EdinetSelectedDate extends $Notifier<DateTime> {
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

/// EDINET 書類種別フィルタ Notifier (デフォルト: '' = 全件)

@ProviderFor(EdinetDocTypeFilter)
final edinetDocTypeFilterProvider = EdinetDocTypeFilterProvider._();

/// EDINET 書類種別フィルタ Notifier (デフォルト: '' = 全件)
final class EdinetDocTypeFilterProvider
    extends $NotifierProvider<EdinetDocTypeFilter, String> {
  /// EDINET 書類種別フィルタ Notifier (デフォルト: '' = 全件)
  EdinetDocTypeFilterProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'edinetDocTypeFilterProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$edinetDocTypeFilterHash();

  @$internal
  @override
  EdinetDocTypeFilter create() => EdinetDocTypeFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$edinetDocTypeFilterHash() =>
    r'8bebfe2be18ec8eb09887abe4c9d58f9e3ccad03';

/// EDINET 書類種別フィルタ Notifier (デフォルト: '' = 全件)

abstract class _$EdinetDocTypeFilter extends $Notifier<String> {
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

/// EDINET お気に入りのみ表示 Notifier (デフォルト: false)

@ProviderFor(EdinetShowOnlyFavorites)
final edinetShowOnlyFavoritesProvider = EdinetShowOnlyFavoritesProvider._();

/// EDINET お気に入りのみ表示 Notifier (デフォルト: false)
final class EdinetShowOnlyFavoritesProvider
    extends $NotifierProvider<EdinetShowOnlyFavorites, bool> {
  /// EDINET お気に入りのみ表示 Notifier (デフォルト: false)
  EdinetShowOnlyFavoritesProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'edinetShowOnlyFavoritesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$edinetShowOnlyFavoritesHash();

  @$internal
  @override
  EdinetShowOnlyFavorites create() => EdinetShowOnlyFavorites();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$edinetShowOnlyFavoritesHash() =>
    r'b9c4ba0f50b830bf6ed1c488414fa1e241e0ad03';

/// EDINET お気に入りのみ表示 Notifier (デフォルト: false)

abstract class _$EdinetShowOnlyFavorites extends $Notifier<bool> {
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

/// EDINET Firestore 生ストリーム Provider (日付別)

@ProviderFor(edinetsRawStream)
final edinetsRawStreamProvider = EdinetsRawStreamFamily._();

/// EDINET Firestore 生ストリーム Provider (日付別)

final class EdinetsRawStreamProvider extends $FunctionalProvider<
        AsyncValue<List<Edinet>>, List<Edinet>, Stream<List<Edinet>>>
    with $FutureModifier<List<Edinet>>, $StreamProvider<List<Edinet>> {
  /// EDINET Firestore 生ストリーム Provider (日付別)
  EdinetsRawStreamProvider._(
      {required EdinetsRawStreamFamily super.from,
      required DateTime super.argument})
      : super(
          retry: null,
          name: r'edinetsRawStreamProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$edinetsRawStreamHash();

  @override
  String toString() {
    return r'edinetsRawStreamProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Edinet>> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Edinet>> create(Ref ref) {
    final argument = this.argument as DateTime;
    return edinetsRawStream(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is EdinetsRawStreamProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$edinetsRawStreamHash() => r'671eb788fee1ca169e2e7343da6082c5846c7377';

/// EDINET Firestore 生ストリーム Provider (日付別)

final class EdinetsRawStreamFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Edinet>>, DateTime> {
  EdinetsRawStreamFamily._()
      : super(
          retry: null,
          name: r'edinetsRawStreamProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// EDINET Firestore 生ストリーム Provider (日付別)

  EdinetsRawStreamProvider call(
    DateTime date,
  ) =>
      EdinetsRawStreamProvider._(argument: date, from: this);

  @override
  String toString() => r'edinetsRawStreamProvider';
}

/// EDINET ハイブリッド型開示フィード Notifier (最上部なら自動更新、スクロール中は画面ズレ防止＆新着バッジ)

@ProviderFor(EdinetFeed)
final edinetFeedProvider = EdinetFeedProvider._();

/// EDINET ハイブリッド型開示フィード Notifier (最上部なら自動更新、スクロール中は画面ズレ防止＆新着バッジ)
final class EdinetFeedProvider
    extends $NotifierProvider<EdinetFeed, EdinetFeedState> {
  /// EDINET ハイブリッド型開示フィード Notifier (最上部なら自動更新、スクロール中は画面ズレ防止＆新着バッジ)
  EdinetFeedProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'edinetFeedProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$edinetFeedHash();

  @$internal
  @override
  EdinetFeed create() => EdinetFeed();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EdinetFeedState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EdinetFeedState>(value),
    );
  }
}

String _$edinetFeedHash() => r'd36b7066fe78bbff71d92d4370c98bb73ace50ba';

/// EDINET ハイブリッド型開示フィード Notifier (最上部なら自動更新、スクロール中は画面ズレ防止＆新着バッジ)

abstract class _$EdinetFeed extends $Notifier<EdinetFeedState> {
  EdinetFeedState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<EdinetFeedState, EdinetFeedState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<EdinetFeedState, EdinetFeedState>,
        EdinetFeedState,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}

/// EDINET フィルタ合成済み開示一覧 Provider

@ProviderFor(filteredEdinets)
final filteredEdinetsProvider = FilteredEdinetsProvider._();

/// EDINET フィルタ合成済み開示一覧 Provider

final class FilteredEdinetsProvider extends $FunctionalProvider<
    AsyncValue<List<Edinet>>,
    AsyncValue<List<Edinet>>,
    AsyncValue<List<Edinet>>> with $Provider<AsyncValue<List<Edinet>>> {
  /// EDINET フィルタ合成済み開示一覧 Provider
  FilteredEdinetsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'filteredEdinetsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$filteredEdinetsHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<List<Edinet>>> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AsyncValue<List<Edinet>> create(Ref ref) {
    return filteredEdinets(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<Edinet>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<Edinet>>>(value),
    );
  }
}

String _$filteredEdinetsHash() => r'77a0d5d8c8deac8d86c013d9c133d95d911c1311';
