import 'package:bloc_provider/bloc_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:disclosure_app_fl/bloc/bloc.dart';
import 'package:disclosure_app_fl/utils/time.dart';
import 'package:disclosure_app_fl/widgets/disclosure_list_item.dart';
import 'package:disclosure_app_fl/widgets/drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';

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
      body: _buildBody(context),
      drawer: AppDrawer(),
    );
  }

  Widget _buildBody(BuildContext context) {
    final appBloc = BlocProvider.of<AppBloc>(context);
    return StreamBuilder<Map<String, List<DocumentSnapshot>>>(
      stream: appBloc.user$
          .switchMap((user) => Firestore.instance
              .collection('users')
              .document(user.uid)
              .collection('disclosures')
              .orderBy('add_at', descending: true)
              .snapshots())
          .map((snapshot) =>
              groupBy(snapshot.documents, (e) => toDate(e['add_at']))),
      builder: (context, snapshot) => snapshot.hasData
          ? CustomScrollView(
              slivers: snapshot.data.entries
                  .map((entry) => SliverStickyHeader(
                        header: Container(
                          height: 50.0,
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.only(left: 10.0),
                          child: Text(
                            '追加日: ${entry.key}',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) => Dismissible(
                                  key: Key(entry.value[i].data['document']),
                                  child: DisclosureListItem(
                                    item: entry.value[i],
                                    showDate: true,
                                  ),
                                  onDismissed: ((direction) async {
                                    await entry.value[i].reference.delete();
                                  }),
                                ),
                            childCount: entry.value.length,
                          ),
                        ),
                      ))
                  .toList(),
            )
          : LinearProgressIndicator(),
    );
  }
}
