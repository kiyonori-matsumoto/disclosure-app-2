import 'package:disclosure_app_fl/models/company.dart';
import 'package:disclosure_app_fl/utils/get_company.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('getCompany', () {
    final company1 = Company('7203', name: 'トヨタ自動車', edinetCode: 'E02144');
    final company2 = Company('6758', name: 'ソニーグループ', edinetCode: 'E01777');

    final codeMap = <String, Company>{
      '7203': company1,
      '6758': company2,
    };

    final edinetMap = <String, Company>{
      'E02144': company1,
      'E01777': company2,
    };

    test('companyCodeMap からコード一致で企業を取得できる', () async {
      final result = await getCompany(
        code: '7203',
        companyCodeMap: codeMap,
      );
      expect(result.code, equals('7203'));
      expect(result.name, equals('トヨタ自動車'));
      expect(result.edinetCode, equals('E02144'));
    });

    test('5桁コード（例: 72030）の場合でも先頭4桁でマスタから企業（EDINETコード含む）を取得できる', () async {
      final result = await getCompany(
        code: '72030',
        companyCodeMap: codeMap,
      );
      expect(result.code, equals('7203'));
      expect(result.name, equals('トヨタ自動車'));
      expect(result.edinetCode, equals('E02144'));
    });

    test('companyMap から EDINET コード一致で企業を取得できる', () async {
      final result = await getCompany(
        edinetCode: 'E01777',
        companyMap: edinetMap,
      );
      expect(result.code, equals('6758'));
      expect(result.name, equals('ソニーグループ'));
    });

    test('Map に存在しない場合は引数の情報でフォールバックの Company を生成する', () async {
      final result = await getCompany(
        code: '9984',
        name: 'ソフトバンクグループ',
        companyCodeMap: codeMap,
      );
      expect(result.code, equals('9984'));
      expect(result.name, equals('ソフトバンクグループ'));
    });

    test('code と edinetCode の両方が null の場合は assertion error が発生する', () {
      expect(
        () => getCompany(name: 'テスト企業'),
        throwsAssertionError,
      );
    });
  });
}
