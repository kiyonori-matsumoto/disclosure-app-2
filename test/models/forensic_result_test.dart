import 'package:disclosure_app_fl/models/disclosure.dart';
import 'package:disclosure_app_fl/models/forensic_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ForensicResult', () {
    test('parses complete map correctly', () {
      final map = {
        'version': 1,
        'analyzedAt': 1730642400,
        'riskLevel': 'critical',
        'tags': ['going_concern', 'negative_operating_cf'],
        'causes': ['raw_material_energy', 'weak_sales_or_churn'],
        'metrics': {
          'revenue': 1580000,
          'operatingIncome': -120000,
          'netIncome': -380000,
          'operatingCashFlow': -280000,
          'payoutRatio': 45.5,
          'totalAssets': 5000000,
          'unit': '千円',
        },
        'details': {
          'blameAttribution': 'external_macro_dominant',
          'unfoundedOptimism': true,
          'hasNegativeFactors': true,
        },
      };

      final result = ForensicResult.fromMap(map);

      expect(result.version, 1);
      expect(result.riskLevel, ForensicRiskLevel.critical);
      expect(result.analyzedAt, DateTime.fromMillisecondsSinceEpoch(1730642400 * 1000));
      expect(result.tags, ['going_concern', 'negative_operating_cf']);
      expect(result.causes, ['raw_material_energy', 'weak_sales_or_churn']);

      expect(result.metrics?.revenue, 1580000);
      expect(result.metrics?.operatingIncome, -120000);
      expect(result.metrics?.netIncome, -380000);
      expect(result.metrics?.operatingCashFlow, -280000);
      expect(result.metrics?.payoutRatio, 45.5);
      expect(result.metrics?.totalAssets, 5000000);
      expect(result.metrics?.unit, '千円');

      expect(result.details?.blameAttribution, 'external_macro_dominant');
      expect(result.details?.unfoundedOptimism, isTrue);
      expect(result.details?.hasNegativeFactors, isTrue);
    });

    test('parses quantitative snapshot and calculations correctly', () {
      final map = {
        'version': 1,
        'riskLevel': 'critical',
        'tags': ['accruals_anomaly', 'equity_erosion'],
        'metrics': {
          'standard': 'J-GAAP',
          'periodType': 'FY',
          'isFinancialIndustry': false,
          'current': {
            'revenue': 10000000,
            'operatingIncome': 500000,
            'netIncome': 2000000,
            'operatingCashFlow': 200000,
            'tradeReceivables': 1600000,
            'inventories': 1200000,
            'cashAndDeposits': 800000,
            'currentLiabilities': 5000000,
            'netAssets': 3000000,
            'investingCashFlow': -100000,
          },
          'prior': {
            'revenue': 9000000,
            'tradeReceivables': 1000000,
            'cashAndDeposits': 1500000,
            'netAssets': 4500000,
          },
          'calculations': {
            'accrualsRatio': 0.18,
            'dsri': 1.60,
            'dsiIndex': 1.22,
            'aqi': 1.12,
            'fcf': 100000,
            'cashCoverage': 0.16,
            'cashDropRate': -0.4667,
            'equityRatio': 0.30,
            'netAssetsDropRate': -0.3333,
          },
          'unit': '千円',
        },
      };

      final result = ForensicResult.fromMap(map);
      expect(result.metrics?.standard, 'J-GAAP');
      expect(result.metrics?.periodType, 'FY');
      expect(result.metrics?.isFinancialIndustry, isFalse);

      // 有効値ゲッターの確認
      expect(result.metrics?.effectiveRevenue, 10000000);
      expect(result.metrics?.effectiveNetIncome, 2000000);
      expect(result.metrics?.effectiveOperatingCashFlow, 200000);
      expect(result.metrics?.tradeReceivables, 1600000);
      expect(result.metrics?.inventories, 1200000);
      expect(result.metrics?.cashAndDeposits, 800000);
      expect(result.metrics?.netAssets, 3000000);
      expect(result.metrics?.investingCashFlow, -100000);

      // calculations
      final calcs = result.metrics?.calculations;
      expect(calcs?.accrualsRatio, 0.18);
      expect(calcs?.dsri, 1.60);
      expect(calcs?.dsiIndex, 1.22);
      expect(calcs?.aqi, 1.12);
      expect(calcs?.fcf, 100000);
      expect(calcs?.cashCoverage, 0.16);
      expect(calcs?.cashDropRate, -0.4667);
      expect(calcs?.equityRatio, 0.30);
      expect(calcs?.netAssetsDropRate, -0.3333);

      // toMap
      final serialized = result.toMap();
      final metricsMap = serialized['metrics'] as Map<String, dynamic>;
      expect(metricsMap['standard'], 'J-GAAP');
      expect(metricsMap['periodType'], 'FY');
      expect((metricsMap['calculations'] as Map)['accrualsRatio'], 0.18);
    });

    test('handles empty or null fields safely', () {
      final result = ForensicResult.fromMap({});

      expect(result.version, 1);
      expect(result.riskLevel, ForensicRiskLevel.normal);
      expect(result.analyzedAt, isNull);
      expect(result.tags, isEmpty);
      expect(result.causes, isEmpty);
      expect(result.metrics, isNull);
      expect(result.details, isNull);
    });

    test('serializes to map correctly', () {
      final result = ForensicResult(
        version: 1,
        analyzedAt: DateTime.fromMillisecondsSinceEpoch(1730642400 * 1000),
        riskLevel: ForensicRiskLevel.warning,
        tags: ['negative_operating_cf'],
        causes: ['fx_fluctuation'],
        metrics: const ForensicMetrics(
          revenue: 1000000,
          operatingCashFlow: -50000,
        ),
        details: const ForensicDetails(
          blameAttribution: 'temporary_one_off',
          unfoundedOptimism: true,
        ),
      );

      final map = result.toMap();
      expect(map['version'], 1);
      expect(map['riskLevel'], 'warning');
      expect(map['analyzedAt'], 1730642400);
      expect(map['tags'], ['negative_operating_cf']);
      expect(map['causes'], ['fx_fluctuation']);
      expect((map['metrics'] as Map)['revenue'], 1000000);
      expect((map['metrics'] as Map)['operatingCashFlow'], -50000);
      expect((map['details'] as Map)['blameAttribution'], 'temporary_one_off');
      expect((map['details'] as Map)['unfoundedOptimism'], isTrue);
    });
  });

  group('Disclosure forensic integration', () {
    test('Disclosure toObject includes forensic if present', () {
      final disclosure = Disclosure(
        code: '1234',
        company: 'テスト企業',
        title: '決算短信',
        forensic: const ForensicResult(
          riskLevel: ForensicRiskLevel.critical,
          tags: ['going_concern'],
        ),
      );

      final obj = disclosure.toObject();
      expect(obj['forensic'], isNotNull);
      expect((obj['forensic'] as Map)['riskLevel'], 'critical');
    });
  });
}
