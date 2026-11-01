import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_mode_provider.g.dart';

const String _prefKeyThemeMode = 'theme_mode';
const String _legacyPrefKeyDarkMode = 'setDarkMode';

@riverpod
class ThemeModeNotifier extends _$ThemeModeNotifier {
  Future<void>? _initFuture;

  @visibleForTesting
  Future<void>? get initFuture => _initFuture;

  @override
  ThemeMode build() {
    _initFuture = _loadSavedThemeMode();
    return ThemeMode.system;
  }

  Future<void> _loadSavedThemeMode() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. 新しい文字列キー 'theme_mode' を確認 ('system' | 'light' | 'dark')
    final savedModeString = prefs.getString(_prefKeyThemeMode);
    if (savedModeString != null) {
      switch (savedModeString) {
        case 'light':
          state = ThemeMode.light;
          return;
        case 'dark':
          state = ThemeMode.dark;
          return;
        case 'system':
        default:
          state = ThemeMode.system;
          return;
      }
    }

    // 2. 過去の旧キー 'setDarkMode' (bool) がある場合の互換処理
    if (prefs.containsKey(_legacyPrefKeyDarkMode)) {
      final isLight = prefs.getBool(_legacyPrefKeyDarkMode) ?? true;
      state = isLight ? ThemeMode.light : ThemeMode.dark;
      return;
    }

    // 3. デフォルトはシステム設定に追従
    state = ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyThemeMode, mode.name);
  }
}
