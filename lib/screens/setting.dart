import 'package:bloc_provider/bloc_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:disclosure_app_fl/bloc/bloc.dart';
import 'package:disclosure_app_fl/screens/customtag.dart';
import 'package:disclosure_app_fl/screens/notification-setting.dart';
import 'package:disclosure_app_fl/utils/url.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'notification-tag-setting.dart';

class SettingScreen extends StatefulWidget {
  @override
  _SettingScreenState createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late AppBloc bloc;

  @override
  void initState() {
    super.initState();
    this.bloc = BlocProvider.of<AppBloc>(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('設定')),
      // drawer: AppDrawer(),
      body: Builder(builder: _buildBody),
    );
  }

  Widget _buildBody(BuildContext context) {
    final bloc = BlocProvider.of<AppBloc>(context);

    return ListView(
      padding: EdgeInsets.all(8.0),
      children: <Widget>[
        ListHeader(title: '通知設定'),
        ListTile(
          leading: Icon(Icons.notifications),
          title: Text('証券コードで通知'),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => NotificationSettingScreen()));
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
        StreamBuilder<bool>(
          stream: bloc.hideDailyDisclosure$,
          builder: (context, snapshot) {
            final value = snapshot.data ?? false;
            return CheckboxListTile(
              value: value,
              onChanged: (v) {
                bloc.setVisibleDailyDisclosure.add(v);
              },
              title: Text('日々の開示情報を表示しない'),
            );
          },
        ),
        StreamBuilder<Brightness>(
            stream: bloc.darkMode$,
            builder: (context, snapshot) {
              return CheckboxListTile(
                value: snapshot.data == Brightness.dark,
                title: Text('ダークモード'),
                onChanged: (v) {
                  bloc.setModeBrightness.add(!v!);
                },
              );
            }),
        ListTile(
          title: Text('カスタムタグ設定'),
          leading: Icon(Icons.local_offer),
          onTap: () {
            Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => CustomTagScreen()));
          },
        ),
        Divider(),
        ListHeader(
          title: 'アカウント設定',
        ),
        StreamBuilder<User>(
          stream: bloc.user$,
          builder: (context, snapshot) => ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xff4285f4),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              snapshot.hasData &&
                      snapshot.data!.providerData
                          .any((p) => p.providerId == "google.com")
                  ? this._handleSignOut(context)
                  : this._handleSignIn(context);
            },
            child: snapshot.hasData &&
                    snapshot.data!.providerData
                        .any((p) => p.providerId == "google.com")
                ? Text('GOOGLE連携を解除')
                : Text('GOOGLE連携'),
          ),
        ),
        ListTile(
          title: Row(
            children: <Widget>[Text('プライバシーポリシー'), Icon(Icons.open_in_browser)],
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
      GoogleSignInAccount googleUser = (await _googleSignIn.signIn())!;
      GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final providers =
          await _auth.fetchSignInMethodsForEmail(googleUser.email);

      User? user;
      if (providers.contains('google.com')) {
        user = (await _auth.signInWithCredential(GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        )))
            .user;
      } else {
        user = FirebaseAuth.instance.currentUser;
        user = (await user!.linkWithCredential(GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        )))
            .user;
      }
      // print(user.providerId);
      // Scaffold.of(context).showSnackBar(SnackBar(
      //   content: Text('Googleアカウントと連携しました'),
      //   duration: Duration(seconds: 5),
      // ));
      user!.reload();
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: const Text('お気に入りから通知を復元しますか？'),
          actions: <Widget>[
            ElevatedButton(
                child: const Text('復元する'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                onPressed: () async {
                  final id = user!.uid;
                  final settings = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(id)
                      .get();
                  final List<String> favs =
                      settings.data()!['favorites'].cast<String>();
                  favs.forEach((fav) {
                    this.bloc.addNotification.add(fav);
                  });
                  Navigator.pop(context);
                }),
            TextButton(
              child: const Text('キャンセル'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
      return user;
    } catch (e) {
      print('exception');
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('アカウント連携に失敗しました'),
        duration: Duration(seconds: 5),
      ));
      return null;
    }
  }

  _handleSignOut(BuildContext context) async {
    final user = _auth.currentUser!;
    await user.unlink('google.com');
    SnackBar snackBar = SnackBar(
      content: Text('連携を解除しました'),
      duration: Duration(seconds: 10),
    );
    user.reload();
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
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
      padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
      child: Text(
        this.title,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodySmall!.color,
        ),
      ),
    );
  }
}
