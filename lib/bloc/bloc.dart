import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:bloc_provider/bloc_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Filter;
import 'package:disclosure_app_fl/models/company.dart';
import 'package:disclosure_app_fl/models/disclosure.dart';
import 'package:disclosure_app_fl/models/filter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:disclosure_app_fl/utils/disclosure_filter_helper.dart';
import 'package:disclosure_app_fl/utils/notification_topic_helper.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

final filterStrings = DisclosureFilterHelper.defaultFilterStrings;

final dateFormatter = DateFormat("yyyy-MM-dd");

final Map<String, Comparator<DocumentSnapshot<Map<String, dynamic>>>?>
    comparators = {
  "最新": null,
  "閲覧回数": (a, b) =>
      DisclosureFilterHelper.compareByViewCount(a.data(), b.data()),
};

class AppBloc extends Bloc {
  final path = 'disclosures';
  final _dateController = BehaviorSubject<DateTime>.seeded(DateTime.now());
  final _edinetDateController =
      BehaviorSubject<DateTime>.seeded(DateTime.now());
  final _disclosure$ = BehaviorSubject<List<DocumentSnapshot>>();
  final _filter$ = BehaviorSubject<List<Filter>>();
  final _edinetFilter$ = BehaviorSubject<String>.seeded('');
  final _showOnlyFavorites$ = BehaviorSubject<bool>.seeded(false);
  final _customFilter$ = BehaviorSubject<List<Filter>>.seeded([]);
  final _savedDisclosure$ =
      BehaviorSubject<List<QueryDocumentSnapshot<Map<String, dynamic>>>>();
  final _darkMode$ = BehaviorSubject<Brightness>.seeded(Brightness.light);
  final _setModeBrightness = StreamController<bool>();
  final StreamController<Disclosure> _saveDisclosureController =
      StreamController();
  final _setDisclosureOrder$ = BehaviorSubject<String?>.seeded("最新");

  final StreamController<String> _addCustomFilterController =
      StreamController();
  final StreamController<Filter> _removeCustomFilterController =
      StreamController();
  final _edinetShowOnlyFavoriteController = BehaviorSubject<bool>.seeded(false);

  final StreamController<String> _filterChangeController = StreamController();

  final PublishSubject<int?> _refreshDisclosuresController = PublishSubject();
  final BehaviorSubject<int?> _newDisclosureCountController =
      BehaviorSubject.seeded(0);

  // users
  final _userController = BehaviorSubject<User>();

  // settings
  final BehaviorSubject<Map<String, dynamic>> _setting$ = BehaviorSubject();
  final BehaviorSubject<bool> _hideDailyDisclosure$ = BehaviorSubject();
  final StreamController<bool?> _setVisibleDailyDisclosureController =
      StreamController();

  // favorites
  final BehaviorSubject<List<String>> _favorite$ = BehaviorSubject();
  final BehaviorSubject<List<Company>> _favoriteWithName$ = BehaviorSubject();
  final StreamController<String?> _addFavoriteController = StreamController();
  final StreamController<String?> _removeFavoriteController =
      StreamController();
  final StreamController<String?> _switchFavoriteController =
      StreamController();

  // companyList
  final _filteredCompanies$ = BehaviorSubject<List<Company>>();
  final _companies$ = BehaviorSubject<List<Company>>();
  final _companiesMap$ = BehaviorSubject<Map<String, Company>>();
  final _companiesCodeMap$ = BehaviorSubject<Map<String, Company>>();
  final _codeStrController = BehaviorSubject<String>.seeded('');
  final _storage = FirebaseStorage.instanceFor(bucket: 'gs://disclosure-app-2');

  final _companiesHistory$ = BehaviorSubject<List<Company>>();
  final _addHistory = StreamController<Company>();

  // notifications
  final _notifications$ = BehaviorSubject<List<Company>>();
  final _tagsNotifications$ = BehaviorSubject<List<String>>();
  final _addNotificationController = StreamController<String?>();
  final _removeNotificationController = StreamController<String?>();
  final _switchNotificationController = StreamController<String>();
  final _addTagsNotificationController = StreamController<String>();
  final _removeTagsNotificationController = StreamController<String>();

  ValueStream<List<DocumentSnapshot>> get disclosure$ => _disclosure$.stream;

  Sink<int?> get refreshDisclosures => _refreshDisclosuresController.sink;
  ValueStream<int?> get newDisclosureCount =>
      _newDisclosureCountController.stream;

  Sink<DateTime> get date => _dateController.sink;
  ValueStream<DateTime> get date$ => _dateController.stream;
  ValueStream<List<Company>> get company$ => _companies$.stream;
  ValueStream<Map<String, Company>> get companyMap$ => _companiesMap$.stream;
  ValueStream<Map<String, Company>> get companyCodeMap$ => _companiesCodeMap$.stream;
  Sink<DateTime> get edinetDate => _edinetDateController.sink;
  ValueStream<DateTime> get edinetDate$ => _edinetDateController.stream;
  Sink<String> get addFilter => _filterChangeController.sink;
  ValueStream<User> get user$ => _userController.stream;
  ValueStream<List<Filter>> get filter$ => _filter$.stream;
  ValueStream<String> get edinetFilter$ => _edinetFilter$.stream;
  Sink<String> get edinetFilterController => _edinetFilter$.sink;
  Stream<int> get filterCount$ =>
      _filter$.map((f) => f.where((_f) => _f.isSelected).length);
  ValueStream<List<Filter>> get customFilters$ => _customFilter$.stream;
  Sink<String> get addCustomFilter => _addCustomFilterController.sink;
  Sink<Filter> get removeCustomFilter => _removeCustomFilterController.sink;

  Sink<bool> get setShowOnlyFavorites => _showOnlyFavorites$.sink;
  ValueStream<bool> get showOnlyFavorites$ => _showOnlyFavorites$.stream;

  ValueStream<bool> get edinetShowOnlyFavorite$ =>
      _edinetShowOnlyFavoriteController.stream;
  Sink<bool> get edinetSetShowOnlyFavorite =>
      _edinetShowOnlyFavoriteController.sink;

  ValueStream<Map<String, dynamic>> get settings$ => _setting$.stream;
  Stream<bool> get hideDailyDisclosure$ => _hideDailyDisclosure$.stream;
  Sink<bool?> get setVisibleDailyDisclosure =>
      _setVisibleDailyDisclosureController.sink;

  Sink<String?> get addFavorite => _addFavoriteController.sink;
  Sink<String?> get removeFavorite => _removeFavoriteController.sink;
  Sink<String?> get switchFavorite => _switchFavoriteController.sink;
  ValueStream<List<String>> get favorites$ => _favorite$.stream;
  ValueStream<List<Company>> get favoritesWithName$ =>
      _favoriteWithName$.stream;

  ValueStream<List<Company>> get filteredCompany$ => _filteredCompanies$.stream;
  Sink<String> get changeFilter => _codeStrController.sink;

  ValueStream<List<Company>> get notifications$ => _notifications$.stream;
  ValueStream<List<String>> get tagsNotifications$ =>
      _tagsNotifications$.stream;
  Sink<String?> get addNotification => _addNotificationController.sink;
  Sink<String?> get removeNotification => _removeNotificationController.sink;
  Sink<String> get switchNotification => _switchNotificationController.sink;
  Sink<String> get addTagsNotification => _addTagsNotificationController.sink;
  Sink<String> get removeTagsNotification =>
      _removeTagsNotificationController.sink;

  ValueStream<List<DocumentSnapshot>> get savedDisclosure$ =>
      _savedDisclosure$.stream;
  Sink<Disclosure> get saveDisclosure => _saveDisclosureController.sink;

  ValueStream<List<Company>> get companyHistory$ => _companiesHistory$.stream;
  Sink<Company> get addHistory => _addHistory.sink;

  ValueStream<Brightness> get darkMode$ => _darkMode$.stream;
  Sink<bool> get setModeBrightness => _setModeBrightness.sink;

  ValueStream<String?> get setDisclosureOrder$ => _setDisclosureOrder$.stream;
  Sink<String?> get setDisclosureOrder => _setDisclosureOrder$.sink;

  final _handleFilterChange = (List<Filter> prev, String element, _) {
    prev.firstWhere((filter) => filter.title == element).toggle();
    return prev;
  };
  final _change = PublishSubject<String>();

  AppBloc() {
    final store = FirebaseFirestore.instance;
    store.settings = Settings(persistenceEnabled: false);
    final initialFilters = filterStrings.map((str) => Filter(str)).toList();

    _setting$
        .map<List<String>>((data) {
          print(data);
          return data["tags"]?.cast<String>() ?? [];
        })
        .distinct()
        .doOnEach(print)
        .map((l) => l.map((str) => Filter(str)).toList())
        .pipe(_customFilter$);

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
      FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        "tags": customTag.map((t) => t.title).toList() + [name]
      }, SetOptions(merge: true));
    });

    _removeCustomFilterController.stream.listen((filter) async {
      print('removing custom filter $filter');
      final user = await _userController.first;
      final customTag = await this._customFilter$.first;
      FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        "tags": customTag
            .where((f) => f.title != filter.title)
            .map((t) => t.title)
            .toList()
      }, SetOptions(merge: true));
    });

    final showingFavorite = _showOnlyFavorites$.switchMap((val) {
      if (val) {
        return _favorite$;
      }
      return Stream.value(<String>[]);
    });

    final createDateStream = (int start, int end) {
      final Stream<QuerySnapshot<Map<String, dynamic>>?> _disclosures = store
          .collection(this.path)
          .where('time', isGreaterThanOrEqualTo: start)
          .where('time', isLessThan: end)
          .orderBy('time', descending: true)
          .snapshots()
          .handleError((dynamic error, StackTrace stack) {
            debugPrint("Disclosures stream error: $error");
            FirebaseCrashlytics.instance.recordError(error, stack, fatal: false);
          })
          .share();

      final Stream<QuerySnapshot<Map<String, dynamic>>?> first =
          _disclosures.take(1).startWith(null);
      final Stream<QuerySnapshot<Map<String, dynamic>>?> cont = _disclosures
          .skip(1)
          .sample(_refreshDisclosuresController.stream); //.doOnData(print));

      final Stream<QuerySnapshot<Map<String, dynamic>>?> _disclosures2 =
          first.mergeWith([cont]);

      final disclosureCount = _disclosures
          .skip(1)
          .doOnData((data) => print(data?.docChanges.map((v) => v.type)))
          .map((data) => data?.docChanges
              .where((change) => change.type == DocumentChangeType.added)
              .length);
      final newDisclosureCount = Rx.merge([
        disclosureCount,
        _refreshDisclosuresController.stream.map((_) => null)
      ]).scan((dynamic a, e, _) {
        print([a, e]);
        if (e == null) {
          return 0;
        }
        return a + e;
      }, 0).startWith(0);

      newDisclosureCount.listen((e) {
        print("new disclosure count is " + e.toString());
        _newDisclosureCountController.add(e);
      });

      return Rx.combineLatest5<
              List<Filter>,
              QuerySnapshot<Map<String, dynamic>>?,
              bool,
              List<String>,
              String?,
              List<DocumentSnapshot>>(
          this._filter$,
          _disclosures2,
          _hideDailyDisclosure$,
          showingFavorite,
          _setDisclosureOrder$, (_filters, d, _hideDaily, _favorites, order) {
        print([_filters, d, _hideDaily, _favorites, order]);
        if (d == null) return [];
        final selectedFilterStr = _filters
            .where((filter) => filter.isSelected)
            .map((filter) => filter.title);

        final docs = d.docs
            .where((doc) => DisclosureFilterHelper.matchesFilter(
                  data: doc.data(),
                  selectedFilterTitles: selectedFilterStr,
                  hideDailyDisclosure: _hideDaily,
                  favoriteCompanyCodes: _favorites,
                ))
            .toList();
        if (order != null) {
          final comp = comparators[order];
          if (comp != null) {
            docs.sort(comp);
          }
        }
        return docs;
      });
    };

    Rx.combineLatest2<String, DateTime, List<int>>(
      _userController.map((u) => u.uid).distinct(),
      _dateController,
      (user, date) {
        final _date = DateTime(date.year, date.month, date.day);
        final start = _date.millisecondsSinceEpoch;
        final end = _date.add(Duration(days: 1)).millisecondsSinceEpoch;
        return [start, end];
      },
    ).switchMap((value) {
      final start = value[0];
      final end = value[1];
      return createDateStream(start, end);
    }).pipe(_disclosure$);

    FirebaseAuth.instance
        .userChanges()
        .whereNotNull()
        .pipe(_userController);

    _createSettingStream();

    _createCompanyListStreams();

    _createNotificationStreams();

    _createSavedDisclosureStreams();

    final Stream<bool> br = _setModeBrightness.stream.doOnData((mode) =>
        SharedPreferences.getInstance()
            .then((pref) => pref.setBool('setDarkMode', mode)));

    Rx.concat(<Stream<bool>>[
      Stream.fromFuture(SharedPreferences.getInstance().then((pref) =>
          pref.containsKey('setDarkMode')
              ? pref.getBool('setDarkMode')!
              : true)),
      br
    ])
        .map((m) => m == true ? Brightness.light : Brightness.dark)
        .pipe(_darkMode$);
  }

  void _createSettingStream() {
    final favorites = Set<String?>();

    final _publishFavorites = (List<String?> _favorites) async {
      final user = await _userController.first;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({"favorites": _favorites}, SetOptions(merge: true));
    };

    _setVisibleDailyDisclosureController.stream.listen((visible) async {
      final user = await _userController.first;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        "setting": {"hideDailyDisclosure": visible}
      }, SetOptions(merge: true));
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
        .switchMap((user) => FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots()
            .handleError((dynamic error, StackTrace stack) {
              debugPrint("User settings stream error: $error");
              FirebaseCrashlytics.instance.recordError(error, stack, fatal: false);
            }))
        .map((res) => res.data() ?? {})
        .pipe(_setting$);

    _setting$
        .map<List<String>>((data) => data["favorites"]?.cast<String>() ?? [])
        .pipe(_favorite$);

    _setting$
        .map<bool>((setting) =>
            (setting['setting'] ?? {})['hideDailyDisclosure'] ?? false)
        .pipe(_hideDailyDisclosure$);

    _favorite$.listen((data) {
      favorites.clear();
      favorites.addAll(data);
    });

    Rx.combineLatest2<List<String>, Map<String, Company>, List<Company>>(
      _favorite$,
      _companiesCodeMap$.stream,
      (_favs, _conps) {
        return _favs.map((_fav) {
          // ⚡ Bolt: O(1) map lookup instead of O(N) list search
          return _conps[_fav] ?? Company(_fav, name: '???');
        }).toList();
      },
    ).pipe(_favoriteWithName$);

    final history = _setting$
        .map<List<String>>((data) => data['cp_hist']?.cast<String>() ?? []);

    Rx.combineLatest2<List<String>, Map<String, Company>, List<Company>>(
      history,
      _companiesCodeMap$.stream,
      (_hist, _comps) {
        // print("hist=$_hist, comps=$_comps");
        return _hist
            // ⚡ Bolt: O(1) map lookup instead of O(N) list search
            .map((_h) => _comps[_h] ?? Company(_h, name: '???'))
            .toList();
      },
    ).pipe(_companiesHistory$);

    Rx.concat(<Stream<List<Company>>>[
      _companiesHistory$.take(1),
      _addHistory.stream.map((e) => [e].toList())
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

          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({"cp_hist": comps}, SetOptions(merge: true));
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
          yield await task
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

    // Bolt Optimization: Debounce search input to prevent expensive list filtering and UI re-renders on every keystroke
    Rx.combineLatest2<List<Company>, String, List<Company>>(
      _companies$.stream,
      _codeStrController.stream.debounceTime(const Duration(milliseconds: 300)),
      (data, str) {
        if (str.length < 2) return [];
        final lowerStr = str.toLowerCase();
        final kanaStr = Company.hiraToKana(lowerStr);
        return data.where((d) => d.match(lowerStr, textKana: kanaStr)).take(100).toList();
      },
    ).pipe(_filteredCompanies$);

    _companies$.share().map((companies) {
      return Map.fromEntries(companies.map((c) => MapEntry(c.edinetCode!, c)));
    }).pipe(_companiesMap$);

    _companies$.share().map((companies) {
      // ⚡ Bolt: Provide a map for O(1) company lookups by code.
      // This prevents O(N^2) complexity in stream transformations.
      return Map.fromEntries(
        companies.where((c) => c.code != null).map((c) => MapEntry(c.code!, c))
      );
    }).pipe(_companiesCodeMap$);
  }

  void _createNotificationStreams() {
    final messaging = FirebaseMessaging.instance;

    Set<String> notifications = Set();

    final _notificationString$ = BehaviorSubject<List<String>>();

    messaging
        .getToken()
        .then((token) {
          print(token);
          return http.post(
              Uri.parse(
                  'https://asia-northeast1-disclosure-app.cloudfunctions.net/listTopicsV2'),
              body: json.encode({'IID_TOKEN': token}),
              headers: {'Content-Type': 'application/json'});
        })
        .then((res) {
          if (res.body != '') {
            final data = json.decode(res.body);
            final List<String> topics =
                (data['topics'] as Map<String, dynamic>?)?.keys.toList() ?? [];
            notifications = topics.toSet();
            print('notifications = $notifications');
            return topics;
          } else {
            return [].cast<String>();
          }
        })
        .then((topics) => _notificationString$.add(topics))
        .catchError((err) {
          print(err);
          if (err is SocketException) {
            _notificationString$
                .addError(new SocketException("サーバーとの通信に失敗しました"));
          } else {
            _notificationString$.addError(err);
          }
        });

    _notificationString$.map((notifications) {
      return notifications
          .where(NotificationTopicHelper.isTagTopic)
          .map(NotificationTopicHelper.toTag)
          .toList();
    }).pipe(_tagsNotifications$);

    Rx.combineLatest2<List<String>, Map<String, Company>, List<Company>>(
      _notificationString$,
      _companiesCodeMap$.stream,
      (_topics, _comps) {
        return _topics
            .where(NotificationTopicHelper.isCodeTopic)
            .map(NotificationTopicHelper.toCode)
            .map((_topic) {
          // ⚡ Bolt: O(1) map lookup instead of O(N) list search
          return _comps[_topic] ?? Company(_topic, name: '???');
        }).toList();
      },
    ).pipe(_notifications$);

    this._addNotificationController.stream.listen((_code) {
      if (_code == null) return;
      final code = NotificationTopicHelper.toTopic(_code);
      print('add notification $code');
      messaging.subscribeToTopic(code);
      notifications.add(code);
      _notificationString$.add(notifications.toList());
    });

    this._removeNotificationController.stream.listen((_code) {
      if (_code == null) return;
      final code = NotificationTopicHelper.toTopic(_code);
      print('remove notification $code');
      messaging.unsubscribeFromTopic(code);
      notifications.remove(code);
      _notificationString$.add(notifications.toList());
    });

    this._addTagsNotificationController.stream.listen((_tag) {
      final topic = NotificationTopicHelper.fromTag(_tag);
      print('add notification $topic');
      messaging.subscribeToTopic(topic);
      notifications.add(topic);
      _notificationString$.add(notifications.toList());
    });

    this._removeTagsNotificationController.stream.listen((_code) {
      final topic = NotificationTopicHelper.fromTag(_code);
      print('remove notification $topic');
      messaging.unsubscribeFromTopic(topic);
      notifications.remove(topic);
      _notificationString$.add(notifications.toList());
    });

    this._switchNotificationController.stream.listen((code) {
      if (notifications.contains(NotificationTopicHelper.toCode(code))) {
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
    _favorite$.close();
    _favoriteWithName$.close();
    _filteredCompanies$.close();
    _companies$.close();
    _companiesMap$.close();
    _companiesCodeMap$.close();
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
    _refreshDisclosuresController.close();
    _change.close();
  }

  void _createSavedDisclosureStreams() {
    final collection = (User user) => FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('disclosures');
    _userController
        .switchMap((user) => collection(user)
            .orderBy('add_at', descending: true)
            .snapshots()
            .handleError((dynamic error, StackTrace stack) {
              debugPrint("Saved disclosures stream error: $error");
              FirebaseCrashlytics.instance.recordError(error, stack, fatal: false);
            }))
        .map((snapshot) => snapshot.docs)
        .pipe(_savedDisclosure$);

    _saveDisclosureController.stream.listen((disclosure) async {
      final user = await _userController.first;
      final obj = disclosure.toObject();
      obj['add_at'] = DateTime.now().millisecondsSinceEpoch;
      await collection(user).doc(disclosure.document).set(obj);
    });
  }
}
