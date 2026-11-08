import 'package:disclosure_app_fl/providers/auth_provider.dart';
import 'package:disclosure_app_fl/providers/disclosures_provider.dart';
import 'package:disclosure_app_fl/utils/url.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({Key? key}) : super(key: key);

  Widget _avatar(String? url, ThemeData theme) {
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        backgroundImage: NetworkImage(url),
      );
    }
    return CircleAvatar(
      backgroundColor: theme.colorScheme.primary,
      child: Icon(
        Icons.person,
        color: theme.colorScheme.onPrimary,
        size: 40,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final isLinked = user != null &&
        user.providerData.any((p) => p.providerId == 'google.com');
    final googleInfo = isLinked
        ? user.providerData
            .firstWhere((p) => p.providerId == 'google.com')
        : null;

    return Drawer(
      child: ListView(
        children: <Widget>[
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
            ),
            accountEmail: isLinked
                ? Text(
                    googleInfo?.email ?? user.email ?? '',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer
                          .withValues(alpha: 0.85),
                      fontSize: 13,
                    ),
                  )
                : Text(
                    '未連携（ゲスト利用中）',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer
                          .withValues(alpha: 0.85),
                      fontSize: 13,
                    ),
                  ),
            accountName: Text(
              isLinked
                  ? (googleInfo?.displayName ?? user.displayName ?? 'ログイン中')
                  : 'ゲスト',
              style: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            currentAccountPicture: _avatar(
              googleInfo?.photoURL ?? user?.photoURL,
              theme,
            ),
          ),
          ListTile(
            title: const Text('適時開示一覧'),
            leading: const Icon(Icons.insert_drive_file),
            onTap: () => Navigator.of(context).pushReplacementNamed('/'),
          ),
          ListTile(
            title: const Text('会社検索'),
            leading: const Icon(Icons.search),
            onTap: () => Navigator.of(context).popAndPushNamed('/companies'),
          ),
          ListTile(
            title: const Text('お気に入り'),
            leading: const Icon(Icons.star),
            onTap: () => Navigator.of(context).popAndPushNamed('/favorites'),
          ),
          ListTile(
            title: const Text('決算予定'),
            leading: const Icon(Icons.monetization_on),
            onTap: () => Navigator.of(context).popAndPushNamed('/settlements'),
          ),
          ListTile(
            title: Text('保存した開示情報'),
            leading: Icon(Icons.bookmark),
            onTap: () =>
                Navigator.of(context).popAndPushNamed('/savedDisclosures'),
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('設定'),
            onTap: () => Navigator.of(context).popAndPushNamed('/settings'),
          ),
          if (kDebugMode)
            Consumer(
              builder: (context, ref, _) => ListTile(
                leading: const Icon(Icons.add_alert, color: Colors.amber),
                title: const Text('【Debug】ダミー新着を受信'),
                onTap: () {
                  ref
                      .read(disclosuresFeedProvider.notifier)
                      .injectDebugNewDisclosure();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('【Debug】ダミー新着開示を受信しました'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('サポートサイト'),
            onTap: () {
              launchURL('https://disclosure-app.firebaseapp.com/');
            },
          ),
          FutureBuilder<PackageInfo>(
            builder: (context, snapshot) => AboutListTile(
              applicationLegalese: '(c) 2019-2023 Matsukiyo Lab.',
              applicationVersion: snapshot.data?.version ?? '',
              child: Text('このアプリについて'),
              icon: Icon(Icons.info),
            ),
            future: PackageInfo.fromPlatform(),
          )
        ],
      ),
    );
  }
}
