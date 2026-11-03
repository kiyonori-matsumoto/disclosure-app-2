// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Firebase Authentication のストリームを監視する内部用 Provider

@ProviderFor(_authState)
final _authStateProvider = _AuthStateProvider._();

/// Firebase Authentication のストリームを監視する内部用 Provider

final class _AuthStateProvider
    extends $FunctionalProvider<AsyncValue<User?>, User?, Stream<User?>>
    with $FutureModifier<User?>, $StreamProvider<User?> {
  /// Firebase Authentication のストリームを監視する内部用 Provider
  _AuthStateProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'_authStateProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$_authStateHash();

  @$internal
  @override
  $StreamProviderElement<User?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<User?> create(Ref ref) {
    return _authState(ref);
  }
}

String _$_authStateHash() => r'98096949d684afb57320818371b07ebd8c8dc86d';

/// 現在ログイン中のユーザーを同期的に取得・監視できる公開 Provider

@ProviderFor(currentUser)
final currentUserProvider = CurrentUserProvider._();

/// 現在ログイン中のユーザーを同期的に取得・監視できる公開 Provider

final class CurrentUserProvider extends $FunctionalProvider<User?, User?, User?>
    with $Provider<User?> {
  /// 現在ログイン中のユーザーを同期的に取得・監視できる公開 Provider
  CurrentUserProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'currentUserProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$currentUserHash();

  @$internal
  @override
  $ProviderElement<User?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  User? create(Ref ref) {
    return currentUser(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(User? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<User?>(value),
    );
  }
}

String _$currentUserHash() => r'cbc129f6232ddefb9f59f2f8b97d1f01e6776652';
