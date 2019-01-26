import 'package:bloc_provider/bloc_provider.dart';
import 'package:disclosure_app_fl/bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bloc = BlocProvider.of<AppBloc>(context);

    return Drawer(
      child: ListView(
        children: <Widget>[
          StreamBuilder<FirebaseUser>(
            builder: (context, snapshot) => UserAccountsDrawerHeader(
                  accountEmail: Text(snapshot.data?.email ?? ''),
                  accountName: Text(snapshot.data?.displayName ?? ''),
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
            onTap: () =>
                Navigator.of(context).pushReplacementNamed('/companies'),
          ),
          ListTile(
            title: Text('お気に入り'),
            leading: Icon(Icons.star),
          ),
          ListTile(
            title: Text('保存した開示情報'),
            leading: Icon(Icons.bookmark),
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('設定'),
          ),
          AboutListTile()
        ],
      ),
    );
  }
}
