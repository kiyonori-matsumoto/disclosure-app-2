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

  testWidgets('ダークモード時にUserAccountsDrawerHeaderの背景とテキスト色が高コントラストに設定される',
      (WidgetTester tester) async {
    final darkTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: Brightness.dark,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => MockGuestUser()),
        ],
        child: MaterialApp(
          theme: darkTheme,
          home: const Scaffold(
            drawer: AppDrawer(),
          ),
        ),
      ),
    );

    final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();

    final header =
        tester.widget<UserAccountsDrawerHeader>(find.byType(UserAccountsDrawerHeader));
    final boxDecoration = header.decoration as BoxDecoration?;
    expect(boxDecoration?.color, equals(darkTheme.colorScheme.primaryContainer));

    final nameText = tester.widget<Text>(find.text('ゲスト'));
    expect(nameText.style?.color, equals(darkTheme.colorScheme.onPrimaryContainer));
    expect(nameText.style?.color, isNot(equals(Colors.black)));

    final emailText = tester.widget<Text>(find.text('未連携（ゲスト利用中）'));
    expect(emailText.style?.color, isNotNull);

    expect(find.byType(CircleAvatar), findsWidgets);
  });
}
