import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:disclosure_app_fl/models/company-settlement.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ja');
  });

  group('CompanySettlement', () {
    test('toString formats name and quote', () {
      final settlement = CompanySettlement(name: 'トヨタ自動車', quote: '本決算');
      expect(settlement.toString(), 'トヨタ自動車 本決算');
    });

    test('toMessage formats message when schedule DateTime is provided', () {
      final settlement = CompanySettlement(
        quote: '3Q',
        schedule: DateTime(2023, 11, 10),
      );
      final msg = settlement.toMessage();
      expect(msg, contains('次回の決算(3Q)発表予定日は'));
      expect(msg, contains('2023'));
      expect(msg, contains('11'));
      expect(msg, contains('10'));
      expect(msg, endsWith('です'));
    });

    test('toMessage formats message when quote is empty and schedule is fallback string', () {
      final settlement = CompanySettlement(
        quote: '',
        schedule: null,
        scheduleStr: '未定',
      );
      final msg = settlement.toMessage();
      expect(msg, '次回の決算発表予定日は未定です');
    });
  });
}
