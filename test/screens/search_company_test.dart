import 'package:disclosure_app_fl/models/company.dart';
import 'package:disclosure_app_fl/providers/auth_provider.dart';
import 'package:disclosure_app_fl/providers/company_history_provider.dart';
import 'package:disclosure_app_fl/providers/company_provider.dart';
import 'package:disclosure_app_fl/providers/favorites_provider.dart';
import 'package:disclosure_app_fl/screens/search_company.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MockUser extends Fake implements User {
  @override
  String get uid => 'test_uid_search';
}

class MockCompanyHistoryAction extends CompanyHistoryAction {
  final List<(String, String)> added = [];

  @override
  void build() {}

  @override
  Future<void> add(
    String uid,
    String code, {
    List<String>? currentHistory,
  }) async {
    added.add((uid, code));
  }
}

class MockFavoritesAction extends FavoritesAction {
  final List<(String, String)> added = [];

  @override
  void build() {}

  @override
  Future<void> add(String uid, String code) async {
    added.add((uid, code));
  }
}

void main() {
  final testCompanies = [
    Company('7203', name: 'トヨタ自動車', nameKana: 'トヨタジドウシャ'),
    Company('6758', name: 'ソニーグループ', nameKana: 'ソニーグループ'),
  ];

  testWidgets('企業マスタダウンロード中にインジケータが表示される',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          companiesStreamProvider.overrideWith((ref) => const Stream.empty()),
        ],
        child: const MaterialApp(
          home: SearchCompanyScreen(),
        ),
      ),
    );

    expect(find.text('会社情報をダウンロード中です…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('検索欄が未入力の場合、検索履歴が表示される',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          companiesStreamProvider.overrideWith((ref) => Stream.value(testCompanies)),
          companyHistoryProvider.overrideWithValue([testCompanies.first]),
        ],
        child: const MaterialApp(
          home: SearchCompanyScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('トヨタ自動車'), findsOneWidget);
    expect(find.byIcon(Icons.history), findsOneWidget);
  });

  testWidgets('検索欄に2文字以上入力すると検索結果が表示される',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          companiesStreamProvider.overrideWith((ref) => Stream.value(testCompanies)),
          companyHistoryProvider.overrideWithValue([testCompanies.first]),
        ],
        child: const MaterialApp(
          home: SearchCompanyScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 検索窓に「ソニー」と入力
    await tester.enterText(find.byType(TextField), 'ソニー');
    await tester.pumpAndSettle();

    expect(find.text('ソニーグループ'), findsOneWidget);
    expect(find.text('トヨタ自動車'), findsNothing);
    expect(find.byIcon(Icons.history), findsNothing);
  });

  testWidgets('企業をタップすると履歴に追加される',
      (WidgetTester tester) async {
    final mockHistoryAction = MockCompanyHistoryAction();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => MockUser()),
          companiesStreamProvider.overrideWith((ref) => Stream.value(testCompanies)),
          companyHistoryProvider.overrideWithValue([testCompanies.first]),
          companyHistoryCodesProvider.overrideWithValue(['7203']),
          companyHistoryActionProvider.overrideWith(() => mockHistoryAction),
        ],
        child: MaterialApp(
          routes: {
            '/company-disclosures': (context) => const Scaffold(body: Text('個別企業画面')),
          },
          home: const SearchCompanyScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('トヨタ自動車'));
    await tester.pumpAndSettle();

    expect(mockHistoryAction.added, [('test_uid_search', '7203')]);
    expect(find.text('個別企業画面'), findsOneWidget);
  });

  testWidgets('ポップアップメニューからお気に入りに追加できる',
      (WidgetTester tester) async {
    final mockFavoritesAction = MockFavoritesAction();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => MockUser()),
          companiesStreamProvider.overrideWith((ref) => Stream.value(testCompanies)),
          companyHistoryProvider.overrideWithValue([testCompanies.first]),
          favoritesActionProvider.overrideWith(() => mockFavoritesAction),
        ],
        child: const MaterialApp(
          home: SearchCompanyScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // ポップアップメニューを開く
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    // 「お気に入りに追加」をタップ
    await tester.tap(find.text('お気に入りに追加'));
    await tester.pumpAndSettle();

    expect(mockFavoritesAction.added, [('test_uid_search', '7203')]);
    expect(find.text('トヨタ自動車をお気に入りに追加しました'), findsOneWidget);
  });
}
