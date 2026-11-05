import 'package:disclosure_app_fl/models/company.dart';
import 'package:flutter/material.dart';

/// Represents the navigation target determined from a notification payload.
sealed class NotificationDestination {
  const NotificationDestination();
}

/// Navigation target for tag-based disclosures.
class TagDestination extends NotificationDestination {
  final String tag;
  const TagDestination(this.tag);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TagDestination && runtimeType == other.runtimeType && tag == other.tag;

  @override
  int get hashCode => tag.hashCode;

  @override
  String toString() => 'TagDestination(tag: $tag)';
}

/// Navigation target for company-based disclosures.
class CompanyDestination extends NotificationDestination {
  final Company company;
  const CompanyDestination(this.company);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompanyDestination &&
          runtimeType == other.runtimeType &&
          company.code == other.company.code &&
          company.edinetCode == other.company.edinetCode &&
          company.name == other.company.name;

  @override
  int get hashCode => Object.hash(company.code, company.edinetCode, company.name);

  @override
  String toString() =>
      'CompanyDestination(company: ${company.code}, ${company.name})';
}

/// No navigation target (invalid or unrecognized payload).
class NoneDestination extends NotificationDestination {
  const NoneDestination();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is NoneDestination;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'NoneDestination()';
}

/// Helper for resolving navigation destination from notification payload
/// and executing navigation transitions.
class NotificationRouteHelper {
  /// Resolves the [NotificationDestination] from raw notification data.
  ///
  /// - If `data['type'] == 'tag'` and `tag` is not empty -> [TagDestination].
  /// - If `data['code']` (or `data['edinetCode']`) is not empty -> [CompanyDestination].
  /// - Otherwise -> [NoneDestination].
  static Future<NotificationDestination> resolveDestination(
    Map<String, dynamic>? data, {
    Map<String, Company>? companyCodeMap,
    Future<Company> Function(String code, String name)? companyResolver,
  }) async {
    if (data == null || data.isEmpty) {
      return const NoneDestination();
    }

    final type = data['type']?.toString().trim();
    if (type == 'tag') {
      final tag = data['tag']?.toString().trim();
      if (tag != null && tag.isNotEmpty) {
        return TagDestination(tag);
      }
      return const NoneDestination();
    }

    final rawCode = data['code']?.toString().trim();
    final rawName = data['name']?.toString().trim() ?? '';
    final rawEdinetCode = data['edinetCode']?.toString().trim();

    final hasCode = rawCode != null && rawCode.isNotEmpty;
    final hasEdinetCode = rawEdinetCode != null && rawEdinetCode.isNotEmpty;

    if (!hasCode && !hasEdinetCode) {
      return const NoneDestination();
    }

    if (companyResolver != null && hasCode) {
      final company = await companyResolver(rawCode, rawName);
      return CompanyDestination(company);
    }

    if (companyCodeMap != null && hasCode) {
      final cachedCompany = companyCodeMap[rawCode];
      if (cachedCompany != null) {
        return CompanyDestination(cachedCompany);
      }
    }

    return CompanyDestination(
      Company(rawCode, edinetCode: rawEdinetCode, name: rawName),
    );
  }

  /// Triggers navigation to the resolved [destination] using the given [navigator].
  /// Returns `true` if navigation was triggered, `false` otherwise.
  static bool navigateToDestination(
    NavigatorState navigator,
    NotificationDestination destination,
  ) {
    switch (destination) {
      case TagDestination(:final tag):
        navigator.pushNamed('/tag-disclosures', arguments: tag);
        return true;
      case CompanyDestination(:final company):
        navigator.pushNamed('/company-disclosures', arguments: company);
        return true;
      case NoneDestination():
        return false;
    }
  }
}
