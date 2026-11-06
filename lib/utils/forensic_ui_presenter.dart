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
      displayName: '🚨 事業継続の重要疑義',
      severity: ForensicRiskLevel.critical,
      templateText: '継続企業の前提に関する重要な疑義や不確実性に関する注記（GC注記）が記載されています。',
    ),
    'covenant_breach': ForensicTagInfo(
      id: 'covenant_breach',
      displayName: '🚨 財務制限条項に抵触',
      severity: ForensicRiskLevel.critical,
      templateText: '借入契約の財務制限条項への抵触またはその懸念が報告されています。',
    ),
    'unsustainable_payout': ForensicTagInfo(
      id: 'unsustainable_payout',
      displayName: '🚨 利益超過分配',
      severity: ForensicRiskLevel.critical,
      templateText: '当期純利益を超える配当の実施など、資本や内部留保の取り崩しによる配当維持が報告されています。',
    ),
    'negative_operating_cf': ForensicTagInfo(
      id: 'negative_operating_cf',
      displayName: '⚠️ 営業CFマイナス',
      severity: ForensicRiskLevel.warning,
      templateText: '本業の営業活動によるキャッシュフローがマイナス（現金流出状態）となっています。',
    ),
    'inventory_receivable_surge': ForensicTagInfo(
      id: 'inventory_receivable_surge',
      displayName: '⚠️ 棚卸資産・売掛金急増',
      severity: ForensicRiskLevel.warning,
      templateText: '棚卸資産（在庫）や売上債権の急増により、運転資本の負担が増加しています。',
    ),
    'impairment_loss': ForensicTagInfo(
      id: 'impairment_loss',
      displayName: '⚠️ 減損損失の計上',
      severity: ForensicRiskLevel.warning,
      templateText: '固定資産やのれん等の減損損失、またはその兆候が報告されています。',
    ),
    'interest_debt_pressure': ForensicTagInfo(
      id: 'interest_debt_pressure',
      displayName: '⚠️ 有利子負債・利払負担',
      severity: ForensicRiskLevel.warning,
      templateText: '借入金の増加や支払利息の負担増大に関する記載があります。',
    ),
    'subsequent_events': ForensicTagInfo(
      id: 'subsequent_events',
      displayName: '⚠️ 重要な後発事象',
      severity: ForensicRiskLevel.warning,
      templateText: '決算期日以降に発生した事業・財務に影響を与える重大な事象が報告されています。',
    ),

    // 定性言い訳・経営トーンタグ
    'blame_external_macro': ForensicTagInfo(
      id: 'blame_external_macro',
      displayName: '⚠️ 外部要因への言及優勢',
      severity: ForensicRiskLevel.warning,
      templateText: '業績変動の要因説明において、為替や原材料高など外部マクロ環境への言及が中心となっています。',
      isToneTag: true,
    ),
    'blame_temporary_one_off': ForensicTagInfo(
      id: 'blame_temporary_one_off',
      displayName: '⚠️ 一時的要因としての説明',
      severity: ForensicRiskLevel.warning,
      templateText: '業績悪化の主因として「一過性の先行投資」や「システム切替」等の一時的費用を挙げています。',
      isToneTag: true,
    ),
    'unfounded_optimism': ForensicTagInfo(
      id: 'unfounded_optimism',
      displayName: '⚠️ 定性的な回復見通し',
      severity: ForensicRiskLevel.warning,
      templateText: '「足元底打ち傾向」「下期回復を見込む」など、定性的・主観的な回復期待表現が記載されています。',
      isToneTag: true,
    ),
    'risk_materialized': ForensicTagInfo(
      id: 'risk_materialized',
      displayName: '⚠️ 事業リスクの顕在化',
      severity: ForensicRiskLevel.warning,
      templateText: '損害賠償、納期遅延、訴訟など、想定されていた事業リスクが実際に発生・顕在化した旨が追記されています。',
      isToneTag: true,
    ),
    'new_major_risk': ForensicTagInfo(
      id: 'new_major_risk',
      displayName: '⚠️ 新規リスク項目の追加',
      severity: ForensicRiskLevel.warning,
      templateText: '前期の開示には記載がなかった、新たな重要リスク項目が追加されています。',
      isToneTag: true,
    ),
    'tone_retreat': ForensicTagInfo(
      id: 'tone_retreat',
      displayName: '⚠️ 開示トーンの慎重化',
      severity: ForensicRiskLevel.warning,
      templateText: '前期に用いられていた強気の表現が削除または修正され、慎重・不透明感を強調する表現へトーンが変化しています。',
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
