import 'package:bloc_provider/bloc_provider.dart';
import 'package:disclosure_app_fl/bloc/bloc.dart';
import 'package:disclosure_app_fl/bloc/edinet_bloc.dart';
import 'package:disclosure_app_fl/models/company.dart';
import 'package:disclosure_app_fl/models/edinet.dart';
import 'package:disclosure_app_fl/utils/downloadEdinet.dart';
import 'package:disclosure_app_fl/utils/time.dart';
import 'package:disclosure_app_fl/widgets/content-view-count.dart';
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
  EdinetBloc edinetBloc;
  AppBloc bloc;

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
  final ValueObservable<List<Edinet>> stream;

  EdinetSliverList({@required this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Edinet>>(
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
            ? snapshot.data.length > 0
                ? SliverList(
                    delegate: SliverChildBuilderDelegate((context, idx) {
                      final edinet = snapshot.data[idx];
                      return Builder(
                        builder: (context) =>
                            new EdinetListItem(edinet: edinet),
                      );
                    }, childCount: snapshot.data.length),
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

class EdinetListItem extends StatelessWidget {
  const EdinetListItem({
    Key key,
    @required this.edinet,
    this.showDate = false,
  }) : super(key: key);

  final Edinet edinet;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    return Stack(
        key: Key(edinet.docId),
        alignment: Alignment.topRight,
        children: <Widget>[
          ListTile(
            contentPadding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0.0),
            title: Text(edinet.docDescription),
            subtitle: Text(edinet.relatedCompaniesName),
            onTap: () => downloadAndOpenEdinet(edinet.docId),
            onLongPress: _onLongPress(context, edinet.companies),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Text(
                  edinet.docType + " | ",
                  style: smallGrey,
                ),
                new ContentViewCount(
                  viewCount: edinet.view_count,
                ),
                Text(
                  this.showDate ? toDate(edinet.time) : toTime(edinet.time),
                  style: smallGrey,
                )
              ],
            ),
          )
        ]);
  }

  _onLongPress(BuildContext context, List<Company> companies) => () async {
        if (companies.length == 0) return;

        RenderBox renderBox = context.findRenderObject();
        final point = renderBox.localToGlobal(Offset.zero);
        final size = MediaQuery.of(context).size;
        print(point);
        final choice = await showMenu(
          context: context,
          position: RelativeRect.fromLTRB(size.width, point.dy, 0.0, point.dy),
          items: companies
              .map((company) => PopupMenuItem(
                    child: ListTile(
                      title: Text('${company.name}'),
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
