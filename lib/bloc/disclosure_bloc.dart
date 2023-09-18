// import 'package:bloc_provider/bloc_provider.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:disclosure_app_fl/bloc/bloc.dart';
// import 'package:disclosure_app_fl/bloc/bloc_util.dart';
// import 'package:disclosure_app_fl/models/company.dart';
// import 'package:disclosure_app_fl/models/disclosure.dart';
// import 'package:disclosure_app_fl/models/filter.dart';
// import 'package:intl/intl.dart';
// import 'package:rxdart/rxdart.dart';

// final dateFormatter = DateFormat("yyyy-MM-dd");

// class EdinetBloc extends Bloc {
//   final path = 'disclosures';

//   final _disclosure$ = BehaviorSubject<List<Disclosure>>();
//   // final _filter$ = BehaviorSubject<String>(seedValue: '');

//   ValueObservable<List<Disclosure>> get disclosure$ => _disclosure$.stream;
//   // ValueObservable<String> get filter$ => _filter$;
//   // Sink<String> get filterController => _filter$.sink;

//   Observable<List<Disclosure>> disclosureStream(AppBloc bloc) {
//     final _disclosures =
//         bloc.user$.switchMap((_) => bloc.date$).switchMap((date) {
//       print("***date*** $date");
//       final start = date.millisecondsSinceEpoch;
//       final end = date.add(Duration(days: 1)).millisecondsSinceEpoch;
//       return Observable(
//         FirebaseFirestore.instance
//             .collection(path)
//             .where('time', isGreaterThanOrEqualTo: start)
//             .where('time', isLessThan: end)
//             .orderBy('time', descending: true)
//             .snapshots(),
//       ).startWith(null);
//     }).map((doc) {
//       return doc?.documents;
//     });

//     final _mappedDisclosures = Observable.combineLatest2<
//         List<DocumentSnapshot>,
//         Map<String, Company>,
//         Iterable<Disclosure>>(_disclosures, bloc.companyMap$, (disclosures, companies) {
//       if (disclosures == null) {
//         return null;
//       }
//       return disclosures.map((snapshot) {
//         final disclosure = Disclosure.fromDocumentSnapshot(snapshot);
//         return disclosure;
//       });
//     });

//     final _favorite$ =
//         Observable.combineLatest2<List<Company>, bool, List<Company>>(
//             bloc.favoritesWithName$, bloc.showOnlyFavorites$,
//             (_favorites, _favoriteOnly) {
//       if (_favoriteOnly == false) {
//         return [];
//       }
//       return _favorites;
//     });

//     return Observable.combineLatest3<Iterable<Disclosure>, List<Filter>, List<Company>,
//             List<Disclosure>>(_mappedDisclosures, bloc.filter$, _favorite$,
//         (disclosures, filters, favorites) {
//       if (disclosures == null) {
//         return null;
//       }
//       return disclosures.where((disclosure) {
//         if (filters == null || filters.length == 0) {
//           return true;
//         }
//         return disclosure.docType == filter;
//       }).where((edinet) {
//         if (favorites.length == 0) {
//           return true;
//         }
//         return Set.of(favorites).intersection(Set.of(edinet.companies)).length >
//             0;
//       }).toList();
//     });
//   }

//   EdinetBloc(AppBloc bloc) {
//     connect(DeferStream(() => disclosureStream(bloc), reusable: true), _disclosure$);
//   }

//   @override
//   void dispose() {
//     _disclosure$.close();
//     // _filter$.close();
//   }
// }
