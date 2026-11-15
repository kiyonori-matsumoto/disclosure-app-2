import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:disclosure_app_fl/providers/auth_provider.dart';
import 'package:disclosure_app_fl/screens/customtag.dart';
import 'package:disclosure_app_fl/screens/favorite.dart';
import 'package:disclosure_app_fl/utils/url.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:disclosure_app_fl/providers/theme_mode_provider.dart';
import 'package:disclosure_app_fl/providers/user_settings_provider.dart';
import 'package:disclosure_app_fl/widgets/delayed_login_prompt.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'notification_tag_setting.dart';

class SettingScreen extends ConsumerStatefulWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends ConsumerState<SettingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: Builder(builder: _buildBody),
    );
  }

  Widget _buildBody(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(8.0),
      children: <Widget>[
        ListHeader(title: '通知設定'),
        ListTile(
          leading: Icon(Icons.notifications),
          title: Text('証券コードで通知'),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const FavoriteScreen()));
          },
        ),
        ListTile(
          leading: Icon(Icons.local_offer),
          title: Text('タグで通知(β)'),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => NotificationTagSettingScreen()));
          },
        ),
        Divider(),
        ListHeader(title: '表示設定'),
        Consumer(
          builder: (context, ref, child) {
            final hideDaily = ref.watch(hideDailyDisclosureProvider);
            return CheckboxListTile(
              value: hideDaily,
              onChanged: (v) {
                if (v != null) {
                  ref
                      .read(userSettingsActionProvider.notifier)
                      .setHideDailyDisclosure(v);
                }
              },
              title: const Text('日々の開示情報を表示しない'),
            );
          },
        ),
        Consumer(
          builder: (context, ref, child) {
            final themeMode = ref.watch(themeModeProvider);
            final String themeTitle;
            switch (themeMode) {
              case ThemeMode.system:
                themeTitle = 'システムの設定に追従';
                break;
              case ThemeMode.light:
                themeTitle = 'ライトモード';
                break;
              case ThemeMode.dark:
                themeTitle = 'ダークモード';
                break;
            }

            return ListTile(
              leading: const Icon(Icons.brightness_medium),
              title: const Text('テーマ設定'),
              subtitle: Text(themeTitle),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (dialogContext) {
                    return SimpleDialog(
                      title: const Text('テーマ設定'),
                      children: [
                        RadioGroup<ThemeMode>(
                          groupValue: themeMode,
                          onChanged: (mode) {
                            if (mode != null) {
                              ref
                                  .read(themeModeProvider.notifier)
                                  .setThemeMode(mode);
                            }
                            Navigator.of(dialogContext).pop();
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              RadioListTile<ThemeMode>(
                                title: Text('システムの設定に追従'),
                                value: ThemeMode.system,
                              ),
                              RadioListTile<ThemeMode>(
                                title: Text('ライトモード'),
                                value: ThemeMode.light,
                              ),
                              RadioListTile<ThemeMode>(
                                title: Text('ダークモード'),
                                value: ThemeMode.dark,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
        ListTile(
          title: Text('カスタムタグ設定'),
          leading: Icon(Icons.local_offer),
          onTap: () {
            Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const CustomTagScreen()));
          },
        ),
        Divider(),
        const ListHeader(
          title: 'アカウント設定',
        ),
        () {
          final theme = Theme.of(context);
          final user = ref.watch(currentUserProvider);
          final isLinked = user != null &&
              user.providerData.any((p) => p.providerId == 'google.com');

          if (isLinked) {
            final googleInfo = user.providerData
                .firstWhere((p) => p.providerId == 'google.com');
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: const Text('Google連携済み'),
                  subtitle: Text(
                    googleInfo.email ?? user.email ?? '連携完了',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'お気に入りや通知設定がGoogleアカウントにバックアップされています。',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Icon(
                    Icons.delete_outline,
                    color: theme.colorScheme.error,
                  ),
                  title: Text(
                    'アカウントを削除',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  subtitle: const Text('保存されたデータとアカウントを削除します'),
                  onTap: () => _handleDeleteAccount(context, user),
                ),
              ],
            );
          } else {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '現在はゲスト（未連携）として利用しています。Googleアカウントと連携すると、機種変更時にもデータを引き継ぐことができます。',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff4285f4),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.account_circle, color: Colors.white),
                    label: const Text('Googleアカウントと連携'),
                    onPressed: () => performGoogleSignInWithFeedback(context),
                  ),
                ],
              ),
            );
          }
        }(),
        ListTile(
          title: const Row(
            children: <Widget>[
              Text('サポートサイト'),
              SizedBox(width: 4),
              Icon(Icons.open_in_browser, size: 18),
            ],
          ),
          onTap: () {
            const url = 'https://disclosure-app.firebaseapp.com/';
            launchURL(url);
          },
        ),
        ListTile(
          title: const Row(
            children: <Widget>[
              Text('プライバシーポリシー'),
              SizedBox(width: 4),
              Icon(Icons.open_in_browser, size: 18),
            ],
          ),
          onTap: () {
            const url = 'https://disclosure-app.firebaseapp.com/privacy/';
            launchURL(url);
          },
        ),
      ],
    );
  }

  Future<void> _handleDeleteAccount(BuildContext context, User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('アカウントの削除'),
        content: const Text(
          'アカウントを削除しますか？\n'
          '登録したお気に入りや通知設定などの全データが完全に削除され、復元できなくなります。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('削除する'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final isGoogleLinked =
          user.providerData.any((p) => p.providerId == 'google.com');

      // Google連携済みの場合は、必ず事前に再認証を行い「requires-recent-login」を未然に防止する
      if (isGoogleLinked) {
        try {
          final googleUser = await GoogleSignIn.instance.authenticate();
          final googleAuth = googleUser.authentication;
          final credential =
              GoogleAuthProvider.credential(idToken: googleAuth.idToken);
          await user.reauthenticateWithCredential(credential);
        } catch (e) {
          debugPrint('Re-authentication cancelled or failed: $e');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('本人確認が完了しなかったため、アカウント削除を中止しました'),
          ));
          return;
        }
      }

      final uid = user.uid;
      // 1. Firestore ユーザーデータの削除
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      } catch (e) {
        debugPrint('Failed to delete user doc: $e');
      }

      // 2. GoogleSignIn からのサインアウト
      try {
        await GoogleSignIn.instance.signOut();
      } catch (e) {
        debugPrint('Google sign out error: $e');
      }

      // 3. Firebase Auth ユーザー削除
      await user.delete();

      // 4. 新たな匿名ユーザーとして初期化
      await FirebaseAuth.instance.signInAnonymously();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('アカウントを削除しました'),
      ));
    } on FirebaseAuthException catch (e) {
      debugPrint('Delete account Firebase error: $e');
      if (!mounted) return;
      final msg = e.code == 'requires-recent-login'
          ? 'セキュリティ保護のため、アカウント削除前に再ログインが必要です。一度再連携してからお試しください。'
          : 'アカウントの削除に失敗しました: ${e.message ?? e.code}';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 5),
      ));
    } catch (e) {
      debugPrint('Delete account error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('アカウントの削除に失敗しました: $e'),
      ));
    }
  }
}

class ListHeader extends StatelessWidget {
  final String title;

  const ListHeader({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}
