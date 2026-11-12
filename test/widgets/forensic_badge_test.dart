import 'package:disclosure_app_fl/models/forensic_result.dart';
import 'package:disclosure_app_fl/widgets/forensic_badge.dart';
import 'package:disclosure_app_fl/widgets/forensic_detail_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ForensicBadge renders nothing for null forensic',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ForensicBadge(forensic: null),
        ),
      ),
    );
    expect(find.byType(GestureDetector), findsNothing);
  });

  testWidgets('ForensicBadge renders normal badge with sound indicator',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ForensicBadge(
            forensic: ForensicResult(riskLevel: ForensicRiskLevel.normal),
          ),
        ),
      ),
    );
    expect(find.text('✓ 通常'), findsOneWidget);
  });

  testWidgets('ForensicBadge renders critical badge with representative tag',
      (tester) async {
    const forensic = ForensicResult(
      riskLevel: ForensicRiskLevel.critical,
      tags: ['going_concern', 'negative_operating_cf'],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ForensicBadge(
            forensic: forensic,
            companyName: 'テスト株式会社',
            documentTitle: '決算短信',
          ),
        ),
      ),
    );

    // 代表タグ名 + 残り数 (+1) が表示されること
    expect(find.text('❗ 事業継続の重要疑義 +1'), findsOneWidget);
  });

  testWidgets('ForensicBadge renders critical badge with quantitative tag',
      (tester) async {
    const forensic = ForensicResult(
      riskLevel: ForensicRiskLevel.critical,
      tags: ['accruals_anomaly', 'liquidity_crunch', 'equity_erosion'],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ForensicBadge(
            forensic: forensic,
          ),
        ),
      ),
    );

    expect(find.text('❗ 総資産アクルーアル乖離 +2'), findsOneWidget);
  });

  testWidgets(
      'ForensicBadge displays critical icon when document is critical even if tag is warning-like',
      (tester) async {
    const forensic = ForensicResult(
      riskLevel: ForensicRiskLevel.critical,
      tags: ['inventory_receivable_surge'],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ForensicBadge(
            forensic: forensic,
          ),
        ),
      ),
    );

    // ⚠️ ではなく ❗ で表示されること
    expect(find.text('❗ 棚卸資産・売掛金急増'), findsOneWidget);
  });

  testWidgets('ForensicBadge renders warning badge with single tag',
      (tester) async {
    const forensic = ForensicResult(
      riskLevel: ForensicRiskLevel.warning,
      tags: ['negative_operating_cf'],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ForensicBadge(
            forensic: forensic,
          ),
        ),
      ),
    );

    expect(find.text('⚠️ 営業CFマイナス'), findsOneWidget);
  });

  testWidgets('ForensicBadge opens ForensicDetailSheet on tap',
      (tester) async {
    const forensic = ForensicResult(
      riskLevel: ForensicRiskLevel.critical,
      tags: ['going_concern'],
      metrics: ForensicMetrics(
        revenue: 1580000,
        operatingCashFlow: -280000,
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ForensicBadge(
            forensic: forensic,
            companyName: 'アクセルマーク (3624)',
            documentTitle: '有価証券報告書',
            enableAnimation: false,
          ),
        ),
      ),
    );

    // タップ前はシートは存在しない
    expect(find.byType(ForensicDetailSheet), findsNothing);

    // バッジをタップ
    await tester.tap(find.text('🚨 事業継続の重要疑義'));
    await tester.pumpAndSettle();

    // ボトムシートが開くこと
    expect(find.byType(ForensicDetailSheet), findsOneWidget);
    expect(find.text('定性・財務フォレンジック解析'), findsOneWidget);
    expect(find.text('アクセルマーク (3624)'), findsOneWidget);
  });

  testWidgets('ForensicBadge provides extended touch target for mis-tap prevention',
      (tester) async {
    const forensic = ForensicResult(
      riskLevel: ForensicRiskLevel.warning,
      tags: ['negative_operating_cf'],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ForensicBadge(
            forensic: forensic,
          ),
        ),
      ),
    );

    // InkWell の直下に拡張パディングが存在すること
    final inkWellFinder = find.byType(InkWell);
    expect(inkWellFinder, findsOneWidget);

    final paddingFinder = find.descendant(
      of: inkWellFinder,
      matching: find.byType(Padding),
    );
    expect(paddingFinder, findsWidgets);

    // クリッカブルであることを示す chevron_right アイコンが存在すること
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);

    // バッジの InkWell（拡張タッチ領域）をタップしてボトムシートが開くこと
    await tester.tap(inkWellFinder);
    await tester.pumpAndSettle();
    expect(find.byType(ForensicDetailSheet), findsOneWidget);
  });
}
