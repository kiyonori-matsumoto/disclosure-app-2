import 'package:disclosure_app_fl/providers/remote_config_provider.dart';
import 'package:disclosure_app_fl/widgets/force_update_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ForceUpdateDialog', () {
    testWidgets('タイトル、メッセージ、バージョン情報およびアップデートボタンが表示される',
        (tester) async {
      const state = ForceUpdateState(
        isRequired: true,
        currentVersion: '2.7.1',
        minRequiredVersion: '2.8.0',
        title: 'AppCheck必須化に伴うアップデート',
        message: 'セキュリティ向上のため、最新版に更新してください。',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ForceUpdateDialog(state: state),
          ),
        ),
      );

      expect(find.text('AppCheck必須化に伴うアップデート'), findsOneWidget);
      expect(find.text('セキュリティ向上のため、最新版に更新してください。'), findsOneWidget);
      expect(
        find.text('現在のバージョン: 2.7.1\n必要最低バージョン: 2.8.0'),
        findsOneWidget,
      );
      expect(find.text('今すぐアップデート'), findsOneWidget);
    });
  });
}
