import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxdart/rxdart.dart';
import 'package:disclosure_app_fl/bloc/bloc_util.dart';

void main() {
  group('connect', () {
    test('forwards data from stream to subject when listened', () async {
      final controller = StreamController<int>();
      final subject = PublishSubject<int>();

      connect(controller.stream, subject);

      final received = <int>[];
      final subscription = subject.listen(received.add);

      controller.add(1);
      controller.add(2);
      controller.add(3);

      await pumpEventQueue();

      expect(received, [1, 2, 3]);

      await subscription.cancel();
      await controller.close();
      await subject.close();
    });

    test('forwards error from stream to subject', () async {
      final controller = StreamController<int>();
      final subject = PublishSubject<int>();

      connect(controller.stream, subject);

      dynamic receivedError;
      final subscription = subject.listen(
        (_) {},
        onError: (e) {
          receivedError = e;
        },
      );

      controller.addError('test error');
      await pumpEventQueue();

      expect(receivedError, 'test error');

      await subscription.cancel();
      await controller.close();
      await subject.close();
    });

    test('cancels subscription when subject has no listeners', () async {
      var isCancelled = false;
      final controller = StreamController<int>(onCancel: () {
        isCancelled = true;
      });
      final subject = PublishSubject<int>();

      connect(controller.stream, subject);

      final subscription = subject.listen((_) {});
      await pumpEventQueue();
      expect(isCancelled, isFalse);

      await subscription.cancel();
      await pumpEventQueue();
      expect(isCancelled, isTrue);

      await controller.close();
      await subject.close();
    });
  });
}
