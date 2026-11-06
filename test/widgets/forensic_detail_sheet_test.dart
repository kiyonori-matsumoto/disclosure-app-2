import 'package:disclosure_app_fl/models/forensic_result.dart';
import 'package:disclosure_app_fl/widgets/forensic_detail_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ForensicDetailSheet displays all sections correctly',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final forensic = ForensicResult(
      version: 1,
      analyzedAt: DateTime.fromMillisecondsSinceEpoch(1730642400 * 1000),
      riskLevel: ForensicRiskLevel.critical,
      tags: const ['going_concern', 'negative_operating_cf'],
      causes: const ['raw_material_energy', 'weak_sales_or_churn'],
      metrics: const ForensicMetrics(
        revenue: 1580000,
        operatingIncome: -120000,
        netIncome: -380000,
        operatingCashFlow: -280000,
      ),
      details: const ForensicDetails(
        blameAttribution: 'external_macro_dominant',
        unfoundedOptimism: true,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ForensicDetailSheet(
            forensic: forensic,
            companyName: 'アクセルマーク (3624)',
            documentTitle: '第31期 有価証券報告書',
          ),
        ),
      ),
    );

    // ヘッダー・企業情報
    expect(find.text('定性・財務フォレンジック診断'), findsOneWidget);
    expect(find.text('アクセルマーク (3624)'), findsOneWidget);
    expect(find.text('第31期 有価証券報告書'), findsOneWidget);

    // 総合判定見出し
    expect(find.text('CRITICAL (危険)'), findsOneWidget);
    expect(find.text('🚨 重大な財務・経営リスクを検知'), findsOneWidget);

    // 検出タグ
    expect(find.text('🚨 倒産危機サイン'), findsOneWidget);
    expect(find.text('⚠️ 本業の現金減少'), findsOneWidget);

    // 診断解説文
    expect(
      find.text(
        '事業を続けられるかどうかの重大な懸念（継続企業の前提の疑義）が出ています。また、本業の営業活動で現金がマイナス（流出状態）になっています。',
      ),
      findsOneWidget,
    );

    // 会社説明要因
    expect(find.text('原材料・光熱費高騰'), findsOneWidget);
    expect(find.text('顧客離れ'), findsOneWidget);

    // 主要財務メトリクス
    expect(find.text('売上高'), findsOneWidget);
    expect(find.text('15.8億円'), findsOneWidget);
    expect(find.text('営業利益'), findsOneWidget);
    expect(find.text('▲1.2億円'), findsOneWidget);
    expect(find.text('当期純利益'), findsOneWidget);
    expect(find.text('▲3.8億円'), findsOneWidget);
    expect(find.text('営業活動CF'), findsOneWidget);
    expect(find.text('▲2.8億円'), findsOneWidget);

    // 免責事項
    expect(find.textContaining('本診断は開示書類の定性情報および財務数値を機械的にクロス検証した参考情報です'), findsOneWidget);
  });
}
