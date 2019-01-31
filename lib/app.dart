import 'package:disclosure_app_fl/models/company.dart';
import 'package:disclosure_app_fl/screens/disclosure-company.dart';
import 'package:disclosure_app_fl/screens/favorite.dart';
import 'package:disclosure_app_fl/screens/search-company.dart';
import 'package:disclosure_app_fl/screens/setting.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'screens/disclosure-stream.dart';

class AppRootWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return AppRootWidgetState();
  }
}

class AppRootWidgetState extends State<AppRootWidget> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final _auth = FirebaseAuth.instance;
  final _message = FirebaseMessaging();

  @override
  void initState() {
    super.initState();
    _googleSignIn
        .signInSilently(suppressErrors: true)
        .then((GoogleSignInAccount googleUser) {
      if (googleUser == null) {
        return _auth.signInAnonymously();
      } else {
        return googleUser.authentication
            .then((googleAuth) => _auth.signInWithGoogle(
                  accessToken: googleAuth.accessToken,
                  idToken: googleAuth.idToken,
                ));
      }
    }).then(print);

    _message.configure(
      onLaunch: _handleNotification,
      onMessage: _handleNotification,
      onResume: _handleNotification,
    );
    // _auth.signInAnonymously().then(print);
  }

  Future<void> _handleNotification(message) {
    print(message);
    final code = message['data']['code'] ?? '';
    final company = Company(code, name: message['name'] ?? '');
    return Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => DisclosureCompanyScreen(company: company)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '適時開示(TDNet) Notifier',
      locale: Locale('ja', 'JP'),
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      routes: {
        '/': (context) => DisclosureStreamScreen(),
        '/companies': (context) => SearchCompanyScreen(),
        '/favorites': (context) => FavoriteScreen(),
        '/settings': (context) => SettingScreen(),
      },
    );
  }
}
