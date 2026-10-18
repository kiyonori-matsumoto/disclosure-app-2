import 'package:flutter_test/flutter_test.dart';
import 'package:disclosure_app_fl/utils/disclosure_filter_helper.dart';

void main() {
  group('DisclosureFilterHelper', () {
    group('compareByViewCount', () {
      test('sorts by view_count descending', () {
        final item1 = {'view_count': 10, 'time': 100};
        final item2 = {'view_count': 20, 'time': 50};

        expect(DisclosureFilterHelper.compareByViewCount(item1, item2), isPositive); // item2 comes first
        expect(DisclosureFilterHelper.compareByViewCount(item2, item1), isNegative);
      });

      test('falls back to time descending when view_count is equal', () {
        final item1 = {'view_count': 10, 'time': 200};
        final item2 = {'view_count': 10, 'time': 100};

        expect(DisclosureFilterHelper.compareByViewCount(item1, item2), isNegative); // item1 is newer
        expect(DisclosureFilterHelper.compareByViewCount(item2, item1), isPositive);
      });

      test('handles null view_count and time safely', () {
        final item1 = <String, dynamic>{};
        final item2 = {'view_count': 5, 'time': 50};

        expect(DisclosureFilterHelper.compareByViewCount(item1, item2), isPositive);
        expect(DisclosureFilterHelper.compareByViewCount(item2, item1), isNegative);
        expect(DisclosureFilterHelper.compareByViewCount(item1, item1), 0);
      });
    });

    group('matchesFilter', () {
      test('filters out daily disclosures when hideDailyDisclosure is true', () {
        final dailyItem = {
          'code': '7203',
          'tags': {'日々の開示事項': true},
        };
        final normalItem = {
          'code': '7203',
          'tags': {'決算': true},
        };

        expect(
          DisclosureFilterHelper.matchesFilter(
            data: dailyItem,
            selectedFilterTitles: [],
            hideDailyDisclosure: true,
            favoriteCompanyCodes: [],
          ),
          isFalse,
        );

        expect(
          DisclosureFilterHelper.matchesFilter(
            data: normalItem,
            selectedFilterTitles: [],
            hideDailyDisclosure: true,
            favoriteCompanyCodes: [],
          ),
          isTrue,
        );
      });

      test('matches only selected filter tags when filter list is not empty', () {
        final kessanItem = {
          'code': '7203',
          'tags': {'決算': true},
        };
        final yutaiItem = {
          'code': '7203',
          'tags': {'株主優待': true},
        };

        expect(
          DisclosureFilterHelper.matchesFilter(
            data: kessanItem,
            selectedFilterTitles: ['決算'],
            hideDailyDisclosure: false,
            favoriteCompanyCodes: [],
          ),
          isTrue,
        );

        expect(
          DisclosureFilterHelper.matchesFilter(
            data: yutaiItem,
            selectedFilterTitles: ['決算'],
            hideDailyDisclosure: false,
            favoriteCompanyCodes: [],
          ),
          isFalse,
        );
      });

      test('filters by favorite companies when favoriteCompanyCodes is not empty', () {
        final favCompanyItem = {
          'code': '7203',
          'tags': {},
        };
        final otherCompanyItem = {
          'code': '6758',
          'tags': {},
        };

        expect(
          DisclosureFilterHelper.matchesFilter(
            data: favCompanyItem,
            selectedFilterTitles: [],
            hideDailyDisclosure: false,
            favoriteCompanyCodes: ['7203'],
          ),
          isTrue,
        );

        expect(
          DisclosureFilterHelper.matchesFilter(
            data: otherCompanyItem,
            selectedFilterTitles: [],
            hideDailyDisclosure: false,
            favoriteCompanyCodes: ['7203'],
          ),
          isFalse,
        );
      });
    });
  });
}
