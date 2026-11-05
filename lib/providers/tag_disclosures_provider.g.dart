// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_disclosures_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// タグ別開示用 Firestore インスタンス Provider (テスト時にモックに差し替え可能)

@ProviderFor(tagDisclosuresFirestore)
final tagDisclosuresFirestoreProvider = TagDisclosuresFirestoreProvider._();

/// タグ別開示用 Firestore インスタンス Provider (テスト時にモックに差し替え可能)

final class TagDisclosuresFirestoreProvider extends $FunctionalProvider<
    FirebaseFirestore,
    FirebaseFirestore,
    FirebaseFirestore> with $Provider<FirebaseFirestore> {
  /// タグ別開示用 Firestore インスタンス Provider (テスト時にモックに差し替え可能)
  TagDisclosuresFirestoreProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'tagDisclosuresFirestoreProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$tagDisclosuresFirestoreHash();

  @$internal
  @override
  $ProviderElement<FirebaseFirestore> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FirebaseFirestore create(Ref ref) {
    return tagDisclosuresFirestore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseFirestore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseFirestore>(value),
    );
  }
}

String _$tagDisclosuresFirestoreHash() =>
    r'b087b4ba3fc7e0c7f3ad15c8b48a7495f62bf0dc';

/// 指定したタグに合致する開示情報のページネーション取得・リフレッシュを管理する Notifier

@ProviderFor(TagDisclosures)
final tagDisclosuresProvider = TagDisclosuresFamily._();

/// 指定したタグに合致する開示情報のページネーション取得・リフレッシュを管理する Notifier
final class TagDisclosuresProvider
    extends $AsyncNotifierProvider<TagDisclosures, PaginatedDisclosuresState> {
  /// 指定したタグに合致する開示情報のページネーション取得・リフレッシュを管理する Notifier
  TagDisclosuresProvider._(
      {required TagDisclosuresFamily super.from,
      required String super.argument})
      : super(
          retry: null,
          name: r'tagDisclosuresProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$tagDisclosuresHash();

  @override
  String toString() {
    return r'tagDisclosuresProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  TagDisclosures create() => TagDisclosures();

  @override
  bool operator ==(Object other) {
    return other is TagDisclosuresProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tagDisclosuresHash() => r'a09e87b813319930f4d4d585345877180cdee522';

/// 指定したタグに合致する開示情報のページネーション取得・リフレッシュを管理する Notifier

final class TagDisclosuresFamily extends $Family
    with
        $ClassFamilyOverride<
            TagDisclosures,
            AsyncValue<PaginatedDisclosuresState>,
            PaginatedDisclosuresState,
            FutureOr<PaginatedDisclosuresState>,
            String> {
  TagDisclosuresFamily._()
      : super(
          retry: null,
          name: r'tagDisclosuresProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// 指定したタグに合致する開示情報のページネーション取得・リフレッシュを管理する Notifier

  TagDisclosuresProvider call(
    String tag,
  ) =>
      TagDisclosuresProvider._(argument: tag, from: this);

  @override
  String toString() => r'tagDisclosuresProvider';
}

/// 指定したタグに合致する開示情報のページネーション取得・リフレッシュを管理する Notifier

abstract class _$TagDisclosures
    extends $AsyncNotifier<PaginatedDisclosuresState> {
  late final _$args = ref.$arg as String;
  String get tag => _$args;

  FutureOr<PaginatedDisclosuresState> build(
    String tag,
  );
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<PaginatedDisclosuresState>,
        PaginatedDisclosuresState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<PaginatedDisclosuresState>,
            PaginatedDisclosuresState>,
        AsyncValue<PaginatedDisclosuresState>,
        Object?,
        Object?>;
    return element.handleCreate(
        ref,
        () => build(
              _$args,
            ));
  }
}
