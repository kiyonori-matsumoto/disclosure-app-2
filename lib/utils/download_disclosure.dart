import 'dart:io';

import 'package:disclosure_app_fl/models/disclosure.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

final _storage = FirebaseStorage.instance;
final _analytics = FirebaseAnalytics.instance;
final _safeDocPattern = RegExp(r'^[a-zA-Z0-9_\-]+$');

Future<void> downloadAndOpenDisclosure(Disclosure item) async {
  final document = item.document;
  if (document == null || document.isEmpty || !_safeDocPattern.hasMatch(document)) {
    throw ArgumentError('Invalid disclosure document identifier: $document');
  }

  final pdf = "$document.pdf";
  final ref = _storage.ref().child('disclosures').child(pdf);
  final Directory systemTempDir = await getTemporaryDirectory();
  final File tempFile = File('${systemTempDir.path}/$pdf');

  if (!tempFile.existsSync()) {
    await _analytics.logEvent(name: 'select_content', parameters: {
      'content_type': 'disclosure_pdf',
      'item_id': item.document,
      'code': item.code
    });

    final File downloadingFile = File('${systemTempDir.path}/$pdf.tmp');
    try {
      await downloadingFile.create();
      final DownloadTask task = ref.writeToFile(downloadingFile);
      final TaskSnapshot snapshot = await task;
      debugPrint('downloadDisclosure bytes: ${snapshot.totalBytes}');
      if (downloadingFile.existsSync()) {
        await downloadingFile.rename(tempFile.path);
      }
    } catch (e) {
      if (downloadingFile.existsSync()) {
        try {
          downloadingFile.deleteSync();
        } catch (_) {}
      }
      rethrow;
    }
  }

  await OpenFilex.open(tempFile.path);
}
