import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:disclosure_app_fl/models/filter.dart';

void main() {
  group('Filter', () {
    test('instantiates with defaults', () {
      final filter = Filter('title');
      expect(filter.title, 'title');
      expect(filter.isSelected, isFalse);
      expect(filter.isCustom, isFalse);
      expect(filter.toString(), 'title false');
      expect(filter.key, isA<ObjectKey>());
    });

    test('instantiates with custom parameters', () {
      final filter = Filter('custom', isSelected: true, isCustom: true);
      expect(filter.title, 'custom');
      expect(filter.isSelected, isTrue);
      expect(filter.isCustom, isTrue);
      expect(filter.toString(), 'custom true');
    });

    test('toggle switches isSelected state', () {
      final filter = Filter('foo');
      expect(filter.isSelected, isFalse);

      filter.toggle();
      expect(filter.isSelected, isTrue);
      expect(filter.toString(), 'foo true');

      filter.toggle();
      expect(filter.isSelected, isFalse);
      expect(filter.toString(), 'foo false');
    });

    test('key produces ObjectKey containing title and isCustom', () {
      final filter = Filter('test', isCustom: true);
      expect(filter.key, isA<ObjectKey>());
      final key = filter.key as ObjectKey;
      expect(key.value, equals({'title': 'test', 'isCustom': true}));
    });
  });
}
