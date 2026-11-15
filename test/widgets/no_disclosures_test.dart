import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:disclosure_app_fl/widgets/no_disclosures.dart';

void main() {
  testWidgets('NoDisclosures renders empty state text',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NoDisclosures(),
        ),
      ),
    );

    expect(find.text("選択した条件の適時開示は0件です"), findsOneWidget);
  });

  testWidgets('NoDisclosures.emptyFavorites renders message and navigates to /companies',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/companies': (_) => const Scaffold(body: Text('CompaniesRoute')),
        },
        home: Scaffold(
          body: Builder(
            builder: (context) => NoDisclosures.emptyFavorites(context),
          ),
        ),
      ),
    );

    expect(find.text('お気に入りが0件です。\n銘柄をお気に入りに登録してください。'), findsOneWidget);
    expect(find.text('銘柄を検索して登録'), findsOneWidget);

    await tester.tap(find.text('銘柄を検索して登録'));
    await tester.pumpAndSettle();
    expect(find.text('CompaniesRoute'), findsOneWidget);
  });
}
