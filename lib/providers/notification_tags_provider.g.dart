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
    r'90106dfa12f47cd260d356772eaf7a46421fa7f1';

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
