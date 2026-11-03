// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'company_disclosures_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 個別企業の決算発表予定を提供する Provider

@ProviderFor(companySettlement)
final companySettlementProvider = CompanySettlementFamily._();

/// 個別企業の決算発表予定を提供する Provider

final class CompanySettlementProvider extends $FunctionalProvider<
        AsyncValue<CompanySettlement?>,
        CompanySettlement?,
        FutureOr<CompanySettlement?>>
    with
        $FutureModifier<CompanySettlement?>,
        $FutureProvider<CompanySettlement?> {
  /// 個別企業の決算発表予定を提供する Provider
  CompanySettlementProvider._(
      {required CompanySettlementFamily super.from,
      required String super.argument})
      : super(
          retry: null,
          name: r'companySettlementProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$companySettlementHash();

  @override
  String toString() {
    return r'companySettlementProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CompanySettlement?> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<CompanySettlement?> create(Ref ref) {
    final argument = this.argument as String;
    return companySettlement(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CompanySettlementProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$companySettlementHash() => r'9e13a85d8a27636e8bcea5068bf0333f4a04a64c';

/// 個別企業の決算発表予定を提供する Provider

final class CompanySettlementFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<CompanySettlement?>, String> {
  CompanySettlementFamily._()
      : super(
          retry: null,
          name: r'companySettlementProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// 個別企業の決算発表予定を提供する Provider

  CompanySettlementProvider call(
    String code,
  ) =>
      CompanySettlementProvider._(argument: code, from: this);

  @override
  String toString() => r'companySettlementProvider';
}

/// 個別企業の開示情報（TDNET）のページネーション取得・リフレッシュを管理する Notifier

@ProviderFor(CompanyDisclosures)
final companyDisclosuresProvider = CompanyDisclosuresFamily._();

/// 個別企業の開示情報（TDNET）のページネーション取得・リフレッシュを管理する Notifier
final class CompanyDisclosuresProvider extends $AsyncNotifierProvider<
    CompanyDisclosures, PaginatedDisclosuresState> {
  /// 個別企業の開示情報（TDNET）のページネーション取得・リフレッシュを管理する Notifier
  CompanyDisclosuresProvider._(
      {required CompanyDisclosuresFamily super.from,
      required String super.argument})
      : super(
          retry: null,
          name: r'companyDisclosuresProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$companyDisclosuresHash();

  @override
  String toString() {
    return r'companyDisclosuresProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CompanyDisclosures create() => CompanyDisclosures();

  @override
  bool operator ==(Object other) {
    return other is CompanyDisclosuresProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$companyDisclosuresHash() =>
    r'd290729a92fa9a8fd2638f5f977c653953fc7fbf';

/// 個別企業の開示情報（TDNET）のページネーション取得・リフレッシュを管理する Notifier

final class CompanyDisclosuresFamily extends $Family
    with
        $ClassFamilyOverride<
            CompanyDisclosures,
            AsyncValue<PaginatedDisclosuresState>,
            PaginatedDisclosuresState,
            FutureOr<PaginatedDisclosuresState>,
            String> {
  CompanyDisclosuresFamily._()
      : super(
          retry: null,
          name: r'companyDisclosuresProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// 個別企業の開示情報（TDNET）のページネーション取得・リフレッシュを管理する Notifier

  CompanyDisclosuresProvider call(
    String code,
  ) =>
      CompanyDisclosuresProvider._(argument: code, from: this);

  @override
  String toString() => r'companyDisclosuresProvider';
}

/// 個別企業の開示情報（TDNET）のページネーション取得・リフレッシュを管理する Notifier

abstract class _$CompanyDisclosures
    extends $AsyncNotifier<PaginatedDisclosuresState> {
  late final _$args = ref.$arg as String;
  String get code => _$args;

  FutureOr<PaginatedDisclosuresState> build(
    String code,
  );
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<PaginatedDisclosuresState>,
        PaginatedDisclosuresState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<PaginatedDisclosuresState>,
            PaginatedDisclosuresState>,
        AsyncValue<PaginatedDisclosuresState>,
        Object?,
        Object?>;
    return element.handleCreate(
        ref,
        () => build(
              _$args,
            ));
  }
}

/// 個別企業の EDINET 開示情報のページネーション取得・リフレッシュを管理する Notifier

@ProviderFor(CompanyEdinets)
final companyEdinetsProvider = CompanyEdinetsFamily._();

/// 個別企業の EDINET 開示情報のページネーション取得・リフレッシュを管理する Notifier
final class CompanyEdinetsProvider
    extends $AsyncNotifierProvider<CompanyEdinets, PaginatedEdinetsState> {
  /// 個別企業の EDINET 開示情報のページネーション取得・リフレッシュを管理する Notifier
  CompanyEdinetsProvider._(
      {required CompanyEdinetsFamily super.from,
      required String super.argument})
      : super(
          retry: null,
          name: r'companyEdinetsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$companyEdinetsHash();

  @override
  String toString() {
    return r'companyEdinetsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CompanyEdinets create() => CompanyEdinets();

  @override
  bool operator ==(Object other) {
    return other is CompanyEdinetsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$companyEdinetsHash() => r'9b7705ae11db547edaafbea74dca6844dc4f65c8';

/// 個別企業の EDINET 開示情報のページネーション取得・リフレッシュを管理する Notifier

final class CompanyEdinetsFamily extends $Family
    with
        $ClassFamilyOverride<CompanyEdinets, AsyncValue<PaginatedEdinetsState>,
            PaginatedEdinetsState, FutureOr<PaginatedEdinetsState>, String> {
  CompanyEdinetsFamily._()
      : super(
          retry: null,
          name: r'companyEdinetsProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// 個別企業の EDINET 開示情報のページネーション取得・リフレッシュを管理する Notifier

  CompanyEdinetsProvider call(
    String edinetCode,
  ) =>
      CompanyEdinetsProvider._(argument: edinetCode, from: this);

  @override
  String toString() => r'companyEdinetsProvider';
}

/// 個別企業の EDINET 開示情報のページネーション取得・リフレッシュを管理する Notifier

abstract class _$CompanyEdinets extends $AsyncNotifier<PaginatedEdinetsState> {
  late final _$args = ref.$arg as String;
  String get edinetCode => _$args;

  FutureOr<PaginatedEdinetsState> build(
    String edinetCode,
  );
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref
        as $Ref<AsyncValue<PaginatedEdinetsState>, PaginatedEdinetsState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<PaginatedEdinetsState>, PaginatedEdinetsState>,
        AsyncValue<PaginatedEdinetsState>,
        Object?,
        Object?>;
    return element.handleCreate(
        ref,
        () => build(
              _$args,
            ));
  }
}
