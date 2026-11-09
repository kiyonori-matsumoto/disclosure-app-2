import 'package:disclosure_app_fl/widgets/disclosure_action_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('showItemActionSheet Tests', () {
    testWidgets('タイトル、サブタイトル、アイテムが正しく表示され、タップでonTapが発火すること',
        (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showItemActionSheet(
                    context: context,
                    title: 'テスト株式会社 (7203)',
                    subtitle: '2026年3月期 決算短信',
                    items: [
                      ActionSheetItem(
                        icon: Icons.bookmark_add_outlined,
                        title: '保存',
                        onTap: () {
                          tapped = true;
                        },
                      ),
                    ],
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      // シートを開く
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('テスト株式会社 (7203)'), findsOneWidget);
      expect(find.text('2026年3月期 決算短信'), findsOneWidget);
      expect(find.text('保存'), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_add_outlined), findsOneWidget);

      // アイテムをタップ
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
      // シートが閉じていること
      expect(find.text('テスト株式会社 (7203)'), findsNothing);
    });
  });
}
