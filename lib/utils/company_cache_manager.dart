import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

typedef DownloadFileFunction = Future<void> Function(File destinationFile);

/// 企業リスト (companies.json) のキャッシュ管理および安全なダウンロード・保存を担当するクラス。
///
/// 特徴:
/// 1. アトミック保存: 一時ファイル (.tmp) にダウンロード・検証後、本番ファイルへ置換。
/// 2. 既存キャッシュ保護: ダウンロード失敗時に既存の健全なローカルキャッシュを削除しない。
/// 3. 安全な削除: ファイルの存在確認を行い、PathNotFoundException を防止。
/// 4. キャッシュ有効期限管理: 指定期間（デフォルト24時間）内であればローカルキャッシュを優先。
class CompanyCacheManager {
  final File file;
  final File tempFile;
  final Duration cacheDuration;
  final DownloadFileFunction downloadFunction;

  CompanyCacheManager({
    required this.file,
    File? tempFile,
    this.cacheDuration = const Duration(hours: 24),
    required this.downloadFunction,
  }) : tempFile = tempFile ?? File('${file.path}.tmp');

  /// ローカルキャッシュが存在するかどうか
  bool get hasLocalCache => file.existsSync();

  /// キャッシュが有効期限内（fresh）であるか判定
  bool isCacheFresh([DateTime? now]) {
    if (!hasLocalCache) return false;
    try {
      final lastModified = file.lastModifiedSync();
      final currentTime = now ?? DateTime.now();
      return lastModified.isAfter(currentTime.subtract(cacheDuration));
    } catch (e) {
      debugPrint('Failed to check cache freshness: $e');
      return false;
    }
  }

  /// ローカルキャッシュからデータを読み込む。
  /// もし破損している（FormatExceptionなど）場合は、安全に削除して null を返す。
  Future<List<dynamic>?> loadLocalCache() async {
    if (!hasLocalCache) return null;
    try {
      final content = await file.readAsString();
      final decoded = jsonDecode(content);
      if (decoded is List) {
        return decoded;
      }
      debugPrint('Local companies.json is not a JSON list. Deleting invalid cache.');
      safeDelete(file);
      return null;
    } catch (e) {
      debugPrint('Failed to parse local companies.json: $e. Deleting corrupted cache.');
      safeDelete(file);
      return null;
    }
  }

  /// 一時ファイルにダウンロードし、検証成功後に本番ファイルへアトミック置換する。
  /// 既存の本番ファイルはダウンロード失敗時も保護される。
  Future<List<dynamic>> downloadAndSave() async {
    // ダウンロード前に古い一時ファイルがあれば安全に削除
    safeDelete(tempFile);

    try {
      // 1. 一時ファイルにダウンロード
      await downloadFunction(tempFile);

      // 2. 一時ファイルの中身を読み込み＆JSON構造の検証
      final content = await tempFile.readAsString();
      final decoded = jsonDecode(content);
      if (decoded is! List) {
        throw const FormatException('Downloaded companies.json is not a JSON List');
      }

      // 3. 検証成功: 本番ファイルへ置換
      if (file.existsSync()) {
        file.deleteSync();
      }
      await tempFile.rename(file.path);

      return decoded;
    } catch (e) {
      // 失敗時は一時ファイルのみ安全に削除し、本番キャッシュは残す
      safeDelete(tempFile);
      rethrow;
    }
  }

  /// ファイルの安全な削除（存在確認を行い、PathNotFoundException を防止）
  static void safeDelete(File? targetFile) {
    if (targetFile == null) return;
    try {
      if (targetFile.existsSync()) {
        targetFile.deleteSync();
      }
    } catch (e) {
      debugPrint('safeDelete failed for ${targetFile.path}: $e');
    }
  }

  /// Stale-While-Revalidate パターンで企業リストを Stream として配信する。
  ///
  /// 1. ローカルキャッシュがあれば即座に emit
  /// 2. キャッシュが無いか期限切れの場合、Storage からダウンロードして最新データを emit
  /// 3. キャッシュがあり、かつダウンロードに失敗した場合は既存キャッシュを維持
  /// 4. キャッシュが無く初回ダウンロードも失敗した場合はエラーを再スロー
  Stream<List<dynamic>> getCompaniesStream({
    int maxRetries = 2,
    void Function(dynamic error, StackTrace stack)? onErrorFallback,
  }) async* {
    final cachedData = await loadLocalCache();
    final bool cacheFresh = isCacheFresh();

    if (cachedData != null) {
      yield cachedData;
    }

    // キャッシュが期限切れ、または存在しない場合はダウンロードを実行
    if (!cacheFresh || cachedData == null) {
      int attempts = 0;
      while (attempts <= maxRetries) {
        attempts++;
        try {
          final downloadedData = await downloadAndSave();
          yield downloadedData;
          break;
        } catch (e, stack) {
          debugPrint('Download companies.json attempt $attempts failed: $e');
          if (attempts > maxRetries) {
            if (cachedData != null) {
              // 既にキャッシュを emit 済みの場合は、既存データを活かして非致命的通知にとどめる
              onErrorFallback?.call(e, stack);
            } else {
              // キャッシュも無く初回取得が完全に失敗した場合はエラーを通知
              onErrorFallback?.call(e, stack);
              rethrow;
            }
          } else {
            // 短い待機後にリトライ
            await Future<void>.delayed(Duration(milliseconds: 300 * attempts));
          }
        }
      }
    }
  }
}
