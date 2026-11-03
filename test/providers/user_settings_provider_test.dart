import 'package:disclosure_app_fl/providers/auth_provider.dart';
import 'package:disclosure_app_fl/providers/user_settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('未ログイン時は userDocStreamProvider は空マップを返す', () async {
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith((ref) => null),
      ],
    );
    addTearDown(container.dispose);

    final sub = container.listen(userDocStreamProvider, (_, __) {});
    addTearDown(sub.close);

    final result = await container.read(userDocStreamProvider.future);
    expect(result, isEmpty);
  });

  test('未ログイン時は hideDailyDisclosureProvider は false を返す', () {
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith((ref) => null),
      ],
    );
    addTearDown(container.dispose);

    final result = container.read(hideDailyDisclosureProvider);
    expect(result, isFalse);
  });

  test('userDocStreamProvider に hideDailyDisclosure: true がある場合、hideDailyDisclosureProvider は true を返す', () async {
    final container = ProviderContainer(
      overrides: [
        userDocStreamProvider.overrideWith((ref) => Stream.value({
              'setting': {'hideDailyDisclosure': true}
            })),
      ],
    );
    addTearDown(container.dispose);

    final sub = container.listen(userDocStreamProvider, (_, __) {});
    addTearDown(sub.close);

    await container.read(userDocStreamProvider.future);
    final result = container.read(hideDailyDisclosureProvider);
    expect(result, isTrue);
  });

  test('userDocStreamProvider に hideDailyDisclosure: false がある場合、hideDailyDisclosureProvider は false を返す', () async {
    final container = ProviderContainer(
      overrides: [
        userDocStreamProvider.overrideWith((ref) => Stream.value({
              'setting': {'hideDailyDisclosure': false}
            })),
      ],
    );
    addTearDown(container.dispose);

    final sub = container.listen(userDocStreamProvider, (_, __) {});
    addTearDown(sub.close);

    await container.read(userDocStreamProvider.future);
    final result = container.read(hideDailyDisclosureProvider);
    expect(result, isFalse);
  });

  test('未ログイン状態で UserSettingsAction.setHideDailyDisclosure を呼ぶと StateError がスローされる', () async {
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith((ref) => null),
      ],
    );
    addTearDown(container.dispose);

    final action = container.read(userSettingsActionProvider.notifier);

    expect(
      action.setHideDailyDisclosure(true),
      throwsA(isA<StateError>()),
    );
  });
}
