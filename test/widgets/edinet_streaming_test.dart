import 'package:disclosure_app_fl/models/company.dart';
import 'package:disclosure_app_fl/models/edinet.dart';
import 'package:disclosure_app_fl/providers/edinet_disclosures_provider.dart';
import 'package:disclosure_app_fl/widgets/edinet_streaming.dart';
import 'package:disclosure_app_fl/widgets/no_disclosures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

Widget createTestWidget({
  required AsyncValue<List<Edinet>> asyncValue,
}) {
  return ProviderScope(
    overrides: [
      filteredEdinetsProvider.overrideWithValue(asyncValue),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: CustomScrollView(
          slivers: const [
            EdinetStreamingWidget(),
          ],
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ja');
  });

  group('EdinetStreamingWidget Tests', () {
    testWidgets('ローディング中は LinearProgressIndicator が表示されること',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(asyncValue: const AsyncLoading()),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('データが0件の時は NoDisclosures が表示されること', (tester) async {
      await tester.pumpWidget(
        createTestWidget(asyncValue: const AsyncData([])),
      );

      expect(find.byType(NoDisclosures), findsOneWidget);
    });

    testWidgets('エラー時はエラーメッセージが表示されること', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          asyncValue: AsyncError('Firestore connection error', StackTrace.empty),
        ),
      );

      expect(find.text('Firestore connection error'), findsOneWidget);
      expect(find.byIcon(Icons.event_busy), findsOneWidget);
    });

    testWidgets('データが存在する時は EdinetListItem がリスト表示されること', (tester) async {
      final edinet1 = Edinet(
        docId: 'doc1',
        docDescription: '有価証券報告書（第10期）',
        docTypeCode: '120',
        filerName: 'テスト株式会社',
        filer: Company('9999', name: 'テスト株式会社'),
        time: 1600000000000,
        viewCount: 15,
      );
      final edinet2 = Edinet(
        docId: 'doc2',
        docDescription: '四半期報告書（第3四半期）',
        docTypeCode: '140',
        filerName: 'サンプルホールディングス',
        filer: Company('8888', name: 'サンプルホールディングス'),
        time: 1600000000000,
        viewCount: 3,
      );

      await tester.pumpWidget(
        createTestWidget(asyncValue: AsyncData([edinet1, edinet2])),
      );

      expect(find.text('有価証券報告書（第10期）'), findsOneWidget);
      expect(find.text('四半期報告書（第3四半期）'), findsOneWidget);
      expect(find.text('有価証券報告書 | '), findsOneWidget);
      expect(find.text('四半期報告書 | '), findsOneWidget);
      expect(find.byType(EdinetListItem), findsNWidgets(2));
    });

    testWidgets('関連企業が存在する場合、長押しで企業選択ポップアップが表示されること', (tester) async {
      final company1 = Company('9999', name: 'テスト株式会社');
      final edinet = Edinet(
        docId: 'doc1',
        docDescription: '大量保有報告書',
        docTypeCode: '350',
        filerName: 'テスト提出者',
        filer: company1,
        time: 1600000000000,
        viewCount: 0,
      );

      await tester.pumpWidget(
        createTestWidget(asyncValue: AsyncData([edinet])),
      );

      // ListTile を長押し
      await tester.longPress(find.text('大量保有報告書'));
      await tester.pumpAndSettle();

      // ポップアップメニュー内に企業名が表示されていること
      expect(find.text('テスト株式会社'), findsOneWidget); // メニュー項目
    });
  });
}
