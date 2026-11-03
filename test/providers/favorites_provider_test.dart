import 'package:disclosure_app_fl/models/company.dart';
import 'package:disclosure_app_fl/providers/auth_provider.dart';
import 'package:disclosure_app_fl/providers/company_provider.dart';
import 'package:disclosure_app_fl/providers/favorites_provider.dart';
import 'package:disclosure_app_fl/providers/user_settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('favoritesProvider', () {
    test('未ログイン時または未設定時は空リストを返す', () {
      final container = ProviderContainer(
        overrides: [
          userDocStreamProvider.overrideWith((ref) => Stream.value({})),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(favoritesProvider);
      expect(result, isEmpty);
    });

    test('userDocStreamProvider に favorites が存在する場合、そのリストを返す', () async {
      final container = ProviderContainer(
        overrides: [
          userDocStreamProvider.overrideWith((ref) => Stream.value({
                'favorites': ['7203', '6758']
              })),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(userDocStreamProvider, (_, __) {});
      addTearDown(sub.close);

      await container.read(userDocStreamProvider.future);
      final result = container.read(favoritesProvider);
      expect(result, ['7203', '6758']);
    });
  });

  group('favoritesWithCompanyProvider', () {
    test('favorites と companyCodeMap を結合して Company リストを生成する', () {
      final mockCodeMap = {
        '7203': Company('7203', name: 'トヨタ自動車'),
      };

      final container = ProviderContainer(
        overrides: [
          favoritesProvider.overrideWithValue(['7203', '9999']),
          companyCodeMapProvider.overrideWithValue(mockCodeMap),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(favoritesWithCompanyProvider);
      expect(result.length, 2);
      expect(result[0].code, '7203');
      expect(result[0].name, 'トヨタ自動車');
      expect(result[1].code, '9999');
      expect(result[1].name, '???');
    });
  });

  group('isFavoriteProvider', () {
    test('指定コードがお気に入りに含まれるかどうかを正しく判定する', () {
      final container = ProviderContainer(
        overrides: [
          favoritesProvider.overrideWithValue(['7203']),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(isFavoriteProvider('7203')), isTrue);
      expect(container.read(isFavoriteProvider('6758')), isFalse);
    });
  });

  group('FavoritesAction', () {
    test('未ログイン状態で add を呼ぶと StateError がスローされる', () {
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => null),
        ],
      );
      addTearDown(container.dispose);

      final action = container.read(favoritesActionProvider.notifier);
      expect(action.add('7203'), throwsA(isA<StateError>()));
    });

    test('未ログイン状態で remove を呼ぶと StateError がスローされる', () {
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => null),
        ],
      );
      addTearDown(container.dispose);

      final action = container.read(favoritesActionProvider.notifier);
      expect(action.remove('7203'), throwsA(isA<StateError>()));
    });

    test('未ログイン状態で toggle を呼ぶと StateError がスローされる', () {
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => null),
        ],
      );
      addTearDown(container.dispose);

      final action = container.read(favoritesActionProvider.notifier);
      expect(action.toggle('7203'), throwsA(isA<StateError>()));
    });
  });
}
