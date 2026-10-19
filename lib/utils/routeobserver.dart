import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class MyRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  static final MyRouteObserver _singleton = MyRouteObserver._internal();

  factory MyRouteObserver() {
    return _singleton;
  }

  MyRouteObserver._internal();

  void _logRoute(
      String action, Route<dynamic>? route, Route<dynamic>? previousRoute) {
    final routeName = route?.settings.name ?? 'unknown';
    final prevName = previousRoute?.settings.name ?? 'none';
    final message = 'Navigation: $action "$routeName" (from "$prevName")';
    debugPrint(message);
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.log(message);
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _logRoute('didPush', route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _logRoute('didPop', route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _logRoute('didReplace', newRoute, oldRoute);
  }
}
