import 'package:flutter/material.dart';

class MyRouteObserver extends RouteObserver<PageRoute> {
  static final MyRouteObserver _singleton = new MyRouteObserver._internal();

  factory MyRouteObserver() {
    return _singleton;
  }

  MyRouteObserver._internal();
}
