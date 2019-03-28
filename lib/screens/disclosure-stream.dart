import 'dart:async';
import 'dart:io';

import 'package:bloc_provider/bloc_provider.dart';
import 'package:disclosure_app_fl/bloc/bloc.dart';
import 'package:disclosure_app_fl/models/edinet.dart';
import 'package:disclosure_app_fl/models/filter.dart';
import 'package:disclosure_app_fl/utils/admob.dart';
import 'package:disclosure_app_fl/utils/routeobserver.dart';
import 'package:disclosure_app_fl/utils/sliver_appbar_delegate.dart';
import 'package:disclosure_app_fl/utils/time.dart';
import 'package:disclosure_app_fl/widgets/disclosure_list_item.dart';
import 'package:disclosure_app_fl/widgets/edinet_streaming.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import '../widgets/drawer.dart';
import 'package:http/http.dart';

final smallGrey = TextStyle(
  color: Colors.grey,
  fontSize: 10,
);

class DisclosureStreamScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return DisclosureStreamScreenState();
  }
}

class DisclosureStreamScreenState extends State<DisclosureStreamScreen>
    with RouteAware {
  DateTime date = DateTime.now();
  BannerAd banner;
  MyRouteObserver routeObserver = MyRouteObserver();
  bool searching = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context));
  }

  @override
  initState() {
    super.initState();
    if (banner == null) {
      banner = showBanner("ca-app-pub-5131663294295156/8292017322");
    }
  }

  @override
  dispose() {
    print('dispose disclosure-stream');
    routeObserver.unsubscribe(this);
    banner?.dispose();
    banner = null;
    super.dispose();
  }

  void didPopNext() {
    if (banner == null) {
      banner = showBanner("ca-app-pub-5131663294295156/8292017322");
    }
  }

  void didPushNext() {
    banner?.dispose();
    banner = null;
  }

  Widget _dialog(BuildContext context, AppBloc bloc) =>
      StreamBuilder<List<Filter>>(
        builder: (context, snapshot) => SimpleDialog(
              title: Text('filter'),
              children: (snapshot.data ?? [])
                  .map(
                    (filter) => Container(
                          child: CheckboxListTile(
                            title: Text(filter.title),
                            value: filter.isSelected,
                            onChanged: (value) {
                              bloc.addFilter.add(filter.title);
                            },
                          ),
                          padding: EdgeInsets.only(left: 16.0),
                        ),
                  )
                  .toList(),
              contentPadding: EdgeInsets.zero,
            ),
        stream: bloc.filter$,
      );

  @override
  Widget build(BuildContext context) {
    return runZoned(() {
      final bloc = BlocProvider.of<AppBloc>(context);
      final formatter = DateFormat.yMd('ja');

      final mediaQuery = MediaQuery.of(context);
      return StreamBuilder<DateTime>(
          stream: bloc.date$,
          builder: (context, snapshot) {
            if (snapshot.data == null) return Container();

            return Scaffold(
              // appBar: buildAppBar(formatter, snapshot, changeDate, bloc),
              // body: _buildBody(context),
              body: buildSliverBody(context, bloc: bloc),
              drawer: AppDrawer(),
              persistentFooterButtons: <Widget>[
                SizedBox(height: getSmartBannerHeight(mediaQuery) - 16.0),
              ],
            );
          });
    }, onError: (error, stacktrace) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(error.toString()),
              content: Text(stacktrace.toString()),
            ),
      );
      throw (error);
    });
  }

  buildSliverBody(BuildContext context, {@required AppBloc bloc}) {
    final formatter = DateFormat.yMd('ja');
    final appbar = SliverAppBar(
        title: Text('適時開示一覧'),
        pinned: false,
        floating: true,
        snap: false,
        bottom: TabBar(
          tabs: <Widget>[
            Tab(
              text: "TDNET",
            ),
            Tab(text: "EDINET")
          ],
        ));

    return SafeArea(
      child: DefaultTabController(
        length: 2,
        child: NestedScrollView(
          headerSliverBuilder: (context, inner) {
            return [
              appbar,
            ];
          },
          body: TabBarView(
            children: [
              SafeArea(
                top: false,
                bottom: false,
                child: Builder(builder: (context) {
                  return CustomScrollView(
                    slivers: <Widget>[
                      filterToolbar(bloc, formatter),
                      tdnetList(bloc),
                    ],
                  );
                }),
              ),
              EdinetStreamingWidget(),
            ],
          ),
        ),
      ),
    );
  }

  SliverPersistentHeader filterToolbar(AppBloc bloc, DateFormat formatter) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: SliverAppBarDelegate(
        child: ListView(
          padding: EdgeInsets.all(8.0),
          scrollDirection: Axis.horizontal,
          children: <Widget>[
            StreamBuilder<DateTime>(
              stream: bloc.date$,
              builder: (context, snapshot) => Container(
                    padding: EdgeInsets.all(4.0),
                    child: ActionChip(
                      avatar: Icon(Icons.calendar_today),
                      label: Text(snapshot.hasData
                          ? formatter.format(snapshot.data)
                          : ''),
                      onPressed: () {
                        changeDate(bloc, initial: snapshot.data);
                      },
                    ),
                  ),
            ),
            StreamBuilder<int>(
              stream: bloc.filterCount$,
              builder: (context, snapshot) {
                final text = snapshot.data?.toString() ?? '0';
                return Container(
                  padding: EdgeInsets.all(4.0),
                  child: ChoiceChip(
                    label: Text(text),
                    avatar: Icon(Icons.filter_list),
                    onSelected: (v) async {
                      final result = await showDialog(
                        context: context,
                        builder: (context) => _dialog(context, bloc),
                      );
                      print(result);
                    },
                    selected: text != '0',
                  ),
                );
              },
            ),
            StreamBuilder<bool>(
              stream: bloc.showOnlyFavorites$,
              builder: (context, snapshot) => Container(
                    padding: EdgeInsets.all(4.0),
                    child: ChoiceChip(
                      avatar: Icon(Icons.favorite),
                      label: Text('お気に入りのみ表示する'),
                      selected: snapshot.hasData && snapshot.data,
                      onSelected: (val) => bloc.setShowOnlyFavorites.add(val),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  StreamBuilder<List<DocumentSnapshot>> tdnetList(AppBloc bloc) {
    return StreamBuilder<List<DocumentSnapshot>>(
      stream: bloc.disclosure$,
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
                        (context, idx) =>
                            DisclosureListItem(item: snapshot.data[idx]),
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

  changeDate(AppBloc bloc, {DateTime initial}) async {
    final _date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2017, 1, 1),
      lastDate: DateTime.now(),
    );
    if (_date == null) return;
    bloc.date.add(_date);
  }
}
