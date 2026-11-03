// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// ログインユーザーの users/{uid} ドキュメントデータをリアルタイム購読する基盤 Provider

@ProviderFor(userDocStream)
final userDocStreamProvider = UserDocStreamProvider._();

/// ログインユーザーの users/{uid} ドキュメントデータをリアルタイム購読する基盤 Provider

final class UserDocStreamProvider extends $FunctionalProvider<
        AsyncValue<Map<String, dynamic>>,
        Map<String, dynamic>,
        Stream<Map<String, dynamic>>>
    with
        $FutureModifier<Map<String, dynamic>>,
        $StreamProvider<Map<String, dynamic>> {
  /// ログインユーザーの users/{uid} ドキュメントデータをリアルタイム購読する基盤 Provider
  UserDocStreamProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'userDocStreamProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$userDocStreamHash();

  @$internal
  @override
  $StreamProviderElement<Map<String, dynamic>> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Map<String, dynamic>> create(Ref ref) {
    return userDocStream(ref);
  }
}

String _$userDocStreamHash() => r'e14941c1eebc4a4bdf7f6ba2449974fa5d5d0ac5';

/// 日々の開示情報を非表示にする設定の Provider

@ProviderFor(hideDailyDisclosure)
final hideDailyDisclosureProvider = HideDailyDisclosureProvider._();

/// 日々の開示情報を非表示にする設定の Provider

final class HideDailyDisclosureProvider
    extends $FunctionalProvider<bool, bool, bool> with $Provider<bool> {
  /// 日々の開示情報を非表示にする設定の Provider
  HideDailyDisclosureProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'hideDailyDisclosureProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$hideDailyDisclosureHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return hideDailyDisclosure(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$hideDailyDisclosureHash() =>
    r'6e22395ccf851e51bf4acfcedf601ad06704e181';

/// ユーザー設定の更新を担当するアクションクラス

@ProviderFor(UserSettingsAction)
final userSettingsActionProvider = UserSettingsActionProvider._();

/// ユーザー設定の更新を担当するアクションクラス
final class UserSettingsActionProvider
    extends $NotifierProvider<UserSettingsAction, void> {
  /// ユーザー設定の更新を担当するアクションクラス
  UserSettingsActionProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'userSettingsActionProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$userSettingsActionHash();

  @$internal
  @override
  UserSettingsAction create() => UserSettingsAction();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$userSettingsActionHash() =>
    r'167892b15d344458450318ddd791978a5ddcac6e';

/// ユーザー設定の更新を担当するアクションクラス

abstract class _$UserSettingsAction extends $Notifier<void> {
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
