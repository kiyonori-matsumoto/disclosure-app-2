import 'dart:async';

import 'package:disclosure_app_fl/models/company.dart';
import 'package:disclosure_app_fl/providers/auth_provider.dart';
import 'package:disclosure_app_fl/providers/company_provider.dart';
import 'package:disclosure_app_fl/providers/theme_mode_provider.dart';
import 'package:disclosure_app_fl/providers/topic_sync_provider.dart';
import 'package:disclosure_app_fl/screens/disclosure_company.dart';
import 'package:disclosure_app_fl/screens/disclosure_stream.dart';
import 'package:disclosure_app_fl/screens/disclosure_tags.dart';
import 'package:disclosure_app_fl/screens/favorite.dart';
import 'package:disclosure_app_fl/screens/saved_disclosures.dart';
import 'package:disclosure_app_fl/screens/search_company.dart';
import 'package:disclosure_app_fl/screens/setting.dart';
import 'package:disclosure_app_fl/screens/settlements_list.dart';
import 'package:disclosure_app_fl/utils/auth_helper.dart';
import 'package:disclosure_app_fl/utils/get_company.dart';
import 'package:disclosure_app_fl/utils/routeobserver.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppRootWidget extends ConsumerStatefulWidget {
  const AppRootWidget({Key? key}) : super(key: key);

  @override
  ConsumerState<AppRootWidget> createState() {
    return AppRootWidgetState();
  }
}

class AppRootWidgetState extends ConsumerState<AppRootWidget> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey(
    debugLabel: "Main Navigation",
  );
  final _message = FirebaseMessaging.instance;
  final List<StreamSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _subscriptions.add(
      FirebaseMessaging.onMessage.listen(_handleNotificationMsg),
    );
    _subscriptions.add(
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotification),
    );

    _initAuth();

    _message.subscribeToTopic('edinet_notification');
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

    final companyCodeMap = ref.read(companyCodeMapProvider);
    final company = await getCompany(
      code: code,
      name: data['name'] ?? '',
      companyCodeMap: companyCodeMap,
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

  Future<void> _initAuth() async {
    await AuthHelper().initializeAuth();
  }

  @override
  Widget build(BuildContext context) {
    // FCM トピック同期とマイグレーションのライフサイクルを維持
    ref.watch(topicSyncProvider);

    // ユーザー変更時に Crashlytics のユーザー ID を自動設定
    ref.listen<dynamic>(currentUserProvider, (previous, next) {
      if (next != null) {
        FirebaseCrashlytics.instance.setUserIdentifier(next.uid);
      }
    });

    final themeMode = ref.watch(themeModeProvider);
    final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
    final routeObserver = MyRouteObserver();

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: '適時開示(TDNet/Edinet) Notifier',
      locale: const Locale('ja', 'JP'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ja', '')],
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
        '/favorites': (context) => const FavoriteScreen(),
        '/settings': (context) => const SettingScreen(),
        '/savedDisclosures': (context) => const SavedDisclosuresScreen(),
        '/settlements': (context) => const SettlementsList(),
      },
      onGenerateRoute: (route) {
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
  }
}
