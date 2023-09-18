import 'dart:async';

import 'package:bloc_provider/bloc_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:disclosure_app_fl/models/company-settlement.dart';
import 'package:disclosure_app_fl/models/company.dart';
import 'package:disclosure_app_fl/models/disclosure.dart';
import 'package:disclosure_app_fl/models/edinet.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class FirestoreGetCount<T> extends Bloc {
  final Query query;
  final Function(T) getFn;
  final T Function(DocumentSnapshot) mapper;
  final ValueStream<User> user$;

  final StreamController<void> _reloadController = StreamController();
  final StreamController<T> _loadNextController = StreamController();
  final BehaviorSubject<List<T>> _data$ = BehaviorSubject();
  final BehaviorSubject<bool> _isLoading$ = BehaviorSubject.seeded(true);

  Sink<void> get reload => _reloadController.sink;
  Sink<T> get loadNext => _loadNextController.sink;
  ValueStream<List<T>> get data$ => _data$.stream;
  ValueStream<bool> get isLoading$ => _isLoading$.stream;

  FirestoreGetCount({
    @required this.query,
    @required this.getFn,
    @required this.mapper,
    @required this.user$,
  }) {
    _reloadController.stream.switchMap((_) {
      return _loadNextController.stream
          .startWith(null)
          .doOnData((_) => this._isLoading$.add(true))
          .flatMap((last) {
            print("last data = $last");
            var q = query;
            if (last != null) {
              var lastData = getFn(last);
              print("start after = $lastData");
              q = q.startAfter([lastData]);
            }
            return Stream.fromFuture(
                user$.first.then((user) => q.limit(20).get()));
          })
          .doOnData((_) => this._isLoading$.add(false))
          .map((d) => d.docs.map(mapper).toList())
          .scan<List<T>>((acc, curr, i) {
            return acc + curr;
          }, [])
          .startWith(null);
    }).pipe(_data$);
  }

  @override
  void dispose() async {
    _reloadController.close();
    _loadNextController.close();
    await _data$.drain();
    _data$.close();
    _isLoading$.close();
  }
}

class CompanyDisclosureBloc2 extends Bloc {
  final Company company;

  final FirestoreGetCount<Edinet> edinet;
  final FirestoreGetCount<DocumentSnapshot> disclosure;

  final ValueStream<Map<String, Company>> companies;
  final ValueStream<User> user$;

  final BehaviorSubject<CompanySettlement> _companySettlement$ =
      BehaviorSubject();

  ValueStream<CompanySettlement> get companySettlement$ =>
      _companySettlement$.stream;

  CompanyDisclosureBloc2._(
    this.company, {
    @required this.companies,
    @required this.user$,
    @required this.edinet,
    @required this.disclosure,
  }) {
    _settlementControllerHandler(this.company.code);
  }

  factory CompanyDisclosureBloc2(Company company,
      {@required ValueStream<Map<String, Company>> companies,
      @required ValueStream<User> user$}) {
    final edinet = (company.edinetCode != null && company.edinetCode != "")
        ? FirestoreGetCount<Edinet>(
            user$: user$,
            query: FirebaseFirestore.instance
                .collection('edinets')
                .where('map.${company.edinetCode}', isGreaterThan: 0)
                .orderBy('map.${company.edinetCode}', descending: true),
            mapper: (doc) {
              final edinet = Edinet.fromDocumentSnapshot(doc);
              return edinet;
            },
            getFn: (edinet) => edinet.lastEvaluate,
          )
        : null;
    final disclosure = (company.code != null && company.code != "")
        ? FirestoreGetCount<DocumentSnapshot<Map<String,dynamic>>>(
            user$: user$,
            query: FirebaseFirestore.instance
                .collection('disclosures')
                .where('code', isEqualTo: company.code)
                .orderBy('time', descending: true),
            mapper: (doc) => doc,
            getFn: (doc) => doc.data()['time'],
          )
        : null;

    return CompanyDisclosureBloc2._(company,
        companies: companies,
        user$: user$,
        edinet: edinet,
        disclosure: disclosure);
  }

  void _settlementControllerHandler(String code) {
    this.user$.first.then((user) {
      print(user);
      return FirebaseFirestore.instance.collection('settlements').doc(code).get();
    }).then((doc) {
      if (doc.exists && doc.data != null) {
        print(doc.data);
        print(CompanySettlement.fromDocumentSnapshot(doc));
        this
            ._companySettlement$
            .add(CompanySettlement.fromDocumentSnapshot(doc));
      } else {
        this._companySettlement$.add(null);
      }
    });
  }

  @override
  void dispose() {
    this.edinet.dispose();
    this.disclosure.dispose();
    _companySettlement$.close();
  }
}
