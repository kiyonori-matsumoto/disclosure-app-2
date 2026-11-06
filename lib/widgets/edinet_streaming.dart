import 'package:disclosure_app_fl/models/company.dart';
import 'package:disclosure_app_fl/models/edinet.dart';
import 'package:disclosure_app_fl/providers/edinet_disclosures_provider.dart';
import 'package:disclosure_app_fl/utils/download_edinet.dart';
import 'package:disclosure_app_fl/utils/time.dart';
import 'package:disclosure_app_fl/widgets/content_view_count.dart';
import 'package:disclosure_app_fl/widgets/forensic_badge.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'no_disclosures.dart';

final smallGrey = TextStyle(
  color: Colors.grey,
  fontSize: 10,
);

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

class EdinetListItem extends StatefulWidget {
  const EdinetListItem({
    Key? key,
    required this.edinet,
    this.showDate = false,
  }) : super(key: key);

  final Edinet edinet;
  final bool showDate;

  @override
  _EdinetListItemState createState() => _EdinetListItemState();
}

class _EdinetListItemState extends State<EdinetListItem> {
  bool isDownloading = false;

  @override
  Widget build(BuildContext context) {
    final docId = widget.edinet.docId ?? '';
    final time = widget.edinet.time ?? 0;
    return Stack(
      alignment: AlignmentDirectional.center,
      children: <Widget>[
        Stack(
            key: Key(docId),
            alignment: Alignment.topRight,
            children: <Widget>[
              ListTile(
                contentPadding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0.0),
                title: Text(widget.edinet.docDescription ?? ""),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.edinet.relatedCompaniesName),
                    if (widget.edinet.forensic != null) ...[
                      const SizedBox(height: 4),
                      ForensicBadge(
                        forensic: widget.edinet.forensic,
                        companyName: widget.edinet.relatedCompaniesName,
                        documentTitle: widget.edinet.docDescription,
                      ),
                    ],
                  ],
                ),
                onTap: isDownloading ? null : () async {
                  try {
                    setState(() {
                      isDownloading = true;
                    });
                    await downloadAndOpenEdinet(widget.edinet.docId);
                  } catch (e, stack) {
                    debugPrint("Failed to download EDINET document: $e");
                    FirebaseCrashlytics.instance.recordError(e, stack, fatal: false);
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
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      "${widget.edinet.docType} | ",
                      style: smallGrey,
                    ),
                    ContentViewCount(
                      viewCount: widget.edinet.viewCount,
                    ),
                    Text(
                      widget.showDate ? toDate(time) : toTime(time),
                      style: smallGrey,
                    )
                  ],
                ),
              )
            ]),
        isDownloading ? const CircularProgressIndicator() : const SizedBox.shrink(),
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
