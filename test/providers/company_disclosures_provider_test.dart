import 'package:disclosure_app_fl/models/company_settlement.dart';
import 'package:disclosure_app_fl/models/edinet.dart';
import 'package:disclosure_app_fl/providers/company_disclosures_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PaginatedDisclosuresState', () {
    test('初期値が正しく設定される', () {
      const state = PaginatedDisclosuresState(docs: []);
      expect(state.docs, isEmpty);
      expect(state.hasMore, isTrue);
      expect(state.isLoadingMore, isFalse);
    });

    test('copyWith で各フィールドを部分更新できる', () {
      const state = PaginatedDisclosuresState(docs: []);
      final updated = state.copyWith(
        hasMore: false,
        isLoadingMore: true,
      );

      expect(updated.docs, isEmpty);
      expect(updated.hasMore, isFalse);
      expect(updated.isLoadingMore, isTrue);
    });
  });

  group('PaginatedEdinetsState', () {
    test('初期値が正しく設定される', () {
      const state = PaginatedEdinetsState(items: []);
      expect(state.items, isEmpty);
      expect(state.lastDoc, isNull);
      expect(state.hasMore, isTrue);
      expect(state.isLoadingMore, isFalse);
    });

    test('copyWith で各フィールドを部分更新できる', () {
      final edinet = Edinet(
        docDescription: '有価証券報告書',
        docId: '1',
        filerName: 'テスト企業',
        time: 123456789,
        edinetCode: 'E00001',
      );
      final state = PaginatedEdinetsState(items: [edinet]);
      final updated = state.copyWith(
        hasMore: false,
        isLoadingMore: true,
      );

      expect(updated.items.length, 1);
      expect(updated.hasMore, isFalse);
      expect(updated.isLoadingMore, isTrue);
    });
  });

  group('companySettlementProvider', () {
    test('コードが空または空白の場合は null を返す', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result1 = await container.read(companySettlementProvider('').future);
      expect(result1, isNull);

      final result2 = await container.read(companySettlementProvider('   ').future);
      expect(result2, isNull);
    });

    test('settlementProvider を override して Settlement データを正常に取得できる', () async {
      final mockSettlement = CompanySettlement(
        schedule: DateTime(2026, 11, 10),
        quote: '本決算',
        name: 'トヨタ自動車',
        code: '7203',
      );

      final container = ProviderContainer(
        overrides: [
          companySettlementProvider('7203')
              .overrideWith((ref) => Future.value(mockSettlement)),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(companySettlementProvider('7203').future);
      expect(result, isNotNull);
      expect(result!.quote, '本決算');
      expect(result.schedule, DateTime(2026, 11, 10));
    });
  });

  group('companyDisclosuresProvider', () {
    test('pageSize は 20 件に設定されている', () {
      expect(CompanyDisclosures.pageSize, 20);
    });

    test('コードが空の場合は空のドキュメントリストと hasMore: false を返す', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state1 = await container.read(companyDisclosuresProvider('').future);
      expect(state1.docs, isEmpty);
      expect(state1.hasMore, isFalse);

      final state2 = await container.read(companyDisclosuresProvider('   ').future);
      expect(state2.docs, isEmpty);
      expect(state2.hasMore, isFalse);
    });
  });

  group('companyEdinetsProvider', () {
    test('pageSize は 20 件に設定されている', () {
      expect(CompanyEdinets.pageSize, 20);
    });

    test('edinetCode が空の場合は空のリストと hasMore: false を返す', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state1 = await container.read(companyEdinetsProvider('').future);
      expect(state1.items, isEmpty);
      expect(state1.hasMore, isFalse);

      final state2 = await container.read(companyEdinetsProvider('   ').future);
      expect(state2.items, isEmpty);
      expect(state2.hasMore, isFalse);
    });
  });
}
