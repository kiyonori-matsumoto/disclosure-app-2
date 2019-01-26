import 'dart:async';

import 'package:bloc_provider/bloc_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

class CompanyDisclosureBloc extends Bloc {
  final path = 'disclosures';
  final StreamController<String> _reloadController = StreamController();
  final StreamController _loadNextController = StreamController();
  final BehaviorSubject<List<DocumentSnapshot>> _disclosuresController =
      BehaviorSubject();

  Sink<String> get reload => _reloadController.sink;
  Sink get loadNext => _loadNextController.sink;
  ValueObservable get disclosures$ => _disclosuresController.stream;

  CompanyDisclosureBloc() {
    List<DocumentSnapshot> items = [];
    String code = "";

    _reloadController.stream.forEach((_code) async {
      items = [];
      code = _code;
      _disclosuresController.add(items);

      final data = await Firestore.instance
          .collection(path)
          .where('code', isEqualTo: code)
          .orderBy('time', descending: true)
          .limit(20)
          .getDocuments();

      items.addAll(data.documents);

      _disclosuresController.add(items);
    });

    _loadNextController.stream.forEach((_) async {
      final data = await Firestore.instance
          .collection(path)
          .where('code', isEqualTo: code)
          .orderBy('time', descending: true)
          .startAfter(items)
          .limit(20)
          .getDocuments();

      items.addAll(data.documents);

      _disclosuresController.add(items);
    });
  }

  @override
  void dispose() {
    _reloadController.close();
    _loadNextController.close();
    _disclosuresController.close();
  }
}
