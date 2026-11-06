import 'dart:async';

import 'package:disclosure_app_fl/models/company.dart';
import 'package:flutter/foundation.dart';

Future<Company> getCompany({
  String? code,
  String? edinetCode,
  String? name,
  Map<String, Company>? companyMap,
  Map<String, Company>? companyCodeMap,
}) async {
  assert(
    edinetCode != null || code != null,
    'must specify code or edinetCode.',
  );

  Company? company;
  final safeName = name ?? '';

  if (edinetCode != null && companyMap != null) {
    company = companyMap[edinetCode];
  } else if (code != null && companyCodeMap != null) {
    final cleanCode = code.trim().toUpperCase();
    company = companyCodeMap[cleanCode];
    if (company == null && cleanCode.length > 4) {
      company = companyCodeMap[cleanCode.substring(0, 4)];
    }
  }

  if (company != null) {
    debugPrint("company is $company");
    return company;
  }
  return Company(code, edinetCode: edinetCode, name: safeName);
}
