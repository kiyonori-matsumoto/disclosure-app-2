import 'package:bloc_provider/bloc_provider.dart';
import 'package:disclosure_app_fl/bloc/bloc.dart';
import 'package:disclosure_app_fl/models/company.dart';
import 'package:disclosure_app_fl/models/disclosure.dart';
import 'package:disclosure_app_fl/screens/disclosure-company.dart';
import 'package:disclosure_app_fl/widgets/content-view-count.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:disclosure_app_fl/utils/get_company.dart';

import 'package:disclosure_app_fl/utils/downloadDisclosure.dart';
import '../utils/time.dart';

final smallGrey = TextStyle(
  color: Colors.grey,
  fontSize: 10,
);

class DisclosureListItem extends StatefulWidget {
  const DisclosureListItem({
    Key? key,
    this.showDate = false,
    required this.item,
  }) : super(key: key);

  final DocumentSnapshot item;
  final bool showDate;

  @override
  DisclosureListItemState createState() {
    return new DisclosureListItemState();
  }
}

class DisclosureListItemState extends State<DisclosureListItem> {
  bool isDownloading = false;

  @override
  Widget build(BuildContext context) {
    final Disclosure disclosure = Disclosure.fromDocumentSnapshot(widget.item);
    final bloc = BlocProvider.of<AppBloc>(context);
    return Stack(
      alignment: AlignmentDirectional.center,
      children: <Widget>[
        isDownloading ? CircularProgressIndicator() : Container(),
        ListTile(
          title: Row(
            children: <Widget>[
              Expanded(
                child: Text("${disclosure.company}(${disclosure.code})"),
              ),
              Row(
                children: <Widget>[
                  if (disclosure.tags!.length > 0)
                    Text(
                      "${(disclosure.tags ?? []).join(', ')} | ",
                      style: smallGrey,
                    ),
                  new ContentViewCount(viewCount: disclosure.viewCount),
                  Text(
                    toTime(disclosure.time!, showDate: widget.showDate),
                    style: smallGrey,
                  ),
                ],
              ),
            ],
          ),
          subtitle: Text(
            disclosure.title!,
            overflow: TextOverflow.fade,
          ),
          isThreeLine: true,
          onTap: () async {
            try {
              setState(() {
                isDownloading = true;
              });
              await downloadAndOpenDisclosure(disclosure);
            } finally {
              setState(() {
                isDownloading = false;
              });
            }
          },
          onLongPress: () async {
            RenderBox renderBox = context.findRenderObject() as RenderBox;
            final point = renderBox.localToGlobal(Offset.zero);
            final size = MediaQuery.of(context).size;
            print(point);
            final choice = await showMenu(
              context: context,
              position:
                  RelativeRect.fromLTRB(size.width, point.dy, 0.0, point.dy),
              items: [
                const PopupMenuItem(
                  child: ListTile(
                    leading: Icon(
                      Icons.save,
                      color: Colors.grey,
                    ),
                    title: Text('保存'),
                  ),
                  value: 0,
                ),
                PopupMenuItem(
                  child: ListTile(
                    title: Text('${disclosure.code}の適時開示情報'),
                  ),
                  value: 1,
                ),
              ],
            );
            if (choice == 0) {
              bloc.saveDisclosure.add(disclosure);
              Scaffold.of(context).showSnackBar(SnackBar(
                content: Text('保存しました'),
                duration: Duration(seconds: 3),
              ));
            }
            if (choice == 1) {
              final company = await getCompany(bloc,
                  code: disclosure.code, name: disclosure.company);
              Navigator.pushNamed(context, '/company-disclosures',
                  arguments: company);
            }
          },
        ),
      ],
    );
  }
}
