# Changelog

## [v2.5.0](https://github.com/kiyonori-matsumoto/disclosure-app-2/compare/v2.4.2...v2.5.0) - 2026-10-31

- Fix UI reaction when downloading EDINET files by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/50
- fix: バナー広告のライフサイクル管理とレイアウトの安定化 by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/52
- chore(deps): update minor and patch dependencies by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/54
- chore(deps-dev): bump flutter_launcher_icons from 0.13.1 to 0.14.4 by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/55
- chore: upgrade Flutter SDK to 3.47.8 and update Android build tools by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/57
- ⚡ Bolt: [performance improvement] Replace O(N) company lookups with O(1) Map lookups by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/58
- fix: use PublishSubject in FirestoreGetCount to prevent Bad state error on reload by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/61
- fix: firestore reload error & update dependencies (Phase 1 & 2) by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/62
- feat(deps): upgrade google_sign_in to ^7.2.0 by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/63
- chore(deps): upgrade google_mobile_ads to ^9.2.0 by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/64
- ⚡ Bolt: [performance improvement] optimize company lookup in SettlementsList by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/66
- ⚡ Bolt: [Performance Improvement] Debounce search input for list filtering by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/53

## [v2.4.2](https://github.com/kiyonori-matsumoto/disclosure-app-2/compare/v2.4.1...v2.4.2) - 2026-10-24

- fix(android): support 16 KB memory page size with Flutter 3.27 and AGP 8.7 by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/32
- fix(android): force com.google.android.recaptcha:recaptcha to 18.6.1 for security fix by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/33
- feat: switch Cloud Functions endpoints to v2 Tokyo region by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/34
- fix: 非機能要件（セキュリティ・信頼性・保守性）の改善 by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/36
- refactor: ファイル命名規則の統一 (snake_case) と未使用ファイルの削除 by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/37
- refactor: BLoCの責務分離第1弾（通知トピック・開示フィルタヘルパーの抽出と単体テスト拡充） by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/39
- Fix null check operator crash in AppRootWidgetState by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/40
- fix(crashlytics): fix top Crashlytics issues and enhance crash reporting by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/42
- ci: automate release PRs with tagpr and builds with codemagic by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/43
- fix(tagpr): pubspec.yamlのサンプルバージョンコメントを削除しtagprの誤検知を防止 by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/49
- ⚡ Bolt: Optimize Company List Filtering RegExp Performance by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/47

## [v2.4.1](https://github.com/kiyonori-matsumoto/disclosure-app-2/commits/v2.4.1) - 2026-10-14

- V2 by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/18
- V2.1 in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/19
- V2.2 in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/20
- feat: introduce Firebase App Check with Play Integrity by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/21
- feat: Firebase App Check導入、単体テストおよびCI環境の追加 by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/22
- chore: Dart SDK制約をDart 3へ引き上げ、基本ライブラリ群を更新 by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/23
- ci: Androidデバッグビルド検証ジョブの追加 by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/25
- fix(android): update compileSdkVersion and targetSdkVersion to 35 by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/26
- fix(android): update compileSdkVersion and targetSdkVersion to 36 by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/27
- fix(android): remove unused photo and media permissions by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/28
- chore: bump version to 2.4.1 by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/29
