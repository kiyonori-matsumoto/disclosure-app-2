import 'package:disclosure_app_fl/widgets/banner_ad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BannerAdWidget', () {
    testWidgets('renders empty SizedBox when ad is not loaded',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            bottomNavigationBar: BannerAdWidget(),
          ),
        ),
      );

      // 初期状態では未ロードのため SizedBox.shrink() がレンダリングされる
      expect(find.byType(BannerAdWidget), findsOneWidget);
      expect(find.byType(SizedBox), findsWidgets);
    });
  });

  group('WithBannerAdWidget', () {
    testWidgets('renders child widget and banner ad widget in Column',
        (WidgetTester tester) async {
      const childKey = Key('child_widget');
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WithBannerAdWidget(
              child: Text('Hello Child', key: childKey),
            ),
          ),
        ),
      );

      expect(find.byKey(childKey), findsOneWidget);
      expect(find.byType(BannerAdWidget), findsOneWidget);
      expect(find.byType(Column), findsOneWidget);
    });
  });
}
