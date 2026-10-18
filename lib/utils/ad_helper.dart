import 'dart:io';
import 'package:flutter/foundation.dart';

class AdHelper {
  static const String _prodAndroidBanner = "ca-app-pub-5131663294295156/8292017322";
  static const String _prodIosBanner = "ca-app-pub-5131663294295156/8292017322";

  // Google official AdMob test ad unit IDs
  static const String _testAndroidBanner = "ca-app-pub-3940256099942544/6300978111";
  static const String _testIosBanner = "ca-app-pub-3940256099942544/2934735716";

  static String get bannerAdUnitId {
    if (kDebugMode) {
      if (Platform.isIOS) {
        return _testIosBanner;
      }
      return _testAndroidBanner;
    }

    if (Platform.isIOS) {
      return _prodIosBanner;
    }
    return _prodAndroidBanner;
  }
}
