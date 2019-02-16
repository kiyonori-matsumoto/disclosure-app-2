import 'package:intl/intl.dart';

final timeFormatter = DateFormat.Hm('ja');
final dateFormatter = DateFormat.yMd('ja').add_Hm();
String toTime(int timestamp, {bool showDate = false}) {
  final time = DateTime.fromMillisecondsSinceEpoch(timestamp);
  return showDate ? dateFormatter.format(time) : timeFormatter.format(time);
}
