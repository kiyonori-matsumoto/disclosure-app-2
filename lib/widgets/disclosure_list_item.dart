import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:disclosure_app_fl/utils/downloadDisclosure.dart';
import '../utils/time.dart';

class DisclosureListItem extends StatelessWidget {
  const DisclosureListItem({
    Key key,
    this.showDate = false,
    @required this.item,
  }) : super(key: key);

  final DocumentSnapshot item;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Row(
        children: <Widget>[
          Expanded(
            child: Text("${item.data['company']}(${item.data['code']})"),
          ),
          Text(
            [
              (item.data['tags']?.keys ?? []).join(' | '),
              (item.data['view_count']),
              toTime(item.data['time'], showDate: showDate),
            ].where((e) => e != null && e != '').join(' | '),
            style: TextStyle(
              color: Colors.grey,
              fontSize: 10,
            ),
          ),
        ],
      ),
      subtitle: Text(
        item.data['title'],
        overflow: TextOverflow.fade,
      ),
      isThreeLine: true,
      onTap: () => downloadAndOpenDisclosure(item.data['document']),
    );
  }
}
