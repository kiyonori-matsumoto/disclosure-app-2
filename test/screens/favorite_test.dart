import 'package:disclosure_app_fl/models/company.dart';
import 'package:disclosure_app_fl/providers/favorites_provider.dart';
import 'package:disclosure_app_fl/providers/user_settings_provider.dart';
import 'package:disclosure_app_fl/screens/favorite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

    expect(mockAction.removed, ['7203']);
    expect(find.text('削除しました'), findsOneWidget);
    expect(find.text('取り消す'), findsOneWidget);

    // 「取り消す」をタップ
    await tester.tap(find.text('取り消す'));
    await tester.pumpAndSettle();

    expect(mockAction.added, ['7203']);
  });
}

class MockFavoritesAction extends FavoritesAction {
  final List<String> added = [];
  final List<String> removed = [];

  @override
  void build() {}

  @override
  Future<void> add(String code) async {
    added.add(code);
  }

  @override
  Future<void> remove(String code) async {
    removed.add(code);
  }
}
