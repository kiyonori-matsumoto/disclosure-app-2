import '../models/forensic_result.dart';

class ForensicTagInfo {
  final String id;
  final String displayName;
  final ForensicRiskLevel severity;
  final String templateText;
  /// バックエンド（functions/src/forensic/schemas/*.ts）で評価されている判定プロンプト設問
  final String promptQuestion;
  final bool isToneTag;

  const ForensicTagInfo({
    required this.id,
    required this.displayName,
    required this.severity,
    required this.templateText,
    required this.promptQuestion,
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

class FormattedQuantitativeIndicator {
  final String key;
  final String label; // 例: 総資産アクルーアル比率
  final String acronym; // 例: Sloan Accruals
  final String formattedValue; // 例: +18.0%
  final String thresholdDescription; // 例: 正常目安: 8.0%未満 (>15.0%で重大)
  final ForensicRiskLevel status; // normal, warning, critical
  final String hint; // 指標の検知目的・解説

  const FormattedQuantitativeIndicator({
    required this.key,
    required this.label,
    required this.acronym,
    required this.formattedValue,
    required this.thresholdDescription,
    required this.status,
    required this.hint,
  });
}

class ForensicUiPresenter {
  static const Map<String, ForensicTagInfo> knownTags = {
    // 財務・注記リスクタグ (参照: backend functions/src/forensic/schemas/financial_anomaly.ts & financial_metrics_extractor.ts)
    'going_concern': ForensicTagInfo(
      id: 'going_concern',
      displayName: '🚨 事業継続の重要疑義',
      severity: ForensicRiskLevel.critical,
      templateText: '継続企業の前提に関する重要な疑義や不確実性に関する注記（GC注記）が記載されています。',
      promptQuestion:
          '自社グループの事業継続に重要な疑義・不確実性が現在進行形で存在することを示す注記（GC注記）の記載がありますか？（「該当事項はありません」等の非該当や、解消済みのものは除く）',
    ),
    'covenant_breach': ForensicTagInfo(
      id: 'covenant_breach',
      displayName: '🚨 財務制限条項に抵触',
      severity: ForensicRiskLevel.critical,
      templateText: '借入契約の財務制限条項への抵触またはその懸念が報告されています。',
      promptQuestion: '財務制限条項（コベナンツ）への抵触、または抵触懸念の記載がありますか？',
    ),
    'unsustainable_payout': ForensicTagInfo(
      id: 'unsustainable_payout',
      displayName: '🚨 利益超過分配・タコ足配当',
      severity: ForensicRiskLevel.critical,
      templateText: '営業CF赤字下での配当やFCF赤字下の過剰還元、当期純利益を超える配当の実施など、資本や借入に依存した無理な配当維持が報告されています。',
      promptQuestion: '営業CF赤字やFCF赤字下の過剰配当、利益剰余金欠損での配当、または当期利益を超える配当性向100%超がありますか？',
    ),
    'accruals_anomaly': ForensicTagInfo(
      id: 'accruals_anomaly',
      displayName: '🚨 アクルーアル異常（ペーパー利益）',
      severity: ForensicRiskLevel.critical,
      templateText: '純利益と営業キャッシュフローの大幅な乖離（総資産アクルーアル比率の異常）が検出され、キャッシュを伴わない見せかけの利益リスクがあります。',
      promptQuestion: '利益と営業CFの大幅乖離・ペーパー利益（総資産アクルーアル比率 >15%で重大、>8%で注意）が検出されていますか？',
    ),
    'asset_quality_deterioration': ForensicTagInfo(
      id: 'asset_quality_deterioration',
      displayName: '🚨 資産の質悪化（費用繰延）',
      severity: ForensicRiskLevel.critical,
      templateText: '資産の質指数（AQI）の急上昇が検出され、本来費用とすべき支出が無形資産や長期前払費用等へ繰り延べ（資産化）されている疑いがあります。',
      promptQuestion: '非流動・非有形資産比率の前年比急増（Beneish AQI > 1.254で重大、>1.15で注意）による費用の資産化・繰延リスクがありますか？',
    ),
    'liquidity_crunch': ForensicTagInfo(
      id: 'liquidity_crunch',
      displayName: '🚨 短期流動性ショック',
      severity: ForensicRiskLevel.critical,
      templateText: '流動負債に対する手元現預金の枯渇または現預金の急激な減少が検出され、短期的な資金ショート・黒字倒産危機が懸念されます。',
      promptQuestion: '流動負債に対する手元現預金比率の低下（<8%かつ営業CF赤字で重大、現預金30%以上急減で注意）による資金ショート懸念がありますか？',
    ),
    'equity_erosion': ForensicTagInfo(
      id: 'equity_erosion',
      displayName: '🚨 純資産毀損・債務超過',
      severity: ForensicRiskLevel.critical,
      templateText: '債務超過または累積赤字下での純資産の急減、あるいは自己資本比率の著しい低下が検出され、資本基盤の重大な毀損状態にあります。',
      promptQuestion: '債務超過または累積赤字下での純資産30%以上急減、自己資本比率10%未満の過剰レバレッジが検出されていますか？',
    ),
    'negative_operating_cf': ForensicTagInfo(
      id: 'negative_operating_cf',
      displayName: '⚠️ 営業CFマイナス',
      severity: ForensicRiskLevel.warning,
      templateText: '本業の営業活動によるキャッシュフローがマイナス（現金流出状態）となっています。',
      promptQuestion: '営業キャッシュ・フローのマイナスや本業での現金流出に関する言及がありますか？（または営業CF実数値がマイナス）',
    ),
    'inventory_receivable_surge': ForensicTagInfo(
      id: 'inventory_receivable_surge',
      displayName: '⚠️ 棚卸資産・売掛金急増',
      severity: ForensicRiskLevel.warning,
      templateText: '売上債権回転期間指数（DSRI）や棚卸資産回転期間指数（DSI）の異常上昇、または棚卸資産（在庫）・売上債権の急増に関する記載が検出されています。',
      promptQuestion: '売上債権回転期間指数(DSRI)や棚卸資産回転期間指数(DSI)の急増、または棚卸資産（売れ残り在庫）・売上債権（未回収代金）の急増に関する記載がありますか？',
    ),
    'impairment_loss': ForensicTagInfo(
      id: 'impairment_loss',
      displayName: '⚠️ 減損損失の計上',
      severity: ForensicRiskLevel.warning,
      templateText: '固定資産やのれん等の減損損失、またはその兆候が報告されています。',
      promptQuestion: '固定資産やのれんの減損損失、または減損の兆候に関する記載がありますか？',
    ),
    'interest_debt_pressure': ForensicTagInfo(
      id: 'interest_debt_pressure',
      displayName: '⚠️ 有利子負債・利払負担',
      severity: ForensicRiskLevel.warning,
      templateText: '借入金の増加や支払利息の負担増大に関する記載がありますか？',
      promptQuestion: '借入金の急増、利払い負担増、有利子負債の急増に関する記載がありますか？',
    ),
    'subsequent_events': ForensicTagInfo(
      id: 'subsequent_events',
      displayName: '⚠️ 重要な後発事象',
      severity: ForensicRiskLevel.warning,
      templateText: '決算期日以降に発生した事業・財務に影響を与える重大な事象が報告されています。',
      promptQuestion: '重要な後発事象（重大訴訟、事故、大口取引終了、不正発覚等）に関する記載がありますか？',
    ),

    // 定性言い訳・経営トーンタグ (参照: backend functions/src/forensic/schemas/qualitative_excuses.ts)
    'blame_external_macro': ForensicTagInfo(
      id: 'blame_external_macro',
      displayName: '⚠️ 外部要因への言及優勢',
      severity: ForensicRiskLevel.warning,
      templateText: '業績変動の要因説明において、為替や原材料高など外部マクロ環境への言及が中心となっています。',
      promptQuestion: '経営陣が説明する業績不振・減益の主因：為替、原材料高、資源高、天候、地政学等に全責任転嫁している',
      isToneTag: true,
    ),
    'blame_temporary_one_off': ForensicTagInfo(
      id: 'blame_temporary_one_off',
      displayName: '⚠️ 一時的要因としての説明',
      severity: ForensicRiskLevel.warning,
      templateText: '業績変動の要因説明において、「一過性の先行投資」や「システム切替」等の一時的費用を挙げています。',
      promptQuestion: '経営陣が説明する業績不振・減益の主因：「一過性の先行投資・システム切替」等の一時的要因と強弁している',
      isToneTag: true,
    ),
    'unfounded_optimism': ForensicTagInfo(
      id: 'unfounded_optimism',
      displayName: '⚠️ 定性的な回復見通し',
      severity: ForensicRiskLevel.warning,
      templateText: '「足元底打ち傾向」「下期回復を見込む」など、定性的・主観的な回復期待表現が記載されています。',
      promptQuestion: '「足元底打ち」「中長期的には堅調」「下期回復を見込む」等の具体的数値根拠を欠く楽観形容詞が含まれますか？',
      isToneTag: true,
    ),
    'risk_materialized': ForensicTagInfo(
      id: 'risk_materialized',
      displayName: '⚠️ 事業リスクの顕在化',
      severity: ForensicRiskLevel.warning,
      templateText: '損害賠償、納期遅延、訴訟など、想定されていた事業リスクが実際に発生・顕在化した旨が追記されています。',
      promptQuestion: '「損害賠償」「訴訟」「不正」「取引停止」「損失計上」などリスクが実際に顕在化した記述がありますか？',
      isToneTag: true,
    ),
    'new_major_risk': ForensicTagInfo(
      id: 'new_major_risk',
      displayName: '⚠️ 新規リスク項目の追加',
      severity: ForensicRiskLevel.warning,
      templateText: '前期の開示には記載がなかった、新たな重要リスク項目が追加されています。',
      promptQuestion: '前期開示になかった、新たな重大リスク項目や大幅な規制・市場リスクが追加されていますか？',
      isToneTag: true,
    ),
    'tone_retreat': ForensicTagInfo(
      id: 'tone_retreat',
      displayName: '⚠️ 開示トーンの慎重化',
      severity: ForensicRiskLevel.warning,
      templateText: '前期に用いられていた表現が修正され、慎重・不透明感を伴う表現へトーンが変更されています。',
      promptQuestion: '「順調」「強固」「安定的」などの強気文言が削除され、慎重・不透明・懸念する表現へ後退していますか？',
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
        return '重大な注記・財務制限事項を検出';
      case ForensicRiskLevel.warning:
        return '財務指標・定性トーンに関する特記事項を検出';
      case ForensicRiskLevel.normal:
        return '対象となる注記・特記事項は未検出';
    }
  }

  String get riskLevelLabel {
    switch (result.riskLevel) {
      case ForensicRiskLevel.critical:
        return 'CRITICAL (重要注記・制限事項)';
      case ForensicRiskLevel.warning:
        return 'WARNING (特記事項・変動要因)';
      case ForensicRiskLevel.normal:
        return 'NORMAL (未検出)';
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
        promptQuestion: '該当項目（$tagId）に関する記載・指標の検知',
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
        return '本開示において、対象となる重要注記・財務制限事項や定性トーンの特記項目は検出されませんでした。';
      }
      return '対象となる特記項目は検出されていません。';
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

  String? get standardLabel {
    final s = result.metrics?.standard;
    if (s == null || s.isEmpty) return null;
    return s;
  }

  String? get periodTypeLabel {
    final p = result.metrics?.periodType;
    if (p == null || p.isEmpty) return null;
    switch (p.toUpperCase()) {
      case 'FY':
        return '通期 (FY)';
      case 'Q1':
        return '第1四半期 (Q1)';
      case 'Q2':
        return '第2四半期 (Q2)';
      case 'Q3':
        return '第3四半期 (Q3)';
      default:
        return p;
    }
  }

  bool get isFinancialIndustry => result.metrics?.isFinancialIndustry == true;

  List<FormattedMetricItem> get metricItems {
    final metrics = result.metrics;
    if (metrics == null) return const [];

    final list = <FormattedMetricItem>[];

    final rev = metrics.effectiveRevenue;
    if (rev != null) {
      list.add(FormattedMetricItem(
        label: '売上高',
        formattedValue: formatAmount(rev),
        isNegative: rev < 0,
        rawValue: rev,
      ));
    }

    final op = metrics.effectiveOperatingIncome;
    if (op != null) {
      list.add(FormattedMetricItem(
        label: '営業利益',
        formattedValue: formatAmount(op),
        isNegative: op < 0,
        rawValue: op,
      ));
    }

    final net = metrics.effectiveNetIncome;
    if (net != null) {
      list.add(FormattedMetricItem(
        label: '当期純利益',
        formattedValue: formatAmount(net),
        isNegative: net < 0,
        rawValue: net,
      ));
    }

    final ocf = metrics.effectiveOperatingCashFlow;
    if (ocf != null) {
      list.add(FormattedMetricItem(
        label: '営業活動CF',
        formattedValue: formatAmount(ocf),
        isNegative: ocf < 0,
        rawValue: ocf,
      ));
    }

    final icf = metrics.investingCashFlow;
    if (icf != null) {
      list.add(FormattedMetricItem(
        label: '投資活動CF',
        formattedValue: formatAmount(icf),
        isNegative: icf < 0,
        rawValue: icf,
      ));
    }

    final fcfVal = metrics.calculations?.fcf ??
        (ocf != null && icf != null ? ocf + icf : null);
    if (fcfVal != null) {
      list.add(FormattedMetricItem(
        label: 'フリーCF (FCF)',
        formattedValue: formatAmount(fcfVal),
        isNegative: fcfVal < 0,
        rawValue: fcfVal,
      ));
    }

    final netAssets = metrics.netAssets;
    if (netAssets != null) {
      list.add(FormattedMetricItem(
        label: '純資産',
        formattedValue: formatAmount(netAssets),
        isNegative: netAssets < 0,
        rawValue: netAssets,
      ));
    }

    final cash = metrics.cashAndDeposits;
    if (cash != null) {
      list.add(FormattedMetricItem(
        label: '現金及び預金',
        formattedValue: formatAmount(cash),
        isNegative: cash < 0,
        rawValue: cash,
      ));
    }

    return list;
  }

  /// 定量フォレンジック計算指標（アクルーアル・DSRI・DSI・AQI等）の整形リスト
  List<FormattedQuantitativeIndicator> get quantitativeIndicators {
    final calcs = result.metrics?.calculations;
    if (calcs == null) return const [];

    final list = <FormattedQuantitativeIndicator>[];

    // 1. 総資産アクルーアル比率 (Sloan's Accruals)
    if (calcs.accrualsRatio != null) {
      final val = calcs.accrualsRatio!;
      final pct = val * 100;
      final sign = pct > 0 ? '+' : (pct < 0 ? '▲' : '');
      final formatted = '$sign${pct.abs().toStringAsFixed(1)}%';
      final status = val > 0.15
          ? ForensicRiskLevel.critical
          : (val > 0.08 ? ForensicRiskLevel.warning : ForensicRiskLevel.normal);

      list.add(FormattedQuantitativeIndicator(
        key: 'accrualsRatio',
        label: '総資産アクルーアル比率',
        acronym: 'Accruals',
        formattedValue: formatted,
        thresholdDescription: '正常目安: 8.0%未満 (>15.0% 重大)',
        status: status,
        hint: 'キャッシュ創出を伴わない見せかけのペーパー利益・利益の質の劣化を検知',
      ));
    }

    // 2. 売上債権回転期間指数 (Beneish DSRI)
    if (calcs.dsri != null) {
      final val = calcs.dsri!;
      final formatted = '${val.toStringAsFixed(2)}倍';
      final status = val > 1.465
          ? ForensicRiskLevel.critical
          : (val > 1.20 ? ForensicRiskLevel.warning : ForensicRiskLevel.normal);

      list.add(FormattedQuantitativeIndicator(
        key: 'dsri',
        label: '売上債権回転期間指数',
        acronym: 'Beneish DSRI',
        formattedValue: formatted,
        thresholdDescription: '正常目安: 1.20倍以下 (>1.465倍 重大)',
        status: status,
        hint: '期末の押し込み販売・架空売上・回収不能債権の滞留リスクを検知',
      ));
    }

    // 3. 棚卸資産回転期間指数 (DSI Index)
    if (calcs.dsiIndex != null) {
      final val = calcs.dsiIndex!;
      final formatted = '${val.toStringAsFixed(2)}倍';
      final status = val > 1.50
          ? ForensicRiskLevel.critical
          : (val > 1.25 ? ForensicRiskLevel.warning : ForensicRiskLevel.normal);

      list.add(FormattedQuantitativeIndicator(
        key: 'dsiIndex',
        label: '棚卸資産回転期間指数',
        acronym: 'DSI Index',
        formattedValue: formatted,
        thresholdDescription: '正常目安: 1.25倍以下 (>1.50倍 重大)',
        status: status,
        hint: '架空在庫の計上・原価の在庫付け替え（原価圧縮）・不良在庫滞留を検知',
      ));
    }

    // 4. 資産の質指数 (Beneish AQI)
    if (calcs.aqi != null) {
      final val = calcs.aqi!;
      final formatted = '${val.toStringAsFixed(2)}倍';
      final status = val > 1.254
          ? ForensicRiskLevel.critical
          : (val > 1.15 ? ForensicRiskLevel.warning : ForensicRiskLevel.normal);

      list.add(FormattedQuantitativeIndicator(
        key: 'aqi',
        label: '資産の質指数',
        acronym: 'Beneish AQI',
        formattedValue: formatted,
        thresholdDescription: '正常目安: 1.15倍以下 (>1.254倍 重大)',
        status: status,
        hint: '本来費用とすべき支出の無形資産や前払費用への繰延（資産化）リスクを検知',
      ));
    }

    // 5. 対流動負債 現預金比率 (Cash Coverage)
    if (calcs.cashCoverage != null) {
      final val = calcs.cashCoverage!;
      final pct = (val * 100).toStringAsFixed(1);
      final ocf = result.metrics?.effectiveOperatingCashFlow;
      final status = (val < 0.08 && ocf != null && ocf < 0)
          ? ForensicRiskLevel.critical
          : (val < 0.15 ? ForensicRiskLevel.warning : ForensicRiskLevel.normal);

      list.add(FormattedQuantitativeIndicator(
        key: 'cashCoverage',
        label: '対流動負債 現預金比率',
        acronym: 'Cash Coverage',
        formattedValue: '$pct%',
        thresholdDescription: '安全目安: 15.0%以上 (<8.0%かつ営業CF赤字で重大)',
        status: status,
        hint: '1年以内の短期負債に対する手元即時支払余力・資金ショートリスクを検知',
      ));
    }

    // 6. 自己資本比率 (Equity Ratio)
    if (calcs.equityRatio != null) {
      final val = calcs.equityRatio!;
      final pct = (val * 100).toStringAsFixed(1);
      final netAssets = result.metrics?.netAssets;
      final status = (val <= 0 || (netAssets != null && netAssets <= 0))
          ? ForensicRiskLevel.critical
          : (val < 0.10 ? ForensicRiskLevel.warning : ForensicRiskLevel.normal);

      list.add(FormattedQuantitativeIndicator(
        key: 'equityRatio',
        label: '自己資本比率',
        acronym: 'Equity Ratio',
        formattedValue: '$pct%',
        thresholdDescription: '安全目安: 10.0%以上 (0%以下で債務超過)',
        status: status,
        hint: '過剰借入レバレッジおよび債務超過リスクを検知',
      ));
    }

    // 7. 純資産 前期比増減率 (Net Assets Change)
    if (calcs.netAssetsDropRate != null) {
      final val = calcs.netAssetsDropRate!;
      final pct = val * 100;
      final sign = pct > 0 ? '+' : (pct < 0 ? '▲' : '');
      final formatted = '$sign${pct.abs().toStringAsFixed(1)}%';
      final retainedEarnings = result.metrics?.retainedEarnings;
      final status = (val <= -0.30 && retainedEarnings != null && retainedEarnings < 0)
          ? ForensicRiskLevel.critical
          : (val <= -0.30 ? ForensicRiskLevel.warning : ForensicRiskLevel.normal);

      list.add(FormattedQuantitativeIndicator(
        key: 'netAssetsDropRate',
        label: '純資産 前期比増減率',
        acronym: 'Equity Change',
        formattedValue: formatted,
        thresholdDescription: '正常目安: 30.0%以上の急減なし',
        status: status,
        hint: '累積赤字や減損による自己資本の急激な毀損・上場基準抵触リスクを検知',
      ));
    }

    return list;
  }
}
