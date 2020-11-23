import 'package:bloc_provider/bloc_provider.dart';
import 'package:disclosure_app_fl/bloc/bloc.dart';
import 'package:disclosure_app_fl/bloc/company_disclosure_bloc2.dart';
import 'package:disclosure_app_fl/models/company-settlement.dart';
import 'package:disclosure_app_fl/models/company.dart';
import 'package:disclosure_app_fl/models/edinet.dart';
import 'package:disclosure_app_fl/utils/admob.dart';
import 'package:disclosure_app_fl/widgets/disclosure_list_item.dart';
import 'package:disclosure_app_fl/widgets/edinet_streaming.dart';
import 'package:disclosure_app_fl/widgets/histories_stream.dart';
import 'package:disclosure_app_fl/widgets/no_disclosures.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DisclosureCompanyScreen extends StatefulWidget {
  final Company company;

  DisclosureCompanyScreen({this.company});

  @override
  _DisclosureCompanyScreenState createState() =>
      _DisclosureCompanyScreenState(company: this.company);
}

class _DisclosureCompanyScreenState extends State<DisclosureCompanyScreen> {
  final Company company;
  BannerAd banner;
  int tabLength;
  CompanyDisclosureBloc2 bloc2;

  @override
  initState() {
    super.initState();
    banner = showBanner("ca-app-pub-5131663294295156/4027309882");
    final appBloc = BlocProvider.of<AppBloc>(context);
    if (company.edinetCode != '') {
      tabLength = 2;
    } else {
      tabLength = 1;
    }
    this.bloc2 = CompanyDisclosureBloc2(
      this.company,
      companies: appBloc.companyMap$,
      user$: appBloc.user$,
    );
    this.bloc2.disclosure.reload.add(null);
    if (company.edinetCode != '') {
      this.bloc2.edinet.reload.add(null);
    }
  }

  _DisclosureCompanyScreenState({this.company}) {}

  Widget _buildList(BuildContext context, List<DocumentSnapshot> snapshot) {
    return RefreshIndicator(
      child: (snapshot.length == 0
          ? const NoDisclosures()
          : CustomScrollView(slivers: <Widget>[
              StreamBuilder<CompanySettlement>(
                stream: bloc2.companySettlement$,
                builder: (context, snapshot) {
                  return SliverList(
                    delegate: SliverChildListDelegate(
                      (!snapshot.hasData ||
                              snapshot.data == null ||
                              snapshot.data.schedule == null ||
                              snapshot.data.schedule
                                  .add(Duration(days: 1))
                                  .isBefore(DateTime.now()))
                          ? []
                          : [
                              Card(
                                child: Column(
                                  children: <Widget>[
                                    ListTile(
                                      leading: Icon(
                                        Icons.announcement,
                                        color:
                                            Theme.of(context).backgroundColor,
                                      ),
                                      title: Text(snapshot.data.toMessage()),
                                    )
                                  ],
                                ),
                                shape: RoundedRectangleBorder(),
                              )
                            ],
                    ),
                  );
                },
              ),
              DisclosureHistoriesStreamWidget(
                builder: (histories) => SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => DisclosureListItem(
                      item: snapshot[index],
                      showDate: true,
                      histories: histories,
                      key: Key(snapshot[index]['document']),
                    ),
                    childCount: snapshot.length,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: RaisedButton(
                    child: StreamBuilder<bool>(
                        stream: bloc2.disclosure.isLoading$,
                        builder: (context, snapshot) {
                          return snapshot.data == false
                              ? Text('更に読み込む')
                              : CircularProgressIndicator();
                        }),
                    onPressed: () {
                      this.bloc2.disclosure?.loadNext?.add(snapshot.last);
                    },
                  ),
                ),
              )
            ])),
      onRefresh: () {
        bloc2.disclosure?.reload?.add(this.company.code);
        return bloc2.disclosure?.isLoading$?.where((e) => e)?.first;
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    return StreamBuilder<List<DocumentSnapshot>>(
      stream: bloc2.disclosure.data$,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return Column(
            children: <Widget>[
              LinearProgressIndicator(),
            ],
          );
        }
        return _buildList(context, snapshot.data);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appBloc = BlocProvider.of<AppBloc>(context);
    final mediaQuery = MediaQuery.of(context);

    return DefaultTabController(
      length: this.tabLength,
      child: Scaffold(
        appBar: AppBar(
          title: Text("${this.company.name} (${this.company.code})"),
          actions: <Widget>[
            StreamBuilder<List<Company>>(
              stream: appBloc.favoritesWithName$,
              builder: (context, snapshot) {
                final isFavorite = snapshot.hasData &&
                    snapshot.data.any((fav) => fav.code == this.company.code);
                return IconButton(
                  icon: Icon(isFavorite ? Icons.star : Icons.star_border),
                  tooltip: 'お気に入り',
                  onPressed: () {
                    appBloc.switchFavorite.add(this.company.code);
                    Scaffold.of(context).showSnackBar(SnackBar(
                      content:
                          Text(isFavorite ? 'お気に入りを解除しました' : 'お気に入りに追加しました'),
                    ));
                  },
                );
              },
            ),
          ],
          bottom: TabBar(tabs: <Widget>[
            Tab(
              text: 'TDNET',
            ),
            if (this.company.edinetCode != '')
              Tab(
                text: 'EDINET',
              ),
          ]),
        ),
        body: TabBarView(
            children: <Widget>[
          _buildBody(context),
          this.tabLength == 2 ? _buildEdinetList(context) : null,
        ].where((e) => e != null).toList()),
        persistentFooterButtons: <Widget>[
          SizedBox(
            height: getSmartBannerHeight(mediaQuery) - 16.0,
          )
        ],
      ),
    );
  }

  Widget _buildEdinetList(BuildContext context) {
    return StreamBuilder<List<Edinet>>(
        stream: bloc2.edinet.data$,
        builder: (context, snapshot) {
          return RefreshIndicator(
            child: Builder(builder: (context) {
              if (!snapshot.hasData || snapshot.data == null) {
                return Column(
                  children: <Widget>[
                    LinearProgressIndicator(),
                  ],
                );
              }
              if (snapshot.data.length == 0) {
                return Container(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.event_busy),
                      Text("選択した条件の適時開示は0件です"),
                    ],
                  ),
                );
              }
              return EdinetHistoriesStreamWidget(
                builder: (histories) => ListView.builder(
                  itemBuilder: (context, idx) {
                    return idx == snapshot.data.length
                        ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: RaisedButton(
                              child: StreamBuilder<bool>(
                                stream: bloc2.edinet.isLoading$,
                                builder: (context, snapshot) {
                                  return snapshot.data == false
                                      ? Text('更に読み込む')
                                      : CircularProgressIndicator();
                                },
                              ),
                              onPressed: () {
                                this
                                    .bloc2
                                    .edinet
                                    ?.loadNext
                                    ?.add(snapshot.data.last);
                              },
                            ),
                          )
                        : EdinetListItem(
                            edinet: snapshot.data[idx],
                            histories: histories,
                            showDate: true,
                          );
                  },
                  itemCount: snapshot.data.length + 1,
                ),
              );
            }),
            onRefresh: () {
              bloc2.edinet.reload.add(null);
              return bloc2.edinet.data$.first;
            },
          );
        });
  }

  @override
  void dispose() {
    banner?.dispose();
    bloc2?.dispose();
    super.dispose();
  }
}
