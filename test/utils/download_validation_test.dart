import 'package:flutter_test/flutter_test.dart';
import 'package:disclosure_app_fl/utils/download_edinet.dart';
import 'package:disclosure_app_fl/utils/download_disclosure.dart';
import 'package:disclosure_app_fl/models/disclosure.dart';

void main() {
  group('Download validation', () {
    test('downloadAndOpenEdinet throws ArgumentError on null docId', () async {
      expect(() => downloadAndOpenEdinet(null), throwsArgumentError);
    });

    test('downloadAndOpenEdinet throws ArgumentError on empty docId', () async {
      expect(() => downloadAndOpenEdinet(''), throwsArgumentError);
    });

    test('downloadAndOpenEdinet throws ArgumentError on path traversal docId', () async {
      expect(() => downloadAndOpenEdinet('../hack'), throwsArgumentError);
      expect(() => downloadAndOpenEdinet('doc/123'), throwsArgumentError);
      expect(() => downloadAndOpenEdinet('doc 123'), throwsArgumentError);
    });

    test('downloadAndOpenDisclosure throws ArgumentError on invalid document', () async {
      final invalidItem = Disclosure(document: null);
      expect(() => downloadAndOpenDisclosure(invalidItem), throwsArgumentError);

      final traversalItem = Disclosure(document: '../../etc/passwd');
      expect(() => downloadAndOpenDisclosure(traversalItem), throwsArgumentError);
    });
  });
}
