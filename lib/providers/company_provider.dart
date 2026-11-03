import 'dart:io';

import 'package:disclosure_app_fl/models/company.dart';
import 'package:disclosure_app_fl/utils/company_cache_manager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'company_provider.g.dart';

/// CompanyCacheManager を提供する内部 Provider（テスト時に override 可能）
@Riverpod(keepAlive: true)
Future<CompanyCacheManager> companyCacheManager(Ref ref) async {
  final appDir = await getApplicationDocumentsDirectory();
  final companyJsonFile = File('${appDir.path}/companies.json');
  final storage = FirebaseStorage.instanceFor(bucket: 'gs://disclosure-app-2');
  final storageRef = storage.ref().child('companies.json');

  return CompanyCacheManager(
    file: companyJsonFile,
    downloadFunction: (destFile) => storageRef.writeToFile(destFile),
  );
}

/// 企業マスタ一覧をリアルタイム購読・キャッシュする Provider
@Riverpod(keepAlive: true)
Stream<List<Company>> companiesStream(Ref ref) async* {
  final cacheManager = await ref.watch(companyCacheManagerProvider.future);

  yield* cacheManager
      .getCompaniesStream(
        onErrorFallback: (error, stack) {
          debugPrint("Failed to download companies.json: $error");
          if (Firebase.apps.isNotEmpty) {
            FirebaseCrashlytics.instance.recordError(
              error,
              stack,
              reason: 'Failed to download companies.json in background',
              fatal: false,
            );
          }
        },
      )
      .map((data) => data
          .map((d) => Company(
                (d['code'] as String).substring(0, 4),
                name: d['name'],
                edinetCode: d['edinetCode'],
                nameKana: d['nameKana'],
              ))
          .toList());
}

/// 証券コードをキーとした企業マスタの Map を提供する Provider (O(1) ルックアップ用)
@Riverpod(keepAlive: true)
Map<String, Company> companyCodeMap(Ref ref) {
  final companies = ref.watch(companiesStreamProvider).value ?? [];
  return Map.fromEntries(
    companies.where((c) => c.code != null).map((c) => MapEntry(c.code!, c)),
  );
}

/// EDINET コードをキーとした企業マスタの Map を提供する Provider (O(1) ルックアップ用)
@Riverpod(keepAlive: true)
Map<String, Company> companyEdinetMap(Ref ref) {
  final companies = ref.watch(companiesStreamProvider).value ?? [];
  return Map.fromEntries(
    companies
        .where((c) => c.edinetCode != null)
        .map((c) => MapEntry(c.edinetCode!, c)),
  );
}
