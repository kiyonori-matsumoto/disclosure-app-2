import 'package:disclosure_app_fl/models/edinet.dart';
import 'package:disclosure_app_fl/widgets/edinet_streaming.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ja');
  });

  group('EdinetListItem widget test', () {
    testWidgets('renders safely even with null fields',
        (WidgetTester tester) async {
      final edinet = Edinet(
        docDescription: null,
        docId: null,
        time: null,
        docTypeCode: '120',
        filerName: 'テスト会社',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EdinetListItem(edinet: edinet),
          ),
        ),
      );

      expect(find.byType(EdinetListItem), findsOneWidget);
      expect(find.text('有価証券報告書 | '), findsOneWidget);
    });

    testWidgets('renders correct content when fields are provided',
        (WidgetTester tester) async {
      final edinet = Edinet(
        docDescription: '有価証券報告書の提出',
        docId: 'S100TEST',
        time: 1700000000000,
        docTypeCode: '120',
        filerName: 'テスト株式会社',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EdinetListItem(edinet: edinet),
          ),
        ),
      );

      expect(find.text('有価証券報告書の提出'), findsOneWidget);
      expect(find.text('テスト株式会社'), findsOneWidget);
    });
  });
}
