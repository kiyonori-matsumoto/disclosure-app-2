import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:disclosure_app_fl/models/company.dart';

void main() {
  group('Company', () {
    test('constructs correctly with default and trimmed values', () {
      final company = Company('7203', name: '  トヨタ自動車  ', edinetCode: null);
      expect(company.code, '7203');
      expect(company.name, 'トヨタ自動車');
      expect(company.edinetCode, '');
      expect(company.nameKana, '');
      expect(company.key, equals(const Key('7203')));
    });

    test('handles null code', () {
      final company = Company(null);
      expect(company.code, isNull);
      expect(company.key, isNull);
    });

    test('hiraToKana converts hiragana to katakana', () {
      expect(Company.hiraToKana('とうきょう'), 'トウキョウ');
      expect(Company.hiraToKana('あいうえお'), 'アイウエオ');
      expect(Company.hiraToKana('abc漢字123'), 'abc漢字123');
      expect(Company.hiraToKana('ひらがなとカタカナ'), 'ヒラガナトカタカナ');
    });

    test('match matches by company name (case-insensitive)', () {
      final company = Company('7203', name: 'Toyota Motor');
      expect(company.match('toyota'), isTrue);
      expect(company.match('TOYOTA'), isFalse); // match expects lowercase input as per implementation
      expect(company.match('motor'), isTrue);
      expect(company.match('honda'), isFalse);
    });

    test('match matches by code prefix', () {
      final company = Company('7203', name: 'トヨタ');
      expect(company.match('72'), isTrue);
      expect(company.match('7203'), isTrue);
      expect(company.match('20'), isFalse);
    });

    test('match matches by kana name with hiragana input', () {
      final company = Company('7203', name: 'トヨタ自動車', nameKana: 'トヨタジドウシャ');
      expect(company.match('とよた'), isTrue);
      expect(company.match('じどうしゃ'), isTrue);
      expect(company.match('ほんだ'), isFalse);
    });

    test('equality and hashCode are based on code', () {
      final c1 = Company('7203', name: 'Company A');
      final c2 = Company('7203', name: 'Company B');
      final c3 = Company('6758', name: 'Sony');

      expect(c1, equals(c2));
      expect(c1.hashCode, equals(c2.hashCode));
      expect(c1, isNot(equals(c3)));

      final set = {c1, c2, c3};
      expect(set.length, 2);
    });

    test('toString formats code and name appropriately', () {
      final c1 = Company('7203', name: 'トヨタ自動車');
      expect(c1.toString(), '7203 トヨタ自動車');

      final c2 = Company('72030', name: 'トヨタ関連');
      expect(c2.toString(), '7203 トヨタ関連');
    });
  });
}
