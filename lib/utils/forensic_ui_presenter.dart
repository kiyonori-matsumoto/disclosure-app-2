import '../models/forensic_result.dart';

class ForensicTagInfo {
  final String id;
  final String displayName;
  final ForensicRiskLevel severity;
  final String templateText;
  final bool isToneTag;

  const ForensicTagInfo({
    required this.id,
    required this.displayName,
    required this.severity,
    required this.templateText,
    this.isToneTag = false,
  });
}

class FormattedMetricItem {
  final String label;
  final String formattedValue;
  final bool isNegative;
  final int? rawValue;

  const FormattedMetricItem({
    required this.label,
    required this.formattedValue,
    required this.isNegative,
    this.rawValue,
  });
}

class ForensicUiPresenter {
  static const Map<String, ForensicTagInfo> knownTags = {
    // 財務・注記リスクタグ
    'going_concern': ForensicTagInfo(
      id: 'going_concern',
      displayName: '🚨 倒産危機サイン',
      severity: ForensicRiskLevel.critical,
      templateText: '事業を続けられるかどうかの重大な懸念（継続企業の前提の疑義）が出ています。',
    ),
    'covenant_breach': ForensicTagInfo(
      id: 'covenant_breach',
      displayName: '🚨 銀行ルール違反',
      severity: ForensicRiskLevel.critical,
      templateText: '銀行との約束（財務制限条項）に違反し、借金の一括返済を求められるリスクがあります。',
    ),
    'unsustainable_payout': ForensicTagInfo(
      id: 'unsustainable_payout',
      displayName: '🚨 無理な配当維持',
      severity: ForensicRiskLevel.critical,
      templateText: '稼いだ利益以上の配当を出すため、会社の貯金（内部留保）を切り崩しています。',
    ),
    'negative_operating_cf': ForensicTagInfo(
      id: 'negative_operating_cf',
      displayName: '⚠️ 本業の現金減少',
      severity: ForensicRiskLevel.warning,
      templateText: '本業の営業活動で現金がマイナス（流出状態）になっています。',
    ),
    'inventory_receivable_surge': ForensicTagInfo(
      id: 'inventory_receivable_surge',
      displayName: '⚠️ 在庫・売掛急増',
      severity: ForensicRiskLevel.warning,
      templateText: '商品の売れ残り（在庫）や未回収の代金が急増し、資金繰りを圧迫しています。',
    ),
    'impairment_loss': ForensicTagInfo(
      id: 'impairment_loss',
      displayName: '⚠️ 資産価値の暴落',
      severity: ForensicRiskLevel.warning,
      templateText: '過去の投資や買収した事業の価値が下がり、特別損失（減損）が発生しています。',
    ),
    'interest_debt_pressure': ForensicTagInfo(
      id: 'interest_debt_pressure',
      displayName: '⚠️ 借入・利払い急増',
      severity: ForensicRiskLevel.warning,
      templateText: '借入金の急増などにより、利払いの負担が重くなっています。',
    ),
    'subsequent_events': ForensicTagInfo(
      id: 'subsequent_events',
      displayName: '⚠️ 決算後の重大事象',
      severity: ForensicRiskLevel.warning,
      templateText: '決算期日後に重大なトラブル（訴訟・事故・大口解約等）が報告されています。',
    ),

    // 定性言い訳・経営トーンタグ
    'blame_external_macro': ForensicTagInfo(
      id: 'blame_external_macro',
      displayName: '⚠️ 外部責任転嫁',
      severity: ForensicRiskLevel.warning,
      templateText: '不振の理由を外部環境（為替・原材料等）ばかりに求めており、自社の課題への言及が乏しい状態です。',
      isToneTag: true,
    ),
    'blame_temporary_one_off': ForensicTagInfo(
      id: 'blame_temporary_one_off',
      displayName: '⚠️ 一過性強弁',
      severity: ForensicRiskLevel.warning,
      templateText: '「一時的な先行投資・システム切替」による悪化と主張しています。',
      isToneTag: true,
    ),
    'unfounded_optimism': ForensicTagInfo(
      id: 'unfounded_optimism',
      displayName: '⚠️ 根拠なき楽観',
      severity: ForensicRiskLevel.warning,
      templateText: '「足元底打ち」「下期回復を見込む」など、具体的数値根拠を欠く楽観的な表現が含まれています。',
      isToneTag: true,
    ),
    'risk_materialized': ForensicTagInfo(
      id: 'risk_materialized',
      displayName: '⚠️ リスク顕在化',
      severity: ForensicRiskLevel.warning,
      templateText: '損害賠償や納期遅延、不正など、想定リスクが実際に顕在化した記述が追加されています。',
      isToneTag: true,
    ),
    'new_major_risk': ForensicTagInfo(
      id: 'new_major_risk',
      displayName: '⚠️ 新規重大リスク',
      severity: ForensicRiskLevel.warning,
      templateText: '前期開示になかった新たな重大リスク項目が追加されています。',
      isToneTag: true,
    ),
    'tone_retreat': ForensicTagInfo(
      id: 'tone_retreat',
      displayName: '⚠️ 表現トーン後退',
      severity: ForensicRiskLevel.warning,
      templateText: '「順調」「強固」などの強気表現が削除され、慎重なトーンへ後退しています。',
      isToneTag: true,
    ),
  };

  static const Map<String, String> knownCauses = {
    'fx_fluctuation': '為替変動',
    'raw_material_energy': '原材料・光熱費高騰',
    'weather_or_disaster': '天候災害',
    'market_or_geopolitics': '市況悪化',
    'upfront_investment': '先行投資',
    'weak_sales_or_churn': '顧客離れ',
    'delayed_price_pass': '値上げ遅れ',
  };

  final ForensicResult result;

  const ForensicUiPresenter(this.result);

  ForensicRiskLevel get riskLevel => result.riskLevel;

  String get headline {
    switch (result.riskLevel) {
      case ForensicRiskLevel.critical:
        return '🚨 重大な財務・経営リスクを検知';
      case ForensicRiskLevel.warning:
        return '⚠️ 留意すべき財務リスク・開示トーンを検知';
      case ForensicRiskLevel.normal:
        return '健全な開示内容';
    }
  }

  String get riskLevelLabel {
    switch (result.riskLevel) {
      case ForensicRiskLevel.critical:
        return 'CRITICAL (危険)';
      case ForensicRiskLevel.warning:
        return 'WARNING (注意)';
      case ForensicRiskLevel.normal:
        return 'NORMAL (正常)';
    }
  }

  List<ForensicTagInfo> get tagInfos {
    return result.tags.map((tagId) {
      if (knownTags.containsKey(tagId)) {
        return knownTags[tagId]!;
      }
      return ForensicTagInfo(
        id: tagId,
        displayName: '⚠️ $tagId',
        severity: ForensicRiskLevel.warning,
        templateText: '特記事項（$tagId）が検知されました。',
      );
    }).toList();
  }

  List<String> get causeLabels {
    return result.causes.map((causeId) {
      return knownCauses[causeId] ?? causeId;
    }).toList();
  }

  /// 検出されたタグのテンプレート文を自然な日本語文章に合成
  String get composedExplanation {
    final tags = tagInfos;
    if (tags.isEmpty) {
      if (result.riskLevel == ForensicRiskLevel.normal) {
        return '重大な財務リスクや特異な定性トーンの変化は検出されませんでした。';
      }
      return '詳細なリスク項目は検出されていません。';
    }

    final buffer = StringBuffer();
    for (int i = 0; i < tags.length; i++) {
      if (i > 0) {
        buffer.write('また、');
      }
      buffer.write(tags[i].templateText);
    }
    return buffer.toString();
  }

  /// 金額（単位: 千円）を億円・百万円単位にフォーマット
  static String formatAmount(int? amountInThousands) {
    if (amountInThousands == null) return '-';
    if (amountInThousands == 0) return '0円';

    final isNegative = amountInThousands < 0;
    final absVal = amountInThousands.abs();
    final sign = isNegative ? '▲' : '';

    // 1億円以上 (100,000 千円)
    if (absVal >= 100000) {
      final oku = absVal / 100000.0;
      final formatted = oku >= 100
          ? oku.toStringAsFixed(0)
          : oku.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
      return '$sign$formatted億円';
    }

    // 100万円以上 (1,000 千円)
    if (absVal >= 1000) {
      final hyakuman = (absVal / 1000.0).round();
      return '$sign$hyakuman百万円';
    }

    // 100万円未満
    return '$sign$absVal千円';
  }

  List<FormattedMetricItem> get metricItems {
    final metrics = result.metrics;
    if (metrics == null) return const [];

    final list = <FormattedMetricItem>[];

    if (metrics.revenue != null) {
      list.add(FormattedMetricItem(
        label: '売上高',
        formattedValue: formatAmount(metrics.revenue),
        isNegative: (metrics.revenue ?? 0) < 0,
        rawValue: metrics.revenue,
      ));
    }

    if (metrics.operatingIncome != null) {
      list.add(FormattedMetricItem(
        label: '営業利益',
        formattedValue: formatAmount(metrics.operatingIncome),
        isNegative: (metrics.operatingIncome ?? 0) < 0,
        rawValue: metrics.operatingIncome,
      ));
    }

    if (metrics.netIncome != null) {
      list.add(FormattedMetricItem(
        label: '当期純利益',
        formattedValue: formatAmount(metrics.netIncome),
        isNegative: (metrics.netIncome ?? 0) < 0,
        rawValue: metrics.netIncome,
      ));
    }

    if (metrics.operatingCashFlow != null) {
      list.add(FormattedMetricItem(
        label: '営業活動CF',
        formattedValue: formatAmount(metrics.operatingCashFlow),
        isNegative: (metrics.operatingCashFlow ?? 0) < 0,
        rawValue: metrics.operatingCashFlow,
      ));
    }

    return list;
  }
}
