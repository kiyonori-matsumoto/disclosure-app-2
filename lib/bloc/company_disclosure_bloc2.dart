import 'dart:async';

import 'package:bloc_provider/bloc_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

class FirestoreGetCount<T> extends Bloc {
  final Query query;
  final Function(T) getFn;
  final T Function(DocumentSnapshot) mapper;
  final ValueStream<User> user$;

  final PublishSubject<void> _reloadController = PublishSubject();
  final PublishSubject<T?> _loadNextController = PublishSubject();
  final BehaviorSubject<List<T>?> _data$ = BehaviorSubject();
  final BehaviorSubject<bool> _isLoading$ = BehaviorSubject.seeded(true);

  Sink<void> get reload => _reloadController.sink;
  Sink<T?> get loadNext => _loadNextController.sink;
  ValueStream<List<T>?> get data$ => _data$.stream;
  ValueStream<bool> get isLoading$ => _isLoading$.stream;

  FirestoreGetCount({
    required this.query,
    required this.getFn,
    required this.mapper,
    required this.user$,
  }) {
    _reloadController.stream.switchMap((_) {
      return _loadNextController.stream
          .startWith(null)
          .doOnData((_) => this._isLoading$.add(true))
          .flatMap((last) {
            var q = query;
            if (last != null) {
              var lastData = getFn(last);
              q = q.startAfter([lastData]);
            }
            return Stream.fromFuture(
              user$.first.then((user) => q.limit(20).get()),
            );
          })
          .doOnData((_) => this._isLoading$.add(false))
          .map((d) => d.docs.map(mapper).toList())
          .scan<List<T>?>((acc, curr, i) {
            return (acc ?? []) + curr;
          }, [])
          .startWith(null)
          .handleError((dynamic error, StackTrace stack) {
            debugPrint("FirestoreGetCount error: $error");
            FirebaseCrashlytics.instance.recordError(error, stack, fatal: false);
            this._isLoading$.add(false);
          });
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

