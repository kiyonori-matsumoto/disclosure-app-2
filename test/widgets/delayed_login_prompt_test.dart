import 'package:disclosure_app_fl/providers/auth_provider.dart';
import 'package:disclosure_app_fl/widgets/delayed_login_prompt.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeUserInfo extends Fake implements UserInfo {
  @override
  final String providerId;
  @override
  final String? email;

  FakeUserInfo({required this.providerId, this.email});
}

class FakeUser extends Fake implements User {
  @override
  final String uid;
  @override
  final List<UserInfo> providerData;
  @override
  final String? email;
  @override
  final String? displayName;

  FakeUser({
    required this.uid,
    this.providerData = const [],
    this.email,
    this.displayName,
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DelayedLoginPrompt.maybePrompt', () {
    testWidgets('does not prompt when user is null', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      bool? promptResult;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => null),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  return ElevatedButton(
                    onPressed: () async {
                      promptResult = await DelayedLoginPrompt.maybePrompt(
                        context,
                        ref,
                        prefs: prefs,
                      );
                    },
                    child: const Text('Action'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Action'));
      await tester.pumpAndSettle();

      expect(promptResult, isFalse);
      expect(find.byType(DelayedLoginBottomSheet), findsNothing);
      expect(prefs.getBool(kPrefKeyHasPromptedDelayedGoogleLink), isNull);
    });

    testWidgets('does not prompt when user is already linked with Google',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final linkedUser = FakeUser(
        uid: 'user_123',
        providerData: [FakeUserInfo(providerId: 'google.com')],
      );

      bool? promptResult;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => linkedUser),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  return ElevatedButton(
                    onPressed: () async {
                      promptResult = await DelayedLoginPrompt.maybePrompt(
                        context,
                        ref,
                        prefs: prefs,
                      );
                    },
                    child: const Text('Action'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Action'));
      await tester.pumpAndSettle();

      expect(promptResult, isFalse);
      expect(find.byType(DelayedLoginBottomSheet), findsNothing);
      expect(prefs.getBool(kPrefKeyHasPromptedDelayedGoogleLink), isNull);
    });

    testWidgets('does not prompt when already prompted previously',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        kPrefKeyHasPromptedDelayedGoogleLink: true,
      });
      final prefs = await SharedPreferences.getInstance();

      final guestUser = FakeUser(
        uid: 'guest_123',
        providerData: [FakeUserInfo(providerId: 'firebase')],
      );

      bool? promptResult;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => guestUser),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  return ElevatedButton(
                    onPressed: () async {
                      promptResult = await DelayedLoginPrompt.maybePrompt(
                        context,
                        ref,
                        prefs: prefs,
                      );
                    },
                    child: const Text('Action'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Action'));
      await tester.pumpAndSettle();

      expect(promptResult, isFalse);
      expect(find.byType(DelayedLoginBottomSheet), findsNothing);
    });

    testWidgets(
        'shows bottom sheet and sets flag when guest user triggers for first time',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final guestUser = FakeUser(
        uid: 'guest_123',
        providerData: [FakeUserInfo(providerId: 'firebase')],
      );

      bool? promptResult;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => guestUser),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  return ElevatedButton(
                    onPressed: () async {
                      promptResult = await DelayedLoginPrompt.maybePrompt(
                        context,
                        ref,
                        prefs: prefs,
                      );
                    },
                    child: const Text('Action'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Action'));
      await tester.pumpAndSettle();

      // Bottom sheet is now visible
      expect(find.byType(DelayedLoginBottomSheet), findsOneWidget);
      expect(find.text('Google連携でデータを保護'), findsOneWidget);
      expect(
        find.text('機種変更時にも登録したお気に入りや通知設定をそのまま引き継げるよう、Googleアカウントと連携しませんか？'),
        findsOneWidget,
      );
      expect(prefs.getBool(kPrefKeyHasPromptedDelayedGoogleLink), isTrue);

      // Dismiss bottom sheet via 'あとで' button
      await tester.tap(find.text('あとで'));
      await tester.pumpAndSettle();

      expect(find.byType(DelayedLoginBottomSheet), findsNothing);
      expect(promptResult, isTrue);
    });
  });

  group('showAccountSwitchConfirmDialog', () {
    testWidgets('returns false when cancelled', (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showAccountSwitchConfirmDialog(context);
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('既存アカウントの復元'), findsOneWidget);
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('returns true when confirmed', (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showAccountSwitchConfirmDialog(context);
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('既存アカウントの復元'), findsOneWidget);
      await tester.tap(find.text('復元してログイン'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });
  });
}
