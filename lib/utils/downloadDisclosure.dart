import 'dart:io';

import 'package:disclosure_app_fl/models/disclosure.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:open_file_safe/open_file_safe.dart';
import 'package:path_provider/path_provider.dart';

final _storage = FirebaseStorage.instance;
final _analytics = FirebaseAnalytics.instance;

Future<Null> downloadAndOpenDisclosure(Disclosure item) async {
  final pdf = "${item.document}.pdf";
  final ref = _storage.ref().child('disclosures').child(pdf);
  // final url = ref.getDownloadURL();
  // final http.Response downloadData = await http.get(url);
  // final Directory systemTempDir = Directory.systemTemp;
  final Directory systemTempDir = await getTemporaryDirectory();
  final File tempFile = File('${systemTempDir.path}/$pdf');
  if (!tempFile.existsSync()) {
    _analytics.logEvent(name: 'select_content', parameters: {
      'content_type': 'disclosure_pdf',
      'item_id': item.document,
      'code': item.code
    });
    await tempFile.create();
    final DownloadTask task = ref.writeToFile(tempFile);
    final int byteCount = (await task).totalBytes;
    print(byteCount);
  }

  OpenFile.open(tempFile.path);
}
