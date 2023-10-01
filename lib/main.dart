import 'dart:async';

import 'package:disclosure_app_fl/provider.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'app.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  // add this, and it should be the first line in main method
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  await Firebase.initializeApp();
  // debugPaintSizeEnabled = true;
  FlutterError.onError = (FlutterErrorDetails details) {
    print("FlutterError onerror handler");
    print(isInDebugMode);
    if (isInDebugMode) {
      // In development mode simply print to console.
      FlutterError.dumpErrorToConsole(details);
    } else {
      // In production mode report to the application zone to report to
      // Crashlytics.
      Zone.current.handleUncaughtError(details.exception, details.stack!);
    }
  };

  // FirebaseCrashlytics.instance.enableInDevMode = true;
  runZonedGuarded<Future<Null>>(() async {
    runApp(AppProvider(
      child: AppRootWidget(),
    ));
  }, (Object error, StackTrace stackTrace) async {
    print("runZoned onerror handler");
    if (isInDebugMode) {
      print(error);
      print(stackTrace);
    } else {
      // Whenever an error occurs, call the `reportCrash` function. This will send
      // Dart errors to our dev console or Crashlytics depending on the environment.
      await FirebaseCrashlytics.instance.recordError(error, stackTrace);
    }
  });
}

bool get isInDebugMode {
  // Assume you're in production mode
  bool inDebugMode = false;

  // Assert expressions are only evaluated during development. They are ignored
  // in production. Therefore, this code only sets `inDebugMode` to true
  // in a development environment.
  assert(inDebugMode = true);

  return inDebugMode;
}
