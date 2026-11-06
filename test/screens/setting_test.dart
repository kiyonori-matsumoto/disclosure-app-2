import 'package:disclosure_app_fl/providers/auth_provider.dart';
import 'package:disclosure_app_fl/providers/theme_mode_provider.dart';
import 'package:disclosure_app_fl/providers/user_settings_provider.dart';
import 'package:disclosure_app_fl/screens/setting.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MockGuestUser extends Fake implements User {
  @override
  String get uid => 'guest_uid';

  @override
  List<UserInfo> get providerData => [];
}

class MockGoogleUserInfo extends Fake implements UserInfo {
  @override
  String get providerId => 'google.com';
}

class MockGoogleUser extends Fake implements User {
  @override
  String get uid => 'google_uid';

  @override
  List<UserInfo> get providerData => [MockGoogleUserInfo()];
}

void main() {
  Widget createTestWidget({User? user, bool hideDaily = false}) {
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) => user),
        hideDailyDisclosureProvider.overrideWith((ref) => hideDaily),
        themeModeProvider.overrideWith(() => ThemeModeNotifier()),
      ],
      child: const MaterialApp(
        home: SettingScreen(),
      ),
    );
  }

  testWidgets('設定画面の各セクション・項目が表示される', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(user: MockGuestUser()));
    await tester.pumpAndSettle();

    expect(find.text('設定'), findsOneWidget);
    expect(find.text('証券コードで通知'), findsOneWidget);
    expect(find.text('タグで通知(β)'), findsOneWidget);
    expect(find.text('日々の開示情報を表示しない'), findsOneWidget);
    expect(find.text('テーマ設定'), findsWidgets);
    expect(find.text('カスタムタグ設定'), findsOneWidget);
    expect(find.text('アカウント設定'), findsOneWidget);
    expect(find.text('GOOGLE連携'), findsOneWidget);
  });

  testWidgets('Google 連携時は「GOOGLE連携を解除」ボタンが表示される',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(user: MockGoogleUser()));
    await tester.pumpAndSettle();

    expect(find.text('GOOGLE連携を解除'), findsOneWidget);
  });
}
