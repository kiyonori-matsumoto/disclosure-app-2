import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:bloc_provider/bloc_provider.dart';
import 'package:disclosure_app_fl/models/company.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';

class CompanyListBloc extends Bloc {
  final _companiesProvider = BehaviorSubject<List<Company>>();
  final _codeStrController = BehaviorSubject<String>(seedValue: '');
  final _storage = FirebaseStorage.instance;

  Future<List<dynamic>> _handleOpenFile() async {
    final _appDir = await getApplicationDocumentsDirectory();
    final companyJsonFile = File(_appDir.path + "/companies.json");
    if (companyJsonFile.existsSync() &&
        companyJsonFile
            .lastModifiedSync()
            .isAfter(DateTime.now().subtract(Duration(days: 7)))) {
      // file exists and latest, so not download this file
      return companyJsonFile.readAsString().then((str) => jsonDecode(str));
    } else {
      final ref = _storage.ref().child('companies.json');
      final task = ref.writeToFile(companyJsonFile);
      return task.future
          .then((snapshot) => companyJsonFile.readAsString())
          .then((str) => jsonDecode(str));
    }
  }

  CompanyListBloc() {
    Observable.combineLatest2<List<dynamic>, String, List<Company>>(
        Observable.fromFuture(_handleOpenFile()), _codeStrController.stream,
        (data, str) {
      if (str.length < 2) return [];
      return data
          .map((d) => Company(d['name'], d['code']))
          .where((d) => d.match(str))
          .toList();
    }).pipe(_companiesProvider);
  }

  ValueObservable<List<Company>> get filteredCompany$ =>
      _companiesProvider.stream;
  Sink<String> get changeFilter => _codeStrController.sink;

  @override
  void dispose() {
    _companiesProvider.close();
    _codeStrController.close();
  }
}
