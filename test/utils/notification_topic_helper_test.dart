import 'package:flutter_test/flutter_test.dart';
import 'package:disclosure_app_fl/utils/notification_topic_helper.dart';

void main() {
  group('NotificationTopicHelper', () {
    group('code topics', () {
      test('toTopic adds code_ prefix', () {
        expect(NotificationTopicHelper.toTopic('7203'), 'code_7203');
      });

      test('toCode extracts company code from topic', () {
        expect(NotificationTopicHelper.toCode('code_7203'), '7203');
      });

      test('toCode handles topic without prefix gracefully', () {
        expect(NotificationTopicHelper.toCode('7203'), '7203');
      });

      test('isCodeTopic identifies code topics correctly', () {
        expect(NotificationTopicHelper.isCodeTopic('code_7203'), isTrue);
        expect(NotificationTopicHelper.isCodeTopic('tags_abc'), isFalse);
        expect(NotificationTopicHelper.isCodeTopic('7203'), isFalse);
      });
    });

    group('tag topics', () {
      test('fromTag and toTag correctly roundtrip Japanese tag strings', () {
        const testTags = ['株主優待', '決算', '配当', '新株', '日々の開示事項', 'Custom Tag 123!'];
        for (final tag in testTags) {
          final topic = NotificationTopicHelper.fromTag(tag);
          expect(topic.startsWith('tags_'), isTrue);
          final decoded = NotificationTopicHelper.toTag(topic);
          expect(decoded, tag);
        }
      });

      test('isTagTopic identifies tag topics correctly', () {
        expect(NotificationTopicHelper.isTagTopic('tags_5qCq5Li75YSq5b6F'), isTrue);
        expect(NotificationTopicHelper.isTagTopic('code_7203'), isFalse);
        expect(NotificationTopicHelper.isTagTopic('plain_tag'), isFalse);
      });
    });
  });
}
