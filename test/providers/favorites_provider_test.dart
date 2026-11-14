import 'package:disclosure_app_fl/models/company.dart';
import 'package:disclosure_app_fl/providers/company_provider.dart';
import 'package:disclosure_app_fl/providers/favorites_provider.dart';
import 'package:disclosure_app_fl/providers/user_settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  group('favoriteSortOrderProvider', () {
    test('デフォルトは codeAsc で、SharedPreferences から復元・保存できる', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(favoriteSortOrderProvider), FavoriteSortOrder.codeAsc);

      await container
          .read(favoriteSortOrderProvider.notifier)
          .setSortOrder(FavoriteSortOrder.nameAsc);
      expect(container.read(favoriteSortOrderProvider), FavoriteSortOrder.nameAsc);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('favorite_sort_order'), 'nameAsc');
    });

    test('保存済みの値が読み込まれ、不正値の場合は codeAsc にフォールバックする', () async {
      SharedPreferences.setMockInitialValues({
        'favorite_sort_order': 'registered',
      });
      final container1 = ProviderContainer();
      addTearDown(container1.dispose);
      container1.read(favoriteSortOrderProvider);
      await container1.read(favoriteSortOrderProvider.notifier).initFuture;
      expect(
        container1.read(favoriteSortOrderProvider),
        FavoriteSortOrder.registered,
      );

      SharedPreferences.setMockInitialValues({
        'favorite_sort_order': 'unknown_value',
      });
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);
      container2.read(favoriteSortOrderProvider);
      await container2.read(favoriteSortOrderProvider.notifier).initFuture;
      expect(
        container2.read(favoriteSortOrderProvider),
        FavoriteSortOrder.codeAsc,
      );
    });
  });

  group('favoritesWithCompanyProvider', () {
    test('favorites と companyCodeMap を結合し、デフォルトで証券コード昇順に並ぶ', () {
      SharedPreferences.setMockInitialValues({});
      final mockCodeMap = {
        '7203': Company('7203', name: 'トヨタ自動車', nameKana: 'トヨタジドウシャ'),
        '130A': Company('130A', name: 'ウェリタス', nameKana: 'ウェリタス'),
        '1301': Company('1301', name: '極洋', nameKana: 'キョクヨウ'),
      };

      final container = ProviderContainer(
        overrides: [
          favoritesProvider.overrideWithValue(['7203', '9999', '130A', '1301']),
          companyCodeMapProvider.overrideWithValue(mockCodeMap),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(favoritesWithCompanyProvider);
      expect(result.map((c) => c.code).toList(), ['1301', '130A', '7203', '9999']);
      expect(result[2].name, 'トヨタ自動車');
      expect(result[3].name, '???');
    });

    test('ソート順に応じて証券コード降順・企業名順・登録順に並ぶ', () async {
      SharedPreferences.setMockInitialValues({});
      final mockCodeMap = {
        '7203': Company('7203', name: 'トヨタ自動車', nameKana: 'トヨタジドウシャ'),
        '6758': Company('6758', name: 'ソニーグループ', nameKana: 'ソニーグループ'),
        '1301': Company('1301', name: '極洋', nameKana: 'キョクヨウ'),
      };

      final container = ProviderContainer(
        overrides: [
          favoritesProvider.overrideWithValue(['7203', '1301', '6758']),
          companyCodeMapProvider.overrideWithValue(mockCodeMap),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(favoriteSortOrderProvider.notifier)
          .setSortOrder(FavoriteSortOrder.codeDesc);
      expect(
        container.read(favoritesWithCompanyProvider).map((c) => c.code).toList(),
        ['7203', '6758', '1301'],
      );

      await container
          .read(favoriteSortOrderProvider.notifier)
          .setSortOrder(FavoriteSortOrder.nameAsc);
      expect(
        container.read(favoritesWithCompanyProvider).map((c) => c.code).toList(),
        ['1301', '6758', '7203'],
      );

      await container
          .read(favoriteSortOrderProvider.notifier)
          .setSortOrder(FavoriteSortOrder.registered);
      expect(
        container.read(favoritesWithCompanyProvider).map((c) => c.code).toList(),
        ['7203', '1301', '6758'],
      );
    });

    test('企業名順で nameKana が空の場合は name にフォールバックし、同名時は code でタイブレークする',
        () async {
      SharedPreferences.setMockInitialValues({});
      final mockCodeMap = {
        '9001': Company('9001', name: 'アイウエオ', nameKana: ''),
        '8002': Company('8002', name: '同名企業A', nameKana: 'ドウメイ'),
        '8001': Company('8001', name: '同名企業B', nameKana: 'ドウメイ'),
        '7001': Company('7001', name: 'カキクケコ', nameKana: null),
      };

      final container = ProviderContainer(
        overrides: [
          favoritesProvider.overrideWithValue(['7001', '8002', '9001', '8001']),
          companyCodeMapProvider.overrideWithValue(mockCodeMap),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(favoriteSortOrderProvider.notifier)
          .setSortOrder(FavoriteSortOrder.nameAsc);
      expect(
        container.read(favoritesWithCompanyProvider).map((c) => c.code).toList(),
        ['9001', '7001', '8001', '8002'],
      );
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
    test('FavoritesAction はデフォルトで autoDispose される', () {
      expect(favoritesActionProvider.isAutoDispose, isTrue);
    });
  });
}
