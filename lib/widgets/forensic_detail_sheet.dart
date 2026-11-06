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
      headerIcon = Icons.crisis_alert;
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
                      '定性・財務フォレンジック診断',
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
                  // 企業名・開示タイトル
                  if (companyName != null || documentTitle != null) ...[
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
                        padding: const EdgeInsets.only(top: 2.0, bottom: 8.0),
                        child: Text(
                          documentTitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
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
                      '検出リスク・定性トーン',
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
                    '診断解説',
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
                      '会社側の説明要因',
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

                  // 主要財務メトリクス表
                  if (presenter.metricItems.isNotEmpty) ...[
                    Text(
                      '主要財務メトリクス（検証ファクト）',
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
                    const SizedBox(height: 20),
                  ],

                  // 免責事項
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '※ 本診断は開示書類の定性情報および財務数値を機械的に抽出・解析した参考情報です。特定の有価証券の価値評価や投資の勧誘・助言を目的としたものではありません。投資に関する最終決定は必ずご自身の判断で行ってください。',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                        height: 1.4,
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
}
