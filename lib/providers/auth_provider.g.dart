// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Firebase Authentication の認証状態（ログインユーザー）を監視する Provider
/// アプリ全体で共有するため常駐（keepAlive: true）とする

@ProviderFor(authState)
final authStateProvider = AuthStateProvider._();

/// Firebase Authentication の認証状態（ログインユーザー）を監視する Provider
/// アプリ全体で共有するため常駐（keepAlive: true）とする

final class AuthStateProvider
    extends $FunctionalProvider<AsyncValue<User?>, User?, Stream<User?>>
    with $FutureModifier<User?>, $StreamProvider<User?> {
  /// Firebase Authentication の認証状態（ログインユーザー）を監視する Provider
  /// アプリ全体で共有するため常駐（keepAlive: true）とする
  AuthStateProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'authStateProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$authStateHash();

  @$internal
  @override
  $StreamProviderElement<User?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<User?> create(Ref ref) {
    return authState(ref);
  }
}

String _$authStateHash() => r'4d015e46839f5a642a975de024dfc4299389759d';

/// 現在ログイン中のユーザーを同期的に取得・監視できる Provider

@ProviderFor(currentUser)
final currentUserProvider = CurrentUserProvider._();

/// 現在ログイン中のユーザーを同期的に取得・監視できる Provider

final class CurrentUserProvider extends $FunctionalProvider<User?, User?, User?>
    with $Provider<User?> {
  /// 現在ログイン中のユーザーを同期的に取得・監視できる Provider
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

String _$currentUserHash() => r'1dffce24ba9336888e45038f2f5abd4eea53a067';
