import 'dart:async';

import 'package:rxdart/rxdart.dart';

void connect<T>(Stream<T> stream, Subject<T> subject) {
  StreamSubscription<T> subscription;
  subject.onListen = () {
    subscription = stream.listen(subject.add, onError: subject.addError);
  };
  subject.onCancel = () {
    subscription.cancel();
  };
}
