import 'package:intl/intl.dart';

String toTime(int timestamp) {
  final formatter = DateFormat.Hm();
  final time = DateTime.fromMillisecondsSinceEpoch(timestamp);
  return formatter.format(time);
}