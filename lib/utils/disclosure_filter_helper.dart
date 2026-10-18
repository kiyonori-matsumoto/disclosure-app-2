/// Helper functions for filtering and sorting disclosure items.
class DisclosureFilterHelper {
  /// Default filter tag strings used across the app.
  static const List<String> defaultFilterStrings = [
    "株主優待",
    "決算",
    "配当",
    "業績予想",
    "新株",
    "自己株式",
    "日々の開示事項",
  ];

  /// Compares two disclosure items by view_count descending, falling back to time descending.
  static int compareByViewCount(
    Map<String, dynamic>? dataA,
    Map<String, dynamic>? dataB,
  ) {
    final num viewCountA = dataA?['view_count'] ?? 0;
    final num viewCountB = dataB?['view_count'] ?? 0;
    final viewDiff = viewCountB.compareTo(viewCountA);
    if (viewDiff != 0) return viewDiff;

    final num timeA = dataA?['time'] ?? 0;
    final num timeB = dataB?['time'] ?? 0;
    return timeB.compareTo(timeA);
  }

  /// Determines whether a disclosure data matches the current filter settings.
  static bool matchesFilter({
    required Map<String, dynamic> data,
    required Iterable<String> selectedFilterTitles,
    required bool hideDailyDisclosure,
    required List<String> favoriteCompanyCodes,
  }) {
    final rawTags = data['tags'];
    final tags = rawTags is Map ? rawTags : const {};

    // 1. Daily disclosure check
    if (hideDailyDisclosure && tags['日々の開示事項'] == true) {
      return false;
    }

    // 2. Tag filter check
    final hasSelectedFilters = selectedFilterTitles.isNotEmpty;
    if (hasSelectedFilters) {
      final matchesAnyTag = selectedFilterTitles.any((tag) => tags[tag] != null);
      if (!matchesAnyTag) {
        return false;
      }
    }

    // 3. Favorite companies check
    if (favoriteCompanyCodes.isNotEmpty) {
      final code = data['code'];
      if (code == null || !favoriteCompanyCodes.contains(code)) {
        return false;
      }
    }

    return true;
  }
}
