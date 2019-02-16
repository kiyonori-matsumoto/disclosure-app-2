import 'package:disclosure_app_fl/models/disclosure.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:disclosure_app_fl/utils/downloadDisclosure.dart';
import '../utils/time.dart';

final smallGrey = TextStyle(
  color: Colors.grey,
  fontSize: 10,
);

class DisclosureListItem extends StatelessWidget {
  const DisclosureListItem({
    Key key,
    this.showDate = false,
    @required this.item,
  }) : super(key: key);

  final DocumentSnapshot item;
  final bool showDate;

  Widget viewCountWidget(int viewCount) {
    if (viewCount == null || viewCount == 0) return null;
    return Row(
      children: <Widget>[
        Icon(Icons.cloud_download, size: 10, color: Colors.grey),
        Text(
          "${viewCount.toString()} | ",
          style: smallGrey,
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final Disclosure disclosure = Disclosure.fromDocumentSnapshot(item);
    return ListTile(
      title: Row(
        children: <Widget>[
          Expanded(
            child: Text("${disclosure.company}(${disclosure.code})"),
          ),
          Row(
            children: <Widget>[
              disclosure.tags.length > 0
                  ? Text(
                      "${(disclosure.tags ?? []).join(', ')} | ",
                      style: smallGrey,
                    )
                  : null,
              viewCountWidget(disclosure.viewCount),
              Text(
                toTime(disclosure.time, showDate: showDate),
                style: smallGrey,
              ),
            ].where((e) => e != null).toList(),
          ),
        ],
      ),
      subtitle: Text(
        disclosure.title,
        overflow: TextOverflow.fade,
      ),
      isThreeLine: true,
      onTap: () => downloadAndOpenDisclosure(disclosure),
    );
  }
}
