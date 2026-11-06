import 'package:disclosure_app_fl/models/filter.dart';
import 'package:disclosure_app_fl/providers/auth_provider.dart';
import 'package:disclosure_app_fl/providers/notification_tags_provider.dart';
import 'package:disclosure_app_fl/providers/user_settings_provider.dart';
import 'package:disclosure_app_fl/screens/notification_tag_setting.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MockUser extends Fake implements User {
  @override
  String get uid => 'test_uid_456';
}

class MockNotificationTagsAction extends NotificationTagsAction {
  final List<(String, String, bool)> toggled = [];

  @override
  void build() {}

  @override
  Future<void> toggle(String uid, String tag, {required bool isSelected}) async {
    toggled.add((uid, tag, isSelected));
  }
}

void main() {
  testWidgets('タグで通知画面にタグ一覧が表示され、設定状態が反映される',
      (WidgetTester tester) async {
    final mockAction = MockNotificationTagsAction();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => MockUser()),
          userDocStreamProvider.overrideWith((ref) => Stream.value({
                'notification_tags': [defaultFilterStrings.first],
              })),
          notificationTagsProvider.overrideWithValue([defaultFilterStrings.first]),
          notificationTagsActionProvider.overrideWith(() => mockAction),
        ],
        child: const MaterialApp(
          home: NotificationTagSettingScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // デフォルトのタグ文字列が表示されていることを確認
    for (final tag in defaultFilterStrings) {
      expect(find.text(tag), findsOneWidget);
    }

    // 最初のタグのスイッチをタップして切り替える
    final firstSwitch = find.byType(Switch).first;
    await tester.tap(firstSwitch);
    await tester.pumpAndSettle();

    expect(mockAction.toggled.length, 1);
    expect(mockAction.toggled.first, ('test_uid_456', defaultFilterStrings.first, true));
  });

  testWidgets('タグ行をタップすると通知履歴画面（/tag-disclosures）へ遷移する',
      (WidgetTester tester) async {
    String? navigatedRoute;
    Object? navigatedArgs;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => MockUser()),
          userDocStreamProvider.overrideWith((ref) => Stream.value({})),
          notificationTagsProvider.overrideWithValue([]),
        ],
        child: MaterialApp(
          home: const NotificationTagSettingScreen(),
          onGenerateRoute: (settings) {
            if (settings.name == '/tag-disclosures') {
              navigatedRoute = settings.name;
              navigatedArgs = settings.arguments;
              return MaterialPageRoute(
                builder: (_) => const Scaffold(body: Text('TagDisclosuresMock')),
              );
            }
            return null;
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 「決算」の行をタップ
    await tester.tap(find.text('決算'));
    await tester.pumpAndSettle();

    expect(navigatedRoute, '/tag-disclosures');
    expect(navigatedArgs, '決算');
    expect(find.text('TagDisclosuresMock'), findsOneWidget);
  });
}
