# Changelog

## [v2.7.3](https://github.com/kiyonori-matsumoto/disclosure-app-2/compare/v2.7.2...v2.7.3) - 2026-11-14

- fix(forensic): フォレンジック可視化の表現を「通常 / 乖離あり / 大幅乖離」に刷新しアイコン不整合を解消 by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/121
- ⚡ Bolt: [performance improvement] Pre-compute favorites Set for O(1) filtering by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/119
- feat(favorites): お気に入り銘柄一覧の並び替え機能を追加 (#125) by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/126

## [v2.7.2](https://github.com/kiyonori-matsumoto/disclosure-app-2/compare/v2.7.1...v2.7.2) - 2026-11-09

- feat(remote-config): Firebase Remote Config によるフォレンジック機能の限定公開および強制アップデート基盤の導入 by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/115
- fix(forensic): フォレンジックバッジのタッチターゲット領域を拡張して誤タップを防止 by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/102
- feat(ui): スワイプ削除インジケーターの統一とコンテキストメニューのボトムシート化 (#109) by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/117

## [v2.7.1](https://github.com/kiyonori-matsumoto/disclosure-app-2/compare/v2.7.0...v2.7.1) - 2026-11-08

- refactor(fcm): remove deprecated edinet_notification topic subscription by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/103
- feat(ui): 情報設計の最適化（TabBar切替・検索動線強化・サポートリンク退避） by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/110
- feat(ui): 開示リストアイテムの情報階層とフォントサイズの改善 (#105) by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/111
- feat(theme): Material 3 への刷新とカラーパレットの近代化 (#108) by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/113
- fix(theme): ダークモードおよびテーマカラーのコントラスト不整合の解消 (#107) by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/112
- feat(forensic): 定量フォレンジック指標（Beneish M-Score・アクルーアル比率等）および新レッドフラグの UI 表示対応 by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/114

## [v2.7.0](https://github.com/kiyonori-matsumoto/disclosure-app-2/compare/v2.6.0...v2.7.0) - 2026-11-06

- feat(disclosures): migrate disclosure stream and filtering to Riverpod (#76) by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/92
- feat(settlements): migrate settlements list to Riverpod (#76) by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/94
- feat(edinet): migrate EDINET disclosure stream to Riverpod and unify FeedState (#76) by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/95
- feat(tags): migrate tag disclosures screen to Riverpod (#76) by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/96
- fix(notification): handle initial message on launch, remove delay, and improve routing by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/97
- refactor(bloc): completely remove legacy AppBloc and migrate FCM topic sync to Riverpod (#76) by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/99
- feat(forensic): 定性リスク＆財務フォレンジック解析結果の UI 表示（リスクバッジ・診断解説シート） (#88) by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/100

## [v2.6.0](https://github.com/kiyonori-matsumoto/disclosure-app-2/compare/v2.5.0...v2.6.0) - 2026-11-05

- feat(deps): upgrade firebase ecosystem plugins to latest major versions by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/65
- feat(notification): resilient topic sync engine and migrate from legacy listTopicsV2 by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/69
- feat(theme): introduce Riverpod 3 and implement theme mode with system setting support by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/70
- feat(saved-disclosures): migrate saved disclosures screen and auth to Riverpod by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/72
- refactor: remove legacy saved disclosures and dark mode from AppBloc by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/74
- fix: resolve PathNotFoundException on companies.json and improve weekly batch cache handling by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/77
- feat(settings): migrate hideDailyDisclosure to Riverpod (#76) by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/80
- fix(android): upgrade Gradle to 9.3.1 and AGP to 9.1.0 by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/78
- feat(company): add Riverpod providers for company master (#76) by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/81
- feat(favorites): migrate favorites to Riverpod (#76) by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/82
- feat(notifications): migrate notification settings to Riverpod and unify favorite screen (#76) by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/83
- feat(custom-tags): migrate custom tag settings to Riverpod (#76) by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/84
- fix(company): support alphanumeric stock codes and normalize case (#79) by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/85
- feat(company-search): migrate company search and history to Riverpod (#76) by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/86
- feat(disclosures): migrate company disclosures to Riverpod (#76) by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/87
- fix(android): add proguard rules to prevent WorkDatabase startup crash on release by @kiyonori-matsumoto in https://github.com/kiyonori-matsumoto/disclosure-app-2/pull/90

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
