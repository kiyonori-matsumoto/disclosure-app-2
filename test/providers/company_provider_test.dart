import 'dart:io';

import 'package:disclosure_app_fl/models/company.dart';
import 'package:disclosure_app_fl/providers/company_provider.dart';
import 'package:disclosure_app_fl/utils/company_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testCompanies = [
    Company('7203', name: 'トヨタ自動車', edinetCode: 'E02144', nameKana: 'トヨタジドウシャ'),
    Company('6758', name: 'ソニーグループ', edinetCode: 'E01777', nameKana: 'ソニーグループ'),
    Company(null, name: 'コードなし企業', edinetCode: 'E99999', nameKana: 'コードナシ'),
  ];

  group('companyCodeMapProvider & companyEdinetMapProvider', () {
    test('データ未ロード時は空マップを返す', () {
      final container = ProviderContainer(
        overrides: [
          companiesStreamProvider.overrideWith((ref) => const Stream.empty()),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(companyCodeMapProvider), isEmpty);
      expect(container.read(companyEdinetMapProvider), isEmpty);
    });

    test('companyCodeMapProvider は証券コードキーの Map を構築し、code が null の企業を除外する', () async {
      final container = ProviderContainer(
        overrides: [
          companiesStreamProvider.overrideWith((ref) => Stream.value(testCompanies)),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(companiesStreamProvider, (_, __) {});
      addTearDown(sub.close);

      await container.read(companiesStreamProvider.future);

      final codeMap = container.read(companyCodeMapProvider);
      expect(codeMap.length, 2);
      expect(codeMap['7203']?.name, 'トヨタ自動車');
      expect(codeMap['6758']?.name, 'ソニーグループ');
      expect(codeMap.containsKey(null), isFalse);
    });

    test('companyEdinetMapProvider は EDINET コードキーの Map を構築する', () async {
      final container = ProviderContainer(
        overrides: [
          companiesStreamProvider.overrideWith((ref) => Stream.value(testCompanies)),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(companiesStreamProvider, (_, __) {});
      addTearDown(sub.close);

      await container.read(companiesStreamProvider.future);

      final edinetMap = container.read(companyEdinetMapProvider);
      expect(edinetMap.length, 3);
      expect(edinetMap['E02144']?.name, 'トヨタ自動車');
      expect(edinetMap['E01777']?.name, 'ソニーグループ');
      expect(edinetMap['E99999']?.name, 'コードなし企業');
    });
  });

  group('companiesStreamProvider with CompanyCacheManager', () {
    late Directory tempDir;
    late File cacheFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('company_provider_test_');
      cacheFile = File('${tempDir.path}/companies.json');
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('ローカルキャッシュから正しく Company リストをストリームとして emit する', () async {
      await cacheFile.writeAsString('''
[
  {"code": "72030", "name": "トヨタ自動車", "edinetCode": "E02144", "nameKana": "トヨタジドウシャ"},
  {"code": "99840", "name": "ソフトバンクグループ", "edinetCode": "E02778", "nameKana": "ソフトバンクグループ"}
]
''');

      final cacheManager = CompanyCacheManager(
        file: cacheFile,
        downloadFunction: (_) async {},
      );

      final container = ProviderContainer(
        overrides: [
          companyCacheManagerProvider.overrideWith((ref) async => cacheManager),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(companiesStreamProvider, (_, __) {});
      addTearDown(sub.close);

      final list = await container.read(companiesStreamProvider.future);
      expect(list.length, 2);
      expect(list[0].code, '7203');
      expect(list[0].name, 'トヨタ自動車');
      expect(list[1].code, '9984');
      expect(list[1].name, 'ソフトバンクグループ');

      final codeMap = container.read(companyCodeMapProvider);
      expect(codeMap['7203']?.name, 'トヨタ自動車');
      expect(codeMap['9984']?.name, 'ソフトバンクグループ');
    });
  });
}
