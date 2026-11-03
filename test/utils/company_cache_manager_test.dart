import 'dart:convert';
import 'dart:io';

import 'package:disclosure_app_fl/utils/company_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CompanyCacheManager', () {
    late Directory tempDir;
    late File targetFile;
    late File tempFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('company_cache_test_');
      targetFile = File('${tempDir.path}/companies.json');
      tempFile = File('${tempDir.path}/companies.json.tmp');
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    final sampleData = [
      {
        'code': '72030',
        'name': 'トヨタ自動車',
        'edinetCode': 'E02144',
        'nameKana': 'トヨタジドウシャ',
      },
      {
        'code': '67580',
        'name': 'ソニーグループ',
        'edinetCode': 'E01777',
        'nameKana': 'ソニーグループ',
      },
    ];

    group('safeDelete (CrashlyticsのPathNotFoundException防止)', () {
      test('存在しないファイルを削除しようとしても例外をスローせず安全に終了する', () {
        final nonExistentFile = File('${tempDir.path}/non_existent.json');
        expect(nonExistentFile.existsSync(), isFalse);

        // 以前のコードではここで PathNotFoundException (errno = 2) が発生していた
        expect(() => CompanyCacheManager.safeDelete(nonExistentFile), returnsNormally);
      });

      test('存在するファイルを正常に削除する', () {
        targetFile.writeAsStringSync('dummy content');
        expect(targetFile.existsSync(), isTrue);

        CompanyCacheManager.safeDelete(targetFile);
        expect(targetFile.existsSync(), isFalse);
      });

      test('null が渡されても安全に終了する', () {
        expect(() => CompanyCacheManager.safeDelete(null), returnsNormally);
      });
    });

    group('loadLocalCache', () {
      test('ファイルが存在しない場合は null を返す', () async {
        final manager = CompanyCacheManager(
          file: targetFile,
          tempFile: tempFile,
          downloadFunction: (_) async {},
        );

        final result = await manager.loadLocalCache();
        expect(result, isNull);
      });

      test('正常な JSON リストファイルの場合はデコード結果を返す', () async {
        await targetFile.writeAsString(jsonEncode(sampleData));

        final manager = CompanyCacheManager(
          file: targetFile,
          tempFile: tempFile,
          downloadFunction: (_) async {},
        );

        final result = await manager.loadLocalCache();
        expect(result, isNotNull);
        expect(result!.length, 2);
        expect(result[0]['code'], '72030');
      });

      test('破損した JSON の場合は例外をスローせずファイルを削除して null を返す', () async {
        await targetFile.writeAsString('corrupted { json [ broken');

        final manager = CompanyCacheManager(
          file: targetFile,
          tempFile: tempFile,
          downloadFunction: (_) async {},
        );

        final result = await manager.loadLocalCache();
        expect(result, isNull);
        // 破損ファイルが安全に削除されていること
        expect(targetFile.existsSync(), isFalse);
      });

      test('JSON のルートが List ではない（Mapなど）場合も無効とみなして削除し null を返す', () async {
        await targetFile.writeAsString(jsonEncode({'error': 'bad format'}));

        final manager = CompanyCacheManager(
          file: targetFile,
          tempFile: tempFile,
          downloadFunction: (_) async {},
        );

        final result = await manager.loadLocalCache();
        expect(result, isNull);
        expect(targetFile.existsSync(), isFalse);
      });
    });

    group('isCacheFresh (有効期限判定)', () {
      test('ファイルが存在しない場合は false を返す', () {
        final manager = CompanyCacheManager(
          file: targetFile,
          tempFile: tempFile,
          downloadFunction: (_) async {},
        );
        expect(manager.isCacheFresh(), isFalse);
      });

      test('キャッシュ期間内の場合は true を返す', () async {
        await targetFile.writeAsString(jsonEncode(sampleData));
        final manager = CompanyCacheManager(
          file: targetFile,
          tempFile: tempFile,
          cacheDuration: const Duration(hours: 24),
          downloadFunction: (_) async {},
        );

        expect(manager.isCacheFresh(), isTrue);
      });

      test('キャッシュ期間を経過している場合は false を返す', () async {
        await targetFile.writeAsString(jsonEncode(sampleData));
        final manager = CompanyCacheManager(
          file: targetFile,
          tempFile: tempFile,
          cacheDuration: const Duration(hours: 24),
          downloadFunction: (_) async {},
        );

        // 25時間後の日時で判定
        final futureTime = DateTime.now().add(const Duration(hours: 25));
        expect(manager.isCacheFresh(futureTime), isFalse);
      });
    });

    group('downloadAndSave (アトミック保存＆既存キャッシュ保護)', () {
      test('ダウンロード成功時: 一時ファイル経由で本番ファイルへ保存されデコード結果を返す', () async {
        final manager = CompanyCacheManager(
          file: targetFile,
          tempFile: tempFile,
          downloadFunction: (dest) async {
            // ダウンロード先が tempFile であることを確認
            expect(dest.path, tempFile.path);
            await dest.writeAsString(jsonEncode(sampleData));
          },
        );

        final result = await manager.downloadAndSave();
        expect(result.length, 2);
        // 本番ファイルが作成され、tempFile は置換完了により残っていないこと
        expect(targetFile.existsSync(), isTrue);
        expect(tempFile.existsSync(), isFalse);
      });

      test('ダウンロード失敗時: 既存の健全なローカルキャッシュは保護され、tempFile のみ削除される', () async {
        // 事前に有効なローカルキャッシュを用意
        await targetFile.writeAsString(jsonEncode(sampleData));

        final manager = CompanyCacheManager(
          file: targetFile,
          tempFile: tempFile,
          downloadFunction: (dest) async {
            // 一時ファイルに書きかけを残した状態で例外発生
            await dest.writeAsString('partial');
            throw const SocketException('Connection lost');
          },
        );

        // 例外が再スローされること
        await expectLater(
          () => manager.downloadAndSave(),
          throwsA(isA<SocketException>()),
        );

        // 重要: 既存の本番キャッシュファイルは絶対に消えていないこと！
        expect(targetFile.existsSync(), isTrue);
        expect(jsonDecode(targetFile.readAsStringSync()).length, 2);

        // 一時ファイルはクリーンアップされていること
        expect(tempFile.existsSync(), isFalse);
      });

      test('初回ダウンロード失敗時（本番ファイル未存在）: tempFile のみ削除され例外がスローされる', () async {
        expect(targetFile.existsSync(), isFalse);

        final manager = CompanyCacheManager(
          file: targetFile,
          tempFile: tempFile,
          downloadFunction: (dest) async {
            await dest.writeAsString('broken');
            throw const SocketException('Timeout');
          },
        );

        await expectLater(
          () => manager.downloadAndSave(),
          throwsA(isA<SocketException>()),
        );

        // 本番ファイルも tempFile も残っていないこと
        expect(targetFile.existsSync(), isFalse);
        expect(tempFile.existsSync(), isFalse);
      });

      test('ダウンロードされたデータが破損JSONの場合: FormatException をスローし本番は更新しない', () async {
        await targetFile.writeAsString(jsonEncode(sampleData));

        final manager = CompanyCacheManager(
          file: targetFile,
          tempFile: tempFile,
          downloadFunction: (dest) async {
            await dest.writeAsString('not a valid json');
          },
        );

        await expectLater(
          () => manager.downloadAndSave(),
          throwsA(isA<FormatException>()),
        );

        // 既存の本番キャッシュは保護されていること
        expect(targetFile.existsSync(), isTrue);
        expect(tempFile.existsSync(), isFalse);
      });
    });

    group('getCompaniesStream (Stale-While-Revalidate)', () {
      test('有効期限内のキャッシュが存在する場合: キャッシュのみ emit しダウンロードは実行しない', () async {
        await targetFile.writeAsString(jsonEncode(sampleData));

        bool downloadCalled = false;
        final manager = CompanyCacheManager(
          file: targetFile,
          tempFile: tempFile,
          cacheDuration: const Duration(hours: 24),
          downloadFunction: (_) async {
            downloadCalled = true;
          },
        );

        final emitted = await manager.getCompaniesStream().toList();

        expect(emitted.length, 1);
        expect(emitted[0].length, 2);
        expect(downloadCalled, isFalse);
      });

      test('キャッシュ未存在時: ダウンロードを実行し結果を emit する', () async {
        expect(targetFile.existsSync(), isFalse);

        final manager = CompanyCacheManager(
          file: targetFile,
          tempFile: tempFile,
          downloadFunction: (dest) async {
            await dest.writeAsString(jsonEncode(sampleData));
          },
        );

        final emitted = await manager.getCompaniesStream().toList();

        expect(emitted.length, 1);
        expect(emitted[0].length, 2);
        expect(targetFile.existsSync(), isTrue);
      });

      test('キャッシュ期限切れ時: キャッシュ emit 後に最新データをダウンロードして再度 emit する (2回)', () async {
        final oldData = [
          {'code': '72030', 'name': 'トヨタ自動車'}
        ];
        await targetFile.writeAsString(jsonEncode(oldData));

        final manager = CompanyCacheManager(
          file: targetFile,
          tempFile: tempFile,
          // キャッシュ期間を 0 にして常に stale 状態にする
          cacheDuration: Duration.zero,
          downloadFunction: (dest) async {
            await dest.writeAsString(jsonEncode(sampleData));
          },
        );

        final emitted = await manager.getCompaniesStream().toList();

        expect(emitted.length, 2);
        expect(emitted[0].length, 1); // 1回目: キャッシュ (1件)
        expect(emitted[1].length, 2); // 2回目: 最新 (2件)
      });

      test('キャッシュあり＆バックグラウンドダウンロード失敗時: キャッシュを維持しストリームは中断しない', () async {
        await targetFile.writeAsString(jsonEncode(sampleData));

        dynamic fallbackError;
        final manager = CompanyCacheManager(
          file: targetFile,
          tempFile: tempFile,
          cacheDuration: Duration.zero,
          downloadFunction: (_) async {
            throw const SocketException('Network is unreachable');
          },
        );

        final emitted = await manager
            .getCompaniesStream(
              maxRetries: 1,
              onErrorFallback: (error, _) => fallbackError = error,
            )
            .toList();

        // キャッシュデータは正しく emit される
        expect(emitted.length, 1);
        expect(emitted[0].length, 2);
        // エラーコールバックが通知される
        expect(fallbackError, isA<SocketException>());
        // キャッシュファイルは維持される
        expect(targetFile.existsSync(), isTrue);
      });

      test('キャッシュ未存在＆ダウンロード全滅時: リトライ後に例外がスローされる（PathNotFoundExceptionは起きない）', () async {
        expect(targetFile.existsSync(), isFalse);

        int attempts = 0;
        final manager = CompanyCacheManager(
          file: targetFile,
          tempFile: tempFile,
          downloadFunction: (_) async {
            attempts++;
            throw const SocketException('Offline');
          },
        );

        // maxRetries = 2 なので合計 3 回試行される
        await expectLater(
          () => manager.getCompaniesStream(maxRetries: 2).toList(),
          throwsA(isA<SocketException>()),
        );

        expect(attempts, 3);
        // 重要: PathNotFoundException は一切発生せず、SocketException が正しくスローされる
        expect(targetFile.existsSync(), isFalse);
      });
    });
  });
}
