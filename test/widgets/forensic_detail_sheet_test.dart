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
    expect(find.text('🚨 事業継続の重要疑義'), findsOneWidget);
    expect(find.text('⚠️ 営業CFマイナス'), findsOneWidget);

    // 診断解説文
    expect(
      find.text(
        '継続企業の前提に関する重要な疑義や不確実性に関する注記（GC注記）が記載されています。また、本業の営業活動によるキャッシュフローがマイナス（現金流出状態）となっています。',
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

    // AI判定基準・プロンプト設問の開示アコーディオン
    expect(find.text('AI 判定基準・プロンプト設問の開示'), findsOneWidget);
    await tester.tap(find.text('AI 判定基準・プロンプト設問の開示'));
    await tester.pumpAndSettle();
    expect(find.textContaining('継続企業の前提に関する注記・疑義'), findsOneWidget);

    // 免責事項
    expect(find.textContaining('特定の有価証券の価値評価や投資の勧誘・助言を目的としたものではありません'), findsOneWidget);
  });

  testWidgets('ForensicDetailSheet displays normal summary and metrics correctly',
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
      riskLevel: ForensicRiskLevel.normal,
      metrics: const ForensicMetrics(
        revenue: 45000000,
        operatingIncome: 4200000,
        operatingCashFlow: 3800000,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ForensicDetailSheet(
            forensic: forensic,
            companyName: '優良企業 (1234)',
            documentTitle: '決算短信',
          ),
        ),
      ),
    );

    expect(find.text('NORMAL (正常)'), findsOneWidget);
    expect(find.text('健全な開示内容'), findsOneWidget);
    expect(
      find.text('重大な財務リスクや特異な定性トーンの変化は検出されませんでした。'),
      findsOneWidget,
    );
    expect(find.text('450億円'), findsOneWidget);
    expect(find.text('42億円'), findsOneWidget);
    expect(find.text('38億円'), findsOneWidget);
  });
}
