import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';

final _storage = FirebaseStorage.instance;
Future<Null> downloadAndOpenDisclosure(String document) async {
  final ref = _storage.ref().child('disclosures').child("${document}.pdf");
  final url = ref.getDownloadURL();
  // final http.Response downloadData = await http.get(url);
  final Directory systemTempDir = Directory.systemTemp;
  final File tempFile = File('${systemTempDir.path}/${document}.pdf');
  if (!tempFile.existsSync()) {
    await tempFile.create();
    final StorageFileDownloadTask task = ref.writeToFile(tempFile);
    final int byteCount = (await task.future).totalByteCount;
    print(byteCount);
  }

  OpenFile.open(tempFile.path);
}