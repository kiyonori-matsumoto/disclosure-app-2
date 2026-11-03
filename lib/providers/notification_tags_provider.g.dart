// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_tags_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// ログインユーザーの通知タグ設定一覧（List<String>）を提供する Provider

@ProviderFor(notificationTags)
final notificationTagsProvider = NotificationTagsProvider._();

/// ログインユーザーの通知タグ設定一覧（List<String>）を提供する Provider

final class NotificationTagsProvider
    extends $FunctionalProvider<List<String>, List<String>, List<String>>
    with $Provider<List<String>> {
  /// ログインユーザーの通知タグ設定一覧（List<String>）を提供する Provider
  NotificationTagsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'notificationTagsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$notificationTagsHash();

  @$internal
  @override
  $ProviderElement<List<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<String> create(Ref ref) {
    return notificationTags(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$notificationTagsHash() => r'2fe88f0f96ff0110fefdbb59c1cf88eb13d704fb';

/// テスト・デバッグ用: 現在の全通知（お気に入り企業 + 通知タグ）をコンソールログに出力する Provider

@ProviderFor(logCurrentNotifications)
final logCurrentNotificationsProvider = LogCurrentNotificationsProvider._();

/// テスト・デバッグ用: 現在の全通知（お気に入り企業 + 通知タグ）をコンソールログに出力する Provider

final class LogCurrentNotificationsProvider
    extends $FunctionalProvider<void, void, void> with $Provider<void> {
  /// テスト・デバッグ用: 現在の全通知（お気に入り企業 + 通知タグ）をコンソールログに出力する Provider
  LogCurrentNotificationsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'logCurrentNotificationsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$logCurrentNotificationsHash();

  @$internal
  @override
  $ProviderElement<void> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  void create(Ref ref) {
    return logCurrentNotifications(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$logCurrentNotificationsHash() =>
    r'6ab8f3eb389d3d428e1e8727d1b4384bce628d2b';

/// タグ通知の追加・削除・トグル操作を担当するアクションクラス

@ProviderFor(NotificationTagsAction)
final notificationTagsActionProvider = NotificationTagsActionProvider._();

/// タグ通知の追加・削除・トグル操作を担当するアクションクラス
final class NotificationTagsActionProvider
    extends $NotifierProvider<NotificationTagsAction, void> {
  /// タグ通知の追加・削除・トグル操作を担当するアクションクラス
  NotificationTagsActionProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'notificationTagsActionProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$notificationTagsActionHash();

  @$internal
  @override
  NotificationTagsAction create() => NotificationTagsAction();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$notificationTagsActionHash() =>
    r'4c720ed099be8779df9ca273787967e5fe92df75';

/// タグ通知の追加・削除・トグル操作を担当するアクションクラス

abstract class _$NotificationTagsAction extends $Notifier<void> {
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
