import 'package:intl/intl.dart';

final timeFormatter = DateFormat.Hm('ja');
final dateFormatter = DateFormat.yMd('ja');
final datetimeFormatter = DateFormat.yMd('ja').add_Hm();
final dateHyphenFormatter = DateFormat('yyyy-MM-dd', 'ja');

String toTime(int timestamp, {bool showDate = false}) {
  final time = DateTime.fromMillisecondsSinceEpoch(timestamp);
  return showDate ? datetimeFormatter.format(time) : timeFormatter.format(time);
}

String toDate(int timestamp) {
  final time = DateTime.fromMillisecondsSinceEpoch(timestamp);
  return dateFormatter.format(time);
}

String toDateHyphenate(DateTime time) {
  return dateHyphenFormatter.format(time);
}
