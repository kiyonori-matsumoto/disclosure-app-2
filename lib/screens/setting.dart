import 'package:bloc_provider/bloc_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:disclosure_app_fl/bloc/bloc.dart';
import 'package:disclosure_app_fl/screens/customtag.dart';
import 'package:disclosure_app_fl/screens/notification_setting.dart';
import 'package:disclosure_app_fl/utils/url.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../utils/auth_helper.dart';

import 'notification_tag_setting.dart';

class SettingScreen extends StatefulWidget {
  @override
  _SettingScreenState createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
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
      final user = await AuthHelper().handleGoogleSignIn();
      if (user == null) return null;

      if (!mounted) return user;
      await showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          content: const Text('お気に入りから通知を復元しますか？'),
          actions: <Widget>[
            ElevatedButton(
                child: const Text('復元する'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                onPressed: () async {
                  try {
                    final id = user.uid;
                    final settings = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(id)
                        .get();
                    final data = settings.data();
                    if (data != null && data['favorites'] != null) {
                      final List<String> favs =
                          (data['favorites'] as List).cast<String>();
                      for (final fav in favs) {
                        this.bloc.addNotification.add(fav);
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('${favs.length}件の通知を復元しました'),
                        ));
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('復元できるお気に入りデータがありませんでした'),
                        ));
                      }
                    }
                  } catch (e) {
                    debugPrint('Restore favorites error: $e');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('お気に入りの復元に失敗しました: $e'),
                      ));
                    }
                  } finally {
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  }
                }),
            TextButton(
              child: const Text('キャンセル'),
              onPressed: () {
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
            ),
          ],
        ),
      );
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
      final user = _auth.currentUser;
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
