import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bloc_provider/bloc_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:disclosure_app_fl/models/company.dart';
import 'package:disclosure_app_fl/models/favorite.dart';
import 'package:disclosure_app_fl/models/filter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';

final filterStrings = ["株主優待", "決算", "配当", "業績予想", "新株", "自己株式", "日々の開示事項"];

class AppBloc extends Bloc {
  final path = 'disclosures';
  final _dateController = BehaviorSubject<DateTime>(seedValue: DateTime.now());
  final _disclosureController =
      BehaviorSubject<List<DocumentSnapshot>>(seedValue: []);
  final _filterController = BehaviorSubject<List<Filter>>();
  final StreamController<String> _filterChangeController = StreamController();

  // users
  final _userController = BehaviorSubject<FirebaseUser>();

  // settings
  final BehaviorSubject<Map<String, dynamic>> _setting$ = BehaviorSubject();
  final BehaviorSubject<bool> _hideDailyDisclosure$ = BehaviorSubject();
  final StreamController<bool> _setVisibleDailyDisclosureController =
      StreamController();

  // favorites
  final BehaviorSubject<List<String>> _favorit$ = BehaviorSubject();
  final BehaviorSubject<List<Favorite>> _favoritWithName$ = BehaviorSubject();
  final StreamController<String> _addFavoriteController = StreamController();
  final StreamController<String> _removeFavoriteController = StreamController();
  final StreamController<String> _switchFavoriteController = StreamController();

  // companyList
  final _filtetrdCompanies$ = BehaviorSubject<List<Company>>();
  final _companies$ = BehaviorSubject<List<Company>>();
  final _codeStrController = BehaviorSubject<String>(seedValue: '');
  final _storage = FirebaseStorage.instance;

  // notifications
  final _notifications$ = BehaviorSubject<List<Company>>();
  final _addNotificationController = StreamController<String>();

  ValueObservable<List<DocumentSnapshot>> get disclosure$ =>
      _disclosureController.stream;
  Sink<DateTime> get date => _dateController.sink;
  Sink<String> get addFilter => _filterChangeController.sink;
  ValueObservable<FirebaseUser> get user$ => _userController.stream;
  ValueObservable<List<Filter>> get filter$ => _filterController.stream;

  ValueObservable<Map<String, dynamic>> get settings$ => _setting$.stream;
  Observable<bool> get hideDailyDisclosure$ => _hideDailyDisclosure$.stream;
  Sink<bool> get setVisibleDailyDisclosure =>
      _setVisibleDailyDisclosureController.sink;

  Sink<String> get addFavorite => _addFavoriteController.sink;
  Sink<String> get removeFavorite => _removeFavoriteController.sink;
  Sink<String> get switchFavorite => _switchFavoriteController.sink;
  ValueObservable<List<String>> get favorites$ => _favorit$.stream;
  ValueObservable<List<Favorite>> get favoritesWithName$ =>
      _favoritWithName$.stream;

  ValueObservable<List<Company>> get filteredCompany$ =>
      _filtetrdCompanies$.stream;
  Sink<String> get changeFilter => _codeStrController.sink;

  ValueObservable<List<Company>> get notifications$ => _notifications$.stream;
  Sink<String> get addNotification => _addNotificationController.sink;

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

    final store$ = _userController
        .share()
        .switchMap((_) => _dateController)
        .flatMap((date) {
      final _date = DateTime(date.year, date.month, date.day);
      final start = _date.millisecondsSinceEpoch;
      final end = _date.add(Duration(days: 1)).millisecondsSinceEpoch;
      return Observable(store
              .collection(this.path)
              .where('time', isGreaterThanOrEqualTo: start)
              .where('time', isLessThan: end)
              .orderBy('time', descending: true)
              .snapshots())
          .startWith(null);
    });

    Observable.combineLatest3<List<Filter>, QuerySnapshot, bool,
            List<DocumentSnapshot>>(filters$, store$, _hideDailyDisclosure$,
        (_filters, d, _hideDaily) {
      print(_filters);
      if (d == null) return null;
      final isNotFilterSelected =
          _filters.where((filter) => filter.isSelected).length == 0;

      final selectedFilterStr = _filters
          .where((filter) => filter.isSelected)
          .map((filter) => filter.title);

      return d.documents
          .where((doc) =>
              !_hideDaily || (doc.data['tags'] ?? {})['日々の開示事項'] != true)
          .where((doc) =>
              isNotFilterSelected ||
              selectedFilterStr.any((str) => doc.data['tags'][str] == true))
          .toList();
    }).pipe(_disclosureController);

    filters$.pipe(_filterController);

    FirebaseAuth.instance.onAuthStateChanged
        .where((u) => u != null)
        .pipe(_userController);

    _createSettingStream();

    _createCompanyListStreams();

    _createNotificationStreams();
  }

  void _createSettingStream() {
    final favorites = Set<String>();

    final _publishFavorites = (List<String> _favorites) async {
      final user = await _userController.first;
      if (user == null) return;
      await Firestore.instance
          .collection('users')
          .document(user.uid)
          .setData({"favorites": _favorites}, merge: true);
    };

    _setVisibleDailyDisclosureController.stream.listen((visible) async {
      final user = await _userController.first;
      if (user == null) return;
      await Firestore.instance.collection('users').document(user.uid).setData({
        "setting": {"hideDailyDisclosure": visible}
      }, merge: true);
    });

    _addFavoriteController.stream.listen((code) {
      favorites.add(code);
      _publishFavorites(favorites.toList());
    });

    _removeFavoriteController.stream.listen((code) {
      favorites.remove(code);
      _publishFavorites(favorites.toList());
    });

    _switchFavoriteController.stream.listen((code) {
      if (favorites.contains(code)) {
        favorites.remove(code);
      } else {
        favorites.add(code);
      }
      _publishFavorites(favorites.toList());
    });

    _userController
        .share()
        .switchMap((user) => Firestore.instance
            .collection('users')
            .document(user.uid)
            .snapshots())
        .map((res) => res.data)
        .pipe(_setting$);

    _setting$
        .map<List<String>>(
            (data) => data != null ? data["favorites"].cast<String>() : [])
        .pipe(_favorit$);

    _setting$
        .map<bool>((setting) =>
            (setting['setting'] ?? {})['hideDailyDisclosure'] ?? false)
        .pipe(_hideDailyDisclosure$);

    _favorit$.listen((data) {
      favorites.clear();
      favorites.addAll(data);
    });

    Observable.combineLatest2<List<String>, List<Company>, List<Favorite>>(
      _favorit$,
      _companies$.stream,
      (_favs, _conps) {
        return _favs.map((_fav) {
          final _name = _conps
              .firstWhere((_conp) => _conp.code == '${_fav}0',
                  orElse: () => Company(_fav, name: '???'))
              .name;
          return Favorite(_name, _fav);
        }).toList();
      },
    ).pipe(_favoritWithName$);
  }

  void _createCompanyListStreams() {
    Future<List<dynamic>> _handleOpenFile() async {
      final _appDir = await getApplicationDocumentsDirectory();
      final companyJsonFile = File(_appDir.path + "/companies.json");
      if (companyJsonFile.existsSync() &&
          companyJsonFile
              .lastModifiedSync()
              .isAfter(DateTime.now().subtract(Duration(days: 7)))) {
        // file exists and latest, so not download this file
        print('use current file');
        return companyJsonFile.readAsString().then((str) => jsonDecode(str));
      } else {
        print('download file from storage');
        final ref = _storage.ref().child('companies.json');
        final task = ref.writeToFile(companyJsonFile);
        return task.future
            .then((snapshot) => companyJsonFile.readAsString())
            .then((str) => jsonDecode(str));
      }
    }

    Observable.fromFuture(_handleOpenFile())
        .map((data) =>
            data.map((d) => Company(d['code'], name: d['name'])).toList())
        .pipe(_companies$);

    Observable.combineLatest2<List<dynamic>, String, List<Company>>(
      _companies$.stream,
      _codeStrController.stream,
      (data, str) {
        if (str.length < 2) return [];
        return data.where((d) => d.match(str)).toList();
      },
    ).pipe(_filtetrdCompanies$);
  }

  void _createNotificationStreams() {
    final messaging = FirebaseMessaging();

    final _toTopic = (code) => "code_$code";

    final _notificationString$ = BehaviorSubject<List<String>>();

    messaging.getToken().then((token) {
      print(token);
      return http.post(
          'https://us-central1-disclosure-app.cloudfunctions.net/listTopics',
          body: json.encode({'IID_TOKEN': token}),
          headers: {'Content-Type': 'application/json'});
    }).then((res) {
      if (res.body != '') {
        final data = json.decode(res.body);
        final List<String> topics = (data['topics'] as Map<String, dynamic>)
                .keys
                .map((key) => _toCode(key))
                .toList() ??
            [];
        return topics;
      } else {
        return [].cast<String>();
      }
    }).then((topics) => _notificationString$.add(topics));

    Observable.combineLatest2<List<String>, List<Company>, List<Company>>(
      _notificationString$,
      _companies$.stream,
      (_topics, _comps) {
        print('notification combinelatest2');
        return _topics.map((_topic) {
          return _comps.firstWhere((_conp) => _conp.code == '${_topic}0',
              orElse: () => Company(_topic, name: '???'));
        }).toList();
      },
    ).pipe(_notifications$);

    this._addNotificationController.stream.listen((code) {
      print('add notification controller $code');
      messaging.subscribeToTopic(_toTopic(code));
    });
  }

  @override
  void dispose() {
    _dateController.close();
    _disclosureController.close();
    _userController.close();
    _filterChangeController.close();
    _filterController.close();
    _addFavoriteController.close();
    _removeFavoriteController.close();
    _switchFavoriteController.close();
    _setting$.close();
    _hideDailyDisclosure$.close();
    _setVisibleDailyDisclosureController.close();
    _favorit$.close();
    _favoritWithName$.close();
    _filtetrdCompanies$.close();
    _companies$.close();
    _codeStrController.close();
    _notifications$.close();
    _addNotificationController.close();
  }

  String _toCode(String topic) {
    return topic.replaceAll(RegExp(r'^code_'), '');
  }
}
