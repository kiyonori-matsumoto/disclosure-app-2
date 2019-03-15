import 'dart:async';

import 'package:bloc_provider/bloc_provider.dart';
import 'package:disclosure_app_fl/bloc/bloc.dart';
import 'package:disclosure_app_fl/models/filter.dart';
import 'package:disclosure_app_fl/utils/admob.dart';
import 'package:disclosure_app_fl/utils/routeobserver.dart';
import 'package:disclosure_app_fl/widgets/disclosure_list_item.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../widgets/drawer.dart';

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

  // Widget _buildList(BuildContext context, List<DocumentSnapshot> snapshot) {
  //   return ListView.builder(
  //     itemBuilder: (context, index) =>
  //         new DisclosureListItem(item: snapshot[index]),
  //     itemCount: snapshot.length,
  //   );
  // }

  // Widget _buildBody(BuildContext context) {
  //   final bloc = BlocProvider.of<AppBloc>(context);

  //   return StreamBuilder<List<DocumentSnapshot>>(
  //     stream: bloc.disclosure$,
  //     builder: (context, snapshot) {
  //       if (!snapshot.hasData || snapshot.data == null)
  //         return LinearProgressIndicator();
  //       else if (snapshot.data.length == 0) {
  //         return Center(
  //           child: Column(
  //             mainAxisAlignment: MainAxisAlignment.center,
  //             children: <Widget>[
  //               Icon(Icons.event_busy),
  //               Text("選択した条件の適時開示は0件です"),
  //             ],
  //           ),
  //         );
  //       }
  //       return _buildList(context, snapshot.data);
  //     },
  //   );
  // }

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

  // AppBar buildAppBar(DateFormat formatter, AsyncSnapshot<DateTime> snapshot,
  //     Future<dynamic> changeDate(), AppBloc bloc) {
  //   return AppBar(
  //     // Here we take the value from the MyHomePage object that was created by
  //     // the App.build method, and use it to set our appbar title.
  //     title: GestureDetector(
  //       child: Text("${formatter.format(snapshot.data)}"),
  //       onTap: changeDate,
  //     ),
  //     actions: <Widget>[
  //       IconButton(
  //         icon: Stack(
  //           alignment: Alignment.center,
  //           children: <Widget>[
  //             Icon(Icons.calendar_today),
  //             Text(
  //               snapshot.data.day.toString(),
  //               style: TextStyle(
  //                   color: Colors.orange, fontWeight: FontWeight.w500),
  //             ),
  //           ],
  //         ),
  //         onPressed: changeDate,
  //       ),
  //       StreamBuilder(
  //         builder: (context, snapshot) => IconButton(
  //               icon: Stack(
  //                 children: [
  //                   Icon(Icons.filter_list),
  //                   snapshot.data != null && snapshot.data > 0
  //                       ? Container(
  //                           decoration: ShapeDecoration(
  //                               color: Colors.red, shape: CircleBorder()),
  //                           child: Text(
  //                             snapshot.data.toString(),
  //                             style: TextStyle(fontSize: 10.0),
  //                           ),
  //                           padding: EdgeInsets.all(4.0),
  //                         )
  //                       : null,
  //                 ].where((w) => w != null).toList(),
  //                 alignment: Alignment.bottomRight,
  //               ),
  //               onPressed: () async {
  //                 final result = await showDialog(
  //                   context: context,
  //                   builder: (context) => _dialog(context, bloc),
  //                 );
  //                 print(result);
  //               },
  //             ),
  //         stream: bloc.filterCount$,
  //       ),
  //     ],
  //   );
  // }

  buildSliverBody(BuildContext context, {@required AppBloc bloc}) {
    final formatter = DateFormat.yMd('ja');
    final appbar = SliverAppBar(
      title: Text('適時開示一覧'),
      pinned: false,
      floating: true,
      snap: true,
    );

    return SafeArea(
      child: CustomScrollView(
        slivers: <Widget>[
          appbar,
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
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
                            onSelected: (val) =>
                                bloc.setShowOnlyFavorites.add(val),
                          ),
                        ),
                  ),
                ],
              ),
            ),
          ),
          StreamBuilder<List<DocumentSnapshot>>(
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
          ),
        ],
      ),
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

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({
    @required this.child,
  });

  final Widget child;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(
      child: Card(child: child, color: Theme.of(context).secondaryHeaderColor

          // decoration: BoxDecoration(
          //     border:
          //         Border(bottom: BorderSide(color: Colors.black, width: 1.0))),
          // color: Theme.of(context).backgroundColor,
          ),
    );
  }

  @override
  double get maxExtent => 60;

  @override
  double get minExtent => 60;

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}
