import 'dart:io';

import 'package:bloc_provider/bloc_provider.dart';
import 'package:disclosure_app_fl/bloc/bloc.dart';
import 'package:disclosure_app_fl/models/company.dart';
import 'package:disclosure_app_fl/screens/disclosure-company.dart';
import 'package:disclosure_app_fl/screens/favorite.dart';
import 'package:disclosure_app_fl/screens/saved-disclosures.dart';
import 'package:disclosure_app_fl/screens/search-company.dart';
import 'package:disclosure_app_fl/screens/setting.dart';
import 'package:disclosure_app_fl/utils/routeobserver.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'screens/disclosure-stream.dart';

class AppRootWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return AppRootWidgetState();
  }
}

class AppRootWidgetState extends State<AppRootWidget> {
  final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey(debugLabel: "Main Navigation");
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final _auth = FirebaseAuth.instance;
  final _message = FirebaseMessaging();
  final _admob = FirebaseAdMob.instance
      .initialize(appId: 'ca-app-pub-5131663294295156~3067610804');

  AppRootWidgetState() {
    print('configure');
    _message.configure(
      onMessage: _handleNotification, //TODO:
      onLaunch: _handleNotification,
      onResume: _handleNotification,
    );
  }

  @override
  void initState() {
    super.initState();
    _googleSignIn
        .signInSilently(suppressErrors: true)
        .then((GoogleSignInAccount googleUser) {
      if (googleUser == null) {
        return _auth.signInAnonymously();
      } else {
        return googleUser.authentication.then((googleAuth) =>
            _auth.signInWithCredential(GoogleAuthProvider.getCredential(
              accessToken: googleAuth.accessToken,
              idToken: googleAuth.idToken,
            )));
      }
    }).then(print);

    final bloc = BlocProvider.of<AppBloc>(context);

    bloc.notifications$.listen((data) {}, onError: (error) {
      showDialog(
        context: navigatorKey.currentState.overlay.context,
        builder: (context) => AlertDialog(
              title: Text("エラー！"),
              content: Text(error.toString()),
            ),
      );
      print("notification onerror $error");
    });
    // initializeDateFormatting('ja_JP');
    // _auth.signInAnonymously().then(print);
  }

  Future<void> _handleNotification(message) async {
    print("###notification handler ###");
    print(message);
    print(navigatorKey.currentContext);
    final code = message['code'] ?? '';
    final company = Company(code, name: message['name'] ?? '');
    await Future.delayed(Duration(milliseconds: 1000));
    // navigatorKey.currentState.pop();
    return navigatorKey.currentState.push(
      MaterialPageRoute(
          builder: (context) => DisclosureCompanyScreen(company: company)),
    );
  }

  Future<void> _handleNotificationMsg(message) async {
    print("###notificationMsg handler ###");
    print(message);
    final data = message['data'] ?? {};
    final code = data['code'] ?? '';
    final company = Company(code, name: data['name'] ?? '');

    final res = await showDialog(
      context: navigatorKey.currentState.overlay.context,
      builder: (context) => AlertDialog(
          title: Text(message['notification']['title']),
          content: Text(message['notification']['body'])),
    );
    print(res);
  }

  double getSmartBannerHeight(MediaQueryData mediaQuery) {
    // https://developers.google.com/admob/android/banner#smart_banners
    if (Platform.isAndroid) {
      if (mediaQuery.size.height > 720) return 90.0;
      if (mediaQuery.size.height > 400) return 50.0;
      return 32.0;
    }
    // https://developers.google.com/admob/ios/banner#smart_banners
    // Smart Banners on iPhones have a height of 50 points in portrait and 32 points in landscape.
    // On iPads, height is 90 points in both portrait and landscape.
    if (Platform.isIOS) {
      // TODO use https://pub.dartlang.org/packages/device_info to detect iPhone/iPad?
      // if (iPad) return 90.0;
      if (mediaQuery.orientation == Orientation.portrait) return 50.0;
      return 32.0;
    }
    // No idea, just return a common value.
    return 50.0;
  }

  @override
  Widget build(BuildContext context) {
    FirebaseAnalytics analytics = FirebaseAnalytics();
    final routeObserver = MyRouteObserver();
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: '適時開示(TDNet) Notifier',
      locale: Locale('ja', 'JP'),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('ja', ''),
      ],
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        // brightness: Brightness.dark,
      ),
      routes: {
        '/': (context) => DisclosureStreamScreen(),
        '/companies': (context) => SearchCompanyScreen(),
        '/favorites': (context) => FavoriteScreen(),
        '/settings': (context) => SettingScreen(),
        '/savedDisclosures': (context) => SavedDisclosuresScreen(),
      },
      onGenerateRoute: (route) {
        print("onGenerateRoute $route");
        if (route.name.startsWith('/company-disclosures')) {
          return MaterialPageRoute(
            builder: (context) =>
                DisclosureCompanyScreen(company: route.arguments),
          );
        }
      },
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: analytics),
        routeObserver
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
