import 'package:flutter/material.dart';

class NoDisclosures extends StatelessWidget {
  const NoDisclosures({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // Icon(Icons.event_busy),
          Image.asset(
            'images/sorry.png',
            color: Theme.of(context).textTheme.bodyMedium!.color,
            height: 200.0,
          ),
          Text("選択した条件の適時開示は0件です"),
        ],
      ),
    );
  }
}
