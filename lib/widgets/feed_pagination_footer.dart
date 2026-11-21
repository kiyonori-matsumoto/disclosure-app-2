import 'package:flutter/material.dart';

/// 無限スクロールのリスト末尾に表示するフッターウィジェット
///
/// 追加ページ読み込み中はローディングインジケータ、
/// 最終ページ到達時は末尾到達メッセージを表示する。
class FeedPaginationFooter extends StatelessWidget {
  const FeedPaginationFooter({
    super.key,
    required this.isLoadingMore,
    required this.hasMore,
    required this.hasItems,
  });

  final bool isLoadingMore;
  final bool hasMore;
  final bool hasItems;

  @override
  Widget build(BuildContext context) {
    if (!hasItems) {
      return const SizedBox.shrink();
    }

    final secondaryColor = Theme.of(context).colorScheme.onSurfaceVariant;

    if (isLoadingMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(
              '読み込み中...',
              style: TextStyle(fontSize: 12, color: secondaryColor),
            ),
          ],
        ),
      );
    }

    if (!hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Center(
          child: Text(
            'すべて表示しました',
            style: TextStyle(fontSize: 12, color: secondaryColor),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
