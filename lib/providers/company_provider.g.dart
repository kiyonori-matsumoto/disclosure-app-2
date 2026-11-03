// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'company_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// CompanyCacheManager を提供する内部 Provider（テスト時に override 可能）

@ProviderFor(companyCacheManager)
final companyCacheManagerProvider = CompanyCacheManagerProvider._();

/// CompanyCacheManager を提供する内部 Provider（テスト時に override 可能）

final class CompanyCacheManagerProvider extends $FunctionalProvider<
        AsyncValue<CompanyCacheManager>,
        CompanyCacheManager,
        FutureOr<CompanyCacheManager>>
    with
        $FutureModifier<CompanyCacheManager>,
        $FutureProvider<CompanyCacheManager> {
  /// CompanyCacheManager を提供する内部 Provider（テスト時に override 可能）
  CompanyCacheManagerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'companyCacheManagerProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$companyCacheManagerHash();

  @$internal
  @override
  $FutureProviderElement<CompanyCacheManager> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<CompanyCacheManager> create(Ref ref) {
    return companyCacheManager(ref);
  }
}

String _$companyCacheManagerHash() =>
    r'07c6f7b9863ccf9ae985d4c7e8ae6358f9a24101';

/// 企業マスタ一覧をリアルタイム購読・キャッシュする Provider

@ProviderFor(companiesStream)
final companiesStreamProvider = CompaniesStreamProvider._();

/// 企業マスタ一覧をリアルタイム購読・キャッシュする Provider

final class CompaniesStreamProvider extends $FunctionalProvider<
        AsyncValue<List<Company>>, List<Company>, Stream<List<Company>>>
    with $FutureModifier<List<Company>>, $StreamProvider<List<Company>> {
  /// 企業マスタ一覧をリアルタイム購読・キャッシュする Provider
  CompaniesStreamProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'companiesStreamProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$companiesStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<Company>> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Company>> create(Ref ref) {
    return companiesStream(ref);
  }
}

String _$companiesStreamHash() => r'be268a25c317f29786eb2603f149a97342c47535';

/// 証券コードをキーとした企業マスタの Map を提供する Provider (O(1) ルックアップ用)

@ProviderFor(companyCodeMap)
final companyCodeMapProvider = CompanyCodeMapProvider._();

/// 証券コードをキーとした企業マスタの Map を提供する Provider (O(1) ルックアップ用)

final class CompanyCodeMapProvider extends $FunctionalProvider<
    Map<String, Company>,
    Map<String, Company>,
    Map<String, Company>> with $Provider<Map<String, Company>> {
  /// 証券コードをキーとした企業マスタの Map を提供する Provider (O(1) ルックアップ用)
  CompanyCodeMapProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'companyCodeMapProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$companyCodeMapHash();

  @$internal
  @override
  $ProviderElement<Map<String, Company>> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Map<String, Company> create(Ref ref) {
    return companyCodeMap(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, Company> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, Company>>(value),
    );
  }
}

String _$companyCodeMapHash() => r'364be8074da9901c72e11dd32ff678775fbc2faa';

/// EDINET コードをキーとした企業マスタの Map を提供する Provider (O(1) ルックアップ用)

@ProviderFor(companyEdinetMap)
final companyEdinetMapProvider = CompanyEdinetMapProvider._();

/// EDINET コードをキーとした企業マスタの Map を提供する Provider (O(1) ルックアップ用)

final class CompanyEdinetMapProvider extends $FunctionalProvider<
    Map<String, Company>,
    Map<String, Company>,
    Map<String, Company>> with $Provider<Map<String, Company>> {
  /// EDINET コードをキーとした企業マスタの Map を提供する Provider (O(1) ルックアップ用)
  CompanyEdinetMapProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'companyEdinetMapProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$companyEdinetMapHash();

  @$internal
  @override
  $ProviderElement<Map<String, Company>> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Map<String, Company> create(Ref ref) {
    return companyEdinetMap(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, Company> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, Company>>(value),
    );
  }
}

String _$companyEdinetMapHash() => r'83613f65454c0d843619086bb470d4b1fa27f2aa';
