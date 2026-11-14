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

/// Route arguments for `/company-disclosures` when extra options are needed.
class CompanyRouteArguments {
  final Company company;
  final int initialTabIndex;

  const CompanyRouteArguments({
    required this.company,
    this.initialTabIndex = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompanyRouteArguments &&
          runtimeType == other.runtimeType &&
          company == other.company &&
          initialTabIndex == other.initialTabIndex;

  @override
  int get hashCode => Object.hash(company, initialTabIndex);
}

/// Navigation target for company-based disclosures.
class CompanyDestination extends NotificationDestination {
  final Company company;
  final int initialTabIndex;
  const CompanyDestination(this.company, {this.initialTabIndex = 0});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompanyDestination &&
          runtimeType == other.runtimeType &&
          company.code == other.company.code &&
          company.edinetCode == other.company.edinetCode &&
          company.name == other.company.name &&
          initialTabIndex == other.initialTabIndex;

  @override
  int get hashCode =>
      Object.hash(company.code, company.edinetCode, company.name, initialTabIndex);

  @override
  String toString() =>
      'CompanyDestination(company: ${company.code}, ${company.name}, initialTabIndex: $initialTabIndex)';
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

    final initialTabIndex = _resolveInitialTabIndex(data, rawEdinetCode);

    if (companyResolver != null && hasCode) {
      final company = await companyResolver(rawCode, rawName);
      return CompanyDestination(company, initialTabIndex: initialTabIndex);
    }

    if (companyCodeMap != null && hasCode) {
      final cachedCompany = companyCodeMap[rawCode] ??
          (rawCode.length > 4 ? companyCodeMap[rawCode.substring(0, 4)] : null);
      if (cachedCompany != null) {
        return CompanyDestination(
          cachedCompany,
          initialTabIndex: initialTabIndex,
        );
      }
    }

    return CompanyDestination(
      Company(rawCode, edinetCode: rawEdinetCode, name: rawName),
      initialTabIndex: initialTabIndex,
    );
  }

  static int _resolveInitialTabIndex(
    Map<String, dynamic> data,
    String? rawEdinetCode,
  ) {
    final type = data['type']?.toString().trim().toLowerCase();
    final source = data['source']?.toString().trim().toLowerCase();
    final docId = (data['docID'] ?? data['docId'])?.toString().trim();
    final isEdinet = type == 'edinet' ||
        source == 'edinet' ||
        (rawEdinetCode != null && rawEdinetCode.isNotEmpty) ||
        (docId != null && docId.isNotEmpty);
    return isEdinet ? 1 : 0;
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
      case CompanyDestination(:final company, :final initialTabIndex):
        navigator.pushNamed(
          '/company-disclosures',
          arguments: initialTabIndex == 0
              ? company
              : CompanyRouteArguments(
                  company: company,
                  initialTabIndex: initialTabIndex,
                ),
        );
        return true;
      case NoneDestination():
        return false;
    }
  }
}
