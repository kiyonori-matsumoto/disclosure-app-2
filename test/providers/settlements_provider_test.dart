import 'package:disclosure_app_fl/models/company_settlement.dart';
import 'package:disclosure_app_fl/providers/settlements_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettlementsSelectedDate Notifier', () {
    test('初期値は現在日時の日付である', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final date = container.read(settlementsSelectedDateProvider);
      final now = DateTime.now();
      expect(date.year, now.year);
      expect(date.month, now.month);
      expect(date.day, now.day);
    });

    test('setDate で日付を更新できる', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final target = DateTime(2026, 11, 15);
      container.read(settlementsSelectedDateProvider.notifier).setDate(target);
      expect(container.read(settlementsSelectedDateProvider), target);
    });
  });

  group('currentSettlementsListProvider', () {
    test('選択された日付に応じた決算発表予定リストを正常に取得できる', () async {
      final targetDate = DateTime(2026, 11, 10);
      final mockSettlement = CompanySettlement(
        code: '7203',
        name: 'トヨタ自動車',
        quote: '本決算',
        schedule: targetDate,
        scheduleStr: '2026-11-10',
      );

      final container = ProviderContainer(
        overrides: [
          settlementsSelectedDateProvider
              .overrideWith(() => _TestSelectedDate(targetDate)),
          settlementsByDateProvider(targetDate)
              .overrideWith((ref) => Future.value([mockSettlement])),
        ],
      );
      addTearDown(container.dispose);

      final list = await container.read(currentSettlementsListProvider.future);
      expect(list.length, 1);
      expect(list.first.code, '7203');
      expect(list.first.name, 'トヨタ自動車');
      expect(list.first.quote, '本決算');
    });

    test('指定日の決算発表予定が0件の場合は空リストを返す', () async {
      final targetDate = DateTime(2026, 11, 10);

      final container = ProviderContainer(
        overrides: [
          settlementsSelectedDateProvider
              .overrideWith(() => _TestSelectedDate(targetDate)),
          settlementsByDateProvider(targetDate)
              .overrideWith((ref) => Future.value([])),
        ],
      );
      addTearDown(container.dispose);

      final list = await container.read(currentSettlementsListProvider.future);
      expect(list, isEmpty);
    });

    test('日付を変更すると、変更後の日付の決算予定が取得される', () async {
      final date1 = DateTime(2026, 11, 10);
      final date2 = DateTime(2026, 11, 11);

      final item1 = CompanySettlement(
        code: '7203',
        name: 'トヨタ自動車',
        quote: '本決算',
      );
      final item2 = CompanySettlement(
        code: '6758',
        name: 'ソニーグループ',
        quote: '第2四半期',
      );

      final container = ProviderContainer(
        overrides: [
          settlementsSelectedDateProvider
              .overrideWith(() => _TestSelectedDate(date1)),
          settlementsByDateProvider(date1)
              .overrideWith((ref) => Future.value([item1])),
          settlementsByDateProvider(date2)
              .overrideWith((ref) => Future.value([item2])),
        ],
      );
      addTearDown(container.dispose);

      var list = await container.read(currentSettlementsListProvider.future);
      expect(list.first.code, '7203');

      // 日付を date2 に変更
      container.read(settlementsSelectedDateProvider.notifier).setDate(date2);
      list = await container.read(currentSettlementsListProvider.future);
      expect(list.first.code, '6758');
    });
  });
}

class _TestSelectedDate extends SettlementsSelectedDate {
  final DateTime _initial;
  _TestSelectedDate(this._initial);

  @override
  DateTime build() => _initial;
}
