import 'dart:convert';

/// Helper for encoding and decoding FCM notification topics for companies and tags.
class NotificationTopicHelper {
  static final Codec<String, String> _stringToBase64Url = utf8.fuse(base64Url);

  static const String codePrefix = 'code_';
  static const String tagPrefix = 'tags_';

  /// Converts a company code to a topic name (e.g., '7203' -> 'code_7203').
  static String toTopic(String code) => '$codePrefix$code';

  /// Extracts the company code from a topic name (e.g., 'code_7203' -> '7203').
  static String toCode(String topic) {
    if (topic.startsWith(codePrefix)) {
      return topic.substring(codePrefix.length);
    }
    return topic;
  }

  /// Encodes a tag string into a base64url topic name (e.g., '株主優待' -> 'tags_...').
  static String fromTag(String tag) {
    return '$tagPrefix${_stringToBase64Url.encode(tag)}';
  }

  /// Decodes a base64url topic name back into a tag string.
  static String toTag(String topic) {
    final encoded = topic.startsWith(tagPrefix)
        ? topic.substring(tagPrefix.length)
        : topic;
    return _stringToBase64Url.decode(encoded);
  }

  /// Checks if the given topic is a company code topic.
  static bool isCodeTopic(String topic) => topic.startsWith(codePrefix);

  /// Checks if the given topic is a tag topic.
  static bool isTagTopic(String topic) => topic.startsWith(tagPrefix);
}
