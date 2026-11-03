import 'package:disclosure_app_fl/models/company.dart';
import 'package:disclosure_app_fl/providers/company_history_provider.dart';
import 'package:disclosure_app_fl/providers/company_provider.dart';
import 'package:disclosure_app_fl/providers/user_settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('searchCompaniesProvider', () {
    final testCompanies = [
      Company('7203', name: 'トヨタ自動車', nameKana: 'トヨタジドウシャ'),
      Company('6758', name: 'ソニーグループ', nameKana: 'ソニーグループ'),
      Company('9984', name: 'ソフトバンクグループ', nameKana: 'ソフトバンクグループ'),
    ];

    test('クエリが2文字未満の場合は空リストを返す', () {
      final container = ProviderContainer(
        overrides: [
          companiesStreamProvider.overrideWith((ref) => Stream.value(testCompanies)),
        ],
      );
      addTearDown(container.dispose);

      final result1 = container.read(searchCompaniesProvider(''));
      expect(result1, isEmpty);

      final result2 = container.read(searchCompaniesProvider('ト'));
      expect(result2, isEmpty);
    });

    test('証券コード前方一致で企業を検索できる', () async {
      final container = ProviderContainer(
        overrides: [
          companiesStreamProvider.overrideWith((ref) => Stream.value(testCompanies)),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(companiesStreamProvider, (_, __) {});
      addTearDown(sub.close);
      await container.read(companiesStreamProvider.future);

      final result = container.read(searchCompaniesProvider('72'));
      expect(result.length, 1);
      expect(result.first.code, '7203');
    });

    test('会社名部分一致で企業を検索できる', () async {
      final container = ProviderContainer(
        overrides: [
          companiesStreamProvider.overrideWith((ref) => Stream.value(testCompanies)),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(companiesStreamProvider, (_, __) {});
      addTearDown(sub.close);
      await container.read(companiesStreamProvider.future);

      final result = container.read(searchCompaniesProvider('グループ'));
      expect(result.length, 2);
      expect(result.map((c) => c.code), containsAll(['6758', '9984']));
    });

    test('ひらがな入力でカタカナ企業名を検索できる', () async {
      final container = ProviderContainer(
        overrides: [
          companiesStreamProvider.overrideWith((ref) => Stream.value(testCompanies)),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(companiesStreamProvider, (_, __) {});
      addTearDown(sub.close);
      await container.read(companiesStreamProvider.future);

      final result = container.read(searchCompaniesProvider('そにー'));
      expect(result.length, 1);
      expect(result.first.code, '6758');
    });
  });

  group('companyHistoryCodesProvider', () {
    test('未設定時は空リストを返す', () {
      final container = ProviderContainer(
        overrides: [
          userDocStreamProvider.overrideWith((ref) => Stream.value({})),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(companyHistoryCodesProvider);
      expect(result, isEmpty);
    });

    test('cp_hist が存在する場合、そのコードリストを返す', () async {
      final container = ProviderContainer(
        overrides: [
          userDocStreamProvider.overrideWith((ref) => Stream.value({
                'cp_hist': ['7203', '6758'],
              })),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(userDocStreamProvider, (_, __) {});
      addTearDown(sub.close);

      await container.read(userDocStreamProvider.future);
      final result = container.read(companyHistoryCodesProvider);
      expect(result, ['7203', '6758']);
    });
  });

  group('companyHistoryProvider', () {
    test('companyHistoryCodes と companyCodeMap を結合して Company リストを生成する', () {
      final toyota = Company('7203', name: 'トヨタ自動車');
      final sony = Company('6758', name: 'ソニーグループ');

      final container = ProviderContainer(
        overrides: [
          companyHistoryCodesProvider.overrideWithValue(['7203', '9999']),
          companyCodeMapProvider.overrideWithValue({
            '7203': toyota,
            '6758': sony,
          }),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(companyHistoryProvider);
      expect(result.length, 2);
      expect(result[0].name, 'トヨタ自動車');
      expect(result[1].name, '???');
    });
  });

  group('CompanyHistoryAction', () {
    test('CompanyHistoryAction はデフォルトで autoDispose される', () {
      expect(companyHistoryActionProvider.isAutoDispose, isTrue);
    });
  });
}
