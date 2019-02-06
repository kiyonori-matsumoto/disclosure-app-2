import 'package:bloc_provider/bloc_provider.dart';
import 'package:disclosure_app_fl/bloc/bloc.dart';
import 'package:disclosure_app_fl/screens/customtag.dart';
import 'package:disclosure_app_fl/screens/notification-setting.dart';
import 'package:disclosure_app_fl/widgets/drawer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SettingScreen extends StatefulWidget {
  @override
  _SettingScreenState createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('設定今骨累直')),
      drawer: AppDrawer(),
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
          title: Text('通知設定'),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => NotificationSettingScreen()));
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
        StreamBuilder<FirebaseUser>(
          stream: bloc.user$,
          builder: (context, snapshot) => RaisedButton(
                color: Colors.red,
                textColor: Colors.white,
                onPressed: () {
                  snapshot.hasData &&
                          snapshot.data.providerData
                              .any((p) => p.providerId == "google.com")
                      ? this._handleSignOut(context)
                      : this._handleSignIn(context);
                },
                child: snapshot.hasData &&
                        snapshot.data.providerData
                            .any((p) => p.providerId == "google.com")
                    ? Text('GOOGLE連携を解除')
                    : Text('GOOGLE連携'),
              ),
        ),
        ListTile(
          title: Text('プライバシーポリシー'),
          onTap: () {
            _launchURL();
          },
        )
      ],
    );
  }

  _launchURL() async {
    const url = 'https://disclosure-app.firebaseapp.com/privacy/';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<FirebaseUser> _handleSignIn(BuildContext context) async {
    try {
      GoogleSignInAccount googleUser = await _googleSignIn.signIn();
      GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final providers =
          await _auth.fetchProvidersForEmail(email: googleUser.email);

      FirebaseUser user;
      if (providers.contains('google.com')) {
        user = await _auth.signInWithGoogle(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
      } else {
        user = await _auth.linkWithGoogleCredential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
      }
      print(user.providerId);
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text('Googleアカウントと連携しました'),
        duration: Duration(seconds: 5),
      ));
      return user;
    } catch (e) {
      print('exception');
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text('アカウント連携に失敗しました'),
        duration: Duration(seconds: 5),
      ));
    }
  }

  _handleSignOut(BuildContext context) async {
    SnackBar snackBar = SnackBar(
      content: Text('現在サインアウトできません'),
      duration: Duration(seconds: 10),
    );
    Scaffold.of(context).showSnackBar(snackBar);
  }
}

class ListHeader extends StatelessWidget {
  final String title;

  const ListHeader({
    Key key,
    @required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
      child: Text(
        this.title,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}
