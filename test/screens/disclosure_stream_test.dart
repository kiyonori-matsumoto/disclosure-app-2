import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' hide Filter;
import 'package:disclosure_app_fl/models/edinet.dart';
import 'package:disclosure_app_fl/models/feed_state.dart';
import 'package:disclosure_app_fl/providers/auth_provider.dart';
import 'package:disclosure_app_fl/providers/company_provider.dart';
import 'package:disclosure_app_fl/providers/disclosures_provider.dart';
import 'package:disclosure_app_fl/providers/edinet_disclosures_provider.dart';
import 'package:disclosure_app_fl/providers/favorites_provider.dart';
import 'package:disclosure_app_fl/providers/saved_disclosures_provider.dart';
import 'package:disclosure_app_fl/screens/disclosure_stream.dart';
import 'package:disclosure_app_fl/widgets/no_disclosures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class MockUser extends Fake implements User {
  @override
  String get uid => 'test_uid_stream';
}

// ignore: subtype_of_sealed_class
class FakeDocumentSnapshot extends Fake
    implements DocumentSnapshot<Map<String, dynamic>> {
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
    child: const MaterialApp(
      home: DisclosureStreamScreen(),
    ),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ja', null);
  });

  group('DisclosureStreamScreen Widget Tests', () {
    testWidgets('ローディング中は LinearProgressIndicator が表示される', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            filteredDisclosuresProvider
                .overrideWith((ref) => const AsyncLoading()),
          ],
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.byType(NoDisclosures), findsNothing);
    });

    testWidgets('開示データが0件の場合は NoDisclosures が表示される', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            filteredDisclosuresProvider
                .overrideWith((ref) => const AsyncData([])),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.byType(NoDisclosures), findsOneWidget);
    });

    testWidgets('開示データが存在する場合、開示情報カードが一覧表示される', (tester) async {
      final doc1 = FakeDocumentSnapshot('doc1', {
        'title': 'テスト適時開示 2026',
        'code': '7203',
        'company': 'トヨタ自動車',
        'time': 1730700000000,
        'view_count': 42,
      });

      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            filteredDisclosuresProvider
                .overrideWith((ref) => AsyncData([doc1])),
          ],
        ),
      );
      await tester.pump();

      expect(find.text('テスト適時開示 2026'), findsOneWidget);
      expect(find.byType(NoDisclosures), findsNothing);
    });

    testWidgets('ツールバーのソートChipをタップするとソート順が切り替わる', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            filteredDisclosuresProvider
                .overrideWith((ref) => const AsyncData([])),
          ],
        ),
      );
      await tester.pump();

      // 初期値は "最新"
      expect(find.text('最新'), findsOneWidget);

      // ソートChipをタップ
      await tester.tap(find.text('最新'), warnIfMissed: false);
      await tester.pump();

      // "閲覧回数" に切り替わる
      expect(find.text('閲覧回数'), findsOneWidget);
    });

    testWidgets('ツールバーのフィルタChipをタップするとフィルタダイアログが表示される', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            filteredDisclosuresProvider
                .overrideWith((ref) => const AsyncData([])),
          ],
        ),
      );
      await tester.pump();

      // 初期フィルタカウント '0' のChipをタップ
      await tester.tap(find.widgetWithText(ChoiceChip, '0'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // フィルタダイアログが表示され、デフォルトタグ（決算、配当等）が並んでいる
      expect(find.text('filter'), findsOneWidget);
      expect(find.text('決算'), findsOneWidget);
      expect(find.text('配当'), findsOneWidget);

      // '決算' をタップして選択
      await tester.tap(find.text('決算'));
      await tester.pumpAndSettle();

      // ダイアログ外をタップして閉じる
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // フィルタカウントが '1' に更新されている
      expect(find.widgetWithText(ChoiceChip, '1'), findsOneWidget);
    });

    testWidgets('ツールバーのお気に入りのみ表示Chipをタップするとトグルされる', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            filteredDisclosuresProvider
                .overrideWith((ref) => const AsyncData([])),
          ],
        ),
      );
      await tester.pump();

      final chipFinder = find.widgetWithText(ChoiceChip, 'お気に入りのみ表示する');
      expect(chipFinder, findsOneWidget);

      ChoiceChip chip = tester.widget<ChoiceChip>(chipFinder);
      expect(chip.selected, isFalse);

      await tester.tap(chipFinder);
      await tester.pump();

      chip = tester.widget<ChoiceChip>(chipFinder);
      expect(chip.selected, isTrue);
    });

    testWidgets('新着件数が0の場合は FAB が表示されない', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            filteredDisclosuresProvider
                .overrideWith((ref) => const AsyncData([])),
            pendingNewDisclosureCountProvider.overrideWith((ref) => 0),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('お気に入りが0件の時にお気に入りのみ表示ChipをタップするとSnackBarが表示される', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            filteredDisclosuresProvider
                .overrideWith((ref) => const AsyncData([])),
          ],
        ),
      );
      await tester.pump();

      final chipFinder = find.widgetWithText(ChoiceChip, 'お気に入りのみ表示する');
      await tester.tap(chipFinder);
      await tester.pump();

      expect(find.text('お気に入りに登録されている銘柄がありません'), findsOneWidget);
    });

    testWidgets('新着件数が1件以上の場合は「N NEW MESSAGE」FAB が表示される', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            filteredDisclosuresProvider
                .overrideWith((ref) => const AsyncData([])),
            pendingNewDisclosureCountProvider.overrideWith((ref) => 3),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('3 NEW MESSAGE'), findsOneWidget);
    });

    testWidgets('リアルタイムストリーム連動: 最上部にいる時は自動反映、スクロール中はFAB表示＆タップで反映される', (tester) async {
      final streamController =
          StreamController<List<DocumentSnapshot<Map<String, dynamic>>>>.broadcast();
      addTearDown(streamController.close);

      final targetDate = DateTime(2026, 11, 5);

      final doc1 = FakeDocumentSnapshot('doc1', {
        'title': '開示1号',
        'code': '7203',
        'company': 'トヨタ自動車',
        'time': 1000,
      });

      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            selectedDateProvider.overrideWith(() => _TestSelectedDate(targetDate)),
            disclosuresRawStreamProvider(targetDate)
                .overrideWith((ref) => streamController.stream),
          ],
        ),
      );

      // 初回データをストリームに流す
      streamController.add([doc1]);
      await tester.pumpAndSettle();

      // 開示1が表示されている
      expect(find.text('開示1号'), findsOneWidget);
      // 最上部にいるので FAB は非表示
      expect(find.byType(FloatingActionButton), findsNothing);

      // 最上部のまま新着 doc2 が届く -> 即座に自動反映
      final doc2 = FakeDocumentSnapshot('doc2', {
        'title': '開示2号(最新)',
        'code': '6758',
        'company': 'ソニー',
        'time': 2000,
      });
      streamController.add([doc2, doc1]);
      await tester.pumpAndSettle();

      expect(find.text('開示2号(最新)'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('EDINET に切り替えると EDINET ツールバーが表示され、書類種別Chipタップでダイアログが開く',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            filteredDisclosuresProvider
                .overrideWith((ref) => const AsyncData([])),
            filteredEdinetsProvider
                .overrideWith((ref) => const AsyncData([])),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // EDINET に切り替え
      await tester.tap(find.text('EDINET'));
      await tester.pumpAndSettle();

      // EDINET ツールバーの書類種別 Chip（初期表示:「なし」）が表示されていること
      final chipFinder = find.ancestor(
        of: find.text('なし'),
        matching: find.byType(ChoiceChip),
      );
      expect(chipFinder, findsOneWidget);

      // 書類種別 Chip をタップ
      await tester.tap(chipFinder);
      await tester.pumpAndSettle();

      // フィルタダイアログが開いていること
      expect(find.byType(SimpleDialog), findsOneWidget);
      expect(find.text('大量保有報告書'), findsOneWidget);

      // ダイアログを閉じる
      Navigator.of(tester.element(find.byType(SimpleDialog))).pop();
      await tester.pumpAndSettle();
      expect(find.byType(SimpleDialog), findsNothing);
    });

    testWidgets('EDINET ツールバーでお気に入り0件時にお気に入りのみ表示ChipをタップするとSnackBarが表示される',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            filteredDisclosuresProvider
                .overrideWith((ref) => const AsyncData([])),
            filteredEdinetsProvider
                .overrideWith((ref) => const AsyncData([])),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // EDINET に切り替え
      await tester.tap(find.text('EDINET'));
      await tester.pumpAndSettle();

      // 「お気に入りのみ表示する」をタップ
      await tester.tap(find.text('お気に入りのみ表示する'));
      await tester.pump();

      // SnackBar が表示されること
      expect(find.text('お気に入りに登録されている銘柄がありません'), findsOneWidget);
    });

    testWidgets('EDINET 表示時に新着件数がある場合、「N NEW MESSAGE」FAB が表示される',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            filteredDisclosuresProvider
                .overrideWith((ref) => const AsyncData([])),
            filteredEdinetsProvider
                .overrideWith((ref) => const AsyncData([])),
            edinetFeedProvider.overrideWith(() => _MockEdinetFeed(
                  const FeedState<Edinet>(
                    newCount: 5,
                    isAtTop: false,
                  ),
                )),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // EDINET に切り替え
      await tester.tap(find.text('EDINET'));
      await tester.pumpAndSettle();

      // FAB が表示されていること
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('5 NEW MESSAGE'), findsOneWidget);
    });

    testWidgets('画面の横スワイプで TDNET から EDINET に切り替えられること',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            filteredDisclosuresProvider
                .overrideWith((ref) => const AsyncData([])),
            filteredEdinetsProvider
                .overrideWith((ref) => const AsyncData([])),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // 左へスワイプ（右側の EDINET 画面へフリング）
      await tester.fling(find.byType(TabBarView), const Offset(-500, 0), 2000);
      await tester.pumpAndSettle();

      // EDINET ツールバーの書類種別 Chip（初期表示:「なし」）が表示されていること
      final chipFinder = find.ancestor(
        of: find.text('なし'),
        matching: find.byType(ChoiceChip),
      );
      expect(chipFinder, findsOneWidget);
    });
  });
}

class _MockEdinetFeed extends EdinetFeed {
  final FeedState<Edinet> _initial;
  _MockEdinetFeed(this._initial);

  @override
  FeedState<Edinet> build() => _initial;
}

class _TestSelectedDate extends SelectedDate {
  final DateTime _initial;
  _TestSelectedDate(this._initial);

  @override
  DateTime build() => _initial;
}
