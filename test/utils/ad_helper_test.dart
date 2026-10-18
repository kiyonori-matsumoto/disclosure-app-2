import 'package:flutter_test/flutter_test.dart';
import 'package:disclosure_app_fl/utils/ad_helper.dart';

void main() {
  group('AdHelper', () {
    test('returns non-empty banner ad unit ID', () {
      final adUnitId = AdHelper.bannerAdUnitId;
      expect(adUnitId, isNotEmpty);
      expect(adUnitId.startsWith('ca-app-pub-'), isTrue);
    });
  });
}
