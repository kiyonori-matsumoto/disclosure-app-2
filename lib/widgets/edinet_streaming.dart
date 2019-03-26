import 'package:bloc_provider/bloc_provider.dart';
import 'package:disclosure_app_fl/bloc/bloc.dart';
import 'package:disclosure_app_fl/bloc/disclosure_bloc.dart';
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
    this.bloc = BlocProvider.of<AppBloc>(context);
    this.edinetBloc = EdinetBloc(bloc);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Builder(builder: (context) {
        return CustomScrollView(
          slivers: <Widget>[
            filterToolbar(bloc),
            edinetList(bloc),
          ],
        );
      }),
    );
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
              stream: edinetBloc.filter$,
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
                      edinetBloc.filterController.add(result);
                    },
                    selected: text != '',
                  ),
                );
              },
            ),
            // StreamBuilder<bool>(
            //   stream: bloc.showOnlyFavorites$,
            //   builder: (context, snapshot) => Container(
            //         padding: EdgeInsets.all(4.0),
            //         child: ChoiceChip(
            //           avatar: Icon(Icons.favorite),
            //           label: Text('お気に入りのみ表示する'),
            //           selected: snapshot.hasData && snapshot.data,
            //           onSelected: (val) => bloc.setShowOnlyFavorites.add(val),
            //         ),
            //       ),
            // ),
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
        stream: edinetBloc.filter$,
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
                    delegate: SliverChildBuilderDelegate(
                        (context, idx) => ListTile(
                            title: Row(
                              children: <Widget>[
                                Expanded(
                                    child: Text(
                                        snapshot.data[idx].docDescription)),
                                Text(
                                  snapshot.data[idx].docType + " | ",
                                  style: smallGrey,
                                ),
                                Text(
                                  toTime(snapshot.data[idx].time),
                                  style: smallGrey,
                                )
                              ],
                            ),
                            subtitle:
                                Text(snapshot.data[idx].relatedCompaniesName),
                            onTap: () => downloadAndOpenEdinet(
                                snapshot.data[idx].docId)),
                        childCount: snapshot.data.length),
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
}
