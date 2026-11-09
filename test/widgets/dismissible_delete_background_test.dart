import 'package:disclosure_app_fl/app.dart';
import 'package:disclosure_app_fl/widgets/dismissible_delete_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DismissibleDeleteBackground Tests', () {
    testWidgets('デフォルトで右揃えかつテーマの errorContainer / onErrorContainer を反映する',
        (tester) async {
      final theme = buildLightTheme();

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(
            body: DismissibleDeleteBackground(),
          ),
        ),
      );

      final containerFinder = find.byType(Container);
      expect(containerFinder, findsOneWidget);
      final container = tester.widget<Container>(containerFinder);
      expect(container.color, theme.colorScheme.errorContainer);
      expect(container.alignment, Alignment.centerRight);

      final iconFinder = find.byIcon(Icons.delete_outline);
      expect(iconFinder, findsOneWidget);
      final icon = tester.widget<Icon>(iconFinder);
      expect(icon.color, theme.colorScheme.onErrorContainer);
    });

    testWidgets('DismissibleDeleteBackground.left で左揃えになること', (tester) async {
      final theme = buildDarkTheme();

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(
            body: DismissibleDeleteBackground.left(),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      expect(container.color, theme.colorScheme.errorContainer);
      expect(container.alignment, Alignment.centerLeft);

      final icon = tester.widget<Icon>(find.byIcon(Icons.delete_outline));
      expect(icon.color, theme.colorScheme.onErrorContainer);
    });
  });
}
