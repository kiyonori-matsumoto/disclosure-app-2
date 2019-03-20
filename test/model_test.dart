import 'package:disclosure_app_fl/models/filter.dart';
import 'package:flutter/material.dart' as mt;
import 'package:test/test.dart';

void main() {
  group("Filter", () {
    test("can instance", () {
      var filter = Filter("title");
      expect(filter.toString(), "title false");
      expect(filter.key, new TypeMatcher<mt.ObjectKey>());
    });

    test("can toggle", () {
      var filter = Filter("foo");
      filter.toggle();
      expect(filter.isSelected, isTrue);

      filter.toggle();
      expect(filter.isSelected, isFalse);
    });
  });
}
