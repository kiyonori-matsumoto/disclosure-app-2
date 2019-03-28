import 'dart:async';

import 'package:bloc_provider/bloc_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:disclosure_app_fl/bloc/bloc.dart';
import 'package:disclosure_app_fl/models/company.dart';
import 'package:disclosure_app_fl/models/edinet.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

final dateFormatter = DateFormat("yyyy-MM-dd");

class EdinetBloc extends Bloc {
  final path = 'edinets';

  final _edinet$ = BehaviorSubject<List<Edinet>>();
  final _filter$ = BehaviorSubject<String>(seedValue: '');
  final StreamController<bool> _showOnlyFavoriteController = StreamController();

  ValueObservable<List<Edinet>> get edinet$ => _edinet$.stream;
  ValueObservable<String> get filter$ => _filter$;
  Sink<String> get filterController => _filter$.sink;

  EdinetBloc(AppBloc bloc) {
    final _edinets =
        bloc.user$.switchMap((_) => bloc.edinetDate$).switchMap((date) {
      print("***date*** $date");
      final start = dateFormatter.format(date);
      final end = dateFormatter.format(date.add(Duration(days: 1)));
      return Observable(Firestore.instance
              .collection(path)
              .where('seq', isGreaterThanOrEqualTo: start)
              .where('seq', isLessThan: end)
              .orderBy('seq', descending: true)
              .snapshots())
          .startWith(null);
    }).map((doc) {
      return doc?.documents;
    });

    final _mappedEdinets = Observable.combineLatest2<
        List<DocumentSnapshot>,
        Map<String, Company>,
        Iterable<Edinet>>(_edinets, bloc.companyMap$, (edinets, companies) {
      if (edinets == null) {
        return null;
      }
      return edinets.map((snapshot) {
        final edinet = Edinet.fromDocumentSnapshot(snapshot);
        edinet.fillCompanyName(companies);
        return edinet;
      });
    });

    Observable.combineLatest2<Iterable<Edinet>, String, List<Edinet>>(
        _mappedEdinets, _filter$, (edinets, filter) {
      if (edinets == null) {
        return null;
      }
      return edinets.where((edinet) {
        if (filter == null || filter == '') {
          return true;
        }
        return edinet.docType == filter;
      }).toList();
    }).pipe(_edinet$);
  }

  @override
  void dispose() {
    _edinet$.close();
    _filter$.close();
    _showOnlyFavoriteController.close();
  }
}
