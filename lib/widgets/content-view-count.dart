import 'package:disclosure_app_fl/screens/disclosure-stream.dart';
import 'package:flutter/material.dart';

class ContentViewCount extends StatelessWidget {
  const ContentViewCount({
    Key? key,
    required this.viewCount,
  }) : super(key: key);

  final int? viewCount;

  @override
  Widget build(BuildContext context) {
    if (viewCount == null || viewCount == 0)
      return const SizedBox(width: 0.0, height: 0.0);
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
}
