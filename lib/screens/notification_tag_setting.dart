import 'package:disclosure_app_fl/models/filter.dart';
import 'package:disclosure_app_fl/providers/auth_provider.dart';
import 'package:disclosure_app_fl/providers/notification_tags_provider.dart';
import 'package:disclosure_app_fl/providers/user_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationTagSettingScreen extends ConsumerWidget {
  const NotificationTagSettingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // テスト・デバッグ用: 現在の通知一覧（お気に入り企業 + 通知タグ）をログ出力
    ref.watch(logCurrentNotificationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("タグで通知")),
      body: _buildBody(context, ref),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final userDocAsync = ref.watch(userDocStreamProvider);

    return userDocAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const <Widget>[
            Icon(Icons.error_outline, color: Colors.grey, size: 48),
            SizedBox(height: 16),
            Text('設定の読み込みに失敗しました'),
          ],
        ),
      ),
      data: (_) {
        final currentTags = ref.watch(notificationTagsProvider);
        return SafeArea(
          child: ListView(
            children: defaultFilterStrings.map((tag) {
              final isSelected = currentTags.contains(tag);
              return SwitchListTile(
                title: Text(tag),
                value: isSelected,
                onChanged: (v) {
                  final uid = ref.read(currentUserProvider)?.uid;
                  if (uid != null) {
                    ref
                        .read(notificationTagsActionProvider.notifier)
                        .toggle(uid, tag, isSelected: isSelected);
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
