import 'package:flutter_test/flutter_test.dart';
import 'package:disclosure_app_fl/models/disclosure.dart';

void main() {
  group('Disclosure', () {
    test('constructs correctly with default values', () {
      final disclosure = Disclosure(
        code: '7203',
        company: 'トヨタ自動車',
        title: '決算短信',
        document: 'doc123',
        exchanges: '東',
        time: 1696000000,
        viewCount: 10,
        tags: ['決算', '配当'],
      );

      expect(disclosure.code, '7203');
      expect(disclosure.company, 'トヨタ自動車');
      expect(disclosure.title, '決算短信');
      expect(disclosure.document, 'doc123');
      expect(disclosure.exchanges, '東');
      expect(disclosure.time, 1696000000);
      expect(disclosure.viewCount, 10);
      expect(disclosure.tags, ['決算', '配当']);
      expect(disclosure.isSelected, isFalse);
    });

    test('toObject converts fields and tags correctly', () {
      final disclosure = Disclosure(
        code: '7203',
        company: 'トヨタ自動車',
        title: '決算短信',
        document: 'doc123',
        exchanges: '東',
        time: 1696000000,
        tags: ['決算', '配当'],
      );

      final map = disclosure.toObject();

      expect(map['code'], '7203');
      expect(map['company'], 'トヨタ自動車');
      expect(map['title'], '決算短信');
      expect(map['document'], 'doc123');
      expect(map['exchanges'], '東');
      expect(map['time'], 1696000000);
      expect(map['tags'], {
        '決算': true,
        '配当': true,
      });
    });

    test('toObject handles empty tags correctly', () {
      final disclosure = Disclosure(
        code: '7203',
        tags: [],
      );

      final map = disclosure.toObject();
      expect(map['tags'], <String, dynamic>{});
    });
  });
}
