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
}
