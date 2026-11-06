import 'package:disclosure_app_fl/providers/auth_provider.dart';
import 'package:disclosure_app_fl/widgets/drawer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MockGuestUser extends Fake implements User {
  @override
  String get uid => 'guest_uid';

  @override
  List<UserInfo> get providerData => [];

  @override
  String? get email => null;

  @override
  String? get displayName => null;

  @override
  String? get photoURL => null;
}

class MockGoogleUserInfo extends Fake implements UserInfo {
  @override
  String get providerId => 'google.com';

  @override
  String get email => 'test@example.com';

  @override
  String get displayName => 'テストユーザー';

  @override
  String? get photoURL => null;
}

class MockGoogleUser extends Fake implements User {
  @override
  String get uid => 'google_uid';

  @override
  List<UserInfo> get providerData => [MockGoogleUserInfo()];

  @override
  String? get email => 'test@example.com';

  @override
  String? get displayName => 'テストユーザー';

  @override
  String? get photoURL => null;
}

void main() {
  Widget createTestWidget({User? user}) {
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) => user),
      ],
      child: const MaterialApp(
        home: Scaffold(
          drawer: AppDrawer(),
        ),
      ),
    );
  }

  testWidgets('未ログイン/ゲスト時は「ゲスト」ヘッダーが表示される', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(user: MockGuestUser()));
    final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();

    expect(find.text('ゲスト'), findsOneWidget);
    expect(find.text('適時開示一覧'), findsOneWidget);
    expect(find.text('会社検索'), findsOneWidget);
    expect(find.text('お気に入り'), findsOneWidget);
    expect(find.text('決算予定'), findsOneWidget);
    expect(find.text('保存した開示情報'), findsOneWidget);
    expect(find.text('設定'), findsOneWidget);
  });

  testWidgets('Google 連携時はユーザー名とメールアドレスが表示される', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(user: MockGoogleUser()));
    final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();

    expect(find.text('テストユーザー'), findsOneWidget);
    expect(find.text('test@example.com'), findsOneWidget);
  });
}
