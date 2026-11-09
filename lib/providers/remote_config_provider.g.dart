// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'remote_config_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// RemoteConfigService インスタンスを提供する Provider

@ProviderFor(remoteConfigService)
final remoteConfigServiceProvider = RemoteConfigServiceProvider._();

/// RemoteConfigService インスタンスを提供する Provider

final class RemoteConfigServiceProvider extends $FunctionalProvider<
    RemoteConfigService,
    RemoteConfigService,
    RemoteConfigService> with $Provider<RemoteConfigService> {
  /// RemoteConfigService インスタンスを提供する Provider
  RemoteConfigServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'remoteConfigServiceProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$remoteConfigServiceHash();

  @$internal
  @override
  $ProviderElement<RemoteConfigService> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RemoteConfigService create(Ref ref) {
    return remoteConfigService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RemoteConfigService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RemoteConfigService>(value),
    );
  }
}

String _$remoteConfigServiceHash() =>
    r'2dc343b102f76b91a447a61e2bc0f2edba7c5bb8';

/// 現在のユーザーがフォレンジック機能を利用できるかどうかを判定する Provider

@ProviderFor(isForensicEnabled)
final isForensicEnabledProvider = IsForensicEnabledProvider._();

/// 現在のユーザーがフォレンジック機能を利用できるかどうかを判定する Provider

final class IsForensicEnabledProvider
    extends $FunctionalProvider<bool, bool, bool> with $Provider<bool> {
  /// 現在のユーザーがフォレンジック機能を利用できるかどうかを判定する Provider
  IsForensicEnabledProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'isForensicEnabledProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$isForensicEnabledHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return isForensicEnabled(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isForensicEnabledHash() => r'4409d99fd4595d273c3dbff60ea0998156339206';

/// 強制アップデート判定を行う Provider

@ProviderFor(forceUpdateState)
final forceUpdateStateProvider = ForceUpdateStateProvider._();

/// 強制アップデート判定を行う Provider

final class ForceUpdateStateProvider extends $FunctionalProvider<
        AsyncValue<ForceUpdateState>,
        ForceUpdateState,
        FutureOr<ForceUpdateState>>
    with $FutureModifier<ForceUpdateState>, $FutureProvider<ForceUpdateState> {
  /// 強制アップデート判定を行う Provider
  ForceUpdateStateProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'forceUpdateStateProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$forceUpdateStateHash();

  @$internal
  @override
  $FutureProviderElement<ForceUpdateState> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<ForceUpdateState> create(Ref ref) {
    return forceUpdateState(ref);
  }
}

String _$forceUpdateStateHash() => r'90750df9112f81ff7367583dac8ee5f12496586f';
