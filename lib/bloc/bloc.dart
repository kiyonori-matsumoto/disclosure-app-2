import 'dart:async';

import 'package:bloc_provider/bloc_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:disclosure_app_fl/bloc/company_list_bloc.dart';
import 'package:disclosure_app_fl/models/filter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

final filterStrings = ["株主優待", "決算", "配当", "業績予想", "新株", "自己株式", "日々の開示事項"];

class AppBloc extends Bloc {
  final path = 'disclosures';
  final _dateController = BehaviorSubject<DateTime>(seedValue: DateTime.now());
  final _disclosureController =
      BehaviorSubject<List<DocumentSnapshot>>(seedValue: []);
  final _userController = BehaviorSubject<FirebaseUser>();
  final _filterController = BehaviorSubject<List<Filter>>();
  final StreamController<String> _filterChangeController = StreamController();

  final _handleFilterChange = (List<Filter> prev, String element, _) {
    prev.firstWhere((filter) => filter.title == element).toggle();
    return prev;
  };

  AppBloc() {
    final store = Firestore.instance;
    final initialFilters = filterStrings.map((str) => Filter(str)).toList();

    final filters$ = Observable(_filterChangeController.stream)
        .scan<List<Filter>>(_handleFilterChange, initialFilters)
        .shareValue(seedValue: initialFilters);

    final store$ = _dateController.flatMap((date) {
      final _date = DateTime(date.year, date.month, date.day);
      final start = _date.millisecondsSinceEpoch;
      final end = _date.add(Duration(days: 1)).millisecondsSinceEpoch;
      return store
          .collection(this.path)
          .where('time', isGreaterThanOrEqualTo: start)
          .where('time', isLessThan: end)
          .orderBy('time', descending: true)
          .snapshots();
    });

    Observable.combineLatest2<List<Filter>, QuerySnapshot,
        List<DocumentSnapshot>>(filters$, store$, (_filters, d) {
      print(_filters);
      if (_filters.where((filter) => filter.isSelected).length == 0) {
        return d.documents;
      }

      final selectedFilterStr = _filters
          .where((filter) => filter.isSelected)
          .map((filter) => filter.title);

      return d.documents
          .where((doc) =>
              selectedFilterStr.any((str) => doc.data['tags'][str] == true))
          .toList();
    }).pipe(_disclosureController);

    _disclosureController.listen(print);
    filters$.pipe(_filterController);
    FirebaseAuth.instance.onAuthStateChanged.pipe(_userController);
  }

  ValueObservable<List<DocumentSnapshot>> get disclosure$ =>
      _disclosureController.stream;
  Sink<DateTime> get date => _dateController.sink;
  Sink<String> get addFilter => _filterChangeController.sink;
  ValueObservable<FirebaseUser> get user$ => _userController.stream;
  ValueObservable<List<Filter>> get filter$ => _filterController.stream;

  @override
  void dispose() {
    _dateController.close();
    _disclosureController.close();
    _userController.close();
    _filterChangeController.close();
    _filterController.close();
  }
}
