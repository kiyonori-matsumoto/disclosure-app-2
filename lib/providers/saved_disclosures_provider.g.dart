// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_disclosures_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// ログインユーザーの保存済み開示情報ドキュメント一覧をリアルタイム購読する Provider

@ProviderFor(savedDisclosuresStream)
final savedDisclosuresStreamProvider = SavedDisclosuresStreamProvider._();

/// ログインユーザーの保存済み開示情報ドキュメント一覧をリアルタイム購読する Provider

final class SavedDisclosuresStreamProvider extends $FunctionalProvider<
        AsyncValue<List<QueryDocumentSnapshot<Map<String, dynamic>>>>,
        List<QueryDocumentSnapshot<Map<String, dynamic>>>,
        Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>>
    with
        $FutureModifier<List<QueryDocumentSnapshot<Map<String, dynamic>>>>,
        $StreamProvider<List<QueryDocumentSnapshot<Map<String, dynamic>>>> {
  /// ログインユーザーの保存済み開示情報ドキュメント一覧をリアルタイム購読する Provider
  SavedDisclosuresStreamProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'savedDisclosuresStreamProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$savedDisclosuresStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      $createElement($ProviderPointer pointer) =>
          $StreamProviderElement(pointer);

  @override
  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> create(Ref ref) {
    return savedDisclosuresStream(ref);
  }
}

String _$savedDisclosuresStreamHash() =>
    r'af7eefc552b16ee37e5e1a1e2a0ba65f229e2fc7';

/// 保存済み開示情報を追加日（日付文字列）ごとにグループ化した Provider

@ProviderFor(groupedSavedDisclosures)
final groupedSavedDisclosuresProvider = GroupedSavedDisclosuresProvider._();

/// 保存済み開示情報を追加日（日付文字列）ごとにグループ化した Provider

final class GroupedSavedDisclosuresProvider extends $FunctionalProvider<
        Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>,
        Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>,
        Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>>
    with
        $Provider<
            Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>> {
  /// 保存済み開示情報を追加日（日付文字列）ごとにグループ化した Provider
  GroupedSavedDisclosuresProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'groupedSavedDisclosuresProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$groupedSavedDisclosuresHash();

  @$internal
  @override
  $ProviderElement<
          Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>>
      $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> create(
      Ref ref) {
    return groupedSavedDisclosures(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(
      Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<
              Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>>(
          value),
    );
  }
}

String _$groupedSavedDisclosuresHash() =>
    r'094c9d7cd960a2762e54e4d1f51222b4d2089df4';

/// 保存済み開示情報の操作（保存・削除・復元）を担当するクラス

@ProviderFor(SavedDisclosuresAction)
final savedDisclosuresActionProvider = SavedDisclosuresActionProvider._();

/// 保存済み開示情報の操作（保存・削除・復元）を担当するクラス
final class SavedDisclosuresActionProvider
    extends $NotifierProvider<SavedDisclosuresAction, void> {
  /// 保存済み開示情報の操作（保存・削除・復元）を担当するクラス
  SavedDisclosuresActionProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'savedDisclosuresActionProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$savedDisclosuresActionHash();

  @$internal
  @override
  SavedDisclosuresAction create() => SavedDisclosuresAction();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$savedDisclosuresActionHash() =>
    r'4079facb228b4cf70783ccb534e9fb20bb49304a';

/// 保存済み開示情報の操作（保存・削除・復元）を担当するクラス

abstract class _$SavedDisclosuresAction extends $Notifier<void> {
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
