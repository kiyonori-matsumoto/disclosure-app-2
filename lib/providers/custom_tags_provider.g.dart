// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_tags_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// ログインユーザーのカスタムタグ一覧（List<String>）を提供する Provider

@ProviderFor(customTags)
final customTagsProvider = CustomTagsProvider._();

/// ログインユーザーのカスタムタグ一覧（List<String>）を提供する Provider

final class CustomTagsProvider
    extends $FunctionalProvider<List<String>, List<String>, List<String>>
    with $Provider<List<String>> {
  /// ログインユーザーのカスタムタグ一覧（List<String>）を提供する Provider
  CustomTagsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'customTagsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$customTagsHash();

  @$internal
  @override
  $ProviderElement<List<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<String> create(Ref ref) {
    return customTags(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$customTagsHash() => r'00f256f03f8026e07e4891b0d9d00016b7dfc765';

/// カスタムタグの追加・削除操作を担当するアクションクラス

@ProviderFor(CustomTagsAction)
final customTagsActionProvider = CustomTagsActionProvider._();

/// カスタムタグの追加・削除操作を担当するアクションクラス
final class CustomTagsActionProvider
    extends $NotifierProvider<CustomTagsAction, void> {
  /// カスタムタグの追加・削除操作を担当するアクションクラス
  CustomTagsActionProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'customTagsActionProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$customTagsActionHash();

  @$internal
  @override
  CustomTagsAction create() => CustomTagsAction();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$customTagsActionHash() => r'227952bd947738852236dc294b1ddab646760d5a';

/// カスタムタグの追加・削除操作を担当するアクションクラス

abstract class _$CustomTagsAction extends $Notifier<void> {
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
