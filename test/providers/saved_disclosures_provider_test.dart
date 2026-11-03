import 'package:disclosure_app_fl/models/disclosure.dart';
import 'package:disclosure_app_fl/providers/auth_provider.dart';
import 'package:disclosure_app_fl/providers/saved_disclosures_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MockUser extends Fake implements User {
  @override
  String get uid => 'test_user_123';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('未ログイン時は savedDisclosuresStreamProvider は空リストを返す', () async {
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith((ref) => null),
      ],
    );
    addTearDown(container.dispose);

    final sub = container.listen(savedDisclosuresStreamProvider, (_, __) {});
    addTearDown(sub.close);

    final result = await container.read(savedDisclosuresStreamProvider.future);
    expect(result, isEmpty);
  });

  test('未ログイン時は groupedSavedDisclosuresProvider は空マップを返す', () async {
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith((ref) => null),
      ],
    );
    addTearDown(container.dispose);

    final map = container.read(groupedSavedDisclosuresProvider);
    expect(map, isEmpty);
  });

  test('未ログイン状態で SavedDisclosuresAction.save を呼ぶと StateError がスローされる', () async {
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith((ref) => null),
      ],
    );
    addTearDown(container.dispose);

    final action = container.read(savedDisclosuresActionProvider.notifier);
    final disclosure = Disclosure(
      code: '7203',
      company: 'トヨタ自動車',
      title: '決算短信',
      document: 'doc_123',
    );

    expect(
      action.save(disclosure),
      throwsA(isA<StateError>()),
    );
  });
}
