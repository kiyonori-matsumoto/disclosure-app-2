import 'dart:async';

import 'package:disclosure_app_fl/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'app.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await GoogleSignIn.instance.initialize();
  await FirebaseAppCheck.instance.activate(
    androidProvider:
        kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
    appleProvider:
        kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
  );

  // デバッグ時は Crashlytics へのデータ送信を無効化してノイズを防止
  await FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(!kDebugMode);

  if (!kDebugMode) {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      await FirebaseCrashlytics.instance
          .setCustomKey('app_version', packageInfo.version);
      await FirebaseCrashlytics.instance
          .setCustomKey('build_number', packageInfo.buildNumber);
      FirebaseCrashlytics.instance.log("App launched: version ${packageInfo.version} (${packageInfo.buildNumber})");
    } catch (e) {
      debugPrint("Failed to initialize package info for Crashlytics: $e");
    }
  }

  FlutterError.onError = (errorDetails) {
    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(errorDetails);
    } else {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      debugPrint("PlatformDispatcher error: $error");
      debugPrint(stack.toString());
    } else {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
    return true;
  };

  unawaited(MobileAds.instance.initialize());

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    debugPrint('User granted permission');
  } else if (settings.authorizationStatus ==
      AuthorizationStatus.provisional) {
    debugPrint('User granted provisional permission');
  } else {
    debugPrint('User declined or has not accepted permission');
  }

  runApp(AppProvider(
    child: AppRootWidget(),
  ));
}
