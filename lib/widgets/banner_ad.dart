import 'package:disclosure_app_fl/utils/ad_helper.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// 画面下部にバナー広告を表示するラッパーウィジェット
class WithBannerAdWidget extends StatelessWidget {
  final Widget child;

  const WithBannerAdWidget({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: child),
        const BannerAdWidget(),
      ],
    );
  }
}

/// 単体でバナー広告の読み込みと表示を行うウィジェット
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({Key? key}) : super(key: key);

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isLoading = false;
  int? _lastWidth;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final width = MediaQuery.of(context).size.width.truncate();
    if (_lastWidth != width) {
      _lastWidth = width;
      _loadAd(width);
    }
  }

  Future<void> _loadAd(int width) async {
    if (_isLoading) return;
    _isLoading = true;

    // 既存の広告があれば安全に破棄
    _bannerAd?.dispose();
    _bannerAd = null;
    if (mounted && _isLoaded) {
      setState(() {
        _isLoaded = false;
      });
    }

    final AnchoredAdaptiveBannerAdSize? size =
        // ignore: deprecated_member_use
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);

    if (!mounted) {
      _isLoading = false;
      return;
    }

    if (size == null) {
      debugPrint("Unable to get height of anchored banner.");
      _isLoading = false;
      return;
    }

    final bannerAd = BannerAd(
      size: size,
      adUnitId: AdHelper.bannerAdUnitId,
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          debugPrint('バナー広告がロードされました。');
          _isLoading = false;
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          debugPrint('バナー広告のロードに失敗しました。: $error');
          _isLoading = false;
          ad.dispose();
          if (mounted) {
            setState(() {
              _bannerAd = null;
              _isLoaded = false;
            });
          }
        },
        onAdOpened: (Ad ad) => debugPrint('バナー広告が開かれました。'),
        onAdClosed: (Ad ad) => debugPrint('バナー広告が閉じられました。'),
      ),
      request: const AdRequest(),
    );

    _bannerAd = bannerAd;
    await bannerAd.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _bannerAd = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }
    return SafeArea(
      top: false,
      child: SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
