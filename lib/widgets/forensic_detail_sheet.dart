import 'package:flutter/material.dart';
import '../models/forensic_result.dart';
import '../utils/forensic_ui_presenter.dart';

Future<void> showForensicDetailSheet({
  required BuildContext context,
  required ForensicResult forensic,
  String? companyName,
  String? documentTitle,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => ForensicDetailSheet(
      forensic: forensic,
      companyName: companyName,
      documentTitle: documentTitle,
    ),
  );
}

class ForensicDetailSheet extends StatelessWidget {
  final ForensicResult forensic;
  final String? companyName;
  final String? documentTitle;

  const ForensicDetailSheet({
    super.key,
    required this.forensic,
    this.companyName,
    this.documentTitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final presenter = ForensicUiPresenter(forensic);
    final isCritical = forensic.riskLevel == ForensicRiskLevel.critical;
    final isWarning = forensic.riskLevel == ForensicRiskLevel.warning;

    final Color primaryColor;
    final Color cardBgColor;
    final IconData headerIcon;

    if (isCritical) {
      primaryColor = Colors.red;
      cardBgColor = theme.brightness == Brightness.dark
          ? Colors.red.shade900.withValues(alpha: 0.3)
          : Colors.red.shade50;
      headerIcon = Icons.insights;
    } else if (isWarning) {
      primaryColor = Colors.orange.shade800;
      cardBgColor = theme.brightness == Brightness.dark
          ? Colors.orange.shade900.withValues(alpha: 0.3)
          : Colors.orange.shade50;
      headerIcon = Icons.warning_amber_rounded;
    } else {
      primaryColor = Colors.green.shade700;
      cardBgColor = theme.brightness == Brightness.dark
          ? Colors.green.shade900.withValues(alpha: 0.3)
          : Colors.green.shade50;
      headerIcon = Icons.check_circle_outline;
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // ドラッグハンドル
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // ヘッダー
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                children: [
                  Icon(
                    headerIcon,
                    color: primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '定性・財務フォレンジック解析',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: '閉じる',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // スクロール可能な本文コンテンツ
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16.0),
                children: [
                  // 企業名・開示タイトル・会計基準/期間区分
                  if (companyName != null ||
                      documentTitle != null ||
                      presenter.standardLabel != null ||
                      presenter.periodTypeLabel != null ||
                      presenter.isFinancialIndustry) ...[
                    if (companyName != null)
                      Text(
                        companyName!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    if (documentTitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0, bottom: 6.0),
                        child: Text(
                          documentTitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    if (presenter.standardLabel != null ||
                        presenter.periodTypeLabel != null ||
                        presenter.isFinancialIndustry) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (presenter.standardLabel != null)
                              _buildMetadataBadge(
                                context,
                                presenter.standardLabel!,
                                icon: Icons.account_balance_outlined,
                              ),
                            if (presenter.periodTypeLabel != null)
                              _buildMetadataBadge(
                                context,
                                presenter.periodTypeLabel!,
                                icon: Icons.calendar_today_outlined,
                              ),
                            if (presenter.isFinancialIndustry)
                              _buildMetadataBadge(
                                context,
                                '金融業',
                                icon: Icons.account_balance,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],

                  // 総合リスク診断カード
                  Container(
                    padding: const EdgeInsets.all(14.0),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                presenter.riskLevelLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (forensic.analyzedAt != null)
                              Text(
                                '解析: ${forensic.analyzedAt!.year}/${forensic.analyzedAt!.month.toString().padLeft(2, '0')}/${forensic.analyzedAt!.day.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          presenter.headline,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 検出バッジ一覧
                  if (presenter.tagInfos.isNotEmpty) ...[
                    Text(
                      '検出された注記・開示トーン項目',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: presenter.tagInfos.map((tag) {
                        final isTagCritical =
                            tag.severity == ForensicRiskLevel.critical;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isTagCritical
                                ? Colors.red.shade100
                                : Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isTagCritical
                                  ? Colors.red.shade400
                                  : Colors.orange.shade400,
                            ),
                          ),
                          child: Text(
                            tag.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isTagCritical
                                  ? Colors.red.shade900
                                  : Colors.orange.shade900,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 診断解説文
                  Text(
                    '解析結果の概要',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      presenter.composedExplanation,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 要因タグ (causes)
                  if (presenter.causeLabels.isNotEmpty) ...[
                    Text(
                      '開示文書に記載された要因',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: presenter.causeLabels.map((cause) {
                        return Chip(
                          label: Text(cause),
                          labelStyle: const TextStyle(fontSize: 12),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 定量フォレンジック指標（財務モデル分析）
                  if (presenter.quantitativeIndicators.isNotEmpty) ...[
                    Text(
                      '定量フォレンジック指標（財務モデル分析）',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...presenter.quantitativeIndicators.map((ind) {
                      return _buildIndicatorCard(context, ind);
                    }),
                    const SizedBox(height: 16),
                  ],

                  // 主要財務メトリクス表
                  if (presenter.metricItems.isNotEmpty) ...[
                    Text(
                      '主要財務数値（開示実績値）',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: presenter.metricItems.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final item = entry.value;
                          final isLast = idx == presenter.metricItems.length - 1;

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              border: isLast
                                  ? null
                                  : Border(
                                      bottom: BorderSide(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item.label,
                                  style: theme.textTheme.bodyMedium,
                                ),
                                Text(
                                  item.formattedValue,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: item.isNegative
                                        ? Colors.red.shade700
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 免責事項
                  Container(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark
                          ? Colors.grey.shade900
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '※ 本解析結果は開示書類の定性情報および財務数値を機械的に抽出・整理した参考情報です。企業状態の健全性や危険性を評価・格付けするものではなく、特定の有価証券の価値評価や投資の勧誘・助言を目的としたものでもありません。投資に関する最終決定は必ずご自身の判断で行ってください。',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.brightness == Brightness.dark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                  ),

                  // 機械判定基準・算出方法・評価設問の開示（最下部に配置）
                  Container(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.brightness == Brightness.dark
                            ? Colors.grey.shade700
                            : Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Theme(
                      data: theme.copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        leading: const Icon(Icons.help_outline, size: 20),
                        title: Text(
                          '機械判定基準・算出方法・評価設問の開示',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                        children: [
                          Text(
                            '本解析は、開示書類（XBRL主要財務データ・財務諸表注記・MD&A・事業等のリスク）に対し、解析エンジンが以下の客観的算出式および判定基準に基づき機械的に抽出・計算した結果を表示しています。',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.brightness == Brightness.dark
                                  ? Colors.grey.shade300
                                  : Colors.grey.shade700,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // 定量フォレンジック指標の算出式一覧
                          Text(
                            '【定量財務指標の算出式・しきい値基準】',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _buildFormulaDescription(
                            title: '総資産アクルーアル比率 (Sloan Accruals)',
                            formula: '(当期純利益 － 営業活動CF) ÷ 総資産',
                            criteria: '基準値: 8.0%未満（>15.0%でCritical、>8.0%でWarning ※金融業除外）',
                            theme: theme,
                          ),
                          _buildFormulaDescription(
                            title: '売上債権回転期間指数 (Beneish DSRI)',
                            formula: '(当期売上債権 ÷ 当期売上高) ÷ (前期売上債権 ÷ 前期売上高)',
                            criteria: '通期基準: 1.20倍以下（>1.465倍でCritical、>1.20倍でWarning / 四半期は季節性係数1.2倍適用）',
                            theme: theme,
                          ),
                          _buildFormulaDescription(
                            title: '棚卸資産回転期間指数 (DSI Index)',
                            formula: '(当期棚卸資産 ÷ 当期売上高) ÷ (前期棚卸資産 ÷ 前期売上高)',
                            criteria: '通期基準: 1.25倍以下（>1.50倍でCritical、>1.25倍でWarning / 四半期は季節性係数1.2倍適用）',
                            theme: theme,
                          ),
                          _buildFormulaDescription(
                            title: '資産の質指数 (Beneish AQI)',
                            formula: '当期非流動非有形比率 ÷ 前期同比率 [1 - (流動資産+有形固定資産)÷総資産]',
                            criteria: '基準値: 1.15倍以下（>1.254倍でCritical、>1.15倍でWarning ※金融業除外）',
                            theme: theme,
                          ),
                          _buildFormulaDescription(
                            title: '対流動負債 現預金比率 (Cash Coverage)',
                            formula: '現金及び預金 ÷ 流動負債合計',
                            criteria: '基準値: 15.0%以上（<8.0%かつ営業CF赤字でCritical、現預金前期比30%以上急減でWarning ※金融業除外）',
                            theme: theme,
                          ),
                          _buildFormulaDescription(
                            title: '自己資本比率 (Equity Ratio)',
                            formula: '純資産合計 ÷ 総資産合計',
                            criteria: '基準値: 10.0%以上（純資産≦0で債務超過Critical、<10.0%でWarning ※金融業除外）',
                            theme: theme,
                          ),
                          _buildFormulaDescription(
                            title: '純資産 前期比増減率 (Equity Change)',
                            formula: '(当期純資産 － 前期純資産) ÷ 前期純資産',
                            criteria: '基準値: 前期比30%以上の急減なし（累積損失下で30%以上急減時Critical）',
                            theme: theme,
                          ),
                          _buildFormulaDescription(
                            title: '利益超過配当・FCF乖離 (Payout Gap)',
                            formula: '配当性向 ＝ 1株当たり配当額 ÷ 1株当たり当期純利益 / FCF ＝ 営業CF ＋ 投資CF',
                            criteria: '営業CF赤字下の配当または欠損下配当でCritical、FCF赤字下の配当性向50%超でWarning',
                            theme: theme,
                          ),
                          const Divider(height: 16),
                          Text(
                            '【注記・定性トーン等の判定基準設問】',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ...((presenter.tagInfos.isNotEmpty
                                  ? presenter.tagInfos
                                  : ForensicUiPresenter.knownTags.values)
                              .map((tag) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${tag.displayName}：',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: theme.brightness == Brightness.dark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      tag.promptQuestion,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.brightness == Brightness.dark
                                            ? Colors.grey.shade100
                                            : Colors.grey.shade900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList()),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetadataBadge(BuildContext context, String text,
      {IconData? icon}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormulaDescription({
    required String title,
    required String formula,
    required String criteria,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? Colors.white10
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '算出式: $formula',
              style: TextStyle(
                fontSize: 10,
                color: theme.brightness == Brightness.dark
                    ? Colors.grey.shade300
                    : Colors.grey.shade800,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            criteria,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorCard(
      BuildContext context, FormattedQuantitativeIndicator ind) {
    final theme = Theme.of(context);
    final isCritical = ind.status == ForensicRiskLevel.critical;
    final isWarning = ind.status == ForensicRiskLevel.warning;

    final Color statusColor;
    final String statusLabel;
    final Color badgeBgColor;

    if (isCritical) {
      statusColor = Colors.red.shade700;
      statusLabel = 'CRITICAL';
      badgeBgColor = Colors.red.shade100;
    } else if (isWarning) {
      statusColor = Colors.orange.shade800;
      statusLabel = 'WARNING';
      badgeBgColor = Colors.orange.shade100;
    } else {
      statusColor = Colors.green.shade700;
      statusLabel = '基準内';
      badgeBgColor = Colors.green.shade100;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: isCritical
            ? (theme.brightness == Brightness.dark
                ? Colors.red.shade900.withValues(alpha: 0.15)
                : Colors.red.shade50.withValues(alpha: 0.5))
            : (isWarning
                ? (theme.brightness == Brightness.dark
                    ? Colors.orange.shade900.withValues(alpha: 0.15)
                    : Colors.orange.shade50.withValues(alpha: 0.5))
                : theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCritical
              ? Colors.red.shade300
              : (isWarning ? Colors.orange.shade300 : Colors.grey.shade300),
          width: isCritical || isWarning ? 1.2 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ind.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      ind.acronym,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    ind.formattedValue,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isCritical
                          ? Colors.red.shade700
                          : (isWarning ? Colors.orange.shade800 : null),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: badgeBgColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            ind.hint,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? Colors.white10
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '算出式: ${ind.formula}',
              style: TextStyle(
                fontSize: 10,
                color: theme.brightness == Brightness.dark
                    ? Colors.grey.shade300
                    : Colors.grey.shade800,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            ind.thresholdDescription,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
