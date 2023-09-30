import 'package:bloc_provider/bloc_provider.dart';
import 'package:disclosure_app_fl/bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';

class AppDrawer extends StatelessWidget {
  Widget? _avator(String? url) {
    if (url == null || url.isEmpty) {
      return null;
    }
    return CircleAvatar(
      backgroundImage: NetworkImage(url),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bloc = BlocProvider.of<AppBloc>(context);

    return Drawer(
      child: ListView(
        children: <Widget>[
          StreamBuilder<User>(
            builder: (context, snapshot) => UserAccountsDrawerHeader(
                  accountEmail: Text(snapshot.data?.email ?? ''),
                  accountName: Text(snapshot.data?.displayName ?? ''),
                  currentAccountPicture: _avator(snapshot.data?.photoURL),
                ),
            stream: bloc.user$,
          ),
          ListTile(
            title: Text('適時開示一覧'),
            leading: Icon(Icons.insert_drive_file),
            onTap: () => Navigator.of(context).pushReplacementNamed('/'),
          ),
          ListTile(
            title: Text('会社検索'),
            leading: Icon(Icons.search),
            onTap: () => Navigator.of(context).popAndPushNamed('/companies'),
          ),
          ListTile(
            title: Text('お気に入り'),
            leading: Icon(Icons.star),
            onTap: () => Navigator.of(context).popAndPushNamed('/favorites'),
          ),
          ListTile(
            title: Text('決算予定'),
            leading: Icon(Icons.monetization_on),
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
          FutureBuilder<PackageInfo>(
            builder: (context, snapshot) => AboutListTile(
                  applicationLegalese: '(c) 2019 Matsukiyo Lab.',
                  applicationVersion: snapshot?.data?.version ?? '',
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
