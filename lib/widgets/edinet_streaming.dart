import 'package:disclosure_app_fl/models/company.dart';
import 'package:disclosure_app_fl/models/edinet.dart';
import 'package:disclosure_app_fl/providers/edinet_disclosures_provider.dart';
import 'package:disclosure_app_fl/providers/remote_config_provider.dart';
import 'package:disclosure_app_fl/utils/download_edinet.dart';
import 'package:disclosure_app_fl/utils/time.dart';
import 'package:disclosure_app_fl/widgets/content_view_count.dart';
import 'package:disclosure_app_fl/widgets/forensic_badge.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'no_disclosures.dart';

class EdinetStreamingWidget extends ConsumerWidget {
  const EdinetStreamingWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final edinetsAsync = ref.watch(filteredEdinetsProvider);

    return edinetsAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: LinearProgressIndicator(),
      ),
      error: (error, stack) => SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.event_busy),
              const SizedBox(height: 8),
              Text(error.toString()),
            ],
          ),
        ),
      ),
      data: (edinets) {
        if (edinets.isEmpty) {
          return const SliverFillRemaining(
            child: NoDisclosures(),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, idx) => EdinetListItem(
              key: Key(edinets[idx].docId ?? '$idx'),
              edinet: edinets[idx],
            ),
            childCount: edinets.length,
          ),
        );
      },
    );
  }
}

class EdinetListItem extends ConsumerStatefulWidget {
  const EdinetListItem({
    Key? key,
    required this.edinet,
    this.showDate = false,
  }) : super(key: key);

  final Edinet edinet;
  final bool showDate;

  @override
  ConsumerState<EdinetListItem> createState() => _EdinetListItemState();
}

class _EdinetListItemState extends ConsumerState<EdinetListItem> {
  bool isDownloading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final companyColor =
        isDark ? theme.colorScheme.onSurface : Colors.grey.shade800;
    final secondaryTextColor = theme.colorScheme.onSurfaceVariant;
    final time = widget.edinet.time ?? 0;
    final docType = widget.edinet.docType;
    final hasViewCount =
        widget.edinet.viewCount != null && widget.edinet.viewCount! > 0;
    final isForensicEnabled = ref.watch(isForensicEnabledProvider);
    final showForensic = isForensicEnabled && widget.edinet.forensic != null;
    final hasBottomRow = showForensic || docType.isNotEmpty;
    final companiesWithCode = widget.edinet.companies;
    final primaryCode =
        companiesWithCode.isNotEmpty ? companiesWithCode.first?.code : null;

    return Stack(
      alignment: AlignmentDirectional.center,
      children: <Widget>[
        InkWell(
          onTap: isDownloading
              ? null
              : () async {
                  try {
                    setState(() {
                      isDownloading = true;
                    });
                    await downloadAndOpenEdinet(widget.edinet.docId);
                  } catch (e, stack) {
                    debugPrint("Failed to download EDINET document: $e");
                    FirebaseCrashlytics.instance
                        .recordError(e, stack, fatal: false);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('EDINET文書の取得に失敗しました'),
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
          onLongPress: _onLongPress(context, widget.edinet.companies),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 11.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1行目: [証券コード] 会社名 + [閲覧数] [時刻]
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if ((primaryCode ?? '').isNotEmpty) ...[
                          Text(
                            primaryCode!,
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
                            widget.edinet.relatedCompaniesName,
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
                          ContentViewCount(
                            viewCount: widget.edinet.viewCount,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          widget.showDate ? toDate(time) : toTime(time),
                          style: TextStyle(
                            fontSize: 12,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    // 2行目: 書類タイトル
                    Text(
                      widget.edinet.docDescription ?? "",
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.normal,
                        height: 1.35,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    // 3行目: フォレンジックバッジ + 書類種別
                    if (hasBottomRow) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (showForensic) ...[
                            ForensicBadge(
                              forensic: widget.edinet.forensic,
                              companyName: widget.edinet.relatedCompaniesName,
                              documentTitle: widget.edinet.docDescription,
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (docType.isNotEmpty)
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
                                docType,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: secondaryTextColor,
                                ),
                              ),
                            ),
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

  _onLongPress(BuildContext context, List<Company?> companies) => () async {
        if (companies.isEmpty) return;

        RenderBox renderBox = context.findRenderObject() as RenderBox;
        final point = renderBox.localToGlobal(Offset.zero);
        final size = MediaQuery.of(context).size;
        final choice = await showMenu<Company>(
          context: context,
          position: RelativeRect.fromLTRB(size.width, point.dy, 0.0, point.dy),
          items: companies
              .map((company) => PopupMenuItem<Company>(
                    child: ListTile(
                      title: Text('${company!.name}'),
                    ),
                    value: company,
                  ))
              .toList(),
        );
        if (choice != null && context.mounted) {
          Navigator.pushNamed(context, '/company-disclosures',
              arguments: choice);
        }
      };
}
