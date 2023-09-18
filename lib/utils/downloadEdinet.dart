import 'dart:io';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

final _analytics = FirebaseAnalytics();

Future<Null> downloadAndOpenEdinet(String docId, {String code = ''}) async {
  print(docId);
  final client = HttpClient();
  client.badCertificateCallback = (_, __, ___) => true;
  final req = await client.getUrl(Uri.parse(
      "https://disclosure.edinet-fsa.go.jp/api/v1/documents/${docId}?type=2"));

  final res = await req.close();
  final Directory systemTempDir = await getTemporaryDirectory();
  final tmpFile = File('${systemTempDir.path}/$docId.pdf');
  await res.pipe(tmpFile.openWrite(encoding: null));
  await OpenFilex.open(tmpFile.path);
  await _analytics.logEvent(name: 'select_content', parameters: {
    'content_type': 'edinet_pdf',
    'item_id': docId,
    'code': code,
  });
}
