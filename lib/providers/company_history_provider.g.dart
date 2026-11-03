// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'company_history_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// ログインユーザーの検索履歴（証券コード一覧）を提供する Provider

@ProviderFor(companyHistoryCodes)
final companyHistoryCodesProvider = CompanyHistoryCodesProvider._();

/// ログインユーザーの検索履歴（証券コード一覧）を提供する Provider

final class CompanyHistoryCodesProvider
    extends $FunctionalProvider<List<String>, List<String>, List<String>>
    with $Provider<List<String>> {
  /// ログインユーザーの検索履歴（証券コード一覧）を提供する Provider
  CompanyHistoryCodesProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'companyHistoryCodesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$companyHistoryCodesHash();

  @$internal
  @override
  $ProviderElement<List<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<String> create(Ref ref) {
    return companyHistoryCodes(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$companyHistoryCodesHash() =>
    r'a8540a20db1f58c8694d7dea85efa83934957f8b';

/// 企業情報付きの検索履歴リストを提供する Provider

@ProviderFor(companyHistory)
final companyHistoryProvider = CompanyHistoryProvider._();

/// 企業情報付きの検索履歴リストを提供する Provider

final class CompanyHistoryProvider
    extends $FunctionalProvider<List<Company>, List<Company>, List<Company>>
    with $Provider<List<Company>> {
  /// 企業情報付きの検索履歴リストを提供する Provider
  CompanyHistoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'companyHistoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$companyHistoryHash();

  @$internal
  @override
  $ProviderElement<List<Company>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Company> create(Ref ref) {
    return companyHistory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Company> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Company>>(value),
    );
  }
}

String _$companyHistoryHash() => r'4e248b095755227013884e8f649818b78789e40a';

/// 検索履歴の追加操作を担当するアクションクラス

@ProviderFor(CompanyHistoryAction)
final companyHistoryActionProvider = CompanyHistoryActionProvider._();

/// 検索履歴の追加操作を担当するアクションクラス
final class CompanyHistoryActionProvider
    extends $NotifierProvider<CompanyHistoryAction, void> {
  /// 検索履歴の追加操作を担当するアクションクラス
  CompanyHistoryActionProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'companyHistoryActionProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$companyHistoryActionHash();

  @$internal
  @override
  CompanyHistoryAction create() => CompanyHistoryAction();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$companyHistoryActionHash() =>
    r'2cf7728255ca1e23da688ddcb906cc6c6d057e3d';

/// 検索履歴の追加操作を担当するアクションクラス

abstract class _$CompanyHistoryAction extends $Notifier<void> {
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
