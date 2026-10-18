import 'dart:convert';
import 'dart:io';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

final _analytics = FirebaseAnalytics.instance;
final _safeDocIdPattern = RegExp(r'^[a-zA-Z0-9_\-]+$');

Future<void> downloadAndOpenEdinet(String? docId, {String code = ''}) async {
  if (docId == null || docId.isEmpty || !_safeDocIdPattern.hasMatch(docId)) {
    throw ArgumentError('Invalid docId: $docId');
  }

  debugPrint('downloadAndOpenEdinet: $docId');

  final Directory systemTempDir = await getTemporaryDirectory();
  final targetFile = File('${systemTempDir.path}/$docId.pdf');

  if (!targetFile.existsSync()) {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    final tempDownloadingFile = File('${systemTempDir.path}/$docId.tmp');

    try {
      final downloadUrlUri = Uri.parse(
          "https://asia-northeast1-disclosure-app.cloudfunctions.net/getDownloadUrlEdinetV2?docId=$docId");
      final downloadUrlReq = await client
          .getUrl(downloadUrlUri)
          .timeout(const Duration(seconds: 15));
      final downloadUrlRes =
          await downloadUrlReq.close().timeout(const Duration(seconds: 15));

      if (downloadUrlRes.statusCode != 200) {
        debugPrint("failed to get download url: status ${downloadUrlRes.statusCode}");
        throw Exception('Failed to get download url: status ${downloadUrlRes.statusCode}');
      }

      final downloadUrl =
          await downloadUrlRes.transform(utf8.decoder).join();
      final signedUrl = jsonDecode(downloadUrl)['signedUrl'] as String?;
      if (signedUrl == null || signedUrl.isEmpty) {
        throw Exception('Invalid signedUrl in response');
      }

      final req = await client
          .getUrl(Uri.parse(signedUrl))
          .timeout(const Duration(seconds: 15));
      final res = await req.close().timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) {
        throw Exception('Failed to download PDF: status ${res.statusCode}');
      }

      final sink = tempDownloadingFile.openWrite();
      try {
        await res.pipe(sink);
      } catch (e) {
        await sink.close();
        rethrow;
      }

      if (tempDownloadingFile.existsSync()) {
        await tempDownloadingFile.rename(targetFile.path);
      }

      await _analytics.logEvent(name: 'select_content', parameters: {
        'content_type': 'edinet_pdf',
        'item_id': docId,
        'code': code,
      });
    } catch (e) {
      if (tempDownloadingFile.existsSync()) {
        try {
          tempDownloadingFile.deleteSync();
        } catch (_) {}
      }
      rethrow;
    } finally {
      client.close();
    }
  }

  await OpenFilex.open(targetFile.path);
}
