import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

Future<Null> downloadAndOpenEdinet(String docId) async {
  print(docId);
  final client = HttpClient();
  client.badCertificateCallback = (_, __, ___) => true;
  final req = await client.getUrl(Uri.parse(
      "https://disclosure.edinet-fsa.go.jp/api/v1/documents/${docId}?type=2"));

  final res = await req.close();
  final Directory systemTempDir = await getTemporaryDirectory();
  final tmpFile = File('${systemTempDir.path}/$docId.pdf');
  await res.pipe(tmpFile.openWrite(encoding: null));

  OpenFile.open(tmpFile.path);
}
