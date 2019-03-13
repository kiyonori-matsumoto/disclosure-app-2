import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

final formatter = DateFormat.yMd('ja');

class CompanySettlement {
  String name;
  String code;
  String quote;
  DateTime schedule;
  String scheduleStr;
  String settlementDate;

  CompanySettlement.fromDocumentSnapshot(DocumentSnapshot snapshot) {
    final item = snapshot.exists ? snapshot.data : null;
    if (item == null) {
      throw Exception("null snapshot");
    }
    this.name = item['name'];
    this.code = item['code'];
    this.quote = item['quote'] == '-' ? '' : item['quote'];
    this.schedule = DateTime.tryParse(item['schedule']);
    this.scheduleStr = item['schedule'];
    this.settlementDate = item['settlementDate'];
  }

  @override
  String toString() {
    return "${this.name} ${this.quote}";
  }

  String toMessage() {
    return "次回の決算${this.quote == '' ? '' : '(' + this.quote + ')'}発表予定日は${this.schedule != null ? formatter.format(this.schedule) : this.scheduleStr}です";
  }
}
