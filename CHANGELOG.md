# Changelog

## [v1.2.43](https://github.com/kiyonori-matsumoto/disclosure-app-2/compare/v2.4.1...v1.2.43) - 2026-10-19

- fix(android): support 16 KB memory page size with Flutter 3.27 and AGP 8.7 by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/32
- fix(android): force com.google.android.recaptcha:recaptcha to 18.6.1 for security fix by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/33
- feat: switch Cloud Functions endpoints to v2 Tokyo region by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/34
- fix: 非機能要件（セキュリティ・信頼性・保守性）の改善 by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/36
- refactor: ファイル命名規則の統一 (snake_case) と未使用ファイルの削除 by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/37
- refactor: BLoCの責務分離第1弾（通知トピック・開示フィルタヘルパーの抽出と単体テスト拡充） by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/39
- Fix null check operator crash in AppRootWidgetState by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/40
- fix(crashlytics): fix top Crashlytics issues and enhance crash reporting by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/42
- ci: automate release PRs with tagpr and builds with codemagic by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/43

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
