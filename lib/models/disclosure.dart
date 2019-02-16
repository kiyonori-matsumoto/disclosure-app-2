import 'package:cloud_firestore/cloud_firestore.dart';

class Disclosure {
  String code;
  String company;
  String title;
  String document;
  String exchanges;
  int time;
  int viewCount;
  List<String> tags;
  bool isSelected;
  DateTime addAt;

  Disclosure(
      {this.code,
      this.company,
      this.title,
      this.document,
      this.exchanges,
      this.time,
      this.viewCount,
      this.tags,
      this.isSelected = false});

  Disclosure.fromDocumentSnapshot(DocumentSnapshot snapshot) {
    final item = snapshot.data;
    code = item['code'];
    company = item['company'];
    title = item['title'];
    document = item['document'];
    exchanges = item['exchanges'];
    time = ((v) => v is String ? int.parse(v) : v)(item['time']);
    viewCount = item['view_count'];
    tags = (item['tags'] ?? {}).keys.toList().cast<String>();
    isSelected = false;
    if (item.containsKey('add_at')) {
      addAt = DateTime.fromMicrosecondsSinceEpoch(item['add_at']);
    }
  }

  Map<String, dynamic> toObject() {
    return {
      'code': code,
      'company': company,
      'title': title,
      'document': document,
      'exchanges': exchanges,
      'time': time,
      'tags': tags.fold({}, (obj, tag) {
        obj[tag] = true;
        return obj;
      }),
    };
  }
}
