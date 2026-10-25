import 'package:bloc_provider/bloc_provider.dart';
import 'package:disclosure_app_fl/bloc/bloc.dart';
import 'package:disclosure_app_fl/bloc/edinet_bloc.dart';
import 'package:disclosure_app_fl/models/company.dart';
import 'package:disclosure_app_fl/models/edinet.dart';
import 'package:disclosure_app_fl/utils/download_edinet.dart';
import 'package:disclosure_app_fl/utils/time.dart';
import 'package:disclosure_app_fl/widgets/content_view_count.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

import 'no_disclosures.dart';

final smallGrey = TextStyle(
  color: Colors.grey,
  fontSize: 10,
);
final formatter = DateFormat.yMd('ja');

class EdinetStreamingWidget extends StatefulWidget {
  @override
  _EdinetStreamingWidgetState createState() => _EdinetStreamingWidgetState();
}

class _EdinetStreamingWidgetState extends State<EdinetStreamingWidget> {
  late EdinetBloc edinetBloc;
  AppBloc? bloc;

  @override
  void initState() {
    super.initState();
    this.bloc = BlocProvider.of<AppBloc>(context);
    this.edinetBloc = BlocProvider.of<EdinetBloc>(context);
  }

  @override
  Widget build(BuildContext context) {
    return EdinetSliverList(stream: this.edinetBloc.edinet$);
  }
}

class EdinetSliverList extends StatelessWidget {
  final ValueStream<List<Edinet>?> stream;

  EdinetSliverList({required this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Edinet>?>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SliverFillRemaining(
            child: Container(
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(Icons.event_busy),
                  Text(snapshot.error.toString()),
                ],
              ),
            ),
          );
        }
        return (snapshot.hasData && snapshot.data != null)
            ? snapshot.data!.length > 0
                ? SliverList(
                    delegate: SliverChildBuilderDelegate((context, idx) {
                      final edinet = snapshot.data![idx];
                      return Builder(
                        builder: (context) =>
                            new EdinetListItem(edinet: edinet),
                      );
                    }, childCount: snapshot.data!.length),
                  )
                : SliverFillRemaining(
                    child: new NoDisclosures(),
                  )
            : SliverToBoxAdapter(
                child: LinearProgressIndicator(),
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
                subtitle: Text(widget.edinet.relatedCompaniesName),
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
        isDownloading ? CircularProgressIndicator() : Container(),
      ],
    );
  }

  _onLongPress(BuildContext context, List<Company?> companies) => () async {
        if (companies.length == 0) return;

        RenderBox renderBox = context.findRenderObject() as RenderBox;
        final point = renderBox.localToGlobal(Offset.zero);
        final size = MediaQuery.of(context).size;
        print(point);
        final choice = await showMenu(
          context: context,
          position: RelativeRect.fromLTRB(size.width, point.dy, 0.0, point.dy),
          items: companies
              .map((company) => PopupMenuItem(
                    child: ListTile(
                      title: Text('${company!.name}'),
                    ),
                    value: company,
                  ))
              .toList(),
        );
        if (choice != null) {
          Navigator.pushNamed(context, '/company-disclosures',
              arguments: choice);
        }
      };
}
