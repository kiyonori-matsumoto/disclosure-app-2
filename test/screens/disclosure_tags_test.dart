import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:disclosure_app_fl/providers/auth_provider.dart';
import 'package:disclosure_app_fl/providers/company_disclosures_provider.dart';
import 'package:disclosure_app_fl/providers/company_provider.dart';
import 'package:disclosure_app_fl/providers/favorites_provider.dart';
import 'package:disclosure_app_fl/providers/saved_disclosures_provider.dart';
import 'package:disclosure_app_fl/providers/tag_disclosures_provider.dart';
import 'package:disclosure_app_fl/screens/disclosure_tags.dart';
import 'package:disclosure_app_fl/widgets/disclosure_list_item.dart';
import 'package:disclosure_app_fl/widgets/no_disclosures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class MockUser extends Fake implements User {
  @override
  String get uid => 'test_uid_tags';
}

// ignore: subtype_of_sealed_class
class FakeDocumentSnapshot extends Fake
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  final Map<String, dynamic> _data;
  final String _id;

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

Widget createTestWidget({
  required String tag,
  List overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      currentUserProvider.overrideWith((ref) => MockUser()),
      companyCodeMapProvider.overrideWith((ref) => {}),
      savedDisclosuresStreamProvider.overrideWith((ref) => Stream.value([])),
      favoritesProvider.overrideWith((ref) => []),
      ...overrides.cast(),
    ],
    child: MaterialApp(
      home: DisclosureTagsScreen(tag: tag),
    ),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ja');
  });

  group('DisclosureTagsScreen Widget Tests', () {
    testWidgets('ローディング中は LinearProgressIndicator が表示される', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          tag: '決算',
          overrides: [
            tagDisclosuresProvider('決算')
                .overrideWith(() => _MockTagDisclosuresAsync(const AsyncLoading())),
          ],
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('決算の通知履歴'), findsOneWidget);
    });

    testWidgets('データが0件の場合は NoDisclosures が表示される', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          tag: '決算',
          overrides: [
            tagDisclosuresProvider('決算').overrideWith(() =>
                _MockTagDisclosuresAsync(const AsyncData(PaginatedDisclosuresState(
                  docs: [],
                  hasMore: false,
                )))),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NoDisclosures), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('エラー時はエラーメッセージが表示される', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          tag: '決算',
          overrides: [
            tagDisclosuresProvider('決算').overrideWith(() =>
                _MockTagDisclosuresAsync(
                    AsyncError('取得エラーが発生しました', StackTrace.empty))),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('取得エラーが発生しました'), findsOneWidget);
      expect(find.byIcon(Icons.event_busy), findsOneWidget);
    });

    testWidgets('データが存在する場合、開示情報カード一覧が表示される', (tester) async {
      final doc1 = FakeDocumentSnapshot('doc1', {
        'title': '2026年3月期 決算短信',
        'code': '7203',
        'company': 'トヨタ自動車',
        'time': 1730000000000,
        'view_count': 10,
        'tags': {'決算': true},
      });
      final doc2 = FakeDocumentSnapshot('doc2', {
        'title': '業績予想の修正に関するお知らせ',
        'code': '6758',
        'company': 'ソニーグループ',
        'time': 1730000000000,
        'view_count': 5,
        'tags': {'決算': true, '業績予想': true},
      });

      await tester.pumpWidget(
        createTestWidget(
          tag: '決算',
          overrides: [
            tagDisclosuresProvider('決算').overrideWith(() =>
                _MockTagDisclosuresAsync(AsyncData(PaginatedDisclosuresState(
                  docs: [doc1, doc2],
                  hasMore: false,
                )))),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2026年3月期 決算短信'), findsOneWidget);
      expect(find.text('業績予想の修正に関するお知らせ'), findsOneWidget);
      expect(find.byType(DisclosureListItem), findsNWidgets(2));
      expect(find.text('更に読み込む'), findsNothing); // hasMore: false
    });

    testWidgets('hasMore: true の場合は「更に読み込む」ボタンが表示される', (tester) async {
      final doc1 = FakeDocumentSnapshot('doc1', {
        'title': '開示テスト1',
        'code': '7203',
        'company': 'トヨタ自動車',
        'time': 1730000000000,
        'view_count': 1,
      });

      await tester.pumpWidget(
        createTestWidget(
          tag: '配当',
          overrides: [
            tagDisclosuresProvider('配当').overrideWith(() =>
                _MockTagDisclosuresAsync(AsyncData(PaginatedDisclosuresState(
                  docs: [doc1],
                  hasMore: true,
                )))),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('更に読み込む'), findsOneWidget);
    });

    testWidgets('isLoadingMore: true の場合はプログレスインジケータが表示されボタンが無効化される',
        (tester) async {
      final doc1 = FakeDocumentSnapshot('doc1', {
        'title': '開示テスト1',
        'code': '7203',
        'company': 'トヨタ自動車',
        'time': 1730000000000,
        'view_count': 1,
      });

      await tester.pumpWidget(
        createTestWidget(
          tag: '配当',
          overrides: [
            tagDisclosuresProvider('配当').overrideWith(() =>
                _MockTagDisclosuresAsync(AsyncData(PaginatedDisclosuresState(
                  docs: [doc1],
                  hasMore: true,
                  isLoadingMore: true,
                )))),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('更に読み込む'), findsNothing);
    });

    testWidgets('Pull-to-refresh で再読み込みができること', (tester) async {
      final doc1 = FakeDocumentSnapshot('doc1', {
        'title': '開示テスト1',
        'code': '7203',
        'company': 'トヨタ自動車',
        'time': 1730000000000,
        'view_count': 1,
        'tags': {'配当': true},
      });

      await tester.pumpWidget(
        createTestWidget(
          tag: '配当',
          overrides: [
            tagDisclosuresProvider('配当').overrideWith(() =>
                _MockTagDisclosuresAsync(AsyncData(PaginatedDisclosuresState(
                  docs: [doc1],
                  hasMore: false,
                )))),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RefreshIndicator), findsOneWidget);

      // 下へスワイプして Pull-to-refresh をトリガー
      await tester.fling(find.text('開示テスト1'), const Offset(0.0, 300.0), 1000.0);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('開示テスト1'), findsOneWidget);
    });
  });
}

class _MockTagDisclosuresAsync extends TagDisclosures {
  final AsyncValue<PaginatedDisclosuresState> _value;
  _MockTagDisclosuresAsync(this._value);

  @override
  Future<PaginatedDisclosuresState> build(String tag) async {
    return _value.when(
      data: (d) => d,
      error: (e, st) => throw e,
      loading: () => Completer<PaginatedDisclosuresState>().future,
    );
  }
}
