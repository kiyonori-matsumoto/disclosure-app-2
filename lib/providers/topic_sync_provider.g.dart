// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'topic_sync_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// TopicSyncHelper を提供する Provider (テスト時に override 可能)

@ProviderFor(topicSyncHelper)
final topicSyncHelperProvider = TopicSyncHelperProvider._();

/// TopicSyncHelper を提供する Provider (テスト時に override 可能)

final class TopicSyncHelperProvider extends $FunctionalProvider<TopicSyncHelper,
    TopicSyncHelper, TopicSyncHelper> with $Provider<TopicSyncHelper> {
  /// TopicSyncHelper を提供する Provider (テスト時に override 可能)
  TopicSyncHelperProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'topicSyncHelperProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$topicSyncHelperHash();

  @$internal
  @override
  $ProviderElement<TopicSyncHelper> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TopicSyncHelper create(Ref ref) {
    return topicSyncHelper(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TopicSyncHelper value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TopicSyncHelper>(value),
    );
  }
}

String _$topicSyncHelperHash() => r'a468ab3300130e247f5d56e95a24bc03cf1742b1';

/// TagMigrationHelper を提供する Provider (テスト時に override 可能)

@ProviderFor(tagMigrationHelper)
final tagMigrationHelperProvider = TagMigrationHelperProvider._();

/// TagMigrationHelper を提供する Provider (テスト時に override 可能)

final class TagMigrationHelperProvider extends $FunctionalProvider<
    TagMigrationHelper,
    TagMigrationHelper,
    TagMigrationHelper> with $Provider<TagMigrationHelper> {
  /// TagMigrationHelper を提供する Provider (テスト時に override 可能)
  TagMigrationHelperProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'tagMigrationHelperProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$tagMigrationHelperHash();

  @$internal
  @override
  $ProviderElement<TagMigrationHelper> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TagMigrationHelper create(Ref ref) {
    return tagMigrationHelper(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TagMigrationHelper value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TagMigrationHelper>(value),
    );
  }
}

String _$tagMigrationHelperHash() =>
    r'0c35d425a60c3c087fb2e7db07db46670edb79cc';

/// 購読すべきトピック集合を計算する Provider

@ProviderFor(desiredNotificationTopics)
final desiredNotificationTopicsProvider = DesiredNotificationTopicsProvider._();

/// 購読すべきトピック集合を計算する Provider

final class DesiredNotificationTopicsProvider
    extends $FunctionalProvider<Set<String>, Set<String>, Set<String>>
    with $Provider<Set<String>> {
  /// 購読すべきトピック集合を計算する Provider
  DesiredNotificationTopicsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'desiredNotificationTopicsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$desiredNotificationTopicsHash();

  @$internal
  @override
  $ProviderElement<Set<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Set<String> create(Ref ref) {
    return desiredNotificationTopics(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$desiredNotificationTopicsHash() =>
    r'9d2fe07e3fb9bf25db39f4e8d11dc69dc4978748';

/// FCM トピック同期およびタグマイグレーションを統括する Notifier

@ProviderFor(TopicSync)
final topicSyncProvider = TopicSyncProvider._();

/// FCM トピック同期およびタグマイグレーションを統括する Notifier
final class TopicSyncProvider extends $NotifierProvider<TopicSync, void> {
  /// FCM トピック同期およびタグマイグレーションを統括する Notifier
  TopicSyncProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'topicSyncProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$topicSyncHash();

  @$internal
  @override
  TopicSync create() => TopicSync();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$topicSyncHash() => r'365b19849c520d722b289189ba6b4b37d6058996';

/// FCM トピック同期およびタグマイグレーションを統括する Notifier

abstract class _$TopicSync extends $Notifier<void> {
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
