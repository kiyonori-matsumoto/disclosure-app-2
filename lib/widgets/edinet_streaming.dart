import 'package:bloc_provider/bloc_provider.dart';
import 'package:disclosure_app_fl/bloc/bloc.dart';
import 'package:disclosure_app_fl/bloc/edinet_bloc.dart';
import 'package:disclosure_app_fl/models/company.dart';
import 'package:disclosure_app_fl/models/edinet.dart';
import 'package:disclosure_app_fl/utils/downloadEdinet.dart';
import 'package:disclosure_app_fl/utils/sliver_appbar_delegate.dart';
import 'package:disclosure_app_fl/utils/time.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    this.edinetBloc = EdinetBloc(bloc);
  }

  @override
  Widget build(BuildContext context) {
    // return SafeArea(
    //   top: false,
    //   bottom: false,
    //   child: Builder(builder: (context) {
    // return CustomScrollView(
    //   slivers: <Widget>[
    //     filterToolbar(bloc),
    //     edinetList(bloc),
    //   ],
    // );
    //   }),
    // );
    return edinetList(bloc);
  }

  SliverPersistentHeader filterToolbar(AppBloc bloc) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: SliverAppBarDelegate(
        child: ListView(
          padding: EdgeInsets.all(8.0),
          scrollDirection: Axis.horizontal,
          children: <Widget>[
            StreamBuilder<DateTime>(
              stream: bloc.edinetDate$,
              builder: (context, snapshot) => Container(
                    padding: EdgeInsets.all(4.0),
                    child: ActionChip(
                      avatar: Icon(Icons.calendar_today),
                      label: Text(snapshot.hasData
                          ? formatter.format(snapshot.data)
                          : ''),
                      onPressed: () async {
                        final _date = await showDatePicker(
                          context: context,
                          initialDate: snapshot.data,
                          firstDate: DateTime(2019, 3, 1),
                          lastDate: DateTime.now(),
                        );
                        bloc.edinetDate.add(_date);
                      },
                    ),
                  ),
            ),
            StreamBuilder<String>(
              stream: bloc.edinetFilter$,
              builder: (context, snapshot) {
                final text = snapshot.data ?? '';
                return Container(
                  padding: EdgeInsets.all(4.0),
                  child: ChoiceChip(
                    label: Text(text == '' ? 'なし' : text),
                    avatar: Icon(Icons.filter_list),
                    onSelected: (v) async {
                      final result = await showDialog<String>(
                        context: context,
                        builder: (context) => _dialog(context),
                      );
                      bloc.edintFilterController.add(result);
                    },
                    selected: text != '',
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialog(BuildContext context) => StreamBuilder<String>(
        builder: (context, snapshot) => SimpleDialog(
              title: Text('filter'),
              children: Edinet.docTypes()
                  .map(
                    (type) => Container(
                          child: CheckboxListTile(
                            title: Text(type),
                            value: type == snapshot.data,
                            onChanged: (value) {
                              Navigator.of(context).pop(value ? type : null);
                            },
                          ),
                          padding: EdgeInsets.only(left: 16.0),
                        ),
                  )
                  .toList(),
              contentPadding: EdgeInsets.zero,
            ),
        stream: bloc.edinetFilter$,
      );

  StreamBuilder<List<Edinet>> edinetList(AppBloc bloc) {
    return StreamBuilder<List<Edinet>>(
      stream: edinetBloc.edinet$,
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
                        builder: (context) => Stack(
                                alignment: Alignment.topRight,
                                children: <Widget>[
                                  ListTile(
                                    contentPadding: EdgeInsets.fromLTRB(
                                        16.0, 8.0, 16.0, 0.0),
                                    title: Text(edinet.docDescription),
                                    subtitle: Text(edinet.relatedCompaniesName),
                                    onTap: () =>
                                        downloadAndOpenEdinet(edinet.docId),
                                    // onLongPress:
                                    //     _onLongPress(context, edinet.companies),
                                  ),
                                  Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: <Widget>[
                                        Text(
                                          edinet.docType + " | ",
                                          style: smallGrey,
                                        ),
                                        Text(
                                          toTime(edinet.time),
                                          style: smallGrey,
                                        )
                                      ],
                                    ),
                                  )
                                ]),
                      );
                    }, childCount: snapshot.data.length),
                  )
                : SliverFillRemaining(
                    child: Container(
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(Icons.event_busy),
                          Text("選択した条件の適時開示は0件です"),
                        ],
                      ),
                    ),
                  )
            : SliverToBoxAdapter(
                child: LinearProgressIndicator(),
              );
      },
    );
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
