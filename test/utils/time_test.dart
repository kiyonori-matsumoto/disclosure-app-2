import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:disclosure_app_fl/utils/time.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ja');
  });

  group('time utils', () {
    test('toDateHyphenate formats DateTime to yyyy-MM-dd', () {
      final dt = DateTime(2023, 10, 5, 12, 30);
      expect(toDateHyphenate(dt), '2023-10-05');
    });

    test('toDate formats timestamp to yMd ja', () {
      final dt = DateTime(2023, 10, 5, 12, 30);
      final formatted = toDate(dt.millisecondsSinceEpoch);
      expect(formatted, contains('2023'));
      expect(formatted, contains('10'));
      expect(formatted, contains('5'));
    });

    test('toTime formats timestamp', () {
      final dt = DateTime(2023, 10, 5, 14, 30);
      final timeStr = toTime(dt.millisecondsSinceEpoch);
      expect(timeStr, contains('14:30'));

      final dateTimeStr = toTime(dt.millisecondsSinceEpoch, showDate: true);
      expect(dateTimeStr, contains('2023'));
      expect(dateTimeStr, contains('14:30'));
    });
  });
}
