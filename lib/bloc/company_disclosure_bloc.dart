import 'dart:async';

import 'package:bloc_provider/bloc_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:disclosure_app_fl/models/company-settlement.dart';
import 'package:rxdart/rxdart.dart';

class CompanyDisclosureBloc extends Bloc {
  final path = 'disclosures';
  final StreamController<String> _reloadController = StreamController();
  final StreamController _loadNextController = StreamController();
  final BehaviorSubject<List<DocumentSnapshot>> _disclosures$ =
      BehaviorSubject();
  final BehaviorSubject<bool> _isLoadingController =
      BehaviorSubject(seedValue: true);

  final BehaviorSubject<CompanySettlement> _companySettlement$ =
      BehaviorSubject();

  Sink<String> get reload => _reloadController.sink;
  Sink get loadNext => _loadNextController.sink;
  ValueObservable<List<DocumentSnapshot>> get disclosures$ =>
      _disclosures$.stream;
  ValueObservable<bool> get isLoading$ => _isLoadingController.stream;
  ValueObservable<CompanySettlement> get companySettlement$ =>
      _companySettlement$.stream;

  String code = "";
  List<DocumentSnapshot> _items = [];
  bool _isLoading = false;
  bool _isLastDocument = false;

  CompanyDisclosureBloc(this.code) {
    _reloadController.stream.forEach(_reloadControllerHandler);
    _loadNextController.stream.forEach(_loadNextControllerHandler);
    _settlementControllerHandler(this.code);
    _reloadController.add(code);
  }

  void _settlementControllerHandler(String code) {
    Firestore.instance
        .collection('dev-companies')
        .document(code)
        .get()
        .then((doc) {
      if (doc.exists && doc.data != null && doc.data['settlement'] != null) {
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

  void _loadNextControllerHandler(_) async {
    if (_isLoading || _isLastDocument) return;
    _isLoading = true;
    _isLoadingController.add(true);
    try {
      final data = await Firestore.instance
          .collection(path)
          .where('code', isEqualTo: code)
          .orderBy('time', descending: true)
          .startAfter([_items.last.data['time']])
          .limit(20)
          .getDocuments();
      _items.addAll(data.documents);
      print(data.documents.last.data);

      _disclosures$.add(_items);
    } on StateError catch (e) {
      _isLastDocument = true;
    } finally {
      _isLoading = false;
      _isLoadingController.add(false);
    }
  }

  void _reloadControllerHandler(_code) async {
    _items = [];
    _isLastDocument = false;
    _isLoading = true;
    _isLoadingController.add(true);
    try {
      // code = _code;
      _disclosures$.add(null);

      final data = await Firestore.instance
          .collection(path)
          .where('code', isEqualTo: code)
          .orderBy('time', descending: true)
          .limit(20)
          .getDocuments();

      _items.addAll(data.documents);

      _disclosures$.add(_items);
    } finally {
      _isLoading = false;
      _isLoadingController.add(false);
    }
  }

  @override
  void dispose() {
    _reloadController.close();
    _loadNextController.close();
    _disclosures$.close();
    _isLoadingController.close();
    _companySettlement$.close();
  }
}
