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
import 'package:disclosure_app_fl/providers/forensic_toggle_provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../utils/auth_helper.dart';

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
            final isForensicToggled = ref.watch(forensicToggleProvider);
            return SwitchListTile(
              secondary: const Icon(Icons.analytics_outlined),
              title: const Text('財務フォレンジック機能（β）'),
              subtitle: const Text('M-Score・粉飾リスク指標の表示（検証用）'),
              value: isForensicToggled,
              onChanged: (val) {
                ref.read(forensicToggleProvider.notifier).setEnabled(val);
              },
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
          final user = ref.watch(currentUserProvider);
          final isLinked = user != null &&
              user.providerData.any((p) => p.providerId == 'google.com');
          return ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff4285f4),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              isLinked
                  ? _handleSignOut(context)
                  : _handleSignIn(context);
            },
            child: isLinked
                ? const Text('GOOGLE連携を解除')
                : const Text('GOOGLE連携'),
          );
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

  Future<User?> _handleSignIn(BuildContext context) async {
    try {
      final user = await AuthHelper().handleGoogleSignIn();
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
            message = '$totalCount件の通知を復元しました';
          }
        }
      } catch (e) {
        debugPrint('Failed to check restored notifications count: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(message),
        ));
      }
      return user;
    } catch (e) {
      debugPrint('Sign in exception: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('アカウント連携に失敗しました: $e'),
          duration: const Duration(seconds: 5),
        ));
      }
      return null;
    }
  }

  Future<void> _handleSignOut(BuildContext context) async {
    try {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        await user.unlink('google.com');
        try {
          await GoogleSignIn.instance.signOut();
        } catch (e) {
          debugPrint('Google sign out error: $e');
        }
        await user.reload();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('連携を解除しました'),
        duration: Duration(seconds: 5),
      ));
    } catch (e) {
      debugPrint('Unlink error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('連携の解除に失敗しました: $e'),
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
