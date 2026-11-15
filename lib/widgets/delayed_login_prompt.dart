import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:disclosure_app_fl/providers/auth_provider.dart';
import 'package:disclosure_app_fl/utils/auth_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kPrefKeyHasPromptedDelayedGoogleLink =
    'has_prompted_delayed_google_link';

/// アカウント競合時に表示する確認ダイアログ
///
/// 機種変更後などにゲスト状態で既存Googleアカウントと連携しようとした際、
/// 既存アカウントのデータを復元して切り替えるかを確認する。
Future<bool> showAccountSwitchConfirmDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('既存アカウントの復元'),
      content: const Text(
        'このGoogleアカウントには以前のデータが存在します。\n'
        '既存アカウントのデータを復元してログインしますか？\n\n'
        '※現在の端末のゲストデータは既存データに置き換わります。',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('復元してログイン'),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Google連携処理を実行し、結果のメッセージを表示する共通ヘルパー
Future<User?> performGoogleSignInWithFeedback(
  BuildContext context, {
  AuthHelper? authHelper,
}) async {
  final helper = authHelper ?? AuthHelper();
  try {
    final user = await helper.handleGoogleSignIn(
      confirmAccountSwitch: () => showAccountSwitchConfirmDialog(context),
    );
    if (user == null) return null;

    String message = 'Google連携が完了しました';
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data();
      if (data != null) {
        final favs = (data['favorites'] as List?)?.cast<String>() ?? [];
        final tags =
            (data['notification_tags'] as List?)?.cast<String>() ?? [];
        final totalCount = favs.length + tags.length;
        if (totalCount > 0) {
          message = '$totalCount件の通知設定を復元しました';
        }
      }
    } catch (e) {
      debugPrint('Failed to check restored notifications count: $e');
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
      ));
    }
    return user;
  } catch (e) {
    debugPrint('Sign in exception: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('アカウント連携に失敗しました: $e'),
        duration: const Duration(seconds: 5),
      ));
    }
    return null;
  }
}

/// コンテキスト駆動の遅延ログイン誘導（案D）
class DelayedLoginPrompt {
  /// お気に入り登録や通知設定の初回アクション時に呼び出す。
  ///
  /// - ユーザーがすでにGoogle連携済みの場合は何もしない。
  /// - 過去に一度でもプロンプトを表示済みの場合は何もしない（1回限定）。
  /// - 条件を満たす場合のみボトムシートを表示する。
  static Future<bool> maybePrompt(
    BuildContext context,
    WidgetRef ref, {
    SharedPreferences? prefs,
    AuthHelper? authHelper,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return false;

    List<UserInfo> providerData = const [];
    try {
      providerData = user.providerData;
    } catch (_) {}
    final isLinked = providerData.any((p) => p.providerId == 'google.com');
    if (isLinked) return false;

    final sp = prefs ?? await SharedPreferences.getInstance();
    final hasPrompted = sp.getBool(kPrefKeyHasPromptedDelayedGoogleLink) ?? false;
    if (hasPrompted) return false;

    // 1回限りの誘導とするため、表示直前にフラグを保存
    await sp.setBool(kPrefKeyHasPromptedDelayedGoogleLink, true);

    if (!context.mounted) return false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => DelayedLoginBottomSheet(
        authHelper: authHelper,
      ),
    );

    return true;
  }
}

/// Google連携を促す軽量なボトムシート
class DelayedLoginBottomSheet extends StatefulWidget {
  final AuthHelper? authHelper;

  const DelayedLoginBottomSheet({
    Key? key,
    this.authHelper,
  }) : super(key: key);

  @override
  State<DelayedLoginBottomSheet> createState() =>
      _DelayedLoginBottomSheetState();
}

class _DelayedLoginBottomSheetState extends State<DelayedLoginBottomSheet> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.cloud_sync_outlined,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Google連携でデータを保護',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '機種変更時にも登録したお気に入りや通知設定をそのまま引き継げるよう、Googleアカウントと連携しませんか？',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff4285f4),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isLoading
                  ? null
                  : () async {
                      setState(() {
                        _isLoading = true;
                      });
                      final user = await performGoogleSignInWithFeedback(
                        context,
                        authHelper: widget.authHelper,
                      );
                      if (mounted) {
                        setState(() {
                          _isLoading = false;
                        });
                        if (user != null) {
                          Navigator.of(context).pop();
                        }
                      }
                    },
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_circle, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Googleで連携する（ワンタップ）',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              child: Text(
                'あとで',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
