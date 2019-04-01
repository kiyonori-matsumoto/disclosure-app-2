import 'package:bloc_provider/bloc_provider.dart';
import 'package:disclosure_app_fl/bloc/bloc.dart';
import 'package:disclosure_app_fl/bloc/company_disclosure_bloc.dart';
import 'package:disclosure_app_fl/models/company-settlement.dart';
import 'package:disclosure_app_fl/models/company.dart';
import 'package:disclosure_app_fl/utils/admob.dart';
import 'package:disclosure_app_fl/widgets/disclosure_list_item.dart';
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

  @override
  initState() {
    super.initState();
    banner = showBanner("ca-app-pub-5131663294295156/4027309882");
  }

  _DisclosureCompanyScreenState({this.company}) {
    this.code = this.company.code;
    this.bloc = CompanyDisclosureBloc(this.code);
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
                            : Container(),
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
        // return Future.value(true);
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

    return Scaffold(
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
                    content: Text(isFavorite ? 'お気に入りを解除しました' : 'お気に入りに追加しました'),
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
                    content: Text(hasNotification ? '通知を解除しました' : '通知を登録しました'),
                  ));
                },
              );
            },
          )
        ],
      ),
      body: _buildBody(context),
      persistentFooterButtons: <Widget>[
        Container(
          height: getSmartBannerHeight(mediaQuery) - 5,
        )
      ],
    );
  }

  @override
  void dispose() {
    banner?.dispose();
    bloc.dispose();
    super.dispose();
  }
}
