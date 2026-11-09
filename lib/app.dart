import 'dart:async';

import 'package:disclosure_app_fl/models/company.dart';
import 'package:disclosure_app_fl/providers/auth_provider.dart';
import 'package:disclosure_app_fl/providers/company_provider.dart';
import 'package:disclosure_app_fl/providers/remote_config_provider.dart';
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
import 'package:disclosure_app_fl/utils/notification_route_helper.dart';
import 'package:disclosure_app_fl/utils/routeobserver.dart';
import 'package:disclosure_app_fl/widgets/force_update_dialog.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

ThemeData buildLightTheme() => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: Brightness.light,
      ),
    );

ThemeData buildDarkTheme() => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: Brightness.dark,
      ),
    );

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
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey(
    debugLabel: "Main ScaffoldMessenger",
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

        // 強制アップデートの確認（クリティカル時のみ）
        final updateState = await ref.read(forceUpdateStateProvider.future);
        if (updateState.isRequired && mounted) {
          final navContext = navigatorKey.currentContext;
          if (navContext != null) {
            ForceUpdateDialog.show(navContext, updateState);
          }
        }
      } catch (e, stack) {
        debugPrint("Failed to handle initial notification message: $e");
        FirebaseCrashlytics.instance.recordError(e, stack, fatal: false);
      }
    });

    _initAuth();
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
    debugPrint("### notification handler ###: ${message.messageId}");
    final nav = navigatorKey.currentState;
    if (nav == null) return;

    final companyCodeMap = ref.read(companyCodeMapProvider);
    final destination = await NotificationRouteHelper.resolveDestination(
      message.data,
      companyCodeMap: companyCodeMap,
      companyResolver: (code, name) => getCompany(
        code: code,
        name: name,
        companyCodeMap: companyCodeMap,
      ),
    );

    NotificationRouteHelper.navigateToDestination(nav, destination);
  }

  Future<void> _handleNotificationMsg(RemoteMessage message) async {
    debugPrint("### notificationMsg handler ###: ${message.messageId}");
    final title = message.notification?.title ?? '';
    final body = message.notification?.body ?? '';
    if (title.isEmpty && body.isEmpty) return;

    final companyCodeMap = ref.read(companyCodeMapProvider);
    final destination = await NotificationRouteHelper.resolveDestination(
      message.data,
      companyCodeMap: companyCodeMap,
      companyResolver: (code, name) => getCompany(
        code: code,
        name: name,
        companyCodeMap: companyCodeMap,
      ),
    );

    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;

    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty)
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            if (body.isNotEmpty)
              Text(
                body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: destination is! NoneDestination
            ? SnackBarAction(
                label: '開く',
                onPressed: () {
                  final nav = navigatorKey.currentState;
                  if (nav != null) {
                    NotificationRouteHelper.navigateToDestination(
                      nav,
                      destination,
                    );
                  }
                },
              )
            : null,
      ),
    );
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

    // 強制アップデートが必要になった場合のダイアログ表示監視
    ref.listen<AsyncValue<ForceUpdateState>>(forceUpdateStateProvider,
        (previous, next) {
      final state = next.value;
      if (state != null && state.isRequired) {
        final navContext = navigatorKey.currentContext;
        if (navContext != null) {
          ForceUpdateDialog.show(navContext, state);
        }
      }
    });

    final themeMode = ref.watch(themeModeProvider);
    final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
    final routeObserver = MyRouteObserver();

    return MaterialApp(
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: '適時開示(TDNet/Edinet) Notifier',
      locale: const Locale('ja', 'JP'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ja', '')],
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeMode,
      routes: {
        '/': (context) => const DisclosureStreamScreen(),
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
