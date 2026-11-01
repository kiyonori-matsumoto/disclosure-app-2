import 'package:disclosure_app_fl/providers/theme_mode_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('初期状態は ThemeMode.system', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final mode = container.read(themeModeProvider);
    expect(mode, ThemeMode.system);
  });

  test('setThemeMode でテーマが変更され SharedPreferences に保存される', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(themeModeProvider.notifier)
        .setThemeMode(ThemeMode.dark);

    expect(container.read(themeModeProvider), ThemeMode.dark);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_mode'), 'dark');
  });

  test('旧 setDarkMode の設定値が存在する場合に互換マイグレーションされる', () async {
    // 旧仕様: setDarkMode: false => Dark
    SharedPreferences.setMockInitialValues({'setDarkMode': false});

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(themeModeProvider.notifier).initFuture;

    expect(container.read(themeModeProvider), ThemeMode.dark);
  });
}
