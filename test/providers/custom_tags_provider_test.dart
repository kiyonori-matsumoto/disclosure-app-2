import 'package:disclosure_app_fl/providers/custom_tags_provider.dart';
import 'package:disclosure_app_fl/providers/user_settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('customTagsProvider', () {
    test('未設定時は空リストを返す', () {
      final container = ProviderContainer(
        overrides: [
          userDocStreamProvider.overrideWith((ref) => Stream.value({})),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(customTagsProvider);
      expect(result, isEmpty);
    });

    test('tags が存在する場合、そのリストを返す', () async {
      final container = ProviderContainer(
        overrides: [
          userDocStreamProvider.overrideWith((ref) => Stream.value({
                'tags': ['自社株買い', 'PO', 'TOB']
              })),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(userDocStreamProvider, (_, __) {});
      addTearDown(sub.close);

      await container.read(userDocStreamProvider.future);
      final result = container.read(customTagsProvider);
      expect(result, ['自社株買い', 'PO', 'TOB']);
    });
  });

  group('CustomTagsAction', () {
    test('CustomTagsAction はデフォルトで autoDispose される', () {
      expect(customTagsActionProvider.isAutoDispose, isTrue);
    });
  });
}
