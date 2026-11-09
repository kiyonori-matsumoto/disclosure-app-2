import 'package:disclosure_app_fl/utils/version_comparator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VersionComparator.isUpdateRequired', () {
    test('現在のバージョンが必須バージョンより低い場合、true を返す', () {
      expect(
        VersionComparator.isUpdateRequired(
          current: '2.7.1',
          minRequired: '2.8.0',
        ),
        isTrue,
      );
      expect(
        VersionComparator.isUpdateRequired(
          current: '2.7.1',
          minRequired: '3.0.0',
        ),
        isTrue,
      );
      expect(
        VersionComparator.isUpdateRequired(
          current: '1.9.9',
          minRequired: '2.0.0',
        ),
        isTrue,
      );
      expect(
        VersionComparator.isUpdateRequired(
          current: '2.7.1',
          minRequired: '2.7.2',
        ),
        isTrue,
      );
    });

    test('現在のバージョンが必須バージョンと同じか高い場合、false を返す', () {
      expect(
        VersionComparator.isUpdateRequired(
          current: '2.7.1',
          minRequired: '2.7.1',
        ),
        isFalse,
      );
      expect(
        VersionComparator.isUpdateRequired(
          current: '2.8.0',
          minRequired: '2.7.1',
        ),
        isFalse,
      );
      expect(
        VersionComparator.isUpdateRequired(
          current: '3.0.0',
          minRequired: '2.7.1',
        ),
        isFalse,
      );
      expect(
        VersionComparator.isUpdateRequired(
          current: '2.7.1',
          minRequired: '2.0.0',
        ),
        isFalse,
      );
    });

    test('ビルド番号やプレリリース修飾子が含まれていても正しく判定できる', () {
      expect(
        VersionComparator.isUpdateRequired(
          current: '2.7.1+104',
          minRequired: '2.8.0',
        ),
        isTrue,
      );
      expect(
        VersionComparator.isUpdateRequired(
          current: '2.7.1+104',
          minRequired: '2.7.1',
        ),
        isFalse,
      );
      expect(
        VersionComparator.isUpdateRequired(
          current: '2.8.0-beta.1',
          minRequired: '2.8.0',
        ),
        isFalse,
      );
    });

    test('桁数の異なるバージョン表記（2桁 vs 3桁）でも正しく判定できる', () {
      expect(
        VersionComparator.isUpdateRequired(
          current: '2.7',
          minRequired: '2.7.1',
        ),
        isTrue,
      );
      expect(
        VersionComparator.isUpdateRequired(
          current: '2.7.1',
          minRequired: '2.7',
        ),
        isFalse,
      );
    });

    test('不正な入力や空文字の場合は安全側に倒して false を返す', () {
      expect(
        VersionComparator.isUpdateRequired(
          current: 'invalid',
          minRequired: '2.0.0',
        ),
        isFalse,
      );
      expect(
        VersionComparator.isUpdateRequired(
          current: '2.7.1',
          minRequired: '',
        ),
        isFalse,
      );
      expect(
        VersionComparator.isUpdateRequired(
          current: '2.7.1',
          minRequired: 'invalid',
        ),
        isFalse,
      );
    });
  });
}
