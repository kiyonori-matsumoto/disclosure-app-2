import 'package:disclosure_app_fl/models/feed_state.dart';
import 'package:flutter_test/flutter_test.dart';

class TestItem {
  final String id;
  final String name;

  TestItem(this.id, this.name);
}

void main() {
  group('FeedState Unit Tests', () {
    test('初期状態のデフォルト値が正しいこと', () {
      const state = FeedState<TestItem>();
      expect(state.displayedItems, isEmpty);
      expect(state.latestItems, isEmpty);
      expect(state.newCount, 0);
      expect(state.isAtTop, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.hasError, isFalse);
      expect(state.error, isNull);
    });

    test('最上部（isAtTop == true）にいる場合、processNewItems で即座に画面へ反映されること', () {
      final items = [TestItem('1', 'Item 1'), TestItem('2', 'Item 2')];

      final state = FeedState.processNewItems<TestItem>(
        previousState: null,
        newItems: items,
        idGetter: (i) => i.id,
        isLoading: false,
        hasError: false,
        error: null,
      );

      expect(state.displayedItems.length, 2);
      expect(state.latestItems.length, 2);
      expect(state.newCount, 0);
      expect(state.isAtTop, isTrue);
    });

    test('スクロール中（isAtTop == false）の場合、processNewItems で新着件数のみ加算され、画面表示は維持されること', () {
      final initialItems = [TestItem('1', 'Item 1')];
      final prevState = FeedState<TestItem>(
        displayedItems: initialItems,
        latestItems: initialItems,
        isAtTop: false,
      );

      final updatedItems = [
        TestItem('2', 'Item 2'), // 新着
        TestItem('1', 'Item 1'),
      ];

      final state = FeedState.processNewItems<TestItem>(
        previousState: prevState,
        newItems: updatedItems,
        idGetter: (i) => i.id,
        isLoading: false,
        hasError: false,
        error: null,
      );

      // 表示は1件のまま維持
      expect(state.displayedItems.length, 1);
      expect(state.displayedItems.first.id, '1');
      // 最新は2件
      expect(state.latestItems.length, 2);
      // 新着件数は1
      expect(state.newCount, 1);
      expect(state.isAtTop, isFalse);
    });

    test('onScrollPositionChanged で最上部に戻った場合、未反映の新着がリストへ反映されること', () {
      final displayed = [TestItem('1', 'Item 1')];
      final latest = [TestItem('2', 'Item 2'), TestItem('1', 'Item 1')];
      final stateWithNew = FeedState<TestItem>(
        displayedItems: displayed,
        latestItems: latest,
        newCount: 1,
        isAtTop: false,
      );

      final atTopState = stateWithNew.onScrollPositionChanged(isAtTop: true);

      expect(atTopState.displayedItems.length, 2);
      expect(atTopState.newCount, 0);
      expect(atTopState.isAtTop, isTrue);
    });

    test('refreshToLatest で即座に最新アイテムが画面に反映されること', () {
      final displayed = [TestItem('1', 'Item 1')];
      final latest = [TestItem('2', 'Item 2'), TestItem('1', 'Item 1')];
      final stateWithNew = FeedState<TestItem>(
        displayedItems: displayed,
        latestItems: latest,
        newCount: 1,
        isAtTop: false,
      );

      final refreshed = stateWithNew.refreshToLatest();

      expect(refreshed.displayedItems.length, 2);
      expect(refreshed.newCount, 0);
      expect(refreshed.isAtTop, isFalse); // スクロール位置フラグは維持
    });
  });
}
