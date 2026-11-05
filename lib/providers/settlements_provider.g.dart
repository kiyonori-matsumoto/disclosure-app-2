// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settlements_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 決算予定一覧の日付選択 Notifier

@ProviderFor(SettlementsSelectedDate)
final settlementsSelectedDateProvider = SettlementsSelectedDateProvider._();

/// 決算予定一覧の日付選択 Notifier
final class SettlementsSelectedDateProvider
    extends $NotifierProvider<SettlementsSelectedDate, DateTime> {
  /// 決算予定一覧の日付選択 Notifier
  SettlementsSelectedDateProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'settlementsSelectedDateProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$settlementsSelectedDateHash();

  @$internal
  @override
  SettlementsSelectedDate create() => SettlementsSelectedDate();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime>(value),
    );
  }
}

String _$settlementsSelectedDateHash() =>
    r'662964de8a22066980a1a8f676c4c7811dfd9415';

/// 決算予定一覧の日付選択 Notifier

abstract class _$SettlementsSelectedDate extends $Notifier<DateTime> {
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

/// 特定の日付の決算予定一覧を取得する Family FutureProvider

@ProviderFor(settlementsByDate)
final settlementsByDateProvider = SettlementsByDateFamily._();

/// 特定の日付の決算予定一覧を取得する Family FutureProvider

final class SettlementsByDateProvider extends $FunctionalProvider<
        AsyncValue<List<CompanySettlement>>,
        List<CompanySettlement>,
        FutureOr<List<CompanySettlement>>>
    with
        $FutureModifier<List<CompanySettlement>>,
        $FutureProvider<List<CompanySettlement>> {
  /// 特定の日付の決算予定一覧を取得する Family FutureProvider
  SettlementsByDateProvider._(
      {required SettlementsByDateFamily super.from,
      required DateTime super.argument})
      : super(
          retry: null,
          name: r'settlementsByDateProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$settlementsByDateHash();

  @override
  String toString() {
    return r'settlementsByDateProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<CompanySettlement>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<CompanySettlement>> create(Ref ref) {
    final argument = this.argument as DateTime;
    return settlementsByDate(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SettlementsByDateProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$settlementsByDateHash() => r'2cfa33b256df5e33a1734003a46374c8706ba368';

/// 特定の日付の決算予定一覧を取得する Family FutureProvider

final class SettlementsByDateFamily extends $Family
    with
        $FunctionalFamilyOverride<FutureOr<List<CompanySettlement>>, DateTime> {
  SettlementsByDateFamily._()
      : super(
          retry: null,
          name: r'settlementsByDateProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// 特定の日付の決算予定一覧を取得する Family FutureProvider

  SettlementsByDateProvider call(
    DateTime date,
  ) =>
      SettlementsByDateProvider._(argument: date, from: this);

  @override
  String toString() => r'settlementsByDateProvider';
}

/// 現在選択されている日付の決算予定一覧を提供する Provider

@ProviderFor(currentSettlementsList)
final currentSettlementsListProvider = CurrentSettlementsListProvider._();

/// 現在選択されている日付の決算予定一覧を提供する Provider

final class CurrentSettlementsListProvider extends $FunctionalProvider<
        AsyncValue<List<CompanySettlement>>,
        List<CompanySettlement>,
        FutureOr<List<CompanySettlement>>>
    with
        $FutureModifier<List<CompanySettlement>>,
        $FutureProvider<List<CompanySettlement>> {
  /// 現在選択されている日付の決算予定一覧を提供する Provider
  CurrentSettlementsListProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'currentSettlementsListProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$currentSettlementsListHash();

  @$internal
  @override
  $FutureProviderElement<List<CompanySettlement>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<CompanySettlement>> create(Ref ref) {
    return currentSettlementsList(ref);
  }
}

String _$currentSettlementsListHash() =>
    r'28ae0e1a15ed0164cf2df2916dccf5c862289e83';
