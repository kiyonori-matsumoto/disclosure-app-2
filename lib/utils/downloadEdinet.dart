import 'dart:convert';
import 'dart:io';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:open_file_safe/open_file_safe.dart';
import 'package:path_provider/path_provider.dart';

final _analytics = FirebaseAnalytics.instance;

Future<Null> downloadAndOpenEdinet(String? docId, {String code = ''}) async {
  print(docId);

  final Directory systemTempDir = await getTemporaryDirectory();
  final tmpFile = File('${systemTempDir.path}/$docId.pdf');

  if (!tmpFile.existsSync()) {
    final client = HttpClient();
    client.badCertificateCallback = (_, __, ___) => true;

    final downloadUrlReq = await client.getUrl(Uri.parse(
        "https://us-central1-disclosure-app-dev.cloudfunctions.net/getDownloadUrlEdinet?docId=$docId"));
    final downloadUrlRes = await downloadUrlReq.close();
    if (downloadUrlRes.statusCode != 200) {
      print("failed to get download url");
      // throw error
      throw Exception('Failed to get download url');
    }

    // get download url from body
    final downloadUrl = await downloadUrlRes.transform(utf8.decoder).join();

    final req =
        await client.getUrl(Uri.parse(jsonDecode(downloadUrl)['signedUrl'][0]));

    final res = await req.close();

    await res.pipe(tmpFile.openWrite());
    await _analytics.logEvent(name: 'select_content', parameters: {
      'content_type': 'edinet_pdf',
      'item_id': docId,
      'code': code,
    });
  }
  await OpenFile.open(tmpFile.path);
}
