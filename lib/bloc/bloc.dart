import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:bloc_provider/bloc_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:disclosure_app_fl/models/company.dart';
import 'package:disclosure_app_fl/models/disclosure.dart';
import 'package:disclosure_app_fl/models/filter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

final filterStrings = ["株主優待", "決算", "配当", "業績予想", "新株", "自己株式", "日々の開示事項"];

final dateFormatter = DateFormat("yyyy-MM-dd");

final Map<String, Comparator<DocumentSnapshot>> comparators = {
  "最新": null,
  "閲覧回数": (a, b) =>
      (b.data['view_count'] ?? 0).compareTo(a.data['view_count'] ?? 0),
};

class AppBloc extends Bloc {
  final path = 'disclosures';
  final _dateController = BehaviorSubject<DateTime>(seedValue: DateTime.now());
  final _edinetDateController =
      BehaviorSubject<DateTime>(seedValue: DateTime.now());
  final _disclosure$ = BehaviorSubject<List<DocumentSnapshot>>();
  final _filter$ = BehaviorSubject<List<Filter>>();
  final _edinetFilter$ = BehaviorSubject<String>(seedValue: '');
  final _showOnlyFavorites$ = BehaviorSubject<bool>(seedValue: false);
  final _customFilter$ = BehaviorSubject<List<Filter>>(seedValue: []);
  final _savedDisclosure$ = BehaviorSubject<List<DocumentSnapshot>>();
  final _darkMode$ = BehaviorSubject<Brightness>(seedValue: Brightness.light);
  final _setModeBrightness = StreamController<bool>();
  final StreamController<Disclosure> _saveDisclosureController =
      StreamController();
  final _setDisclosureOrder$ = BehaviorSubject<String>(seedValue: "最新");

  final StreamController<String> _addCustomFilterController =
      StreamController();
  final StreamController<Filter> _removeCustomFilterController =
      StreamController();
  final _edinetShowOnlyFavoriteController =
      BehaviorSubject<bool>(seedValue: false);

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
  final BehaviorSubject<List<Company>> _favoritWithName$ = BehaviorSubject();
  final StreamController<String> _addFavoriteController = StreamController();
  final StreamController<String> _removeFavoriteController = StreamController();
  final StreamController<String> _switchFavoriteController = StreamController();

  // companyList
  final _filtetrdCompanies$ = BehaviorSubject<List<Company>>();
  final _companies$ = BehaviorSubject<List<Company>>();
  final _companiesMap$ = BehaviorSubject<Map<String, Company>>();
  final _codeStrController = BehaviorSubject<String>(seedValue: '');
  final _storage = FirebaseStorage(storageBucket: 'gs://disclosure-app-2');

  final _companiesHistory$ = BehaviorSubject<List<Company>>();
  final _addHistory = StreamController<Company>();

  // notifications
  final _notifications$ = BehaviorSubject<List<Company>>();
  final _tagsNotifications$ = BehaviorSubject<List<String>>();
  final _addNotificationController = StreamController<String>();
  final _removeNotificationController = StreamController<String>();
  final _switchNotificationController = StreamController<String>();
  final _addTagsNotificationController = StreamController<String>();
  final _removeTagsNotificationController = StreamController<String>();

  ValueObservable<List<DocumentSnapshot>> get disclosure$ =>
      _disclosure$.stream;

  Sink<DateTime> get date => _dateController.sink;
  ValueObservable<DateTime> get date$ => _dateController.stream;
  ValueObservable<List<Company>> get company$ => _companies$.stream;
  ValueObservable<Map<String, Company>> get companyMap$ =>
      _companiesMap$.stream;
  Sink<DateTime> get edinetDate => _edinetDateController.sink;
  ValueObservable<DateTime> get edinetDate$ => _edinetDateController.stream;
  Sink<String> get addFilter => _filterChangeController.sink;
  ValueObservable<FirebaseUser> get user$ => _userController.stream;
  ValueObservable<List<Filter>> get filter$ => _filter$.stream;
  ValueObservable<String> get edinetFilter$ => _edinetFilter$.stream;
  Sink<String> get edintFilterController => _edinetFilter$.sink;
  Observable<int> get filterCount$ =>
      _filter$.map((f) => f.where((_f) => _f.isSelected).length);
  ValueObservable<List<Filter>> get customFilters$ => _customFilter$.stream;
  Sink<String> get addCustomFilter => _addCustomFilterController.sink;
  Sink<Filter> get removeCustomFilter => _removeCustomFilterController.sink;

  Sink<bool> get setShowOnlyFavorites => _showOnlyFavorites$.sink;
  ValueObservable<bool> get showOnlyFavorites$ => _showOnlyFavorites$.stream;

  ValueObservable<bool> get edinetShowOnlyFavorite$ =>
      _edinetShowOnlyFavoriteController.stream;
  Sink<bool> get edinetSetShowOnlyFavorite =>
      _edinetShowOnlyFavoriteController.sink;

  ValueObservable<Map<String, dynamic>> get settings$ => _setting$.stream;
  Observable<bool> get hideDailyDisclosure$ => _hideDailyDisclosure$.stream;
  Sink<bool> get setVisibleDailyDisclosure =>
      _setVisibleDailyDisclosureController.sink;

  Sink<String> get addFavorite => _addFavoriteController.sink;
  Sink<String> get removeFavorite => _removeFavoriteController.sink;
  Sink<String> get switchFavorite => _switchFavoriteController.sink;
  ValueObservable<List<String>> get favorites$ => _favorit$.stream;
  ValueObservable<List<Company>> get favoritesWithName$ =>
      _favoritWithName$.stream;

  ValueObservable<List<Company>> get filteredCompany$ =>
      _filtetrdCompanies$.stream;
  Sink<String> get changeFilter => _codeStrController.sink;

  ValueObservable<List<Company>> get notifications$ => _notifications$.stream;
  ValueObservable<List<String>> get tagsNotifications$ =>
      _tagsNotifications$.stream;
  Sink<String> get addNotification => _addNotificationController.sink;
  Sink<String> get removeNotification => _removeNotificationController.sink;
  Sink<String> get switchNotification => _switchNotificationController.sink;
  Sink<String> get addTagsNotification => _addTagsNotificationController.sink;
  Sink<String> get removeTagsNotification =>
      _removeTagsNotificationController.sink;

  ValueObservable<List<DocumentSnapshot>> get savedDisclosure$ =>
      _savedDisclosure$.stream;
  Sink<Disclosure> get saveDisclosure => _saveDisclosureController.sink;

  ValueObservable<List<Company>> get companyHistory$ =>
      _companiesHistory$.stream;
  Sink<Company> get addHistory => _addHistory.sink;

  ValueObservable<Brightness> get darkMode$ => _darkMode$.stream;
  Sink<bool> get setModeBrightness => _setModeBrightness.sink;

  ValueObservable<String> get setDisclosureOrder$ =>
      _setDisclosureOrder$.stream;
  Sink<String> get setDisclosureOrder => _setDisclosureOrder$.sink;

  final _handleFilterChange = (List<Filter> prev, String element, _) {
    prev.firstWhere((filter) => filter.title == element).toggle();
    return prev;
  };

  AppBloc() {
    final store = Firestore.instance;
    store.settings(persistenceEnabled: false);
    final initialFilters = filterStrings.map((str) => Filter(str)).toList();

    _setting$
        .map<List<String>>((data) {
          print(data);
          return data != null ? data["tags"]?.cast<String>() ?? [] : [];
        })
        .distinct()
        .doOnEach(print)
        .map((l) => l.map((str) => Filter(str)).toList())
        .pipe(_customFilter$);

    final _change = PublishSubject<String>();
    _filterChangeController.stream.pipe(_change.sink);

    _customFilter$
        .map((v) => initialFilters + v)
        .doOnEach(print)
        .switchMap((list) => _change
            .scan<List<Filter>>(_handleFilterChange, list)
            .startWith(list))
        .pipe(_filter$);

    // _customFilter$.add([]);

    _addCustomFilterController.stream.listen((name) async {
      final user = await _userController.first;
      final customTag = await this._customFilter$.first;
      Firestore.instance.collection('users').document(user.uid).setData({
        "tags": customTag.map((t) => t.title).toList() + [name]
      }, merge: true);
    });

    _removeCustomFilterController.stream.listen((filter) async {
      print('removing custom filter $filter');
      final user = await _userController.first;
      final customTag = await this._customFilter$.first;
      Firestore.instance.collection('users').document(user.uid).setData({
        "tags": customTag
            .where((f) => f.title != filter.title)
            .map((t) => t.title)
            .toList()
      }, merge: true);
    });

    // _filter$
    //     .map((filters) => filters.where((f) => f.isCustom).toList())
    //     .pipe(_customFilter$);

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

    final showingFavorite = _showOnlyFavorites$.switchMap((val) {
      if (val) {
        return _favorit$;
      }
      return Observable.just(<String>[]);
    });

    Observable.combineLatest5<List<Filter>, QuerySnapshot, bool, List<String>,
            String, List<DocumentSnapshot>>(
        this._filter$,
        store$,
        _hideDailyDisclosure$,
        showingFavorite,
        _setDisclosureOrder$, (_filters, d, _hideDaily, _favorites, order) {
      print("combinelatest3 $_filters , $d , $_hideDaily");
      if (d == null) return null;
      final isNotFilterSelected =
          _filters.where((filter) => filter.isSelected).length == 0;

      final selectedFilterStr = _filters
          .where((filter) => filter.isSelected)
          .map((filter) => filter.title);

      final docs = d.documents
          .where((doc) =>
              !_hideDaily || (doc.data['tags'] ?? {})['日々の開示事項'] != true)
          .where((doc) =>
              isNotFilterSelected ||
              selectedFilterStr
                  .any((str) => (doc.data['tags'] ?? {})[str] != null))
          .where((doc) => _favorites.length == 0
              ? true
              : _favorites.contains(doc.data['code']))
          .toList();
      if (order != null) {
        final comp = comparators[order];
        if (comp != null) {
          docs.sort(comp);
        }
      }
      return docs;
    }).pipe(_disclosure$);

    FirebaseAuth.instance.onAuthStateChanged
        .where((u) => u != null)
        .pipe(_userController);

    _createSettingStream();

    _createCompanyListStreams();

    _createNotificationStreams();

    _createSavedDisclosureStreams();

    final br = Observable(_setModeBrightness.stream).doOnData((mode) =>
        SharedPreferences.getInstance()
            .then((pref) => pref.setBool('setDarkMode', mode)));

    Observable.concat(<Stream<bool>>[
      Observable.fromFuture(SharedPreferences.getInstance().then((pref) =>
          pref.containsKey('setDarkMode')
              ? pref.getBool('setDarkMode')
              : true)),
      br
    ])
        .map((m) => m == true ? Brightness.light : Brightness.dark)
        .pipe(_darkMode$);
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
      _addNotificationController.add(code);
      _publishFavorites(favorites.toList());
    });

    _removeFavoriteController.stream.listen((code) {
      favorites.remove(code);
      _removeNotificationController.add(code);
      _publishFavorites(favorites.toList());
    });

    _switchFavoriteController.stream.listen((code) {
      if (favorites.contains(code)) {
        favorites.remove(code);
        _removeNotificationController.add(code);
      } else {
        favorites.add(code);
        _addNotificationController.add(code);
      }
      _publishFavorites(favorites.toList());
    });

    _userController
        .share()
        .switchMap((user) => Firestore.instance
            .collection('users')
            .document(user.uid)
            .snapshots())
        .map((res) => res.data ?? {})
        .pipe(_setting$);

    _setting$
        .map<List<String>>((data) =>
            data != null ? data["favorites"]?.cast<String>() ?? [] : [])
        .pipe(_favorit$);

    _setting$
        .map<bool>((setting) =>
            (setting['setting'] ?? {})['hideDailyDisclosure'] ?? false)
        .pipe(_hideDailyDisclosure$);

    _favorit$.listen((data) {
      favorites.clear();
      favorites.addAll(data);
    });

    Observable.combineLatest2<List<String>, List<Company>, List<Company>>(
      _favorit$,
      _companies$.stream,
      (_favs, _conps) {
        return _favs.map((_fav) {
          return _conps.firstWhere((_conp) => _conp.code == _fav,
              orElse: () => Company(_fav, name: '???'));
        }).toList();
      },
    ).pipe(_favoritWithName$);

    final history = _setting$.map<List<String>>(
        (data) => data != null ? data['cp_hist']?.cast<String>() ?? [] : []);

    Observable.combineLatest2<List<String>, List<Company>, List<Company>>(
      history,
      _companies$.stream,
      (_hist, _comps) {
        // print("hist=$_hist, comps=$_comps");
        return _hist
            .map((_h) => _comps.firstWhere((_c) => _c.code == _h,
                orElse: () => Company(_h, name: '???')))
            .toList();
      },
    ).pipe(_companiesHistory$);

    Observable.concat(<Stream<List<Company>>>[
      _companiesHistory$.take(1),
      Observable(_addHistory.stream).map((e) => [e].toList())
    ])
        .scan<List<Company>>(
          (a, e, i) =>
              (e + a.where((_a) => !e.contains(_a)).toList()).take(20).toList(),
          [],
        )
        .doOnData((data) => print("******$data*******"))
        .skip(1)
        .map((e) => e.map((_e) => _e.code).toList())
        .forEach((comps) async {
          final user = await _userController.first;
          if (user == null) return;
          await Firestore.instance
              .collection('users')
              .document(user.uid)
              .setData({"cp_hist": comps}, merge: true);
        });
  }

  void _createCompanyListStreams() {
    Stream<List<dynamic>> _handleOpenFile() async* {
      final _appDir = await getApplicationDocumentsDirectory();
      final companyJsonFile = File(_appDir.path + "/companies.json");
      final exists = companyJsonFile.existsSync();
      try {
        if (exists) {
          print('send current file');
          yield await companyJsonFile
              .readAsString()
              .then((str) => jsonDecode(str));
        }
        if (!(exists &&
            companyJsonFile
                .lastModifiedSync()
                .isAfter(DateTime.now().subtract(Duration(seconds: 1))))) {
          print('download file from storage');

          final ref = _storage.ref().child('companies.json');
          final task = ref.writeToFile(companyJsonFile);
          yield await task.future
              .then((snapshot) => companyJsonFile.readAsString())
              .then((str) => jsonDecode(str));
        }
      } catch (e) {
        // エラー発生時はファイルを削除する
        companyJsonFile.deleteSync();
        throw (e);
      }
    }

    _userController
        .switchMap((user) => _handleOpenFile())
        .map((data) => data
            .map((d) => Company(
                  (d['code'] as String).substring(0, 4),
                  name: d['name'],
                  edinetCode: d['edinetCode'],
                  nameKana: d['nameKana'],
                ))
            .toList())
        .pipe(_companies$);

    Observable.combineLatest2<List<Company>, String, List<Company>>(
      _companies$.stream,
      _codeStrController.stream,
      (data, str) {
        if (str.length < 2) return [];
        final lowerStr = str.toLowerCase();
        return data.where((d) => d.match(lowerStr)).take(100).toList();
      },
    ).pipe(_filtetrdCompanies$);

    _companies$.share().map((companies) {
      return Map.fromEntries(companies.map((c) => MapEntry(c.edinetCode, c)));
    }).pipe(_companiesMap$);
  }

  void _createNotificationStreams() {
    final messaging = FirebaseMessaging();

    Set<String> notifications = Set();

    final _toTopic = (code) => "code_$code";

    final _notificationString$ = BehaviorSubject<List<String>>();

    messaging
        .getToken()
        .then((token) {
          print(token);
          return http.post(
              'https://us-central1-disclosure-app.cloudfunctions.net/listTopics',
              body: json.encode({'IID_TOKEN': token}),
              headers: {'Content-Type': 'application/json'});
        })
        .then((res) {
          if (res.body != '') {
            final data = json.decode(res.body);
            final List<String> topics =
                (data['topics'] as Map<String, dynamic>)?.keys?.toList() ?? [];
            notifications = topics.toSet();
            print('notifications = $notifications');
            return topics;
          } else {
            return [].cast<String>();
          }
        })
        .then((topics) => _notificationString$.add(topics))
        .catchError(_notificationString$.addError);

    _notificationString$.map((notifications) {
      return notifications
          .where((key) => key.startsWith(('tags_')))
          .map((key) => _toTag(key))
          .toList();
    }).pipe(_tagsNotifications$);

    Observable.combineLatest2<List<String>, List<Company>, List<Company>>(
      _notificationString$,
      _companies$.stream,
      (_topics, _comps) {
        return _topics
            .where((key) => key.startsWith('code_'))
            .map((key) => _toCode(key))
            .map((_topic) {
          return _comps.firstWhere((_conp) => _conp.code == _topic,
              orElse: () => Company(_topic, name: '???'));
        }).toList();
      },
    ).pipe(_notifications$);

    this._addNotificationController.stream.listen((_code) {
      final code = _toTopic(_code);
      print('add notification $code');
      messaging.subscribeToTopic(code);
      notifications.add(code);
      _notificationString$.add(notifications.toList());
    });

    this._removeNotificationController.stream.listen((_code) {
      final code = _toTopic(_code);
      print('remove notification $code');
      messaging.unsubscribeFromTopic(code);
      notifications.remove(code);
      _notificationString$.add(notifications.toList());
    });

    this._addTagsNotificationController.stream.listen((_tag) {
      final topic = _fromTag(_tag);
      print('add notification $topic');
      messaging.subscribeToTopic(topic);
      notifications.add(topic);
      _notificationString$.add(notifications.toList());
    });

    this._removeTagsNotificationController.stream.listen((_code) {
      final topic = _fromTag(_code);
      print('remove notification $topic');
      messaging.unsubscribeFromTopic(topic);
      notifications.remove(topic);
      _notificationString$.add(notifications.toList());
    });

    this._switchNotificationController.stream.listen((code) {
      if (notifications.contains(_toCode(code))) {
        this._removeNotificationController.add(code);
      } else {
        this._addNotificationController.add(code);
      }
    });
  }

  @override
  void dispose() {
    _dateController.close();
    _disclosure$.close();
    _userController.close();
    _filterChangeController.close();
    _addCustomFilterController.close();
    _removeCustomFilterController.close();
    _filter$.close();
    _edinetFilter$.close();
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
    _companiesMap$.close();
    _codeStrController.close();
    _notifications$.close();
    _tagsNotifications$.close();
    _addNotificationController.close();
    _removeNotificationController.close();
    _switchNotificationController.close();
    _addTagsNotificationController.close();
    _removeTagsNotificationController.close();
    _customFilter$.close();
    _savedDisclosure$.close();
    _saveDisclosureController.close();
    _showOnlyFavorites$.close();
    _edinetShowOnlyFavoriteController.close();
    _edinetDateController.close();
    _darkMode$.close();
    _setModeBrightness.close();
    _setDisclosureOrder$.close();
    _companiesHistory$.close();
    _addHistory.close();
  }

  String _toCode(String topic) {
    return topic.replaceAll(RegExp(r'^code_'), '');
  }

  Codec<String, String> stringToBase64Url = utf8.fuse(base64Url);
  String _toTag(String key) {
    return stringToBase64Url.decode(key.replaceAll(RegExp(r'^tags_'), ''));
  }

  String _fromTag(String key) {
    return "tags_${stringToBase64Url.encode(key)}";
  }

  void _createSavedDisclosureStreams() {
    final collection = (FirebaseUser user) => Firestore.instance
        .collection('users')
        .document(user.uid)
        .collection('disclosures');
    _userController
        .switchMap((user) =>
            collection(user).orderBy('add_at', descending: true).snapshots())
        .map((snapshot) => snapshot.documents)
        .pipe(_savedDisclosure$);

    _saveDisclosureController.stream.listen((disclosure) async {
      final user = await _userController.first;
      final obj = disclosure.toObject();
      obj['add_at'] = DateTime.now().millisecondsSinceEpoch;
      await collection(user).document(disclosure.document).setData(obj);
    });
  }
}
