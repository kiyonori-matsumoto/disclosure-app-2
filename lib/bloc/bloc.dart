import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';
import 'package:bloc_provider/bloc_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Filter;
import 'package:disclosure_app_fl/models/company.dart';
import 'package:disclosure_app_fl/models/filter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:disclosure_app_fl/utils/company_cache_manager.dart';
import 'package:disclosure_app_fl/utils/disclosure_filter_helper.dart';
import 'package:disclosure_app_fl/utils/notification_topic_helper.dart';
import 'package:disclosure_app_fl/utils/tag_migration_helper.dart';
import 'package:disclosure_app_fl/utils/topic_sync_helper.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';

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
  final _edinetDateController = BehaviorSubject<DateTime>.seeded(
    DateTime.now(),
  );
  final _disclosure$ = BehaviorSubject<List<DocumentSnapshot>>();
  final _filter$ = BehaviorSubject<List<Filter>>();
  final _edinetFilter$ = BehaviorSubject<String>.seeded('');
  final _showOnlyFavorites$ = BehaviorSubject<bool>.seeded(false);
  final _customFilter$ = BehaviorSubject<List<Filter>>.seeded([]);
  final _setDisclosureOrder$ = BehaviorSubject<String?>.seeded("最新");

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

  // favorites
  final BehaviorSubject<List<String>> _favorite$ = BehaviorSubject();
  final BehaviorSubject<List<Company>> _favoriteWithName$ = BehaviorSubject();
  final StreamController<String?> _addFavoriteController = StreamController();
  final StreamController<String?> _removeFavoriteController =
      StreamController();
  final StreamController<String?> _switchFavoriteController =
      StreamController();

  // companyList
  final _companies$ = BehaviorSubject<List<Company>>();
  final _companiesMap$ = BehaviorSubject<Map<String, Company>>();
  final _companiesCodeMap$ = BehaviorSubject<Map<String, Company>>();
  final _storage = FirebaseStorage.instanceFor(bucket: 'gs://disclosure-app-2');

  // notifications
  final _notifications$ = BehaviorSubject<List<Company>>();
  final _tagsNotifications$ = BehaviorSubject<List<String>>();

  ValueStream<List<DocumentSnapshot>> get disclosure$ => _disclosure$.stream;

  Sink<int?> get refreshDisclosures => _refreshDisclosuresController.sink;
  ValueStream<int?> get newDisclosureCount =>
      _newDisclosureCountController.stream;

  Sink<DateTime> get date => _dateController.sink;
  ValueStream<DateTime> get date$ => _dateController.stream;
  ValueStream<List<Company>> get company$ => _companies$.stream;
  ValueStream<Map<String, Company>> get companyMap$ => _companiesMap$.stream;
  ValueStream<Map<String, Company>> get companyCodeMap$ =>
      _companiesCodeMap$.stream;
  Sink<DateTime> get edinetDate => _edinetDateController.sink;
  ValueStream<DateTime> get edinetDate$ => _edinetDateController.stream;
  Sink<String> get addFilter => _filterChangeController.sink;
  ValueStream<User> get user$ => _userController.stream;
  ValueStream<List<Filter>> get filter$ => _filter$.stream;
  ValueStream<String> get edinetFilter$ => _edinetFilter$.stream;
  Sink<String> get edinetFilterController => _edinetFilter$.sink;
  Stream<int> get filterCount$ =>
      _filter$.map((f) => f.where((_f) => _f.isSelected).length);

  Sink<bool> get setShowOnlyFavorites => _showOnlyFavorites$.sink;
  ValueStream<bool> get showOnlyFavorites$ => _showOnlyFavorites$.stream;

  ValueStream<bool> get edinetShowOnlyFavorite$ =>
      _edinetShowOnlyFavoriteController.stream;
  Sink<bool> get edinetSetShowOnlyFavorite =>
      _edinetShowOnlyFavoriteController.sink;

  ValueStream<Map<String, dynamic>> get settings$ => _setting$.stream;

  Sink<String?> get addFavorite => _addFavoriteController.sink;
  Sink<String?> get removeFavorite => _removeFavoriteController.sink;
  Sink<String?> get switchFavorite => _switchFavoriteController.sink;
  ValueStream<List<String>> get favorites$ => _favorite$.stream;
  ValueStream<List<Company>> get favoritesWithName$ =>
      _favoriteWithName$.stream;

  ValueStream<List<Company>> get notifications$ => _notifications$.stream;
  ValueStream<List<String>> get tagsNotifications$ =>
      _tagsNotifications$.stream;

  ValueStream<String?> get setDisclosureOrder$ => _setDisclosureOrder$.stream;
  Sink<String?> get setDisclosureOrder => _setDisclosureOrder$.sink;

  final _handleFilterChange = (List<Filter> prev, String element, _) {
    prev.firstWhere((filter) => filter.title == element).toggle();
    return prev;
  };
  final _change = PublishSubject<String>();

  final TopicSyncHelper _topicSyncHelper;
  final TagMigrationHelper _tagMigrationHelper;

  AppBloc({
    TopicSyncHelper? topicSyncHelper,
    TagMigrationHelper? tagMigrationHelper,
  }) : _topicSyncHelper = topicSyncHelper ?? TopicSyncHelper(),
       _tagMigrationHelper = tagMigrationHelper ?? TagMigrationHelper() {
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
        .switchMap(
          (list) => _change
              .scan<List<Filter>>(_handleFilterChange, list)
              .startWith(list),
        )
        .pipe(_filter$);

    // _customFilter$.add([]);

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
            FirebaseCrashlytics.instance.recordError(
              error,
              stack,
              fatal: false,
            );
          })
          .share();

      final Stream<QuerySnapshot<Map<String, dynamic>>?> first = _disclosures
          .take(1)
          .startWith(null);
      final Stream<QuerySnapshot<Map<String, dynamic>>?> cont = _disclosures
          .skip(1)
          .sample(_refreshDisclosuresController.stream); //.doOnData(print));

      final Stream<QuerySnapshot<Map<String, dynamic>>?> _disclosures2 = first
          .mergeWith([cont]);

      final disclosureCount = _disclosures
          .skip(1)
          .doOnData((data) => print(data?.docChanges.map((v) => v.type)))
          .map(
            (data) => data?.docChanges
                .where((change) => change.type == DocumentChangeType.added)
                .length,
          );
      final newDisclosureCount =
          Rx.merge([
                disclosureCount,
                _refreshDisclosuresController.stream.map((_) => null),
              ])
              .scan((dynamic a, e, _) {
                print([a, e]);
                if (e == null) {
                  return 0;
                }
                return a + e;
              }, 0)
              .startWith(0);

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
        List<DocumentSnapshot>
      >(
        this._filter$,
        _disclosures2,
        _hideDailyDisclosure$,
        showingFavorite,
        _setDisclosureOrder$,
        (_filters, d, _hideDaily, _favorites, order) {
          print([_filters, d, _hideDaily, _favorites, order]);
          if (d == null) return [];
          // ⚡ Bolt: Pre-compute filters and convert lists to sets outside the loop
          // to avoid O(N*M) complexity and garbage collection thrashing.
          final selectedFilterStr = _filters
              .where((filter) => filter.isSelected)
              .map((filter) => filter.title)
              .toSet();

          final favoriteSet = _favorites.toSet();

          final docs = d.docs
              .where(
                (doc) => DisclosureFilterHelper.matchesFilter(
                  data: doc.data(),
                  selectedFilterTitles: selectedFilterStr,
                  hideDailyDisclosure: _hideDaily,
                  favoriteCompanyCodes: favoriteSet,
                ),
              )
              .toList();
          if (order != null) {
            final comp = comparators[order];
            if (comp != null) {
              docs.sort(comp);
            }
          }
          return docs;
        },
      );
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
        )
        .switchMap((value) {
          final start = value[0];
          final end = value[1];
          return createDateStream(start, end);
        })
        .pipe(_disclosure$);

    FirebaseAuth.instance.userChanges().whereNotNull().pipe(_userController);

    _createSettingStream();

    _createCompanyListStreams();

    _createNotificationStreams();
  }

  void _createSettingStream() {
    final favorites = Set<String?>();

    final _publishFavorites = (List<String?> _favorites) async {
      final user = await _userController.first;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        "favorites": _favorites,
      }, SetOptions(merge: true));
    };

    _addFavoriteController.stream.listen((code) {
      if (code == null) return;
      if (!favorites.contains(code)) {
        favorites.add(code);
        _publishFavorites(favorites.toList());
      }
    });

    _removeFavoriteController.stream.listen((code) {
      if (code == null) return;
      if (favorites.contains(code)) {
        favorites.remove(code);
        _publishFavorites(favorites.toList());
      }
    });

    _switchFavoriteController.stream.listen((code) {
      if (code == null) return;
      if (favorites.contains(code)) {
        favorites.remove(code);
      } else {
        favorites.add(code);
      }
      _publishFavorites(favorites.toList());
    });

    _userController
        .share()
        .switchMap(
          (user) => FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots()
              .handleError((dynamic error, StackTrace stack) {
                debugPrint("User settings stream error: $error");
                FirebaseCrashlytics.instance.recordError(
                  error,
                  stack,
                  fatal: false,
                );
              }),
        )
        .map((res) => res.data() ?? {})
        .pipe(_setting$);

    _setting$
        .map<List<String>>((data) => data["favorites"]?.cast<String>() ?? [])
        .pipe(_favorite$);

    _setting$
        .map<List<String>>(
          (data) => data["notification_tags"]?.cast<String>() ?? [],
        )
        .pipe(_tagsNotifications$);

    _setting$
        .map<bool>(
          (setting) =>
              (setting['setting'] ?? {})['hideDailyDisclosure'] ?? false,
        )
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

    _favoriteWithName$.pipe(_notifications$);
  }

  void _createCompanyListStreams() {
    Stream<List<dynamic>> _handleOpenFile() async* {
      final appDir = await getApplicationDocumentsDirectory();
      final companyJsonFile = File('${appDir.path}/companies.json');
      final ref = _storage.ref().child('companies.json');

      final cacheManager = CompanyCacheManager(
        file: companyJsonFile,
        downloadFunction: (destFile) => ref.writeToFile(destFile),
      );

      yield* cacheManager.getCompaniesStream(
        onErrorFallback: (error, stack) {
          debugPrint("Failed to download companies.json: $error");
          FirebaseCrashlytics.instance.recordError(
            error,
            stack,
            reason: 'Failed to download companies.json in background',
            fatal: false,
          );
        },
      );
    }

    _userController
        .switchMap((user) => _handleOpenFile())
        .handleError((dynamic error, StackTrace stack) {
          debugPrint("Companies stream error: $error");
          FirebaseCrashlytics.instance.recordError(
            error,
            stack,
            reason: 'Unhandled error in company list stream',
            fatal: false,
          );
        })
        .map(
          (data) => data
              .map(
                (d) => Company(
                  (d['code'] as String).substring(0, 4),
                  name: d['name'],
                  edinetCode: d['edinetCode'],
                  nameKana: d['nameKana'],
                ),
              )
              .toList(),
        )
        .pipe(_companies$);

    _companies$
        .share()
        .map((companies) {
          return Map.fromEntries(
            companies.map((c) => MapEntry(c.edinetCode!, c)),
          );
        })
        .pipe(_companiesMap$);

    _companies$
        .share()
        .map((companies) {
          // ⚡ Bolt: Provide a map for O(1) company lookups by code.
          // This prevents O(N^2) complexity in stream transformations.
          return Map.fromEntries(
            companies
                .where((c) => c.code != null)
                .map((c) => MapEntry(c.code!, c)),
          );
        })
        .pipe(_companiesCodeMap$);
  }

  void _createNotificationStreams() {
    final messaging = FirebaseMessaging.instance;

    // 1. 初回タグ通知マイグレーション（未移行ユーザーがアプリを起動したときに1度だけ実行）
    Rx.combineLatest2<User, Map<String, dynamic>, void>(
      _userController.stream,
      _setting$.stream,
      (user, setting) {
        if (!setting.containsKey('notification_tags')) {
          // ignore: deprecated_member_use
          // ignore: deprecated_member_use_from_same_package
          messaging
              .getToken()
              .then((token) {
                _tagMigrationHelper.ensureTagsMigrated(
                  uid: user.uid,
                  fcmToken: token,
                  userDocData: setting,
                );
              })
              .catchError((dynamic e) {
                debugPrint("getToken for tag migration failed: $e");
              });
        }
      },
    ).listen((_) {});

    // 2. トークン変更（再インストール、端末データ消去、リフレッシュ）検知と同期
    void triggerTopicSync() {
      final favs = _favorite$.hasValue ? _favorite$.value : <String>[];
      final tags = _tagsNotifications$.hasValue
          ? _tagsNotifications$.value
          : <String>[];
      final desiredTopics = {
        ...favs.map(NotificationTopicHelper.toTopic),
        ...tags.map(NotificationTopicHelper.fromTag),
      };
      _topicSyncHelper.syncTopics(desiredTopics: desiredTopics);
    }

    // ignore: deprecated_member_use
    messaging.onTokenRefresh.listen((newToken) async {
      final changed = await _topicSyncHelper.handleTokenChange(newToken);
      if (changed) {
        triggerTopicSync();
      }
    });

    // ignore: deprecated_member_use
    // ignore: deprecated_member_use_from_same_package
    messaging
        .getToken()
        .then((token) async {
          final changed = await _topicSyncHelper.handleTokenChange(token);
          if (changed) {
            triggerTopicSync();
          }
        })
        .catchError((dynamic e) {
          debugPrint("Initial getToken check failed: $e");
        });

    // 3. Firestore (favorites / notification_tags) の変化に応じたトピック差分同期
    Rx.combineLatest2<List<String>, List<String>, Set<String>>(
      _favorite$,
      _tagsNotifications$,
      (favs, tags) {
        final codeTopics = favs.map(NotificationTopicHelper.toTopic);
        final tagTopics = tags.map(NotificationTopicHelper.fromTag);
        return {...codeTopics, ...tagTopics};
      },
    ).distinct((prev, curr) => setEquals(prev, curr)).listen((desiredTopics) {
      debugPrint(
        "[TopicSync] Desired topics updated: ${desiredTopics.length} topics (favorites: ${_favorite$.valueOrNull?.length ?? 0}, tags: ${_tagsNotifications$.valueOrNull?.length ?? 0})",
      );
      _topicSyncHelper.syncTopics(desiredTopics: desiredTopics);
    });
  }

  @override
  void dispose() {
    _dateController.close();
    _disclosure$.close();
    _userController.close();
    _filterChangeController.close();
    _filter$.close();
    _edinetFilter$.close();
    _addFavoriteController.close();
    _removeFavoriteController.close();
    _switchFavoriteController.close();
    _setting$.close();
    _hideDailyDisclosure$.close();
    _favorite$.close();
    _favoriteWithName$.close();
    _companies$.close();
    _companiesMap$.close();
    _companiesCodeMap$.close();
    _notifications$.close();
    _tagsNotifications$.close();
    _customFilter$.close();
    _showOnlyFavorites$.close();
    _edinetShowOnlyFavoriteController.close();
    _edinetDateController.close();
    _setDisclosureOrder$.close();
    _refreshDisclosuresController.close();
    _change.close();
  }
}
