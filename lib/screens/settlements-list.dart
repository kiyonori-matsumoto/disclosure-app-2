import 'package:bloc_provider/bloc_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:disclosure_app_fl/bloc/bloc.dart';
import 'package:disclosure_app_fl/models/company.dart';
import 'package:disclosure_app_fl/utils/time.dart';
import 'package:flutter/material.dart';

class SettlementsList extends StatefulWidget {
  @override
  _SettlementsListState createState() => _SettlementsListState();
}

class _SettlementsListState extends State<SettlementsList> {
  late DateTime current;
  final DateTime today;
  final DateTime start;
  final DateTime end;

  _SettlementsListState()
      : today = DateTime.now(),
        start = DateTime.now().subtract(Duration(days: 30)),
        end = DateTime.now().add(Duration(days: 30));

  @override
  void initState() {
    super.initState();
    current = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(toDate(current.millisecondsSinceEpoch) + "の決算予定"),
      ),
      body: _buildBody(context),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.calendar_today),
        onPressed: () {
          showDatePicker(
            context: context,
            initialDate: current,
            firstDate: start,
            lastDate: end,
          ).then((date) {
            if (date != null) {
              setState(() {
                this.current = date;
              });
            }
          });
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final bloc = BlocProvider.of<AppBloc>(context);
    return FutureBuilder(
      initialData: null,
      future: FirebaseFirestore.instance
          .collection('settlements')
          .where('schedule', isEqualTo: toDateHyphenate(current))
          .get(),
      builder: (context, snapshot) => snapshot.data != null
          ? (snapshot.data as QuerySnapshot).docs.length != 0
              ? ListView.builder(
                  itemBuilder: (context, idx) {
                    final data =
                        (snapshot.data as QuerySnapshot<Map<String, dynamic>>)
                            .docs[idx]
                            .data();
                    return ListTile(
                      title: Text("${data['name']} (${data['quote']})"),
                      onTap: () async {
                        final companies = await bloc.company$.first;
                        final company = companies.firstWhere(
                            (e) => e.code == data['code'],
                            orElse: () =>
                                Company(data['code'], name: data['name']));
                        Navigator.pushNamed(context, '/company-disclosures',
                            arguments: company);
                      },
                    );
                  },
                  itemCount: (snapshot.data as QuerySnapshot).docs.length,
                )
              : SizedBox(
                  child: Card(
                    child: Column(
                      children: <Widget>[
                        ListTile(
                          leading: Icon(
                            Icons.announcement,
                            color: Theme.of(context).colorScheme.background,
                          ),
                          title: Text('指定された日の決算予定はありません'),
                        )
                      ],
                    ),
                    shape: RoundedRectangleBorder(),
                  ),
                  width: double.infinity,
                  height: 80.0,
                )
          : LinearProgressIndicator(),
    );
  }

  // Widget _buildBody(BuildContext context) {
  //   return StreamBuilder<QuerySnapshot>(
  //     stream: FirebaseFirestore.instance
  //         .collection('settlements')
  //         .where('schedule', isEqualTo: toDateHyphenate(current))
  //         .snapshots(),
  //     builder: (context, snapshot) => snapshot.hasData
  //         ? snapshot.data.documents.length != 0
  //             ? ListView.builder(
  //                 itemBuilder: (context, idx) {
  //                   return ListTile(
  //                       title: Text(snapshot.data.documents[idx].data['name']));
  //                 },
  //                 itemCount: snapshot.data.documents.length,
  //               )
  //             : SizedBox(
  //                 child: Card(
  //                   child: Column(
  //                     children: <Widget>[
  //                       ListTile(
  //                         leading: Icon(
  //                           Icons.announcement,
  //                           color: Theme.of(context).backgroundColor,
  //                         ),
  //                         title: Text('指定された日の決算予定はありません'),
  //                       )
  //                     ],
  //                   ),
  //                   shape: RoundedRectangleBorder(),
  //                 ),
  //                 width: double.infinity,
  //                 height: 80.0,
  //               )
  //         : LinearProgressIndicator(),
  //   );
  // }
}
