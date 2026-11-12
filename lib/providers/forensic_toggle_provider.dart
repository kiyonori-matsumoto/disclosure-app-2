import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _prefKeyForensicToggle = 'forensic_feature_toggle_enabled';

/// 財務フォレンジック機能の手動トグル Provider
///
/// スクリーンショット撮影や限定公開・精度検証のため、手動でON/OFFを切り替えることができます。
/// デフォルト値: false（撮影用に一時的に除外）
final forensicToggleProvider =
    NotifierProvider<ForensicToggleNotifier, bool>(ForensicToggleNotifier.new);

class ForensicToggleNotifier extends Notifier<bool> {
  Future<void>? _initFuture;

  @visibleForTesting
  Future<void>? get initFuture => _initFuture;

  @override
  bool build() {
    _initFuture = _loadSavedPreference();
    // 撮影用に一時的に除外するため初期状態は false
    return false;
  }

  Future<void> _loadSavedPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getBool(_prefKeyForensicToggle);
      if (saved != null) {
        state = saved;
      }
    } catch (_) {
      // テスト環境などで SharedPreferences が利用できない場合のフォールバック
    }
  }

  /// トグルの有効／無効を設定
  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyForensicToggle, enabled);
    } catch (_) {
      // ignore
    }
  }
}
