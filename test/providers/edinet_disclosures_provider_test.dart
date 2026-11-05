import 'dart:async';

import 'package:disclosure_app_fl/models/company.dart';
import 'package:disclosure_app_fl/models/edinet.dart';
import 'package:disclosure_app_fl/providers/company_provider.dart';
import 'package:disclosure_app_fl/providers/edinet_disclosures_provider.dart';
import 'package:disclosure_app_fl/providers/favorites_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Edinet createTestEdinet({
  required String docId,
  String? docDescription,
  String? docTypeCode,
  String? edinetCode,
  String? filerName,
  int? time,
}) {
  return Edinet(
    docId: docId,
    docDescription: docDescription ?? '有価証券報告書',
    docTypeCode: docTypeCode ?? '120', // 有価証券報告書
    edinetCode: edinetCode ?? 'E00001',
    filerName: filerName ?? 'テスト提出者',
    time: time ?? 1600000000,
    viewCount: 0,
  );
}

class _TestSelectedDate extends EdinetSelectedDate {
  final DateTime initial;
  _TestSelectedDate(this.initial);

  @override
  DateTime build() => initial;
}

void main() {
  group('Edinet Notifiers Unit Tests', () {
    test('EdinetSelectedDate: 初期値と setDate', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initial = container.read(edinetSelectedDateProvider);
      final now = DateTime.now();
      expect(initial.year, now.year);
      expect(initial.month, now.month);
      expect(initial.day, now.day);

      final newDate = DateTime(2025, 5, 20);
      container.read(edinetSelectedDateProvider.notifier).setDate(newDate);
      expect(container.read(edinetSelectedDateProvider), newDate);
    });

    test('EdinetDocTypeFilter: 初期値、setFilter、reset', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(edinetDocTypeFilterProvider), '');

      container
          .read(edinetDocTypeFilterProvider.notifier)
          .setFilter('大量保有報告書');
      expect(container.read(edinetDocTypeFilterProvider), '大量保有報告書');

      container.read(edinetDocTypeFilterProvider.notifier).reset();
      expect(container.read(edinetDocTypeFilterProvider), '');
    });

    test('EdinetShowOnlyFavorites: 初期値、toggle、set', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(edinetShowOnlyFavoritesProvider), isFalse);

      container.read(edinetShowOnlyFavoritesProvider.notifier).toggle();
      expect(container.read(edinetShowOnlyFavoritesProvider), isTrue);

      container.read(edinetShowOnlyFavoritesProvider.notifier).set(false);
      expect(container.read(edinetShowOnlyFavoritesProvider), isFalse);
    });
  });

  group('EdinetFeed & filteredEdinetsProvider Tests', () {
    final testDate = DateTime(2025, 5, 20);

    test('最上部にいる場合、新着が即座に画面へ反映されること', () async {
      final streamController = StreamController<List<Edinet>>.broadcast();
      addTearDown(streamController.close);

      final container = ProviderContainer(
        overrides: [
          edinetSelectedDateProvider
              .overrideWith(() => _TestSelectedDate(testDate)),
          edinetsRawStreamProvider(testDate)
              .overrideWith((ref) => streamController.stream),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(edinetFeedProvider, (_, __) {});
      addTearDown(sub.close);

      final edinet1 = createTestEdinet(docId: 'doc1');
      streamController.add([edinet1]);
      await Future<void>.delayed(Duration.zero);

      final state1 = container.read(edinetFeedProvider);
      expect(state1.displayedItems.length, 1);
      expect(state1.displayedItems.first.docId, 'doc1');
      expect(state1.newCount, 0);

      // 新着注入
      container.read(edinetFeedProvider.notifier).injectDebugNewEdinet(
            title: '新着ダミー',
          );

      final state2 = container.read(edinetFeedProvider);
      expect(state2.displayedItems.length, 2);
      expect(state2.newCount, 0); // 最上部のため即座に反映
    });

    test('スクロール中（isAtTop == false）の場合、新着は保留され newCount が加算されること', () async {
      final streamController = StreamController<List<Edinet>>.broadcast();
      addTearDown(streamController.close);

      final container = ProviderContainer(
        overrides: [
          edinetSelectedDateProvider
              .overrideWith(() => _TestSelectedDate(testDate)),
          edinetsRawStreamProvider(testDate)
              .overrideWith((ref) => streamController.stream),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(edinetFeedProvider, (_, __) {});
      addTearDown(sub.close);

      final edinet1 = createTestEdinet(docId: 'doc1');
      streamController.add([edinet1]);
      await Future<void>.delayed(Duration.zero);

      // スクロール中へ遷移
      container
          .read(edinetFeedProvider.notifier)
          .updateScrollPosition(isAtTop: false);

      expect(container.read(edinetFeedProvider).isAtTop, isFalse);

      // 新着注入
      container.read(edinetFeedProvider.notifier).injectDebugNewEdinet(
            title: '保留される新着',
          );

      final state = container.read(edinetFeedProvider);
      expect(state.displayedItems.length, 1); // 画面は1件のまま
      expect(state.latestItems.length, 2); // 最新は2件
      expect(state.newCount, 1); // 新着件数1

      // 最上部へ戻ると自動反映
      container
          .read(edinetFeedProvider.notifier)
          .updateScrollPosition(isAtTop: true);

      final atTopState = container.read(edinetFeedProvider);
      expect(atTopState.displayedItems.length, 2);
      expect(atTopState.newCount, 0);
    });

    test('filteredEdinets: 企業名補完と書類種別フィルタが正しく動作すること', () async {
      final streamController = StreamController<List<Edinet>>.broadcast();
      addTearDown(streamController.close);

      final edinet1 = createTestEdinet(
        docId: 'doc1',
        docTypeCode: '350', // 大量保有報告書
        edinetCode: 'E00001',
      );
      final edinet2 = createTestEdinet(
        docId: 'doc2',
        docTypeCode: '140', // 四半期報告書
        edinetCode: 'E00002',
      );

      final container = ProviderContainer(
        overrides: [
          edinetSelectedDateProvider
              .overrideWith(() => _TestSelectedDate(testDate)),
          edinetsRawStreamProvider(testDate)
              .overrideWith((ref) => streamController.stream),
          companyEdinetMapProvider.overrideWithValue({
            'E00001': Company('7203', name: 'トヨタ自動車', edinetCode: 'E00001'),
            'E00002': Company('6758', name: 'ソニーグループ', edinetCode: 'E00002'),
          }),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(filteredEdinetsProvider, (_, __) {});
      addTearDown(sub.close);

      streamController.add([edinet1, edinet2]);
      await Future<void>.delayed(Duration.zero);

      // 全件表示時
      final allList = container.read(filteredEdinetsProvider).value!;
      expect(allList.length, 2);
      expect(allList[0].filer?.name, 'トヨタ自動車');
      expect(allList[1].filer?.name, 'ソニーグループ');

      // 書類種別「大量保有報告書」でフィルタ
      container
          .read(edinetDocTypeFilterProvider.notifier)
          .setFilter('大量保有報告書');

      final filteredList = container.read(filteredEdinetsProvider).value!;
      expect(filteredList.length, 1);
      expect(filteredList.first.docId, 'doc1');
      expect(filteredList.first.docType, '大量保有報告書');
    });

    test('filteredEdinets: お気に入り絞り込みが正しく動作すること', () async {
      final streamController = StreamController<List<Edinet>>.broadcast();
      addTearDown(streamController.close);

      final edinet1 = createTestEdinet(
        docId: 'doc1',
        edinetCode: 'E00001',
      );
      final edinet2 = createTestEdinet(
        docId: 'doc2',
        edinetCode: 'E00002',
      );

      final container = ProviderContainer(
        overrides: [
          edinetSelectedDateProvider
              .overrideWith(() => _TestSelectedDate(testDate)),
          edinetsRawStreamProvider(testDate)
              .overrideWith((ref) => streamController.stream),
          companyEdinetMapProvider.overrideWithValue({
            'E00001': Company('7203', name: 'トヨタ自動車', edinetCode: 'E00001'),
            'E00002': Company('6758', name: 'ソニーグループ', edinetCode: 'E00002'),
          }),
          favoritesProvider.overrideWithValue(['7203']), // トヨタのみお気に入り
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(filteredEdinetsProvider, (_, __) {});
      addTearDown(sub.close);

      streamController.add([edinet1, edinet2]);
      await Future<void>.delayed(Duration.zero);

      // お気に入りのみ表示をONにする
      container.read(edinetShowOnlyFavoritesProvider.notifier).set(true);

      final list = container.read(filteredEdinetsProvider).value!;
      expect(list.length, 1);
      expect(list.first.docId, 'doc1');
      expect(list.first.filer?.name, 'トヨタ自動車');
    });

    test('【最重要】filteredEdinets: お気に入りが0件でお気に入りフィルタONの場合、空リスト（0件）を返すこと',
        () async {
      final streamController = StreamController<List<Edinet>>.broadcast();
      addTearDown(streamController.close);

      final edinet1 = createTestEdinet(
        docId: 'doc1',
        edinetCode: 'E00001',
      );

      final container = ProviderContainer(
        overrides: [
          edinetSelectedDateProvider
              .overrideWith(() => _TestSelectedDate(testDate)),
          edinetsRawStreamProvider(testDate)
              .overrideWith((ref) => streamController.stream),
          companyEdinetMapProvider.overrideWithValue({
            'E00001': Company('7203', name: 'トヨタ自動車', edinetCode: 'E00001'),
          }),
          favoritesProvider.overrideWithValue([]), // お気に入り 0 件
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(filteredEdinetsProvider, (_, __) {});
      addTearDown(sub.close);

      streamController.add([edinet1]);
      await Future<void>.delayed(Duration.zero);

      // お気に入りのみ表示をONにする
      container.read(edinetShowOnlyFavoritesProvider.notifier).set(true);

      final list = container.read(filteredEdinetsProvider).value!;
      // 0件が返ること（従来の全件表示バグが解消されていること）
      expect(list, isEmpty);
    });
  });
}
