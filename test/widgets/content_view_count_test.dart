import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:disclosure_app_fl/widgets/content_view_count.dart';

void main() {
  testWidgets('ContentViewCount renders empty SizedBox when viewCount is null',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ContentViewCount(viewCount: null),
        ),
      ),
    );

    expect(find.byType(SizedBox), findsOneWidget);
    expect(find.byIcon(Icons.cloud_download), findsNothing);
  });

  testWidgets('ContentViewCount renders empty SizedBox when viewCount is 0',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ContentViewCount(viewCount: 0),
        ),
      ),
    );

    expect(find.byType(SizedBox), findsOneWidget);
    expect(find.byIcon(Icons.cloud_download), findsNothing);
  });

  testWidgets('ContentViewCount renders icon and count text when viewCount > 0',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ContentViewCount(viewCount: 42),
        ),
      ),
    );

    expect(find.byIcon(Icons.cloud_download), findsOneWidget);
    expect(find.text('42 | '), findsOneWidget);
  });
}
