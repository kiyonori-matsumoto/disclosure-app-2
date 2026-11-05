import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' hide Filter;
import 'package:disclosure_app_fl/providers/custom_tags_provider.dart';
import 'package:disclosure_app_fl/providers/disclosures_provider.dart';
import 'package:disclosure_app_fl/providers/favorites_provider.dart';
import 'package:disclosure_app_fl/providers/user_settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore: subtype_of_sealed_class
class FakeDocumentSnapshot extends Fake
    implements DocumentSnapshot<Map<String, dynamic>> {
  final String _id;
  final Map<String, dynamic> _data;

  FakeDocumentSnapshot(this._id, this._data);

  @override
  String get id => _id;

  @override
  Map<String, dynamic> data() => _data;

  @override
  dynamic operator [](Object? key) => _data[key];

  @override
  bool get exists => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SelectedDate Notifier', () {
    test('初期値は現在日時の日付である', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final date = container.read(selectedDateProvider);
      final now = DateTime.now();
      expect(date.year, now.year);
      expect(date.month, now.month);
      expect(date.day, now.day);
    });

    test('setDate で日付を更新できる', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final target = DateTime(2026, 1, 1);
      container.read(selectedDateProvider.notifier).setDate(target);
      expect(container.read(selectedDateProvider), target);
    });
  });

  group('DisclosureOrder Notifier', () {
    test('初期値は "最新" である', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(disclosureOrderProvider), '最新');
    });

    test('toggle で "閲覧回数" と "最新" を交互に切り替えられる', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(disclosureOrderProvider.notifier);
      notifier.toggle();
      expect(container.read(disclosureOrderProvider), '閲覧回数');

      notifier.toggle();
      expect(container.read(disclosureOrderProvider), '最新');
    });

    test('setOrder で直接ソート順を指定できる', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(disclosureOrderProvider.notifier);
      notifier.setOrder('閲覧回数');
      expect(container.read(disclosureOrderProvider), '閲覧回数');
    });
  });

  group('ShowOnlyFavorites Notifier', () {
    test('初期値は false である', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(showOnlyFavoritesProvider), isFalse);
    });

    test('toggle で ON/OFF を切り替えられる', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(showOnlyFavoritesProvider.notifier);
      notifier.toggle();
      expect(container.read(showOnlyFavoritesProvider), isTrue);

      notifier.toggle();
      expect(container.read(showOnlyFavoritesProvider), isFalse);
    });

    test('set で明示的に値を設定できる', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(showOnlyFavoritesProvider.notifier);
      notifier.set(true);
      expect(container.read(showOnlyFavoritesProvider), isTrue);
    });
  });

  group('SelectedFilters Notifier', () {
    test('初期値は空の Set である', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(selectedFiltersProvider), isEmpty);
      expect(container.read(selectedFilterCountProvider), 0);
    });

    test('toggle でタグを追加・削除できる', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(selectedFiltersProvider.notifier);
      notifier.toggle('決算');
      expect(container.read(selectedFiltersProvider), {'決算'});
      expect(container.read(selectedFilterCountProvider), 1);

      notifier.toggle('配当');
      expect(container.read(selectedFiltersProvider), {'決算', '配当'});
      expect(container.read(selectedFilterCountProvider), 2);

      notifier.toggle('決算');
      expect(container.read(selectedFiltersProvider), {'配当'});
      expect(container.read(selectedFilterCountProvider), 1);
    });

    test('clear で全選択を解除できる', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(selectedFiltersProvider.notifier);
      notifier.toggle('決算');
      notifier.toggle('配当');
      expect(container.read(selectedFilterCountProvider), 2);

      notifier.clear();
      expect(container.read(selectedFiltersProvider), isEmpty);
      expect(container.read(selectedFilterCountProvider), 0);
    });
  });

  group('availableFiltersProvider', () {
    test('プリセットタグとカスタムタグがマージされ、選択状態が反映される', () {
      final container = ProviderContainer(
        overrides: [
          customTagsProvider.overrideWith((ref) => ['EV関連', 'AI関連', '決算']),
          selectedFiltersProvider
              .overrideWith(() => _TestSelectedFilters({'決算', 'AI関連'})),
        ],
      );
      addTearDown(container.dispose);

      final filters = container.read(availableFiltersProvider);

      // デフォルトフィルタ7件 + 新規カスタムタグ2件（'決算'は重複のため排除）= 9件
      expect(filters.length, 9);

      final kessan = filters.firstWhere((f) => f.title == '決算');
      expect(kessan.isSelected, isTrue);

      final ai = filters.firstWhere((f) => f.title == 'AI関連');
      expect(ai.isSelected, isTrue);

      final haito = filters.firstWhere((f) => f.title == '配当');
      expect(haito.isSelected, isFalse);
    });
  });

  group('DisclosuresFeed & filteredDisclosuresProvider', () {
    test('最上部にいる場合（isAtTop == true）、新着ドキュメントが届くと即座に画面へ自動反映される', () async {
      final streamController =
          StreamController<List<DocumentSnapshot<Map<String, dynamic>>>>.broadcast();
      addTearDown(streamController.close);

      final targetDate = DateTime(2026, 11, 5);

      final container = ProviderContainer(
        overrides: [
          selectedDateProvider.overrideWith(() => _TestSelectedDate(targetDate)),
          disclosuresRawStreamProvider(targetDate)
              .overrideWith((ref) => streamController.stream),
          userDocStreamProvider.overrideWith((ref) => Stream.value({})),
        ],
      );
      addTearDown(container.dispose);

      // 購読を開始
      final subscription = container.listen(disclosuresFeedProvider, (_, __) {});
      addTearDown(subscription.close);

      // 初回データを流す
      final doc1 = FakeDocumentSnapshot('doc1', {'title': '開示1', 'time': 1000});
      streamController.add([doc1]);
      await Future<void>.delayed(Duration.zero);

      final feed = container.read(disclosuresFeedProvider);
      expect(feed.displayedDocs.length, 1);
      expect(feed.displayedDocs.first.id, 'doc1');
      expect(feed.newCount, 0);
      expect(container.read(pendingNewDisclosureCountProvider), 0);

      // 最上部にいる状態で新着 doc2 を流す
      final doc2 = FakeDocumentSnapshot('doc2', {'title': '開示2', 'time': 2000});
      streamController.add([doc2, doc1]);
      await Future<void>.delayed(Duration.zero);

      final updatedFeed = container.read(disclosuresFeedProvider);
      expect(updatedFeed.displayedDocs.length, 2);
      expect(updatedFeed.displayedDocs.first.id, 'doc2');
      expect(updatedFeed.newCount, 0); // 最上部のため即反映されカウントは0
    });

    test('スクロール中（isAtTop == false）の場合、新着ドキュメントは即座に反映されず newCount が加算される', () async {
      final streamController =
          StreamController<List<DocumentSnapshot<Map<String, dynamic>>>>.broadcast();
      addTearDown(streamController.close);

      final targetDate = DateTime(2026, 11, 5);

      final container = ProviderContainer(
        overrides: [
          selectedDateProvider.overrideWith(() => _TestSelectedDate(targetDate)),
          disclosuresRawStreamProvider(targetDate)
              .overrideWith((ref) => streamController.stream),
          userDocStreamProvider.overrideWith((ref) => Stream.value({})),
        ],
      );
      addTearDown(container.dispose);

      final subscription = container.listen(disclosuresFeedProvider, (_, __) {});
      addTearDown(subscription.close);

      final doc1 = FakeDocumentSnapshot('doc1', {'title': '開示1', 'time': 1000});
      streamController.add([doc1]);
      await Future<void>.delayed(Duration.zero);

      // ユーザーがスクロールした状態にする
      container
          .read(disclosuresFeedProvider.notifier)
          .updateScrollPosition(isAtTop: false);

      // 新着 doc2 が追加された
      final doc2 = FakeDocumentSnapshot('doc2', {'title': '開示2', 'time': 2000});
      streamController.add([doc2, doc1]);
      await Future<void>.delayed(Duration.zero);

      final feed = container.read(disclosuresFeedProvider);
      // 画面表示は doc1 のまま（ズレ防止）
      expect(feed.displayedDocs.length, 1);
      expect(feed.displayedDocs.first.id, 'doc1');
      // newCount に新着1件がカウントされる
      expect(feed.newCount, 1);
      expect(container.read(pendingNewDisclosureCountProvider), 1);

      // refreshToLatest() を呼ぶと最新が反映され newCount は 0 にリセット
      container.read(disclosuresFeedProvider.notifier).refreshToLatest();
      final refreshedFeed = container.read(disclosuresFeedProvider);
      expect(refreshedFeed.displayedDocs.length, 2);
      expect(refreshedFeed.displayedDocs.first.id, 'doc2');
      expect(refreshedFeed.newCount, 0);
      expect(container.read(pendingNewDisclosureCountProvider), 0);
    });

    test('スクロール中から最上部に戻った場合（isAtTop: true）、自動で最新が反映される', () async {
      final streamController =
          StreamController<List<DocumentSnapshot<Map<String, dynamic>>>>.broadcast();
      addTearDown(streamController.close);

      final targetDate = DateTime(2026, 11, 5);

      final container = ProviderContainer(
        overrides: [
          selectedDateProvider.overrideWith(() => _TestSelectedDate(targetDate)),
          disclosuresRawStreamProvider(targetDate)
              .overrideWith((ref) => streamController.stream),
          userDocStreamProvider.overrideWith((ref) => Stream.value({})),
        ],
      );
      addTearDown(container.dispose);

      final subscription = container.listen(disclosuresFeedProvider, (_, __) {});
      addTearDown(subscription.close);

      final doc1 = FakeDocumentSnapshot('doc1', {'title': '開示1', 'time': 1000});
      streamController.add([doc1]);
      await Future<void>.delayed(Duration.zero);

      container
          .read(disclosuresFeedProvider.notifier)
          .updateScrollPosition(isAtTop: false);

      final doc2 = FakeDocumentSnapshot('doc2', {'title': '開示2', 'time': 2000});
      streamController.add([doc2, doc1]);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(disclosuresFeedProvider).newCount, 1);

      // 最上部へ戻った
      container
          .read(disclosuresFeedProvider.notifier)
          .updateScrollPosition(isAtTop: true);

      final feed = container.read(disclosuresFeedProvider);
      expect(feed.displayedDocs.length, 2);
      expect(feed.newCount, 0);
    });

    test('injectDebugNewDisclosure: 最上部なら即座に追加され、スクロール中なら newCount が加算される', () async {
      final targetDate = DateTime(2026, 11, 5);

      final container = ProviderContainer(
        overrides: [
          selectedDateProvider.overrideWith(() => _TestSelectedDate(targetDate)),
          disclosuresRawStreamProvider(targetDate)
              .overrideWith((ref) => Stream.value([])),
        ],
      );
      addTearDown(container.dispose);

      final subscription =
          container.listen(disclosuresFeedProvider, (_, __) {});
      addTearDown(subscription.close);

      await Future<void>.delayed(Duration.zero);

      // 1. 最上部にいる状態で注入 -> displayedDocs に即座に追加
      container.read(disclosuresFeedProvider.notifier).injectDebugNewDisclosure(
            title: 'デバッグ開示1',
          );
      var feed = container.read(disclosuresFeedProvider);
      expect(feed.displayedDocs.length, 1);
      expect(feed.displayedDocs.first['title'], contains('デバッグ開示1'));
      expect(feed.newCount, 0);

      // 2. スクロール中に注入 -> displayedDocs は維持され newCount が加算
      container
          .read(disclosuresFeedProvider.notifier)
          .updateScrollPosition(isAtTop: false);

      container.read(disclosuresFeedProvider.notifier).injectDebugNewDisclosure(
            title: 'デバッグ開示2',
          );
      feed = container.read(disclosuresFeedProvider);
      expect(feed.displayedDocs.length, 1);
      expect(feed.newCount, 1);

      // 3. refreshToLatest() で反映
      container.read(disclosuresFeedProvider.notifier).refreshToLatest();
      feed = container.read(disclosuresFeedProvider);
      expect(feed.displayedDocs.length, 2);
      expect(feed.newCount, 0);
    });

    test('filteredDisclosuresProvider: 日々の開示非表示、お気に入り絞り込み、タグフィルタ、ソートが正しく適用される', () async {
      final targetDate = DateTime(2026, 11, 5);

      final docDaily = FakeDocumentSnapshot('doc1', {
        'title': '日々の開示',
        'code': '7203',
        'tags': {'日々の開示事項': true},
        'view_count': 10,
        'time': 1000,
      });
      final docKessanToyota = FakeDocumentSnapshot('doc2', {
        'title': '決算短信',
        'code': '7203',
        'tags': {'決算': true},
        'view_count': 100,
        'time': 2000,
      });
      final docHaitoSony = FakeDocumentSnapshot('doc3', {
        'title': '配当予想修正',
        'code': '6758',
        'tags': {'配当': true},
        'view_count': 50,
        'time': 1500,
      });

      final streamController =
          StreamController<List<DocumentSnapshot<Map<String, dynamic>>>>.broadcast();
      addTearDown(streamController.close);

      final container = ProviderContainer(
        overrides: [
          selectedDateProvider.overrideWith(() => _TestSelectedDate(targetDate)),
          disclosuresRawStreamProvider(targetDate)
              .overrideWith((ref) => streamController.stream),
          hideDailyDisclosureProvider.overrideWith((ref) => true),
          favoritesProvider.overrideWith((ref) => ['7203']),
        ],
      );
      addTearDown(container.dispose);

      final subscription =
          container.listen(filteredDisclosuresProvider, (_, __) {});
      addTearDown(subscription.close);

      streamController.add([docDaily, docKessanToyota, docHaitoSony]);
      await Future<void>.delayed(Duration.zero);

      // 1. 初回: hideDailyDisclosure=true のみ適用
      var result = container.read(filteredDisclosuresProvider).value!;
      // docDaily が除外され、docKessanToyota と docHaitoSony の2件
      expect(result.map((d) => d.id).toList(), ['doc2', 'doc3']);

      // 4. ソート順を "閲覧回数" に切り替える
      container.read(disclosureOrderProvider.notifier).toggle();
      result = container.read(filteredDisclosuresProvider).value!;
      // view_count: doc2 (100) > doc3 (50)
      expect(result.map((d) => d.id).toList(), ['doc2', 'doc3']);
    });

    test('お気に入りのみ表示がONでお気に入り登録が0件の場合、空リストを返す', () async {
      final targetDate = DateTime(2026, 11, 5);
      final doc1 = FakeDocumentSnapshot('doc1', {'title': '開示1', 'code': '7203'});

      final container = ProviderContainer(
        overrides: [
          selectedDateProvider.overrideWith(() => _TestSelectedDate(targetDate)),
          disclosuresRawStreamProvider(targetDate)
              .overrideWith((ref) => Stream.value([doc1])),
          favoritesProvider.overrideWith((ref) => []),
          showOnlyFavoritesProvider.overrideWith(() => _TestShowOnlyFavorites(true)),
        ],
      );
      addTearDown(container.dispose);

      final subscription =
          container.listen(filteredDisclosuresProvider, (_, __) {});
      addTearDown(subscription.close);

      await Future<void>.delayed(Duration.zero);
      final result = container.read(filteredDisclosuresProvider).value!;
      expect(result, isEmpty);
    });
  });
}

class _TestSelectedDate extends SelectedDate {
  final DateTime _initial;
  _TestSelectedDate(this._initial);

  @override
  DateTime build() => _initial;
}

class _TestSelectedFilters extends SelectedFilters {
  final Set<String> _initial;
  _TestSelectedFilters(this._initial);

  @override
  Set<String> build() => _initial;
}

class _TestShowOnlyFavorites extends ShowOnlyFavorites {
  final bool _initial;
  _TestShowOnlyFavorites(this._initial);

  @override
  bool build() => _initial;
}
