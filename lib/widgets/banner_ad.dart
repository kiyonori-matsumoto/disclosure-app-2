import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class WithBannerAdWidget extends StatefulWidget {
  final Widget child;

  const WithBannerAdWidget({Key? key, required this.child}) : super(key: key);

  @override
  State<WithBannerAdWidget> createState() => _WithBannerAdWidgetState();
}

class _WithBannerAdWidgetState extends State<WithBannerAdWidget> {
  BannerAd? _bannerAd;

  @override
  Widget build(BuildContext context) {
    if (_bannerAd == null) {
      return widget.child;
    }
    return Stack(
      children: [
        SizedBox(
            child: widget.child,
            height: MediaQuery.of(context).size.height -
                _bannerAd!.size.height.toDouble()),
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            child: SizedBox(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAd();
  }

  Future<void> _loadAd() async {
    final AnchoredAdaptiveBannerAdSize? size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
            MediaQuery.of(context).size.width.truncate());

    if (size == null) {
      print("Unable to get height of anchored banner.");
      return;
    }

    _bannerAd = BannerAd(
      size: size,
      adUnitId: "ca-app-pub-5131663294295156/8292017322",
      // adUnitId: "ca-app-pub-3940256099942544/6300978111", // test
      listener: BannerAdListener(
        // 広告が正常にロードされたときに呼ばれます。
        onAdLoaded: (Ad ad) {
          print('バナー広告がロードされました。');
          setState(() {
            _bannerAd = ad as BannerAd?;
          });
        },
        // 広告のロードが失敗した際に呼ばれます。
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          print('バナー広告のロードに失敗しました。: $error');
        },
        // 広告が開かれたときに呼ばれます。
        onAdOpened: (Ad ad) => print('バナー広告が開かれました。'),
        // 広告が閉じられたときに呼ばれます。
        onAdClosed: (Ad ad) => print('バナー広告が閉じられました。'),
      ),
      request: AdRequest(),
    );
    _bannerAd!.load();
  }

  @override
  void dispose() {
    super.dispose();
    _bannerAd?.dispose();
  }
}

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({Key? key}) : super(key: key);

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;

  @override
  Widget build(BuildContext context) {
    if (_bannerAd == null) {
      return const SizedBox.shrink();
    }
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: SizedBox(
          width: _bannerAd!.size.width.toDouble(),
          height: _bannerAd!.size.height.toDouble(),
          child: AdWidget(ad: _bannerAd!),
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAd();
  }

  Future<void> _loadAd() async {
    final AnchoredAdaptiveBannerAdSize? size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
            MediaQuery.of(context).size.width.truncate());

    if (size == null) {
      print("Unable to get height of anchored banner.");
      return;
    }

    _bannerAd = BannerAd(
      size: size,
      // adUnitId: "ca-app-pub-5131663294295156/8292017322",
      adUnitId: "ca-app-pub-3940256099942544/6300978111", // test
      listener: BannerAdListener(
        // 広告が正常にロードされたときに呼ばれます。
        onAdLoaded: (Ad ad) {
          print('バナー広告がロードされました。');
          setState(() {
            _bannerAd = ad as BannerAd?;
          });
        },
        // 広告のロードが失敗した際に呼ばれます。
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          print('バナー広告のロードに失敗しました。: $error');
        },
        // 広告が開かれたときに呼ばれます。
        onAdOpened: (Ad ad) => print('バナー広告が開かれました。'),
        // 広告が閉じられたときに呼ばれます。
        onAdClosed: (Ad ad) => print('バナー広告が閉じられました。'),
      ),
      request: AdRequest(),
    );
    _bannerAd!.load();
  }

  @override
  void dispose() {
    super.dispose();
    _bannerAd?.dispose();
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
