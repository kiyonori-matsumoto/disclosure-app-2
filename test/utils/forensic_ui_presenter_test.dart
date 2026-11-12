import 'package:disclosure_app_fl/models/forensic_result.dart';
import 'package:disclosure_app_fl/utils/forensic_ui_presenter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ForensicUiPresenter', () {
    test('resolves known tags with correct display names and severity sorted by severity', () {
      const result = ForensicResult(
        riskLevel: ForensicRiskLevel.critical,
        tags: [
          'negative_operating_cf',
          'going_concern',
          'blame_external_macro',
          'accruals_anomaly',
        ],
      );

      final presenter = ForensicUiPresenter(result);
      final tagInfos = presenter.tagInfos;

      expect(tagInfos.length, 4);
      // 大幅乖離 (Critical) が優先されて先頭に来ること
      expect(tagInfos[0].displayName, '❗ 事業継続の重要疑義');
      expect(tagInfos[0].severity, ForensicRiskLevel.critical);

      expect(tagInfos[1].displayName, '❗ 総資産アクルーアル乖離');
      expect(tagInfos[1].severity, ForensicRiskLevel.critical);

      // 乖離あり (Warning) が後ろに並ぶこと
      expect(tagInfos[2].displayName, '⚠️ 営業CFマイナス');
      expect(tagInfos[2].severity, ForensicRiskLevel.warning);

      expect(tagInfos[3].displayName, '⚠️ 外部要因への言及優勢');
      expect(tagInfos[3].severity, ForensicRiskLevel.warning);
    });

    test('promotes inventory_receivable_surge to critical when document riskLevel is critical', () {
      const result = ForensicResult(
        riskLevel: ForensicRiskLevel.critical,
        tags: ['inventory_receivable_surge'],
        metrics: ForensicMetrics(
          calculations: QuantitativeCalculations(
            dsiIndex: 2.5, // > 1.50 (大幅乖離)
          ),
        ),
      );

      final presenter = ForensicUiPresenter(result);
      final tagInfos = presenter.tagInfos;

      expect(tagInfos.length, 1);
      expect(tagInfos[0].displayName, '❗ 棚卸資産・売掛金急増');
      expect(tagInfos[0].severity, ForensicRiskLevel.critical);
    });

    test('returns appropriate labels for deviation tiers (Plan A: 通常 < 乖離あり < 大幅乖離)', () {
      const normalResult = ForensicResult(riskLevel: ForensicRiskLevel.normal);
      const warningResult = ForensicResult(riskLevel: ForensicRiskLevel.warning);
      const criticalResult = ForensicResult(riskLevel: ForensicRiskLevel.critical);

      expect(ForensicUiPresenter(normalResult).riskLevelLabel, '通常 (乖離なし)');
      expect(ForensicUiPresenter(warningResult).riskLevelLabel, '乖離あり (留意事項・変動)');
      expect(ForensicUiPresenter(criticalResult).riskLevelLabel, '大幅乖離 (顕著な変化・特異値)');
    });

    test('composes template explanation string accurately', () {
      const result = ForensicResult(
        riskLevel: ForensicRiskLevel.critical,
        tags: ['going_concern', 'negative_operating_cf'],
      );

      final presenter = ForensicUiPresenter(result);
      final text = presenter.composedExplanation;

      expect(
        text,
        '継続企業の前提に関する重要な疑義や不確実性に関する注記（GC注記）が記載されています。また、本業の営業活動によるキャッシュフローがマイナス（現金流出状態）となっています。',
      );
    });

    test('resolves cause labels', () {
      const result = ForensicResult(
        causes: ['raw_material_energy', 'weak_sales_or_churn', 'unknown_cause'],
      );

      final presenter = ForensicUiPresenter(result);
      expect(presenter.causeLabels, ['原材料・光熱費高騰', '顧客離れ', 'unknown_cause']);
    });

    test('formats financial amounts into Japanese units correctly', () {
      expect(ForensicUiPresenter.formatAmount(null), '-');
      expect(ForensicUiPresenter.formatAmount(0), '0円');
      expect(ForensicUiPresenter.formatAmount(1580000), '15.8億円');
      expect(ForensicUiPresenter.formatAmount(-280000), '▲2.8億円');
      expect(ForensicUiPresenter.formatAmount(-120000), '▲1.2億円');
      expect(ForensicUiPresenter.formatAmount(50000), '50百万円');
      expect(ForensicUiPresenter.formatAmount(-80000), '▲80百万円');
      expect(ForensicUiPresenter.formatAmount(500), '500千円');
      expect(ForensicUiPresenter.formatAmount(-300), '▲300千円');
    });

    test('returns metric items with negative indicators', () {
      const result = ForensicResult(
        metrics: ForensicMetrics(
          revenue: 1580000,
          operatingIncome: -120000,
          netIncome: -380000,
          operatingCashFlow: -280000,
        ),
      );

      final presenter = ForensicUiPresenter(result);
      final items = presenter.metricItems;

      expect(items.length, 4);
      expect(items[0].label, '売上高');
      expect(items[0].formattedValue, '15.8億円');
      expect(items[0].isNegative, isFalse);

      expect(items[1].label, '営業利益');
      expect(items[1].formattedValue, '▲1.2億円');
      expect(items[1].isNegative, isTrue);

      expect(items[2].label, '当期純利益');
      expect(items[2].formattedValue, '▲3.8億円');
      expect(items[2].isNegative, isTrue);

      expect(items[3].label, '営業活動CF');
      expect(items[3].formattedValue, '▲2.8億円');
      expect(items[3].isNegative, isTrue);
    });

    test('returns expanded metric items including FCF, net assets, and cash', () {
      const result = ForensicResult(
        metrics: ForensicMetrics(
          current: FinancialSnapshot(
            revenue: 10000000,
            operatingIncome: 500000,
            netIncome: 300000,
            operatingCashFlow: 800000,
            investingCashFlow: -300000,
            netAssets: 4000000,
            cashAndDeposits: 1200000,
          ),
          calculations: QuantitativeCalculations(
            fcf: 500000,
          ),
        ),
      );

      final presenter = ForensicUiPresenter(result);
      final items = presenter.metricItems;

      expect(items.length, 8);
      expect(items[0].label, '売上高');
      expect(items[0].formattedValue, '100億円');
      expect(items[4].label, '投資活動CF');
      expect(items[4].formattedValue, '▲3億円');
      expect(items[5].label, 'フリーCF (FCF)');
      expect(items[5].formattedValue, '5億円');
      expect(items[6].label, '純資産');
      expect(items[6].formattedValue, '40億円');
      expect(items[7].label, '現金及び預金');
      expect(items[7].formattedValue, '12億円');
    });

    test('formats quantitativeIndicators accurately with risk levels', () {
      const result = ForensicResult(
        metrics: ForensicMetrics(
          standard: 'IFRS',
          periodType: 'FY',
          isFinancialIndustry: false,
          current: FinancialSnapshot(
            operatingCashFlow: -100000,
            netAssets: 500000,
            retainedEarnings: -200000,
          ),
          calculations: QuantitativeCalculations(
            accrualsRatio: 0.18, // > 0.15 -> Critical
            dsri: 1.60, // > 1.465 -> Critical
            dsiIndex: 1.30, // 1.25..1.50 -> Warning
            aqi: 1.10, // <= 1.15 -> Normal
            cashCoverage: 0.05, // < 0.08 & OCF < 0 -> Critical
            equityRatio: 0.08, // < 0.10 -> Warning
            netAssetsDropRate: -0.40, // <= -0.30 & retainedEarnings < 0 -> Critical
          ),
        ),
      );

      final presenter = ForensicUiPresenter(result);
      expect(presenter.standardLabel, 'IFRS');
      expect(presenter.periodTypeLabel, '通期 (FY)');
      expect(presenter.isFinancialIndustry, isFalse);

      final inds = presenter.quantitativeIndicators;
      expect(inds.length, 7);

      // 1. Accruals
      expect(inds[0].key, 'accrualsRatio');
      expect(inds[0].formattedValue, '+18.0%');
      expect(inds[0].formula, '(当期純利益 － 営業活動CF) ÷ 総資産');
      expect(inds[0].thresholdDescription, contains('指標基準値: 8.0%未満'));
      expect(inds[0].status, ForensicRiskLevel.critical);

      // 2. DSRI
      expect(inds[1].key, 'dsri');
      expect(inds[1].formattedValue, '1.60倍');
      expect(inds[1].formula, contains('売上債権'));
      expect(inds[1].status, ForensicRiskLevel.critical);

      // 3. DSI
      expect(inds[2].key, 'dsiIndex');
      expect(inds[2].formattedValue, '1.30倍');
      expect(inds[2].formula, contains('棚卸資産'));
      expect(inds[2].status, ForensicRiskLevel.warning);

      // 4. AQI
      expect(inds[3].key, 'aqi');
      expect(inds[3].formattedValue, '1.10倍');
      expect(inds[3].formula, contains('非流動非有形比率'));
      expect(inds[3].status, ForensicRiskLevel.normal);

      // 5. Cash coverage
      expect(inds[4].key, 'cashCoverage');
      expect(inds[4].formattedValue, '5.0%');
      expect(inds[4].formula, contains('流動負債合計'));
      expect(inds[4].status, ForensicRiskLevel.critical);

      // 6. Equity ratio
      expect(inds[5].key, 'equityRatio');
      expect(inds[5].formattedValue, '8.0%');
      expect(inds[5].formula, contains('総資産合計'));
      expect(inds[5].status, ForensicRiskLevel.warning);

      // 7. Net assets drop
      expect(inds[6].key, 'netAssetsDropRate');
      expect(inds[6].formattedValue, '▲40.0%');
      expect(inds[6].formula, contains('前期純資産'));
      expect(inds[6].status, ForensicRiskLevel.critical);
    });

    test('headlines reflect riskLevel', () {
      expect(
        const ForensicUiPresenter(ForensicResult(riskLevel: ForensicRiskLevel.critical)).headline,
        '財務指標・開示項目に【大幅な乖離】を検出',
      );
      expect(
        const ForensicUiPresenter(ForensicResult(riskLevel: ForensicRiskLevel.warning)).headline,
        '財務指標・開示トーンに【乖離】を検出',
      );
      expect(
        const ForensicUiPresenter(ForensicResult(riskLevel: ForensicRiskLevel.normal)).headline,
        '通常の範囲内（乖離なし）',
      );
    });
  });
}
