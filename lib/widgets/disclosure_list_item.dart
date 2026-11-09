import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:disclosure_app_fl/models/disclosure.dart';
import 'package:disclosure_app_fl/providers/company_provider.dart';
import 'package:disclosure_app_fl/providers/remote_config_provider.dart';
import 'package:disclosure_app_fl/providers/saved_disclosures_provider.dart';
import 'package:disclosure_app_fl/utils/download_disclosure.dart';
import 'package:disclosure_app_fl/utils/get_company.dart';
import 'package:disclosure_app_fl/utils/time.dart';
import 'package:disclosure_app_fl/widgets/content_view_count.dart';
import 'package:disclosure_app_fl/widgets/disclosure_action_sheet.dart';
import 'package:disclosure_app_fl/widgets/forensic_badge.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DisclosureListItem extends ConsumerStatefulWidget {
  const DisclosureListItem({
    Key? key,
    this.showDate = false,
    required this.item,
  }) : super(key: key);

  final DocumentSnapshot item;
  final bool showDate;

  @override
  DisclosureListItemState createState() {
    return DisclosureListItemState();
  }
}

class DisclosureListItemState extends ConsumerState<DisclosureListItem> {
  bool isDownloading = false;

  @override
  Widget build(BuildContext context) {
    final Disclosure disclosure = Disclosure.fromDocumentSnapshot(widget.item);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final companyColor =
        isDark ? theme.colorScheme.onSurface : Colors.grey.shade800;
    final secondaryTextColor = theme.colorScheme.onSurfaceVariant;
    final tags = (disclosure.tags ?? []).where((t) => t.isNotEmpty).toList();
    final hasViewCount =
        disclosure.viewCount != null && disclosure.viewCount! > 0;
    final isForensicEnabled = ref.watch(isForensicEnabledProvider);
    final showForensic = isForensicEnabled && disclosure.forensic != null;
    final hasBottomRow = showForensic || tags.isNotEmpty;

    return Stack(
      alignment: AlignmentDirectional.center,
      children: <Widget>[
        InkWell(
          onTap: () async {
            try {
              setState(() {
                isDownloading = true;
              });
              await downloadAndOpenDisclosure(disclosure);
            } catch (e, stack) {
              debugPrint("Failed to download disclosure document: $e");
              FirebaseCrashlytics.instance.recordError(e, stack, fatal: false);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('適時開示文書の取得に失敗しました'),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            } finally {
              if (mounted) {
                setState(() {
                  isDownloading = false;
                });
              }
            }
          },
          onLongPress: () => _showActionMenu(context, disclosure),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1行目: [証券コード] 会社名 + [閲覧数] [時刻]
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if ((disclosure.code ?? '').isNotEmpty) ...[
                          Text(
                            disclosure.code!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: secondaryTextColor,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            disclosure.company ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              color: companyColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (hasViewCount) ...[
                          ContentViewCount(viewCount: disclosure.viewCount),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          toTime(disclosure.time ?? 0,
                              showDate: widget.showDate),
                          style: TextStyle(
                            fontSize: 12,
                            color: secondaryTextColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Tooltip(
                          message: 'オプション',
                          child: InkResponse(
                            radius: 14,
                            onTap: () =>
                                _showActionMenu(context, disclosure),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 2.0, vertical: 2.0),
                              child: Icon(
                                Icons.more_horiz,
                                size: 16,
                                color: secondaryTextColor
                                    .withValues(alpha: 0.75),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3.5),
                    // 2行目: 開示タイトル
                    Text(
                      disclosure.title ?? '',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.normal,
                        height: 1.35,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    // 3行目: フォレンジックバッジ + タグ
                    if (hasBottomRow) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (showForensic) ...[
                            ForensicBadge(
                              forensic: disclosure.forensic,
                              companyName:
                                  "${disclosure.company} (${disclosure.code})",
                              documentTitle: disclosure.title,
                            ),
                            const SizedBox(width: 6),
                          ],
                          for (final tag in tags) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1.5),
                              margin: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: secondaryTextColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Divider(
                height: 1,
                thickness: 0.5,
                color: theme.dividerColor.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
        if (isDownloading) const CircularProgressIndicator(),
      ],
    );
  }

  void _showActionMenu(BuildContext context, Disclosure disclosure) {
    final companyName = disclosure.company ?? '';
    final code = disclosure.code ?? '';
    final title = code.isNotEmpty ? '$companyName ($code)' : companyName;

    showItemActionSheet(
      context: context,
      title: title.isNotEmpty ? title : '適時開示情報',
      subtitle: disclosure.title,
      items: [
        ActionSheetItem(
          icon: Icons.bookmark_add_outlined,
          title: '保存',
          onTap: () {
            ref.read(savedDisclosuresActionProvider.notifier).save(disclosure);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('保存しました'),
                duration: Duration(seconds: 3),
              ),
            );
          },
        ),
        if (code.isNotEmpty || companyName.isNotEmpty)
          ActionSheetItem(
            icon: Icons.business_outlined,
            title: code.isNotEmpty ? '$codeの適時開示情報' : '適時開示情報',
            onTap: () async {
              final companyCodeMap = ref.read(companyCodeMapProvider);
              final company = await getCompany(
                code: disclosure.code,
                name: disclosure.company,
                companyCodeMap: companyCodeMap,
              );
              if (context.mounted) {
                Navigator.pushNamed(
                  context,
                  '/company-disclosures',
                  arguments: company,
                );
              }
            },
          ),
      ],
    );
  }
}
