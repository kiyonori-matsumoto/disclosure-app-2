import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/remote_config_service.dart';
import '../utils/version_comparator.dart';
import 'auth_provider.dart';

part 'remote_config_provider.g.dart';

/// RemoteConfigService インスタンスを提供する Provider
@Riverpod(keepAlive: true)
RemoteConfigService remoteConfigService(Ref ref) {
  return RemoteConfigService();
}

/// 現在のユーザーがフォレンジック機能を利用できるかどうかを判定する Provider
@Riverpod(keepAlive: true)
bool isForensicEnabled(Ref ref) {
  final user = ref.watch(currentUserProvider);
  final service = ref.watch(remoteConfigServiceProvider);

  String? email;
  String? uid;
  if (user != null) {
    try {
      email = user.email;
    } catch (_) {
      // テスト時の Fake/Mock で未実装の場合のセーフティガード
    }
    try {
      uid = user.uid;
    } catch (_) {
      // テスト時の Fake/Mock で未実装の場合のセーフティガード
    }
  }

  return service.isUserAllowedForForensic(
    email: email,
    uid: uid,
  );
}

/// 強制アップデート判定の結果モデル
class ForceUpdateState {
  final bool isRequired;
  final String currentVersion;
  final String minRequiredVersion;
  final String title;
  final String message;

  const ForceUpdateState({
    required this.isRequired,
    required this.currentVersion,
    required this.minRequiredVersion,
    required this.title,
    required this.message,
  });
}

/// 強制アップデート判定を行う Provider
@Riverpod(keepAlive: true)
Future<ForceUpdateState> forceUpdateState(Ref ref) async {
  final service = ref.watch(remoteConfigServiceProvider);
  final minRequired = service.minRequiredVersion;

  try {
    final packageInfo = await PackageInfo.fromPlatform();
    final current = packageInfo.version;
    final isRequired = VersionComparator.isUpdateRequired(
      current: current,
      minRequired: minRequired,
    );

    return ForceUpdateState(
      isRequired: isRequired,
      currentVersion: current,
      minRequiredVersion: minRequired,
      title: service.forceUpdateTitle,
      message: service.forceUpdateMessage,
    );
  } catch (e) {
    debugPrint('[ForceUpdate] Failed to get package info: $e');
    return ForceUpdateState(
      isRequired: false,
      currentVersion: '',
      minRequiredVersion: minRequired,
      title: service.forceUpdateTitle,
      message: service.forceUpdateMessage,
    );
  }
}
