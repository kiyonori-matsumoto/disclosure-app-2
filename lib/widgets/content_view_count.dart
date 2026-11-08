import 'package:flutter/material.dart';

class ContentViewCount extends StatelessWidget {
  const ContentViewCount({
    Key? key,
    required this.viewCount,
  }) : super(key: key);

  final int? viewCount;

  @override
  Widget build(BuildContext context) {
    if (viewCount == null || viewCount == 0) {
      return const SizedBox.shrink();
    }
    final color = Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(Icons.cloud_download, size: 14, color: color),
        const SizedBox(width: 3),
        Text(
          viewCount.toString(),
          style: TextStyle(
            fontSize: 12,
            color: color,
          ),
        ),
      ],
    );
  }
}
