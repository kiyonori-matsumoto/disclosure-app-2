import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:disclosure_app_fl/models/forensic_result.dart';

class Disclosure {
  String? code;
  String? company;
  String? title;
  String? document;
  String? exchanges;
  int? time;
  int? viewCount;
  List<String>? tags;
  bool? isSelected;
  DateTime? addAt;
  ForensicResult? forensic;

  Disclosure(
      {this.code,
      this.company,
      this.title,
      this.document,
      this.exchanges,
      this.time,
      this.viewCount,
      this.tags,
      this.isSelected = false,
      this.forensic});

  Disclosure.fromDocumentSnapshot(DocumentSnapshot snapshot) {
    final item = snapshot.data() as Map<String, dynamic>;
    code = item['code'];
    company = item['company'];
    title = item['title'];
    document = item['document'];
    exchanges = item['exchanges'];
    time = ((dynamic v) => v is String ? int.parse(v) : v)(item['time']);
    viewCount = item['view_count'];
    tags = (item['tags'] ?? {}).keys.toList().cast<String>();
    isSelected = false;
    if (item.containsKey('add_at')) {
      addAt = DateTime.fromMicrosecondsSinceEpoch(item['add_at']);
    }
    if (item.containsKey('forensic') && item['forensic'] != null) {
      try {
        final forensicMap = item['forensic'] is Map<String, dynamic>
            ? item['forensic'] as Map<String, dynamic>
            : Map<String, dynamic>.from(item['forensic'] as Map);
        forensic = ForensicResult.fromMap(forensicMap);
      } catch (_) {}
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
      'tags': (tags ?? []).fold<Map<String, dynamic>>({}, (obj, tag) {
        obj[tag] = true;
        return obj;
      }),
      if (forensic != null) 'forensic': forensic!.toMap(),
    };
  }
}
