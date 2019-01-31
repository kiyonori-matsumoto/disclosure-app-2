import 'package:bloc_provider/bloc_provider.dart';
import 'package:disclosure_app_fl/bloc/bloc.dart';
import 'package:disclosure_app_fl/bloc/company_disclosure_bloc.dart';
import 'package:disclosure_app_fl/models/company.dart';
import 'package:disclosure_app_fl/models/favorite.dart';
import 'package:disclosure_app_fl/models/filter.dart';
import 'package:disclosure_app_fl/widgets/disclosure_list_item.dart';
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

  _DisclosureCompanyScreenState({this.company}) {
    this.code = this.company.code.substring(0, 4);
    this.bloc = CompanyDisclosureBloc(this.code);
  }

  Widget _buildList(BuildContext context, List<DocumentSnapshot> snapshot) {
    return RefreshIndicator(
      child: Scrollbar(
          child: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
            this.bloc.loadNext.add(code);
          }
        },
        child: ListView.builder(
          itemBuilder: (context, index) => new DisclosureListItem(
                item: snapshot[index],
                showDate: true,
                key: Key(snapshot[index]['document']),
              ),
          itemCount: snapshot.length,
        ),
      )),
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
        if (!snapshot.hasData) return LinearProgressIndicator();
        return _buildList(context, snapshot.data);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appBloc = BlocProvider.of<AppBloc>(context);

    return StreamBuilder<List<Favorite>>(
      stream: appBloc.favoritesWithName$,
      builder: (context, snapshot) {
        final isFavorite = snapshot.hasData &&
            snapshot.data.any((fav) => fav.code == this.code);
        return Scaffold(
            appBar: AppBar(
              title: Text("${this.company.name} (${this.code})"),
              actions: <Widget>[
                IconButton(
                  icon: Icon(isFavorite ? Icons.star : Icons.star_border),
                  onPressed: () {
                    appBloc.switchFavorite.add(this.code);
                  },
                )
              ],
            ),
            body: _buildBody(context));
      },
    );
  }

  @override
  void dispose() {
    bloc.dispose();
    super.dispose();
  }
}
