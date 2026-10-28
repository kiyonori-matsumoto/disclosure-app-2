import 'dart:async';

import 'package:disclosure_app_fl/bloc/bloc.dart';
import 'package:disclosure_app_fl/models/company.dart';
import 'package:flutter/foundation.dart';

Future<Company> getCompany(AppBloc? bloc,
    {String? code, String? edinetCode, String? name}) async {
  assert(
    edinetCode != null || code != null,
    'must specify code or edinetCode.',
  );

  Company? company;
  final safeName = name ?? '';

  if (bloc != null) {
    if (edinetCode != null) {
      final companies = await bloc.companyMap$.first;
      company = companies[edinetCode];
    } else if (code != null) {
      final companies = await bloc.companyCodeMap$.first;
      company = companies[code];
    }
  }

  if (company != null) {
    debugPrint("company is $company");
    return company;
  }
  return Company(code, edinetCode: edinetCode, name: safeName);
}
