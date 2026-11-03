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
}
