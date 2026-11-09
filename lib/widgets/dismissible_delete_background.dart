import 'package:flutter/material.dart';

/// スワイプ削除（Dismissible）用の統一背景インジケーター。
/// テーマのカラーパレット（errorContainer / onErrorContainer）に沿った配色で
/// vividすぎない落ち着いたトーンとゴミ箱アイコンを提供します。
class DismissibleDeleteBackground extends StatelessWidget {
  const DismissibleDeleteBackground({
    super.key,
    this.alignment = Alignment.centerRight,
  });

  const DismissibleDeleteBackground.left({super.key})
      : alignment = Alignment.centerLeft;

  const DismissibleDeleteBackground.right({super.key})
      : alignment = Alignment.centerRight;

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.errorContainer,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Icon(
        Icons.delete_outline,
        color: colorScheme.onErrorContainer,
      ),
    );
  }
}
