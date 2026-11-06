import 'package:disclosure_app_fl/models/forensic_result.dart';
import 'package:disclosure_app_fl/utils/forensic_ui_presenter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ForensicUiPresenter', () {
    test('resolves known tags with correct display names and severity', () {
      const result = ForensicResult(
        riskLevel: ForensicRiskLevel.critical,
        tags: ['going_concern', 'negative_operating_cf', 'blame_external_macro'],
      );

      final presenter = ForensicUiPresenter(result);
      final tagInfos = presenter.tagInfos;

      expect(tagInfos.length, 3);
      expect(tagInfos[0].displayName, '🚨 事業継続の重要疑義');
      expect(tagInfos[0].severity, ForensicRiskLevel.critical);
      expect(tagInfos[0].promptQuestion, contains('継続企業の前提に関する注記・疑義'));
      expect(tagInfos[1].displayName, '⚠️ 営業CFマイナス');
      expect(tagInfos[1].severity, ForensicRiskLevel.warning);
      expect(tagInfos[1].promptQuestion, contains('営業キャッシュ・フロー'));
      expect(tagInfos[2].displayName, '⚠️ 外部要因への言及優勢');
      expect(tagInfos[2].severity, ForensicRiskLevel.warning);
      expect(tagInfos[2].isToneTag, isTrue);
      expect(tagInfos[2].promptQuestion, contains('為替、原材料高'));
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

    test('headlines reflect riskLevel', () {
      expect(
        const ForensicUiPresenter(ForensicResult(riskLevel: ForensicRiskLevel.critical)).headline,
        '🚨 重大な財務・経営リスクを検知',
      );
      expect(
        const ForensicUiPresenter(ForensicResult(riskLevel: ForensicRiskLevel.warning)).headline,
        '⚠️ 留意すべき財務リスク・開示トーンを検知',
      );
      expect(
        const ForensicUiPresenter(ForensicResult(riskLevel: ForensicRiskLevel.normal)).headline,
        '特記事項・リスク未検出',
      );
    });
  });
}
