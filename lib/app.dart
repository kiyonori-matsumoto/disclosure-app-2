import 'dart:async';

import 'package:bloc_provider/bloc_provider.dart';
import 'package:disclosure_app_fl/bloc/bloc.dart';
import 'package:disclosure_app_fl/screens/disclosure_company.dart';
import 'package:disclosure_app_fl/screens/disclosure_tags.dart';
import 'package:disclosure_app_fl/models/company.dart';
import 'package:disclosure_app_fl/screens/favorite.dart';
import 'package:disclosure_app_fl/screens/saved_disclosures.dart';
import 'package:disclosure_app_fl/screens/search_company.dart';
import 'package:disclosure_app_fl/screens/setting.dart';
import 'package:disclosure_app_fl/screens/settlements_list.dart';
import 'package:disclosure_app_fl/utils/routeobserver.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:disclosure_app_fl/providers/theme_mode_provider.dart';
import 'screens/disclosure_stream.dart';
import 'utils/get_company.dart';
import 'utils/auth_helper.dart';
import 'utils/notification_route_helper.dart';

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
  final _message = FirebaseMessaging.instance;
  final List<StreamSubscription> _subscriptions = [];

  AppBloc? bloc;

  @override
  void initState() {
    super.initState();
    _subscriptions.add(
      FirebaseMessaging.onMessage.listen(_handleNotificationMsg),
    );
    _subscriptions.add(
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotification),
    );

    _message.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Terminated 状態（アプリ未起動）から通知タップで起動された場合のハンドリング
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final initialMessage = await _message.getInitialMessage();
        if (initialMessage != null && mounted) {
          await _handleNotification(initialMessage);
        }
      } catch (e, stack) {
        debugPrint("Failed to handle initial notification message: $e");
        FirebaseCrashlytics.instance.recordError(e, stack, fatal: false);
      }
    });

    _initAuth();

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
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    super.dispose();
  }

  Future<void> _handleNotification(RemoteMessage message) async {
    debugPrint("###notification handler ###: ${message.messageId}");
    final nav = navigatorKey.currentState;
    if (nav == null) return;

    final destination = await NotificationRouteHelper.resolveDestination(
      message.data,
      companyResolver: (code, name) => getCompany(
        bloc,
        code: code,
        name: name,
      ),
    );

    NotificationRouteHelper.navigateToDestination(nav, destination);
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
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleNotification(message);
              },
              child: const Text('開く'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _initAuth() async {
    await AuthHelper().initializeAuth();
  }

  @override
  Widget build(BuildContext context) {
    FirebaseAnalytics analytics = FirebaseAnalytics.instance;
    final routeObserver = MyRouteObserver();

    return Consumer(
      builder: (context, ref, child) {
        final themeMode = ref.watch(themeModeProvider);

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
            brightness: Brightness.light,
            useMaterial3: false,
          ),
          darkTheme: ThemeData(
            primarySwatch: Colors.deepPurple,
            brightness: Brightness.dark,
            useMaterial3: false,
          ),
          themeMode: themeMode,
          routes: {
            '/': (context) => DisclosureStreamScreen(),
            '/companies': (context) => const SearchCompanyScreen(),
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
                final company =
                    route.arguments is Company ? route.arguments as Company : null;
                return MaterialPageRoute<dynamic>(
                  builder: (context) => DisclosureCompanyScreen(
                    company: company,
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
