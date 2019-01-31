import 'package:intl/intl.dart';

final timeFormatter = DateFormat.Hm();
final dateFormatter = DateFormat.yMd().add_Hm();
String toTime(int timestamp, {bool showDate = false}) {
  final time = DateTime.fromMillisecondsSinceEpoch(timestamp);
  return showDate ? dateFormatter.format(time) : timeFormatter.format(time);
}
