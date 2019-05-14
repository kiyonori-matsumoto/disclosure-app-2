import 'dart:async';

import 'package:disclosure_app_fl/bloc/bloc.dart';
import 'package:disclosure_app_fl/models/company.dart';

Future<Company> getCompany(AppBloc bloc,
    {String code, String edinetCode, String name}) async {
  assert(
      edinetCode != null || code != null, 'must specify code or edinetCode.',);

  Company company;

  if (bloc != null) {
    if (edinetCode != null) {
      final companies = await bloc.companyMap$.first;
      company = companies[edinetCode];
    } else if (code != null) {
      final companies = await bloc.company$.first;
      company = companies.firstWhere((e) => e.code == code,
          orElse: () => Company(code, edinetCode: edinetCode, name: name));
    }
  }

  if (company != null) {
    print("company is " + company.toString());
    return company;
  }
  return Company(code, edinetCode: edinetCode, name: name);
}
