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
    expect(find.text('定性・財務フォレンジック解析'), findsOneWidget);
    expect(find.text('アクセルマーク (3624)'), findsOneWidget);
    expect(find.text('第31期 有価証券報告書'), findsOneWidget);

    // 総合判定見出し
    expect(find.text('CRITICAL (重要注記・制限事項)'), findsOneWidget);
    expect(find.text('重大な注記・財務制限事項を検出'), findsOneWidget);

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
    expect(find.text('機械判定基準・算出方法・評価設問の開示'), findsOneWidget);
    await tester.tap(find.text('機械判定基準・算出方法・評価設問の開示'));
    await tester.pumpAndSettle();
    expect(find.text('【定量財務指標の算出式・しきい値基準】'), findsOneWidget);
    expect(find.textContaining('現在進行形で存在することを示す注記'), findsOneWidget);

    // 免責事項
    expect(find.textContaining('企業状態の健全性や危険性を評価・格付けするものではなく'), findsOneWidget);
  });

  testWidgets('ForensicDetailSheet displays quantitative indicators and metadata badges',
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
      tags: const ['accruals_anomaly', 'liquidity_crunch'],
      metrics: const ForensicMetrics(
        standard: 'J-GAAP',
        periodType: 'FY',
        isFinancialIndustry: false,
        current: FinancialSnapshot(
          revenue: 10000000,
          operatingIncome: 200000,
          netIncome: 1800000,
          operatingCashFlow: -100000,
          investingCashFlow: -50000,
          netAssets: 2500000,
          cashAndDeposits: 300000,
        ),
        calculations: QuantitativeCalculations(
          accrualsRatio: 0.19,
          dsri: 1.55,
          fcf: -150000,
          cashCoverage: 0.05,
          equityRatio: 0.25,
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ForensicDetailSheet(
            forensic: forensic,
            companyName: 'フューチャーリンクネットワーク (9241)',
            documentTitle: '決算短信',
          ),
        ),
      ),
    );

    // メタデータバッジ
    expect(find.text('J-GAAP'), findsOneWidget);
    expect(find.text('通期 (FY)'), findsOneWidget);

    // 新規定量タグ
    expect(find.text('🚨 総資産アクルーアル乖離'), findsOneWidget);
    expect(find.text('🚨 短期流動性ショック'), findsOneWidget);

    // 定量フォレンジック指標セクション
    expect(find.text('定量フォレンジック指標（財務モデル分析）'), findsOneWidget);
    expect(find.text('総資産アクルーアル比率'), findsOneWidget);
    expect(find.text('+19.0%'), findsOneWidget);
    expect(find.text('算出式: (当期純利益 － 営業活動CF) ÷ 総資産'), findsOneWidget);
    expect(find.text('売上債権回転期間指数'), findsOneWidget);
    expect(find.text('1.55倍'), findsOneWidget);
    expect(find.text('算出式: (当期売上債権 ÷ 当期売上高) ÷ (前期売上債権 ÷ 前期売上高)'), findsOneWidget);
    expect(find.text('対流動負債 現預金比率'), findsOneWidget);
    expect(find.text('5.0%'), findsOneWidget);

    // 拡張財務数値
    expect(find.text('フリーCF (FCF)'), findsOneWidget);
    expect(find.text('▲1.5億円'), findsOneWidget);
    expect(find.text('純資産'), findsOneWidget);
    expect(find.text('25億円'), findsOneWidget);
    expect(find.text('現金及び預金'), findsOneWidget);
    expect(find.text('3億円'), findsOneWidget);
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

    expect(find.text('NORMAL (未検出)'), findsOneWidget);
    expect(find.text('対象となる注記・特記事項は未検出'), findsOneWidget);
    expect(
      find.text('本開示において、対象となる重要注記・財務制限事項や定性トーンの特記項目は検出されませんでした。'),
      findsOneWidget,
    );
    expect(find.text('450億円'), findsOneWidget);
    expect(find.text('42億円'), findsOneWidget);
    expect(find.text('38億円'), findsOneWidget);
  });

  testWidgets('ForensicDetailSheet renders clearly in dark mode',
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
      riskLevel: ForensicRiskLevel.warning,
      tags: const ['negative_operating_cf'],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: ForensicDetailSheet(
            forensic: forensic,
            companyName: 'ダークモード企業 (9999)',
            documentTitle: '四半期報告書',
          ),
        ),
      ),
    );

    expect(find.text('定性・財務フォレンジック解析'), findsOneWidget);
    expect(find.text('機械判定基準・算出方法・評価設問の開示'), findsOneWidget);

    // プロンプト開示を展開して視認できること
    await tester.tap(find.text('機械判定基準・算出方法・評価設問の開示'));
    await tester.pumpAndSettle();
    expect(find.textContaining('営業キャッシュ・フロー'), findsOneWidget);
  });
}
