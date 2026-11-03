import 'package:disclosure_app_fl/providers/auth_provider.dart';
import 'package:disclosure_app_fl/providers/custom_tags_provider.dart';
import 'package:disclosure_app_fl/providers/user_settings_provider.dart';
import 'package:disclosure_app_fl/screens/customtag.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MockUser extends Fake implements User {
  @override
  String get uid => 'test_uid_789';
}

class MockCustomTagsAction extends CustomTagsAction {
  final List<(String, String)> added = [];
  final List<(String, String)> removed = [];

  @override
  void build() {}

  @override
  Future<void> add(String uid, String tag) async {
    added.add((uid, tag));
  }

  @override
  Future<void> remove(String uid, String tag) async {
    removed.add((uid, tag));
  }
}

void main() {
  testWidgets('カスタムタグが空の場合、「カスタムタグはありません」が表示される',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userDocStreamProvider.overrideWith((ref) => Stream.value({})),
          customTagsProvider.overrideWithValue([]),
        ],
        child: const MaterialApp(
          home: CustomTagScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('カスタムタグはありません'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('カスタムタグが存在する場合、タグ一覧が表示される',
      (WidgetTester tester) async {
    final testTags = ['自社株買い', 'PO', 'TOB'];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userDocStreamProvider.overrideWith((ref) => Stream.value({
                'tags': testTags,
              })),
          customTagsProvider.overrideWithValue(testTags),
        ],
        child: const MaterialApp(
          home: CustomTagScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    for (final tag in testTags) {
      expect(find.text(tag), findsOneWidget);
    }
  });

  testWidgets('アイテムをスワイプ削除後、SnackBarの「取り消す」をタップして復元できる',
      (WidgetTester tester) async {
    final testTags = ['自社株買い'];
    final mockAction = MockCustomTagsAction();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => MockUser()),
          userDocStreamProvider.overrideWith((ref) => Stream.value({
                'tags': testTags,
              })),
          customTagsProvider.overrideWithValue(testTags),
          customTagsActionProvider.overrideWith(() => mockAction),
        ],
        child: const MaterialApp(
          home: CustomTagScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // スワイプして削除
    await tester.drag(find.text('自社株買い'), const Offset(-500.0, 0.0));
    await tester.pumpAndSettle();

    expect(mockAction.removed, [('test_uid_789', '自社株買い')]);
    expect(find.text('削除しました'), findsOneWidget);
    expect(find.text('取り消す'), findsOneWidget);

    // 「取り消す」をタップ
    await tester.tap(find.text('取り消す'));
    await tester.pumpAndSettle();

    expect(mockAction.added, [('test_uid_789', '自社株買い')]);
  });

  testWidgets('テキストを入力して送信ボタンを押すとタグが追加される',
      (WidgetTester tester) async {
    final mockAction = MockCustomTagsAction();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => MockUser()),
          userDocStreamProvider.overrideWith((ref) => Stream.value({})),
          customTagsProvider.overrideWithValue([]),
          customTagsActionProvider.overrideWith(() => mockAction),
        ],
        child: const MaterialApp(
          home: CustomTagScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // テキストを入力
    await tester.enterText(find.byType(TextField), '新規タグ');
    await tester.pumpAndSettle();

    // 送信アイコン（IconButton）をタップ
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    expect(mockAction.added, [('test_uid_789', '新規タグ')]);
  });
}
