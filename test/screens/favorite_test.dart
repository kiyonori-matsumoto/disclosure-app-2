import 'package:disclosure_app_fl/models/company.dart';
import 'package:disclosure_app_fl/providers/auth_provider.dart';
import 'package:disclosure_app_fl/providers/company_provider.dart';
import 'package:disclosure_app_fl/providers/favorites_provider.dart';
import 'package:disclosure_app_fl/providers/user_settings_provider.dart';
import 'package:disclosure_app_fl/screens/favorite.dart';
import 'package:disclosure_app_fl/widgets/dismissible_delete_background.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockUser extends Fake implements User {
  @override
  String get uid => 'test_uid_123';
}

void main() {
  testWidgets('お気に入りが空の場合、「お気に入りはありません」が表示される',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userDocStreamProvider.overrideWith((ref) => Stream.value({})),
          favoritesWithCompanyProvider.overrideWithValue([]),
        ],
        child: const MaterialApp(
          home: FavoriteScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('お気に入りはありません'), findsOneWidget);
    expect(find.text('検索して追加'), findsOneWidget);
  });

  testWidgets('お気に入りが存在する場合、企業一覧が表示される',
      (WidgetTester tester) async {
    final testCompanies = [
      Company('7203', name: 'トヨタ自動車'),
      Company('6758', name: 'ソニーグループ'),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userDocStreamProvider.overrideWith((ref) => Stream.value({
                'favorites': ['7203', '6758'],
              })),
          favoritesWithCompanyProvider.overrideWithValue(testCompanies),
        ],
        child: const MaterialApp(
          home: FavoriteScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('7203 トヨタ自動車'), findsOneWidget);
    expect(find.text('6758 ソニーグループ'), findsOneWidget);

    final dismissibles =
        tester.widgetList<Dismissible>(find.byType(Dismissible));
    for (final dismissible in dismissibles) {
      expect(dismissible.background, isA<DismissibleDeleteBackground>());
      expect(dismissible.secondaryBackground,
          isA<DismissibleDeleteBackground>());
    }
  });

  testWidgets('アイテムをスワイプ削除後、SnackBarの「取り消す」をタップして復元できる',
      (WidgetTester tester) async {
    final testCompanies = [
      Company('7203', name: 'トヨタ自動車'),
    ];

    final mockAction = MockFavoritesAction();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => MockUser()),
          userDocStreamProvider.overrideWith((ref) => Stream.value({
                'favorites': ['7203'],
              })),
          favoritesWithCompanyProvider.overrideWithValue(testCompanies),
          favoritesActionProvider.overrideWith(() => mockAction),
        ],
        child: const MaterialApp(
          home: FavoriteScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // スワイプして削除
    await tester.drag(find.text('7203 トヨタ自動車'), const Offset(-500.0, 0.0));
    await tester.pumpAndSettle();

    expect(mockAction.removed, [('test_uid_123', '7203')]);
    expect(find.text('削除しました'), findsOneWidget);
    expect(find.text('取り消す'), findsOneWidget);

    // 「取り消す」をタップ
    await tester.tap(find.text('取り消す'));
    await tester.pumpAndSettle();

    expect(mockAction.added, [('test_uid_123', '7203')]);
  });

  testWidgets('AppBarの並び替えメニューからソート順を切り替えられる',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final mockCodeMap = {
      '7203': Company('7203', name: 'トヨタ自動車', nameKana: 'トヨタジドウシャ'),
      '6758': Company('6758', name: 'ソニーグループ', nameKana: 'ソニーグループ'),
    };

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userDocStreamProvider.overrideWith((ref) => Stream.value({
                'favorites': ['7203', '6758'],
              })),
          companyCodeMapProvider.overrideWithValue(mockCodeMap),
        ],
        child: const MaterialApp(
          home: FavoriteScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // デフォルトは証券コード昇順 (6758 -> 7203)
    var tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
    expect((tiles[0].title as Text).data, '6758 ソニーグループ');
    expect((tiles[1].title as Text).data, '7203 トヨタ自動車');

    // 並び替えメニューを開き「登録順」を選択（デフォルトの証券コード昇順にチェックがある）
    await tester.tap(find.byIcon(Icons.sort));
    await tester.pumpAndSettle();
    final defaultItem = tester.widget<CheckedPopupMenuItem<FavoriteSortOrder>>(
      find.widgetWithText(
        CheckedPopupMenuItem<FavoriteSortOrder>,
        FavoriteSortOrder.codeAsc.label,
      ),
    );
    expect(defaultItem.checked, isTrue);

    await tester.tap(
      find.widgetWithText(
        CheckedPopupMenuItem<FavoriteSortOrder>,
        FavoriteSortOrder.registered.label,
      ),
    );
    await tester.pumpAndSettle();

    // 登録順 (7203 -> 6758) に切り替わる
    tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
    expect((tiles[0].title as Text).data, '7203 トヨタ自動車');
    expect((tiles[1].title as Text).data, '6758 ソニーグループ');

    // 「証券コード順（降順）」に切り替え
    await tester.tap(find.byIcon(Icons.sort));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(
        CheckedPopupMenuItem<FavoriteSortOrder>,
        FavoriteSortOrder.codeDesc.label,
      ),
    );
    await tester.pumpAndSettle();

    tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
    expect((tiles[0].title as Text).data, '7203 トヨタ自動車');
    expect((tiles[1].title as Text).data, '6758 ソニーグループ');

    // 「企業名順」に切り替え (ソニーグループ -> トヨタ自動車)
    await tester.tap(find.byIcon(Icons.sort));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(
        CheckedPopupMenuItem<FavoriteSortOrder>,
        FavoriteSortOrder.nameAsc.label,
      ),
    );
    await tester.pumpAndSettle();

    tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
    expect((tiles[0].title as Text).data, '6758 ソニーグループ');
    expect((tiles[1].title as Text).data, '7203 トヨタ自動車');
  });
}

class MockFavoritesAction extends FavoritesAction {
  final List<(String, String)> added = [];
  final List<(String, String)> removed = [];

  @override
  void build() {}

  @override
  Future<void> add(String uid, String code) async {
    added.add((uid, code));
  }

  @override
  Future<void> remove(String uid, String code) async {
    removed.add((uid, code));
  }
}
