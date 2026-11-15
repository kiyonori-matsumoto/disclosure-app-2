import 'package:flutter/material.dart';

class NoDisclosures extends StatelessWidget {
  final String message;
  final Widget? action;

  const NoDisclosures({
    Key? key,
    this.message = "選択した条件の適時開示は0件です",
    this.action,
  }) : super(key: key);

  factory NoDisclosures.emptyFavorites(BuildContext context, {Key? key}) {
    return NoDisclosures(
      key: key,
      message: 'お気に入りが0件です。\n銘柄をお気に入りに登録してください。',
      action: FilledButton.icon(
        onPressed: () {
          Navigator.of(context).pushNamed('/companies');
        },
        icon: const Icon(Icons.search),
        label: const Text('銘柄を検索して登録'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // Icon(Icons.event_busy),
          Image.asset(
            'images/sorry.png',
            color: Theme.of(context).textTheme.bodyMedium!.color,
            height: 200.0,
          ),
          Text(
            message,
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[
            const SizedBox(height: 16),
            action!,
          ],
        ],
      ),
    );
  }
}
