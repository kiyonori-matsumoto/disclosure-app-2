import 'package:flutter/material.dart';

/// アクションシート（ModalBottomSheet）の各メニュー項目
class ActionSheetItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const ActionSheetItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}

/// 開示アイテムやEDINETアイテムの操作用モーダルボトムシートを表示する
Future<void> showItemActionSheet({
  required BuildContext context,
  required String title,
  String? subtitle,
  required List<ActionSheetItem> items,
}) {
  final theme = Theme.of(context);

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Divider(
              height: 1,
              thickness: 0.5,
              color: theme.dividerColor.withValues(alpha: 0.4),
            ),
            ...items.map(
              (item) => ListTile(
                leading: Icon(
                  item.icon,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                title: Text(item.title),
                onTap: () {
                  Navigator.pop(sheetContext);
                  item.onTap();
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
