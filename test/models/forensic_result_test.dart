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
