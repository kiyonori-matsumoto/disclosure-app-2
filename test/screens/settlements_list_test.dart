import 'dart:async';

import 'package:disclosure_app_fl/models/company.dart';
import 'package:disclosure_app_fl/models/company_settlement.dart';
import 'package:disclosure_app_fl/providers/company_provider.dart';
import 'package:disclosure_app_fl/providers/settlements_provider.dart';
import 'package:disclosure_app_fl/screens/settlements_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

Widget createTestWidget({
  List overrides = const [],
  NavigatorObserver? navigatorObserver,
}) {
  return ProviderScope(
    overrides: [
      companyCodeMapProvider.overrideWith((ref) => {
            '7203': Company('7203', name: 'トヨタ自動車'),
          }),
      ...overrides.cast(),
    ],
    child: MaterialApp(
      home: const SettlementsList(),
      navigatorObservers: [
        if (navigatorObserver != null) navigatorObserver,
      ],
      onGenerateRoute: (settings) {
        if (settings.name == '/company-disclosures') {
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => Scaffold(
              body: Text('Company: ${(settings.arguments as Company).name}'),
            ),
          );
        }
        return null;
      },
    ),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ja', null);
  });

  group('SettlementsList Widget Tests', () {
    testWidgets('ローディング中は LinearProgressIndicator が表示される', (tester) async {
      final completer = Completer<List<CompanySettlement>>();
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            currentSettlementsListProvider
                .overrideWith((ref) => completer.future),
          ],
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('決算予定が0件の場合は「指定された日の決算予定はありません」が表示される',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            currentSettlementsListProvider
                .overrideWith((ref) => Future.value([])),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.text('指定された日の決算予定はありません'), findsOneWidget);
      final announcementIcon =
          tester.widget<Icon>(find.byIcon(Icons.announcement));
      final theme = Theme.of(tester.element(find.byType(SettlementsList)));
      expect(announcementIcon.color, equals(theme.colorScheme.primary));
      expect(announcementIcon.color, isNot(equals(theme.colorScheme.surface)));
    });

    testWidgets('決算予定データが存在する場合、リストアイテムが表示される', (tester) async {
      final item1 = CompanySettlement(
        code: '7203',
        name: 'トヨタ自動車',
        quote: '本決算',
      );
      final item2 = CompanySettlement(
        code: '6758',
        name: 'ソニーグループ',
        quote: '',
      );

      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            currentSettlementsListProvider
                .overrideWith((ref) => Future.value([item1, item2])),
          ],
        ),
      );
      await tester.pump();

      expect(find.text('トヨタ自動車 (本決算)'), findsOneWidget);
      expect(find.text('ソニーグループ'), findsOneWidget);
      expect(find.text('指定された日の決算予定はありません'), findsNothing);
    });

    testWidgets('アイテムをタップすると /company-disclosures へ正しい引数で遷移する',
        (tester) async {
      final item = CompanySettlement(
        code: '7203',
        name: 'トヨタ自動車',
        quote: '本決算',
      );

      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            currentSettlementsListProvider
                .overrideWith((ref) => Future.value([item])),
          ],
        ),
      );
      await tester.pump();

      // トヨタ自動車をタップ
      await tester.tap(find.text('トヨタ自動車 (本決算)'));
      await tester.pumpAndSettle();

      // 遷移先の画面が表示されていること
      expect(find.text('Company: トヨタ自動車'), findsOneWidget);
    });

    testWidgets('カレンダー FAB をタップすると日付ピッカーが表示される', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            currentSettlementsListProvider
                .overrideWith((ref) => Future.value([])),
          ],
        ),
      );
      await tester.pump();

      // FAB をタップ
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // DatePickerDialog が表示される
      expect(find.byType(DatePickerDialog), findsOneWidget);
    });
  });
}
