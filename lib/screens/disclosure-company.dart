import 'package:bloc_provider/bloc_provider.dart';
import 'package:disclosure_app_fl/bloc/bloc.dart';
import 'package:disclosure_app_fl/bloc/company_disclosure_bloc.dart';
import 'package:disclosure_app_fl/models/company-settlement.dart';
import 'package:disclosure_app_fl/models/company.dart';
import 'package:disclosure_app_fl/models/edinet.dart';
import 'package:disclosure_app_fl/utils/admob.dart';
import 'package:disclosure_app_fl/widgets/disclosure_list_item.dart';
import 'package:disclosure_app_fl/widgets/edinet_streaming.dart';
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
  String code;
  CompanyDisclosureBloc bloc;
  BannerAd banner;
  int tabLength;

  @override
  initState() {
    super.initState();
    banner = showBanner("ca-app-pub-5131663294295156/4027309882");
    final appBloc = BlocProvider.of<AppBloc>(context);
    this.bloc = CompanyDisclosureBloc(
      this.code,
      companies: appBloc.companyMap$,
      user$: appBloc.user$,
    );
    if (company.edinetCode != '') {
      this.bloc.edinetInit.add(company.edinetCode);
      tabLength = 2;
    } else {
      tabLength = 1;
    }
  }

  _DisclosureCompanyScreenState({this.company}) {
    this.code = this.company.code;
  }

  Widget _buildList(BuildContext context, List<DocumentSnapshot> snapshot) {
    return RefreshIndicator(
      child: Scrollbar(
        child: NotificationListener<ScrollNotification>(
          onNotification: (scrollInfo) {
            if (scrollInfo.metrics.pixels ==
                scrollInfo.metrics.maxScrollExtent) {
              this.bloc.loadNext.add(code);
            }
          },
          child: CustomScrollView(slivers: <Widget>[
            StreamBuilder<CompanySettlement>(
                stream: bloc.companySettlement$,
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
                }),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => index == snapshot.length
                    ? StreamBuilder(
                        stream: bloc.isLoading$,
                        builder: (context, snapshot) => snapshot.data
                            ? Container(
                                alignment: Alignment.center,
                                child: CircularProgressIndicator(),
                              )
                            : SizedBox(),
                        initialData: false,
                      )
                    : new DisclosureListItem(
                        item: snapshot[index],
                        showDate: true,
                        key: Key(snapshot[index]['document']),
                      ),
                childCount: snapshot.length + 1,
              ),
            ),
          ]),
        ),
      ),
      onRefresh: () {
        bloc.reload.add(this.company.code);
        return bloc.isLoading$.where((e) => e).first;
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    return StreamBuilder<List<DocumentSnapshot>>(
      stream: bloc.disclosures$,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return LinearProgressIndicator();
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
          title: Text("${this.company.name} (${this.code})"),
          actions: <Widget>[
            StreamBuilder<List<Company>>(
              stream: appBloc.favoritesWithName$,
              builder: (context, snapshot) {
                final isFavorite = snapshot.hasData &&
                    snapshot.data.any((fav) => fav.code == this.code);
                return IconButton(
                  icon: Icon(isFavorite ? Icons.star : Icons.star_border),
                  tooltip: 'お気に入り',
                  onPressed: () {
                    appBloc.switchFavorite.add(this.code);
                    Scaffold.of(context).showSnackBar(SnackBar(
                      content:
                          Text(isFavorite ? 'お気に入りを解除しました' : 'お気に入りに追加しました'),
                    ));
                  },
                );
              },
            ),
            StreamBuilder<List<Company>>(
              stream: appBloc.notifications$,
              builder: (context, snapshot) {
                final hasNotification = snapshot.hasData &&
                    snapshot.data.any((comp) => comp.code == this.code);
                return IconButton(
                  icon: Icon(hasNotification
                      ? Icons.notifications
                      : Icons.notifications_off),
                  tooltip: '通知',
                  onPressed: () {
                    appBloc.switchNotification.add(this.code);
                    Scaffold.of(context).showSnackBar(SnackBar(
                      content:
                          Text(hasNotification ? '通知を解除しました' : '通知を登録しました'),
                    ));
                  },
                );
              },
            )
          ],
          bottom: TabBar(
            tabs: <Widget>[
              Tab(
                text: 'TDNET',
              ),
              this.company.edinetCode == ''
                  ? null
                  : Tab(
                      text: 'EDINET',
                    ),
            ].where((e) => e != null).toList(),
          ),
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
        stream: bloc.edinet$,
        builder: (context, snapshot) {
          return RefreshIndicator(
            child: Scrollbar(
              child: Builder(builder: (context) {
                if (!snapshot.hasData || snapshot.data == null) {
                  return LinearProgressIndicator();
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
                return NotificationListener<ScrollNotification>(
                    child: ListView.builder(
                      itemBuilder: (context, idx) => EdinetListItem(
                            edinet: snapshot.data[idx],
                            showDate: true,
                          ),
                      itemCount: snapshot.data.length,
                    ),
                    onNotification: (scrollInfo) {
                      print("onNotification");
                      if (snapshot.connectionState == ConnectionState.active) {
                        bloc.edinetLoadNext.add(snapshot.data.last);
                      }
                    });
              }),
            ),
            onRefresh: () {
              bloc.edinetInit.add(this.company.edinetCode);
              return bloc.edinet$.first;
            },
          );
        });
  }

  @override
  void dispose() {
    banner?.dispose();
    super.dispose();
  }
}
