import 'package:bloc_provider/bloc_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:disclosure_app_fl/bloc/bloc.dart';
import 'package:disclosure_app_fl/models/disclosure.dart';
import 'package:disclosure_app_fl/widgets/disclosure_list_item.dart';
import 'package:flutter/material.dart';

class SavedDisclosuresScreen extends StatefulWidget {
  @override
  _SavedDisclosuresScreenState createState() => _SavedDisclosuresScreenState();
}

class _SavedDisclosuresScreenState extends State<SavedDisclosuresScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("保存したドキュメント"),
        ),
        body: _buildBody(context));
  }

  Widget _buildBody(BuildContext context) {
    final appBloc = BlocProvider.of<AppBloc>(context);
    return StreamBuilder<List<DocumentSnapshot>>(
      stream: appBloc.user$
          .switchMap((user) => Firestore.instance
              .collection('users')
              .document(user.uid)
              .collection('disclosures')
              .orderBy('add_at', descending: true)
              .snapshots())
          .map((snapshot) => snapshot.documents),
      builder: (context, snapshot) => snapshot.hasData
          ? ListView.separated(
              itemBuilder: (context, index) => DisclosureListItem(
                    item: snapshot.data[index],
                    showDate: true,
                  ),
              separatorBuilder: (context, index) => index == 0
                  ? Text(snapshot.data[index]['add_at'].toString())
                  : Container(),
              itemCount: snapshot.data.length,
            )
          : LinearProgressIndicator(),
    );
  }
}
