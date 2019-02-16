import 'dart:io';

import 'package:firebase_admob/firebase_admob.dart';
import 'package:flutter/material.dart';

MobileAdTargetingInfo targetingInfo = MobileAdTargetingInfo(
  keywords: <String>['disclosure', 'tdnet'],
  contentUrl: 'https://flutter.io',
  childDirected: false,
  testDevices: <String>[
    'BBAD97782D98B8B76526B5A34CDE98A7'
  ], // Android emulators are considered test devices
);

BannerAd showBanner(String adUnitId) {
  final _bannerAd = BannerAd(
    adUnitId: adUnitId,
    size: AdSize.smartBanner,
    targetingInfo: targetingInfo,
  );
  _bannerAd
    ..load()
    ..show();

  return _bannerAd;
}

//      adUnitId: 'ca-app-pub-5131663294295156/8292017322',

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
