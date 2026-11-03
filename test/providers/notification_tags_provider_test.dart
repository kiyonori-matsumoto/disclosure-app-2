import 'package:disclosure_app_fl/providers/notification_tags_provider.dart';
import 'package:disclosure_app_fl/providers/user_settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('notificationTagsProvider', () {
    test('未設定時は空リストを返す', () {
      final container = ProviderContainer(
        overrides: [
          userDocStreamProvider.overrideWith((ref) => Stream.value({})),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(notificationTagsProvider);
      expect(result, isEmpty);
    });

    test('notification_tags が存在する場合、そのリストを返す', () async {
      final container = ProviderContainer(
        overrides: [
          userDocStreamProvider.overrideWith((ref) => Stream.value({
                'notification_tags': ['決算発表', '業績予想の修正']
              })),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(userDocStreamProvider, (_, __) {});
      addTearDown(sub.close);

      await container.read(userDocStreamProvider.future);
      final result = container.read(notificationTagsProvider);
      expect(result, ['決算発表', '業績予想の修正']);
    });
  });

  group('NotificationTagsAction', () {
    test('NotificationTagsAction はデフォルトで autoDispose される', () {
      expect(notificationTagsActionProvider.isAutoDispose, isTrue);
    });
  });
}
