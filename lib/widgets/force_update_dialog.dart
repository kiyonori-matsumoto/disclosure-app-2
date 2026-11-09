import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/remote_config_provider.dart';

/// クリティカルな変更時に表示する強制アップデートダイアログ
class ForceUpdateDialog extends StatelessWidget {
  final ForceUpdateState state;

  const ForceUpdateDialog({
    Key? key,
    required this.state,
  }) : super(key: key);

  /// ダイアログを表示するヘルパー（キャンセル不可）
  static Future<void> show(BuildContext context, ForceUpdateState state) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ForceUpdateDialog(state: state),
    );
  }

  Future<void> _openStore() async {
    Uri? uri;
    if (Platform.isAndroid) {
      uri = Uri.parse('market://details?id=com.disclosure.android');
      if (!await canLaunchUrl(uri)) {
        uri = Uri.parse(
          'https://play.google.com/store/apps/details?id=com.disclosure.android',
        );
      }
    } else if (Platform.isIOS) {
      // iOS の App Store URL（必要に応じてIDを指定可能）
      uri = Uri.parse(
        'https://apps.apple.com/app/idcom.disclosure.android',
      );
    }

    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Android の戻るボタンでも閉じられない
      child: AlertDialog(
        title: Text(
          state.title.isNotEmpty ? state.title : 'アップデートのお知らせ',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.message.isNotEmpty
                  ? state.message
                  : '快適にご利用いただくために、最新バージョンへのアップデートをお願いいたします。',
            ),
            const SizedBox(height: 12),
            Text(
              '現在のバージョン: ${state.currentVersion}\n必要最低バージョン: ${state.minRequiredVersion}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: _openStore,
            child: const Text('今すぐアップデート'),
          ),
        ],
      ),
    );
  }
}
