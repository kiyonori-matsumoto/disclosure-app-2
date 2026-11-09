import 'package:disclosure_app_fl/services/remote_config_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RemoteConfigService', () {
    test('デフォルト状態ではフォレンジックは無効で、許可ユーザーリストは空', () {
      final service = RemoteConfigService.custom();

      expect(service.isForensicGloballyEnabled, isFalse);
      expect(service.forensicAllowedUsers, isEmpty);
      expect(service.minRequiredVersion, '2.0.0');
      expect(
        service.isUserAllowedForForensic(email: 'user@example.com'),
        isFalse,
      );
    });

    test('isForensicGloballyEnabled が true の場合、誰でもフォレンジックが有効', () {
      final service = RemoteConfigService.custom(
        isForensicGloballyEnabled: true,
      );

      expect(
        service.isUserAllowedForForensic(email: 'anyone@example.com'),
        isTrue,
      );
      expect(
        service.isUserAllowedForForensic(uid: 'random-uid'),
        isTrue,
      );
      expect(
        service.isUserAllowedForForensic(),
        isTrue,
      );
    });

    test('許可ユーザーリストに含まれるメールアドレスまたはUIDのみ有効になる', () {
      final service = RemoteConfigService.custom(
        forensicAllowedUsers: ['admin@example.com', 'beta_tester_uid'],
      );

      // 大文字小文字を無視して一致
      expect(
        service.isUserAllowedForForensic(email: 'Admin@Example.com'),
        isTrue,
      );
      expect(
        service.isUserAllowedForForensic(uid: 'beta_tester_uid'),
        isTrue,
      );

      // 一致しないユーザーは false
      expect(
        service.isUserAllowedForForensic(email: 'other@example.com'),
        isFalse,
      );
      expect(
        service.isUserAllowedForForensic(uid: 'other_uid'),
        isFalse,
      );
      expect(
        service.isUserAllowedForForensic(),
        isFalse,
      );
    });
  });
}
