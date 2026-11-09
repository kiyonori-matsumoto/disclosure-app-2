import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Firebase Remote Config を管理するサービスクラス
///
/// 個人開発環境で課金が発生しないよう、本番環境のキャッシュ期間（minimumFetchInterval）を
/// 12時間に設定し、1日10万リクエストの無料枠内に確実に抑える設計です。
class RemoteConfigService {
  final FirebaseRemoteConfig? _remoteConfig;
  final bool? _mockGloballyEnabled;
  final List<String>? _mockAllowedUsers;
  final String? _mockMinRequiredVersion;
  final String? _mockForceUpdateTitle;
  final String? _mockForceUpdateMessage;

  // Remote Config パラメータキー
  static const String keyForensicFeatureEnabled = 'forensic_feature_enabled';
  static const String keyForensicAllowedUsers = 'forensic_allowed_users';
  static const String keyMinRequiredVersion = 'min_required_version';
  static const String keyForceUpdateTitle = 'force_update_title';
  static const String keyForceUpdateMessage = 'force_update_message';

  // デフォルト値
  static const Map<String, dynamic> _defaults = {
    keyForensicFeatureEnabled: false,
    keyForensicAllowedUsers: '',
    keyMinRequiredVersion: '2.0.0',
    keyForceUpdateTitle: 'アップデートのお知らせ',
    keyForceUpdateMessage: '最新のバージョンへのアップデートをお願いいたします。',
  };

  RemoteConfigService({FirebaseRemoteConfig? remoteConfig})
      : _remoteConfig = remoteConfig ?? (Firebase.apps.isNotEmpty ? FirebaseRemoteConfig.instance : null),
        _mockGloballyEnabled = null,
        _mockAllowedUsers = null,
        _mockMinRequiredVersion = null,
        _mockForceUpdateTitle = null,
        _mockForceUpdateMessage = null;

  /// テスト用のモック値を直接注入できるコンストラクタ
  @visibleForTesting
  RemoteConfigService.custom({
    bool isForensicGloballyEnabled = false,
    List<String> forensicAllowedUsers = const [],
    String minRequiredVersion = '2.0.0',
    String forceUpdateTitle = 'アップデートのお知らせ',
    String forceUpdateMessage = '最新のバージョンへのアップデートをお願いいたします。',
  })  : _remoteConfig = null,
        _mockGloballyEnabled = isForensicGloballyEnabled,
        _mockAllowedUsers = forensicAllowedUsers,
        _mockMinRequiredVersion = minRequiredVersion,
        _mockForceUpdateTitle = forceUpdateTitle,
        _mockForceUpdateMessage = forceUpdateMessage;

  /// 初期設定および設定値のフェッチ
  Future<void> initialize() async {
    final remoteConfig = _remoteConfig;
    if (remoteConfig == null || Firebase.apps.isEmpty) {
      debugPrint('[RemoteConfigService] Firebase is not initialized, skipping RemoteConfig.');
      return;
    }

    try {
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          // デバッグ時は即時反映、リリース時は12時間キャッシュ（無料枠の浪費を防止）
          minimumFetchInterval:
              kDebugMode ? Duration.zero : const Duration(hours: 12),
          fetchTimeout: const Duration(seconds: 10),
        ),
      );

      await remoteConfig.setDefaults(_defaults);

      // 設定値を取得して有効化
      final updated = await remoteConfig.fetchAndActivate();
      debugPrint('[RemoteConfigService] Remote Config activated: updated=$updated');
    } catch (e, stack) {
      debugPrint('[RemoteConfigService] Failed to fetch Remote Config: $e');
      debugPrint(stack.toString());
      // 失敗しても setDefaults または以前のキャッシュ値で安全に動作継続
    }
  }

  /// 全体向けにフォレンジック機能が開放されているか
  bool get isForensicGloballyEnabled =>
      _mockGloballyEnabled ?? _remoteConfig?.getBool(keyForensicFeatureEnabled) ?? false;

  /// フォレンジック機能の利用を許可されたユーザー（メールアドレス / UID）のリスト
  List<String> get forensicAllowedUsers {
    if (_mockAllowedUsers != null) return _mockAllowedUsers!;
    final raw = _remoteConfig?.getString(keyForensicAllowedUsers) ?? '';
    if (raw.trim().isEmpty) return const [];
    return raw
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  /// クリティカルな更新を強制したい最低必須バージョン
  String get minRequiredVersion =>
      _mockMinRequiredVersion ?? _remoteConfig?.getString(keyMinRequiredVersion) ?? '2.0.0';

  /// 強制アップデート画面のタイトル
  String get forceUpdateTitle =>
      _mockForceUpdateTitle ?? _remoteConfig?.getString(keyForceUpdateTitle) ?? 'アップデートのお知らせ';

  /// 強制アップデート画面のメッセージ
  String get forceUpdateMessage =>
      _mockForceUpdateMessage ?? _remoteConfig?.getString(keyForceUpdateMessage) ?? '最新のバージョンへのアップデートをお願いいたします。';

  /// 指定したユーザー（メールアドレスまたはUID）がフォレンジック機能を利用可能か判定
  bool isUserAllowedForForensic({String? email, String? uid}) {
    // デバッグ実行時（エミュレータ・シミュレータ等）は未ログインでも自動で有効化して開発効率を向上
    // （※ユニットテスト等で custom モックが明示的に渡された場合はその値を優先）
    if (kDebugMode && _mockGloballyEnabled == null && _mockAllowedUsers == null) {
      return true;
    }

    if (isForensicGloballyEnabled) {
      return true;
    }

    final allowed = forensicAllowedUsers;
    if (allowed.isEmpty) {
      return false;
    }

    if (email != null && allowed.contains(email.trim().toLowerCase())) {
      return true;
    }

    if (uid != null && allowed.contains(uid.trim().toLowerCase())) {
      return true;
    }

    return false;
  }
}
