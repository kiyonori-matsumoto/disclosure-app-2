import 'package:bloc_provider/bloc_provider.dart';
import 'package:disclosure_app_fl/bloc/bloc.dart';
import 'package:disclosure_app_fl/models/company.dart';
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

  _DisclosureCompanyScreenState({this.company});

  Widget _buildList(BuildContext context, List<DocumentSnapshot> snapshot) {
    return RefreshIndicator(
      child: Scrollbar(
          child: ListView.builder(
        itemBuilder: (context, index) =>
            new DisclosureListItem(item: snapshot[index]),
        itemCount: snapshot.length,
      )),
      onRefresh: () {},
    );
  }

  Widget _buildBody(BuildContext context) {
    final bloc = BlocProvider.of<AppBloc>(context);

    return StreamBuilder<List<DocumentSnapshot>>(
      stream: bloc.disclosure$,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return LinearProgressIndicator();
        return _buildList(context, snapshot.data);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${company.name} (${company.code})")),
    );
  }
}
