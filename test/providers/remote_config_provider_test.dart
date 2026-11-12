import 'package:disclosure_app_fl/providers/auth_provider.dart';
import 'package:disclosure_app_fl/providers/forensic_toggle_provider.dart';
import 'package:disclosure_app_fl/providers/remote_config_provider.dart';
import 'package:disclosure_app_fl/services/remote_config_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeUser extends Fake implements User {
  @override
  final String? email;
  @override
  final String uid;

  FakeUser({this.email, required this.uid});
}

void main() {
  group('isForensicEnabledProvider', () {
    test('手動トグルが false の場合、許可ユーザーであっても false を返す', () {
      final container = ProviderContainer(
        overrides: [
          forensicToggleProvider.overrideWith(() => ForensicToggleNotifier()),
          currentUserProvider.overrideWith(
            (ref) => FakeUser(email: 'special@example.com', uid: 'u123'),
          ),
          remoteConfigServiceProvider.overrideWithValue(
            RemoteConfigService.custom(
              isForensicGloballyEnabled: true,
              forensicAllowedUsers: ['special@example.com'],
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(isForensicEnabledProvider), isFalse);
    });

    test('未ログインかつ全体開放されていない場合、false を返す', () {
      final container = ProviderContainer(
        overrides: [
          forensicToggleProvider.overrideWith(() => _MockForensicToggleNotifier(true)),
          currentUserProvider.overrideWith((ref) => null),
          remoteConfigServiceProvider.overrideWithValue(
            RemoteConfigService.custom(
              isForensicGloballyEnabled: false,
              forensicAllowedUsers: ['test@example.com'],
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(isForensicEnabledProvider), isFalse);
    });

    test('ログインユーザーが許可リストに含まれる場合、true を返す', () {
      final container = ProviderContainer(
        overrides: [
          forensicToggleProvider.overrideWith(() => _MockForensicToggleNotifier(true)),
          currentUserProvider.overrideWith(
            (ref) => FakeUser(email: 'special@example.com', uid: 'u123'),
          ),
          remoteConfigServiceProvider.overrideWithValue(
            RemoteConfigService.custom(
              isForensicGloballyEnabled: false,
              forensicAllowedUsers: ['special@example.com'],
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(isForensicEnabledProvider), isTrue);
    });

    test('ログインユーザーが許可リストに含まれない場合、false を返す', () {
      final container = ProviderContainer(
        overrides: [
          forensicToggleProvider.overrideWith(() => _MockForensicToggleNotifier(true)),
          currentUserProvider.overrideWith(
            (ref) => FakeUser(email: 'normal@example.com', uid: 'u456'),
          ),
          remoteConfigServiceProvider.overrideWithValue(
            RemoteConfigService.custom(
              isForensicGloballyEnabled: false,
              forensicAllowedUsers: ['special@example.com'],
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(isForensicEnabledProvider), isFalse);
    });

    test('isForensicGloballyEnabled が true の場合、一般ユーザーでも true を返す', () {
      final container = ProviderContainer(
        overrides: [
          forensicToggleProvider.overrideWith(() => _MockForensicToggleNotifier(true)),
          currentUserProvider.overrideWith(
            (ref) => FakeUser(email: 'normal@example.com', uid: 'u456'),
          ),
          remoteConfigServiceProvider.overrideWithValue(
            RemoteConfigService.custom(
              isForensicGloballyEnabled: true,
              forensicAllowedUsers: [],
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(isForensicEnabledProvider), isTrue);
    });
  });
}

class _MockForensicToggleNotifier extends ForensicToggleNotifier {
  final bool initialValue;
  _MockForensicToggleNotifier(this.initialValue);

  @override
  bool build() => initialValue;
}
