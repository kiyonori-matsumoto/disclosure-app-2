import 'package:bloc_provider/bloc_provider.dart';
import 'package:disclosure_app_fl/bloc/bloc.dart';
import 'package:disclosure_app_fl/bloc/company_disclosure_bloc2.dart';
import 'package:disclosure_app_fl/models/company_settlement.dart';
import 'package:disclosure_app_fl/models/company.dart';
import 'package:disclosure_app_fl/models/edinet.dart';
import 'package:disclosure_app_fl/widgets/banner_ad.dart';
import 'package:disclosure_app_fl/widgets/disclosure_list_item.dart';
import 'package:disclosure_app_fl/widgets/edinet_streaming.dart';
import 'package:disclosure_app_fl/widgets/no_disclosures.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DisclosureCompanyScreen extends StatefulWidget {
  final Company? company;

  DisclosureCompanyScreen({this.company});

  @override
  _DisclosureCompanyScreenState createState() =>
      _DisclosureCompanyScreenState(company: this.company);
}

class _DisclosureCompanyScreenState extends State<DisclosureCompanyScreen> {
  int tabLength = 1;
  CompanyDisclosureBloc2? bloc2;

  Company? get _company => widget.company;

  @override
  void initState() {
    super.initState();
    final appBloc = BlocProvider.of<AppBloc>(context);
    final company = _company;
    final hasEdinet = (company?.edinetCode ?? '').isNotEmpty;
    tabLength = hasEdinet ? 2 : 1;

    if (company != null) {
      bloc2 = CompanyDisclosureBloc2(
        company,
        companies: appBloc.companyMap$,
        user$: appBloc.user$,
      );
      bloc2?.disclosure?.reload.add(null);
      if (hasEdinet) {
        bloc2?.edinet?.reload.add(null);
      }
    }
  }

  _DisclosureCompanyScreenState({Company? company});

  Widget _buildList(BuildContext context, List<DocumentSnapshot> snapshot) {
    final disclosureBloc = bloc2?.disclosure;
    return RefreshIndicator(
      child: (snapshot.isEmpty
          ? const NoDisclosures()
          : CustomScrollView(slivers: <Widget>[
              StreamBuilder<CompanySettlement?>(
                stream: bloc2?.companySettlement$,
                builder: (context, snapshot) {
                  return SliverList(
                    delegate: SliverChildListDelegate(
                      (!snapshot.hasData ||
                              snapshot.data == null ||
                              snapshot.data!.schedule == null ||
                              snapshot.data!.schedule!
                                  .add(const Duration(days: 1))
                                  .isBefore(DateTime.now()))
                          ? []
                          : [
                              Card(
                                shape: const RoundedRectangleBorder(),
                                child: Column(
                                  children: <Widget>[
                                    ListTile(
                                      leading: Icon(
                                        Icons.announcement,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surface,
                                      ),
                                      title: Text(snapshot.data!.toMessage()),
                                    )
                                  ],
                                ),
                              )
                            ],
                    ),
                  );
                },
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final doc = snapshot[index];
                    final data = doc.data() as Map<String, dynamic>?;
                    final docKey = data?['document']?.toString() ?? doc.id;
                    return DisclosureListItem(
                      item: doc,
                      showDate: true,
                      key: Key(docKey),
                    );
                  },
                  childCount: snapshot.length,
                ),
              ),
              if (disclosureBloc != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 24.0),
                    child: ElevatedButton(
                      child: StreamBuilder<bool>(
                          stream: disclosureBloc.isLoading$,
                          builder: (context, snapshot) {
                            return snapshot.data == false
                                ? const Text('更に読み込む')
                                : const CircularProgressIndicator();
                          }),
                      onPressed: () {
                        disclosureBloc.loadNext.add(snapshot.last);
                      },
                    ),
                  ),
                )
            ])),
      onRefresh: () async {
        final code = _company?.code;
        if (code != null && disclosureBloc != null) {
          disclosureBloc.reload.add(code);
          await disclosureBloc.isLoading$.firstWhere((e) => !e, orElse: () => false);
        }
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    final disclosureBloc = bloc2?.disclosure;
    if (disclosureBloc == null) {
      return const NoDisclosures();
    }
    return StreamBuilder<List<DocumentSnapshot>?>(
      stream: disclosureBloc.data$,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const Column(
            children: <Widget>[
              LinearProgressIndicator(),
            ],
          );
        }
        return _buildList(context, snapshot.data!);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appBloc = BlocProvider.of<AppBloc>(context);
    final company = _company;
    final companyName = company?.name ?? '';
    final companyCode = company?.code ?? '';
    final hasEdinet = (company?.edinetCode ?? '').isNotEmpty;
    final title = companyName.isNotEmpty
        ? (companyCode.isNotEmpty ? "$companyName ($companyCode)" : companyName)
        : (companyCode.isNotEmpty ? companyCode : '会社詳細');

    return DefaultTabController(
      length: tabLength,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: <Widget>[
            if (companyCode.isNotEmpty)
              StreamBuilder<List<Company>>(
                stream: appBloc.favoritesWithName$,
                builder: (context, snapshot) {
                  final isFavorite = snapshot.hasData &&
                      snapshot.data!
                          .any((fav) => fav.code == companyCode);
                  return IconButton(
                    icon: Icon(isFavorite ? Icons.star : Icons.star_border),
                    tooltip: 'お気に入り',
                    onPressed: () {
                      appBloc.switchFavorite.add(companyCode);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(isFavorite
                            ? 'お気に入りを解除しました'
                            : 'お気に入りに追加しました'),
                      ));
                    },
                  );
                },
              ),
          ],
          bottom: TabBar(tabs: <Widget>[
            const Tab(
              text: 'TDNET',
            ),
            if (hasEdinet)
              const Tab(
                text: 'EDINET',
              ),
          ]),
        ),
        body: TabBarView(
          children: <Widget>[
            _buildBody(context),
            if (tabLength == 2) _buildEdinetList(context),
          ],
        ),
        bottomNavigationBar: const BannerAdWidget(),
      ),
    );
  }

  Widget _buildEdinetList(BuildContext context) {
    final edinetBloc = bloc2?.edinet;
    if (edinetBloc == null) {
      return Container(
        alignment: Alignment.center,
        child: const Text("選択した条件の適時開示は0件です"),
      );
    }
    return StreamBuilder<List<Edinet>?>(
        stream: edinetBloc.data$,
        builder: (context, snapshot) {
          return RefreshIndicator(
            child: Builder(builder: (context) {
              if (!snapshot.hasData || snapshot.data == null) {
                return const Column(
                  children: <Widget>[
                    LinearProgressIndicator(),
                  ],
                );
              }
              if (snapshot.data!.isEmpty) {
                return Container(
                  alignment: Alignment.center,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.event_busy),
                      Text("選択した条件の適時開示は0件です"),
                    ],
                  ),
                );
              }
              return ListView.builder(
                itemBuilder: (context, idx) {
                  return idx == snapshot.data!.length
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 24.0),
                          child: ElevatedButton(
                            child: StreamBuilder<bool>(
                              stream: edinetBloc.isLoading$,
                              builder: (context, snapshot) {
                                return snapshot.data == false
                                    ? const Text('更に読み込む')
                                    : const CircularProgressIndicator();
                              },
                            ),
                            onPressed: () {
                              edinetBloc.loadNext.add(snapshot.data!.last);
                            },
                          ),
                        )
                      : EdinetListItem(
                          edinet: snapshot.data![idx],
                          showDate: true,
                        );
                },
                itemCount: snapshot.data!.length + 1,
              );
            }),
            onRefresh: () async {
              edinetBloc.reload.add(null);
              await edinetBloc.data$.first;
            },
          );
        });
  }

  @override
  void dispose() {
    bloc2?.dispose();
    super.dispose();
  }
}
