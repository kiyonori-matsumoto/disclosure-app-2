// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorites_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// お気に入り一覧の並び順を管理・永続化する Notifier

@ProviderFor(FavoriteSortOrderNotifier)
final favoriteSortOrderProvider = FavoriteSortOrderNotifierProvider._();

/// お気に入り一覧の並び順を管理・永続化する Notifier
final class FavoriteSortOrderNotifierProvider
    extends $NotifierProvider<FavoriteSortOrderNotifier, FavoriteSortOrder> {
  /// お気に入り一覧の並び順を管理・永続化する Notifier
  FavoriteSortOrderNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'favoriteSortOrderProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$favoriteSortOrderNotifierHash();

  @$internal
  @override
  FavoriteSortOrderNotifier create() => FavoriteSortOrderNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FavoriteSortOrder value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FavoriteSortOrder>(value),
    );
  }
}

String _$favoriteSortOrderNotifierHash() =>
    r'caebbfc090eb5f79aeb00ce2bc83548a7ff13128';

/// お気に入り一覧の並び順を管理・永続化する Notifier

abstract class _$FavoriteSortOrderNotifier
    extends $Notifier<FavoriteSortOrder> {
  FavoriteSortOrder build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<FavoriteSortOrder, FavoriteSortOrder>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<FavoriteSortOrder, FavoriteSortOrder>,
        FavoriteSortOrder,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}

/// ログインユーザーのお気に入り企業コード一覧を提供する Provider

@ProviderFor(favorites)
final favoritesProvider = FavoritesProvider._();

/// ログインユーザーのお気に入り企業コード一覧を提供する Provider

final class FavoritesProvider
    extends $FunctionalProvider<List<String>, List<String>, List<String>>
    with $Provider<List<String>> {
  /// ログインユーザーのお気に入り企業コード一覧を提供する Provider
  FavoritesProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'favoritesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$favoritesHash();

  @$internal
  @override
  $ProviderElement<List<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<String> create(Ref ref) {
    return favorites(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$favoritesHash() => r'e0f75bffcdad9499b0038dcfa143fd3768bcb856';

/// 企業情報付きのお気に入り企業リストを提供する Provider

@ProviderFor(favoritesWithCompany)
final favoritesWithCompanyProvider = FavoritesWithCompanyProvider._();

/// 企業情報付きのお気に入り企業リストを提供する Provider

final class FavoritesWithCompanyProvider
    extends $FunctionalProvider<List<Company>, List<Company>, List<Company>>
    with $Provider<List<Company>> {
  /// 企業情報付きのお気に入り企業リストを提供する Provider
  FavoritesWithCompanyProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'favoritesWithCompanyProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$favoritesWithCompanyHash();

  @$internal
  @override
  $ProviderElement<List<Company>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Company> create(Ref ref) {
    return favoritesWithCompany(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Company> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Company>>(value),
    );
  }
}

String _$favoritesWithCompanyHash() =>
    r'7c2f53063c59a49680235dcfd2ed8dcb4a9937e3';

/// 指定した企業コードがお気に入りに登録されているかを判定する Provider

@ProviderFor(isFavorite)
final isFavoriteProvider = IsFavoriteFamily._();

/// 指定した企業コードがお気に入りに登録されているかを判定する Provider

final class IsFavoriteProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// 指定した企業コードがお気に入りに登録されているかを判定する Provider
  IsFavoriteProvider._(
      {required IsFavoriteFamily super.from, required String super.argument})
      : super(
          retry: null,
          name: r'isFavoriteProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$isFavoriteHash();

  @override
  String toString() {
    return r'isFavoriteProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    final argument = this.argument as String;
    return isFavorite(
      ref,
      argument,
    );
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is IsFavoriteProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$isFavoriteHash() => r'8134cdba0569a02004808d73ffcd703791e91564';

/// 指定した企業コードがお気に入りに登録されているかを判定する Provider

final class IsFavoriteFamily extends $Family
    with $FunctionalFamilyOverride<bool, String> {
  IsFavoriteFamily._()
      : super(
          retry: null,
          name: r'isFavoriteProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// 指定した企業コードがお気に入りに登録されているかを判定する Provider

  IsFavoriteProvider call(
    String code,
  ) =>
      IsFavoriteProvider._(argument: code, from: this);

  @override
  String toString() => r'isFavoriteProvider';
}

/// お気に入りの追加・削除・トグル操作を担当するアクションクラス

@ProviderFor(FavoritesAction)
final favoritesActionProvider = FavoritesActionProvider._();

/// お気に入りの追加・削除・トグル操作を担当するアクションクラス
final class FavoritesActionProvider
    extends $NotifierProvider<FavoritesAction, void> {
  /// お気に入りの追加・削除・トグル操作を担当するアクションクラス
  FavoritesActionProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'favoritesActionProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$favoritesActionHash();

  @$internal
  @override
  FavoritesAction create() => FavoritesAction();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$favoritesActionHash() => r'59f5fb09259a2946ecebd7805e2a027afad27d60';

/// お気に入りの追加・削除・トグル操作を担当するアクションクラス

abstract class _$FavoritesAction extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<void, void>, void, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}
