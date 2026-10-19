import 'dart:async';
import 'dart:io';

import 'package:bloc_provider/bloc_provider.dart';
import 'package:disclosure_app_fl/bloc/bloc.dart';
import 'package:disclosure_app_fl/screens/disclosure_company.dart';
import 'package:disclosure_app_fl/screens/disclosure_tags.dart';
import 'package:disclosure_app_fl/screens/favorite.dart';
import 'package:disclosure_app_fl/screens/saved_disclosures.dart';
import 'package:disclosure_app_fl/screens/search_company.dart';
import 'package:disclosure_app_fl/screens/setting.dart';
import 'package:disclosure_app_fl/screens/settlements_list.dart';
import 'package:disclosure_app_fl/utils/ad_helper.dart';
import 'package:disclosure_app_fl/utils/routeobserver.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'screens/disclosure_stream.dart';
import 'utils/get_company.dart';

class AppRootWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return AppRootWidgetState();
  }
}

class AppRootWidgetState extends State<AppRootWidget> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey(
    debugLabel: "Main Navigation",
  );
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final _auth = FirebaseAuth.instance;
  final _message = FirebaseMessaging.instance;
  final List<StreamSubscription> _subscriptions = [];

  AppBloc? bloc;
  late BannerAd _bannerAd;

  @override
  void initState() {
    super.initState();
    _subscriptions.add(
      FirebaseMessaging.onMessage.listen(_handleNotificationMsg),
    );
    _subscriptions.add(
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotification),
    );

    _googleSignIn
        .signInSilently(suppressErrors: true)
        .then((GoogleSignInAccount? googleUser) {
      if (googleUser == null) {
        return _auth.signInAnonymously();
      } else {
        return googleUser.authentication.then(
          (googleAuth) => _auth.signInWithCredential(
            GoogleAuthProvider.credential(
              accessToken: googleAuth.accessToken,
              idToken: googleAuth.idToken,
            ),
          ),
        );
      }
    }).then((user) {
      debugPrint("Signed in user: $user");
    }).catchError((dynamic error) {
      debugPrint("Silent sign in error: $error");
    });

    final appBloc = BlocProvider.of<AppBloc>(context);
    bloc = appBloc;

    _subscriptions.add(
      appBloc.notifications$.listen(
        (data) {},
        onError: (dynamic error) {
          final dialogContext = navigatorKey.currentState?.overlay?.context;
          if (dialogContext != null) {
            showDialog<dynamic>(
              context: dialogContext,
              builder: (context) => AlertDialog(
                title: const Text("エラー！"),
                content: Text(error.toString()),
              ),
            );
          }
          debugPrint("notification onerror $error");
        },
      ),
    );

    _message.subscribeToTopic('edinet_notification');
    // _message.unsubscribeFromTopic('edinet');

    _subscriptions.add(
      appBloc.user$.listen((user) {
        FirebaseCrashlytics.instance.setUserIdentifier(user.uid);
      }),
    );
    _bannerAd = BannerAd(
      size: AdSize.banner,
      adUnitId: AdHelper.bannerAdUnitId,
      listener: BannerAdListener(),
      request: AdRequest(),
    );
    _bannerAd.load();
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _bannerAd.dispose();
    super.dispose();
  }

  Future<void> _handleNotification(RemoteMessage message) async {
    debugPrint("###notification handler ###: ${message.messageId}");
    final data = message.data;
    final String code = data['code'] ?? '';
    await Future<dynamic>.delayed(const Duration(milliseconds: 1000));

    if (navigatorKey.currentState == null) return;

    if (data['type'] == 'tag') {
      final tag = data['tag'];
      await navigatorKey.currentState?.pushNamed(
        '/tag-disclosures',
        arguments: tag,
      );
      return;
    }

    final company = await getCompany(
      bloc,
      code: code,
      name: data['name'] ?? '',
    );
    await navigatorKey.currentState?.pushNamed(
      '/company-disclosures',
      arguments: company,
    );
  }

  Future<void> _handleNotificationMsg(RemoteMessage message) async {
    debugPrint("###notificationMsg handler ###: ${message.messageId}");
    final dialogContext = navigatorKey.currentState?.overlay?.context;
    if (dialogContext != null && message.notification != null) {
      await showDialog<dynamic>(
        context: dialogContext,
        builder: (context) => AlertDialog(
          title: Text(message.notification?.title ?? ''),
          content: Text(message.notification?.body ?? ''),
        ),
      );
    }
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
    FirebaseAnalytics analytics = FirebaseAnalytics.instance;
    final routeObserver = MyRouteObserver();
    final bloc = BlocProvider.of<AppBloc>(context);

    return StreamBuilder<Brightness>(
      stream: bloc.darkMode$,
      builder: (context, snapshot) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: '適時開示(TDNet/Edinet) Notifier',
          locale: Locale('ja', 'JP'),
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('ja', '')],
          theme: ThemeData(
            primarySwatch: Colors.deepPurple,
            brightness: snapshot.data,
            useMaterial3: false,
          ),
          routes: {
            '/': (context) => DisclosureStreamScreen(),
            '/companies': (context) => SearchCompanyScreen(),
            '/favorites': (context) => FavoriteScreen(),
            '/settings': (context) => SettingScreen(),
            '/savedDisclosures': (context) => SavedDisclosuresScreen(),
            '/settlements': (context) => SettlementsList(),
          },
          onGenerateRoute: (route) {
            print("onGenerateRoute $route");
            final routeName = route.name;
            if (routeName != null) {
              if (routeName.startsWith('/company-disclosures')) {
                return MaterialPageRoute<dynamic>(
                  builder: (context) => DisclosureCompanyScreen(
                    company: route.arguments as dynamic,
                  ),
                );
              }
              if (routeName.startsWith('/tag-disclosures')) {
                return MaterialPageRoute<dynamic>(
                  builder: (context) =>
                      DisclosureTagsScreen(tag: route.arguments as String?),
                );
              }
            }
            return null;
          },
          navigatorObservers: [
            FirebaseAnalyticsObserver(analytics: analytics),
            routeObserver,
          ],
        );
      },
    );
  }
}
